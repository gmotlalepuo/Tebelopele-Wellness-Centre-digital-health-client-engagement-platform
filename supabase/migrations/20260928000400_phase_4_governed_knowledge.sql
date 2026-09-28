begin;

insert into public.tebelopele_capabilities(slug, description) values
 ('content.author','Create and revise governed health content'),
 ('content.review','Review and approve governed health content'),
 ('content.publish','Publish and archive governed health content'),
 ('knowledge.manage','Manage source documents and indexing jobs')
on conflict (slug) do nothing;

alter table public.tebelopele_health_articles
  add column current_version_id uuid,
  add column review_due_at timestamptz,
  add column archived_at timestamptz;
alter table public.tebelopele_health_articles add constraint tebelopele_articles_current_version_fk foreign key(current_version_id) references public.tebelopele_health_article_versions(id) on delete restrict;
alter table public.tebelopele_health_article_versions
  add column source_object_key text,
  add column source_filename text,
  add column source_mime_type text,
  add column source_size_bytes bigint check(source_size_bytes is null or source_size_bytes between 1 and 10485760),
  add column source_sha256 text check(source_sha256 is null or source_sha256 ~ '^[a-f0-9]{64}$'),
  add column extracted_text text,
  add column processing_status text not null default 'ready' check(processing_status in ('queued','extracting','ready','failed')),
  add column processing_error text;
alter table public.tebelopele_faqs add column current_version_id uuid;
alter table public.tebelopele_faqs add constraint tebelopele_faqs_current_version_fk foreign key(current_version_id) references public.tebelopele_faq_versions(id) on delete restrict;
update public.tebelopele_health_articles set current_version_id=published_version_id where published_version_id is not null;
update public.tebelopele_faqs set current_version_id=published_version_id where published_version_id is not null;

create table public.tebelopele_content_tags (
 id uuid primary key default extensions.gen_random_uuid(), slug text not null unique check(slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'), name text not null unique, created_at timestamptz not null default now()
);
create table public.tebelopele_article_tags (
 article_id uuid not null references public.tebelopele_health_articles(id) on delete cascade,
 tag_id uuid not null references public.tebelopele_content_tags(id) on delete cascade,
 primary key(article_id,tag_id)
);
create table public.tebelopele_content_reviews (
 id uuid primary key default extensions.gen_random_uuid(),
 entity_type text not null check(entity_type in ('article','faq')),
 entity_id uuid not null,
 version_id uuid not null,
 decision text not null check(decision in ('submitted','changes_requested','approved','rejected','published','archived')),
 comment text check(comment is null or char_length(comment)<=4000),
 reviewer_id uuid not null references public.tebelopele_profiles(id) on delete restrict,
 created_at timestamptz not null default now()
);
create index tebelopele_content_reviews_entity_idx on public.tebelopele_content_reviews(entity_type,entity_id,created_at desc);

create table public.tebelopele_knowledge_index_jobs (
 id uuid primary key default extensions.gen_random_uuid(),
 article_version_id uuid not null references public.tebelopele_health_article_versions(id) on delete cascade,
 job_type text not null check(job_type in ('extract','chunk','embed','reindex','remove')),
 status text not null default 'queued' check(status in ('queued','processing','completed','failed','cancelled')),
 idempotency_key text not null unique,
 attempt_count integer not null default 0,
 last_error text,
 available_at timestamptz not null default now(),
 completed_at timestamptz,
 created_at timestamptz not null default now()
);
create index tebelopele_knowledge_jobs_due_idx on public.tebelopele_knowledge_index_jobs(status,available_at) where status in ('queued','failed');

create table public.tebelopele_knowledge_chunks (
 id uuid primary key default extensions.gen_random_uuid(),
 article_id uuid not null references public.tebelopele_health_articles(id) on delete cascade,
 article_version_id uuid not null references public.tebelopele_health_article_versions(id) on delete cascade,
 chunk_number integer not null check(chunk_number>=0),
 heading text,
 content text not null,
 token_count integer check(token_count is null or token_count>=0),
 embedding_provider text,
 embedding_model text,
 embedding jsonb,
 search_vector tsvector generated always as (to_tsvector('english',coalesce(heading,'')||' '||content)) stored,
 created_at timestamptz not null default now(),
 unique(article_version_id,chunk_number)
);
create index tebelopele_knowledge_chunks_fts_idx on public.tebelopele_knowledge_chunks using gin(search_vector);

create or replace function public.tebelopele_create_article_draft(article_slug text, article_title text, article_summary text, article_body text, article_source_name text default null, source_object_key text default null, source_filename text default null, source_mime_type text default null, source_size_bytes bigint default null, source_sha256 text default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare article_id uuid; version_id uuid; current_user_id uuid := (select auth.uid());
begin
 if not public.tebelopele_has_capability('content.author') then raise exception 'Author capability required'; end if;
 if article_slug !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$' then raise exception 'Invalid slug'; end if;
 insert into public.tebelopele_health_articles(slug,created_by,updated_by) values(article_slug,current_user_id,current_user_id) returning id into article_id;
 insert into public.tebelopele_health_article_versions(article_id,version_number,title,summary,body,source_name,extracted_text,created_by,source_object_key,source_filename,source_mime_type,source_size_bytes,source_sha256,processing_status)
 values(article_id,1,trim(article_title),trim(article_summary),trim(article_body),nullif(trim(article_source_name),''),trim(article_body),current_user_id,source_object_key,source_filename,source_mime_type,source_size_bytes,source_sha256,case when source_object_key is null then 'ready' else 'queued' end) returning id into version_id;
 if source_object_key is not null then insert into public.tebelopele_knowledge_index_jobs(article_version_id,job_type,idempotency_key) values(version_id,'extract','extract:'||version_id); end if;
 update public.tebelopele_health_articles set current_version_id=version_id where id=article_id;
 insert into public.tebelopele_audit_events(actor_id,action,entity_type,entity_id) values(current_user_id,'content.draft_created','health_article',article_id);
 return article_id;
end; $$;

create or replace function public.tebelopele_publish_article(target_article_id uuid, target_version_id uuid, review_comment text default null)
returns void language plpgsql security definer set search_path='' as $$
declare current_user_id uuid := (select auth.uid());
begin
 if not public.tebelopele_has_capability('content.publish') then raise exception 'Publication capability required'; end if;
 if not exists(select 1 from public.tebelopele_health_article_versions where id=target_version_id and article_id=target_article_id and processing_status='ready') then raise exception 'A ready version is required'; end if;
 if not exists(select 1 from public.tebelopele_content_reviews where entity_type='article' and entity_id=target_article_id and version_id=target_version_id and decision='approved') then raise exception 'An approval decision is required'; end if;
 update public.tebelopele_health_articles set status='published',published_version_id=target_version_id,current_version_id=target_version_id,published_at=now(),updated_by=current_user_id where id=target_article_id;
 insert into public.tebelopele_content_reviews(entity_type,entity_id,version_id,decision,comment,reviewer_id) values('article',target_article_id,target_version_id,'published',review_comment,current_user_id);
 insert into public.tebelopele_knowledge_index_jobs(article_version_id,job_type,idempotency_key) values(target_version_id,'reindex','publish:'||target_version_id) on conflict(idempotency_key) do nothing;
 insert into public.tebelopele_audit_events(actor_id,action,entity_type,entity_id) values(current_user_id,'content.published','health_article',target_article_id);
end; $$;

create or replace function public.tebelopele_search_published_knowledge(search_query text, result_limit integer default 10)
returns table(article_id uuid,article_version_id uuid,slug text,title text,heading text,excerpt text,rank real)
language sql stable security invoker set search_path='' as $$
 select a.id,v.id,a.slug,v.title,c.heading,left(c.content,320),ts_rank(c.search_vector,websearch_to_tsquery('english',search_query))
 from public.tebelopele_knowledge_chunks c
 join public.tebelopele_health_articles a on a.id=c.article_id and a.published_version_id=c.article_version_id
 join public.tebelopele_health_article_versions v on v.id=c.article_version_id
 where a.status='published' and a.published_at<=now() and a.visibility in ('public','authenticated')
   and (v.effective_at is null or v.effective_at<=now()) and (v.expires_at is null or v.expires_at>now())
   and c.search_vector @@ websearch_to_tsquery('english',search_query)
 order by 7 desc limit least(greatest(result_limit,1),25)
$$;

alter table public.tebelopele_content_tags enable row level security;
alter table public.tebelopele_article_tags enable row level security;
alter table public.tebelopele_content_reviews enable row level security;
alter table public.tebelopele_knowledge_index_jobs enable row level security;
alter table public.tebelopele_knowledge_chunks enable row level security;
create policy "content_tags_public_read" on public.tebelopele_content_tags for select to anon,authenticated using(true);
create policy "article_tags_public_read" on public.tebelopele_article_tags for select to anon,authenticated using(exists(select 1 from public.tebelopele_health_articles a where a.id=article_id and a.status='published' and a.visibility='public'));
create policy "content_tags_manage" on public.tebelopele_content_tags for all to authenticated using(public.tebelopele_has_capability('content.author')) with check(public.tebelopele_has_capability('content.author'));
create policy "article_tags_manage" on public.tebelopele_article_tags for all to authenticated using(public.tebelopele_has_capability('content.author')) with check(public.tebelopele_has_capability('content.author'));
create policy "article_staff_read" on public.tebelopele_health_articles for select to authenticated using(public.tebelopele_has_capability('content.author') or public.tebelopele_has_capability('content.review'));
create policy "article_staff_write" on public.tebelopele_health_articles for all to authenticated using(public.tebelopele_has_capability('content.author')) with check(public.tebelopele_has_capability('content.author'));
create policy "article_version_staff_read" on public.tebelopele_health_article_versions for select to authenticated using(public.tebelopele_has_capability('content.author') or public.tebelopele_has_capability('content.review'));
create policy "article_version_staff_insert" on public.tebelopele_health_article_versions for insert to authenticated with check(public.tebelopele_has_capability('content.author') and created_by=(select auth.uid()));
create policy "faq_staff_read" on public.tebelopele_faqs for select to authenticated using(public.tebelopele_has_capability('content.author') or public.tebelopele_has_capability('content.review'));
create policy "faq_staff_write" on public.tebelopele_faqs for all to authenticated using(public.tebelopele_has_capability('content.author')) with check(public.tebelopele_has_capability('content.author'));
create policy "faq_version_staff_read" on public.tebelopele_faq_versions for select to authenticated using(public.tebelopele_has_capability('content.author') or public.tebelopele_has_capability('content.review'));
create policy "faq_version_staff_insert" on public.tebelopele_faq_versions for insert to authenticated with check(public.tebelopele_has_capability('content.author') and created_by=(select auth.uid()));
create policy "reviews_staff_read" on public.tebelopele_content_reviews for select to authenticated using(public.tebelopele_has_capability('content.author') or public.tebelopele_has_capability('content.review'));
create policy "reviews_staff_insert" on public.tebelopele_content_reviews for insert to authenticated with check(public.tebelopele_has_capability('content.review') and reviewer_id=(select auth.uid()));
create policy "jobs_staff_only" on public.tebelopele_knowledge_index_jobs for all to authenticated using(public.tebelopele_has_capability('knowledge.manage')) with check(public.tebelopele_has_capability('knowledge.manage'));
create policy "chunks_published_read" on public.tebelopele_knowledge_chunks for select to anon,authenticated using(exists(select 1 from public.tebelopele_health_articles a where a.id=article_id and a.published_version_id=article_version_id and a.status='published' and a.visibility='public'));
create policy "chunks_staff_manage" on public.tebelopele_knowledge_chunks for all to authenticated using(public.tebelopele_has_capability('knowledge.manage')) with check(public.tebelopele_has_capability('knowledge.manage'));

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('tebelopele-knowledge','tebelopele-knowledge',false,10485760,array['application/pdf','text/plain','text/markdown','application/vnd.openxmlformats-officedocument.wordprocessingml.document']) on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
create policy "knowledge_objects_staff_read" on storage.objects for select to authenticated using(bucket_id='tebelopele-knowledge' and (public.tebelopele_has_capability('content.author') or public.tebelopele_has_capability('content.review')));
create policy "knowledge_objects_author_insert" on storage.objects for insert to authenticated with check(bucket_id='tebelopele-knowledge' and public.tebelopele_has_capability('content.author'));
create policy "knowledge_objects_author_delete" on storage.objects for delete to authenticated using(bucket_id='tebelopele-knowledge' and owner_id=(select auth.uid()::text) and public.tebelopele_has_capability('content.author'));

grant select on public.tebelopele_content_tags,public.tebelopele_article_tags,public.tebelopele_content_reviews,public.tebelopele_knowledge_index_jobs,public.tebelopele_knowledge_chunks to authenticated;
grant insert,update,delete on public.tebelopele_content_tags,public.tebelopele_article_tags,public.tebelopele_health_articles,public.tebelopele_faqs,public.tebelopele_knowledge_index_jobs,public.tebelopele_knowledge_chunks to authenticated;
grant insert on public.tebelopele_health_article_versions,public.tebelopele_faq_versions,public.tebelopele_content_reviews to authenticated;
grant select on public.tebelopele_content_tags,public.tebelopele_article_tags,public.tebelopele_knowledge_chunks to anon;
revoke execute on function public.tebelopele_publish_article(uuid,uuid,text) from public,anon;
grant execute on function public.tebelopele_publish_article(uuid,uuid,text) to authenticated;
revoke execute on function public.tebelopele_create_article_draft(text,text,text,text,text,text,text,text,bigint,text) from public,anon;
grant execute on function public.tebelopele_create_article_draft(text,text,text,text,text,text,text,text,bigint,text) to authenticated;
grant execute on function public.tebelopele_search_published_knowledge(text,integer) to anon,authenticated;
commit;
