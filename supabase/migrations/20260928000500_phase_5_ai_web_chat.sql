begin;

insert into public.tebelopele_capabilities(slug,description) values
 ('conversations.read','Read permitted client conversation transcripts'),
 ('ai.monitor','Review AI response quality and provider operations')
on conflict(slug) do nothing;

drop function if exists public.tebelopele_search_published_knowledge(text,integer);
create function public.tebelopele_search_published_knowledge(search_query text,result_limit integer default 10)
returns table(article_id uuid,article_version_id uuid,chunk_id uuid,slug text,title text,heading text,excerpt text,rank real)
language sql stable security invoker set search_path='' as $$
 select a.id,v.id,c.id,a.slug,v.title,c.heading,left(c.content,1200),ts_rank(c.search_vector,websearch_to_tsquery('english',search_query))
 from public.tebelopele_knowledge_chunks c join public.tebelopele_health_articles a on a.id=c.article_id and a.published_version_id=c.article_version_id join public.tebelopele_health_article_versions v on v.id=c.article_version_id
 where a.status='published' and a.published_at<=now() and a.visibility in ('public','authenticated') and (v.effective_at is null or v.effective_at<=now()) and (v.expires_at is null or v.expires_at>now()) and c.search_vector@@websearch_to_tsquery('english',search_query)
 order by 8 desc limit least(greatest(result_limit,1),25)
$$;
grant execute on function public.tebelopele_search_published_knowledge(text,integer) to anon,authenticated;

create table public.tebelopele_conversations(
 id uuid primary key default extensions.gen_random_uuid(),
 client_user_id uuid references public.tebelopele_clients(user_id) on delete restrict,
 channel text not null default 'web' check(channel in ('web','whatsapp')),
 control_state text not null default 'automated' check(control_state in ('automated','human_pending','human_active','closed')),
 locale text not null default 'en', title text,
 last_message_at timestamptz not null default now(), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index tebelopele_conversations_client_idx on public.tebelopele_conversations(client_user_id,last_message_at desc);

create table public.tebelopele_messages(
 id uuid primary key default extensions.gen_random_uuid(),
 conversation_id uuid not null references public.tebelopele_conversations(id) on delete cascade,
 sender_type text not null check(sender_type in ('client','assistant','agent','system','menu')),
 sender_user_id uuid references public.tebelopele_profiles(id) on delete set null,
 message_type text not null default 'text' check(message_type in ('text','menu','image','document','event')),
 body text not null check(char_length(body) between 1 and 12000),
 source_label text check(source_label in ('verified','verified_ai','live_data','assistant','no_evidence','human','menu')),
 citations jsonb not null default '[]'::jsonb check(jsonb_typeof(citations)='array'),
 ai_model text, correlation_id uuid not null default extensions.gen_random_uuid(),
 provider_message_id text unique, idempotency_key text unique,
 created_at timestamptz not null default now()
);
create index tebelopele_messages_transcript_idx on public.tebelopele_messages(conversation_id,created_at,id);

create table public.tebelopele_message_feedback(
 id uuid primary key default extensions.gen_random_uuid(), message_id uuid not null references public.tebelopele_messages(id) on delete cascade,
 client_user_id uuid not null references public.tebelopele_clients(user_id) on delete cascade,
 rating text not null check(rating in ('helpful','not_helpful')), reason text check(reason is null or char_length(reason)<=500), created_at timestamptz not null default now(),
 unique(message_id,client_user_id)
);
create table public.tebelopele_chat_rate_events(
 id bigint generated always as identity primary key, user_id uuid not null references public.tebelopele_profiles(id) on delete cascade, occurred_at timestamptz not null default now()
);
create index tebelopele_chat_rate_events_idx on public.tebelopele_chat_rate_events(user_id,occurred_at desc);

create or replace function public.tebelopele_create_web_conversation(conversation_title text default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare result_id uuid; current_user_id uuid := (select auth.uid());
begin
 if current_user_id is null then raise exception 'Authentication required'; end if;
 insert into public.tebelopele_conversations(client_user_id,title) values(current_user_id,nullif(trim(conversation_title),'')) returning id into result_id;
 insert into public.tebelopele_audit_events(actor_id,action,entity_type,entity_id) values(current_user_id,'conversation.created','conversation',result_id);
 return result_id;
end; $$;

create or replace function public.tebelopele_append_client_message(target_conversation_id uuid,message_body text,message_idempotency_key text)
returns uuid language plpgsql security definer set search_path='' as $$
declare result_id uuid; current_user_id uuid := (select auth.uid()); current_control text;
begin
 if char_length(trim(message_body)) not between 1 and 2000 then raise exception 'Message length is invalid'; end if;
 select control_state into current_control from public.tebelopele_conversations where id=target_conversation_id and client_user_id=current_user_id for update;
 if not found or current_control='closed' then raise exception 'Conversation is unavailable'; end if;
 if (select count(*) from public.tebelopele_chat_rate_events where user_id=current_user_id and occurred_at>now()-interval '1 minute')>=10 then raise exception 'Rate limit exceeded'; end if;
 insert into public.tebelopele_chat_rate_events(user_id) values(current_user_id);
 insert into public.tebelopele_messages(conversation_id,sender_type,sender_user_id,body,idempotency_key,source_label)
 values(target_conversation_id,'client',current_user_id,trim(message_body),message_idempotency_key,null)
 on conflict(idempotency_key) do update set idempotency_key=excluded.idempotency_key returning id into result_id;
 update public.tebelopele_conversations set last_message_at=now() where id=target_conversation_id;
 return result_id;
end; $$;

create or replace function public.tebelopele_append_assistant_message(actor_user_id uuid,target_conversation_id uuid,message_body text,message_source text,message_citations jsonb,message_model text,message_correlation_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare result_id uuid; current_control text;
begin
 select control_state into current_control from public.tebelopele_conversations where id=target_conversation_id and client_user_id=actor_user_id for update;
 if not found then raise exception 'Conversation unavailable'; end if;
 if current_control<>'automated' then raise exception 'Automated replies are paused'; end if;
 if message_source in ('verified','verified_ai') and (jsonb_typeof(message_citations)<>'array' or jsonb_array_length(message_citations)=0) then raise exception 'Verified answers require citations'; end if;
 insert into public.tebelopele_messages(conversation_id,sender_type,body,source_label,citations,ai_model,correlation_id)
 values(target_conversation_id,'assistant',trim(message_body),message_source,message_citations,message_model,message_correlation_id) returning id into result_id;
 update public.tebelopele_conversations set last_message_at=now() where id=target_conversation_id;
 return result_id;
end; $$;

create trigger tebelopele_conversations_updated_at before update on public.tebelopele_conversations for each row execute function public.tebelopele_set_updated_at();
alter table public.tebelopele_conversations enable row level security; alter table public.tebelopele_messages enable row level security; alter table public.tebelopele_message_feedback enable row level security; alter table public.tebelopele_chat_rate_events enable row level security;
create policy "conversations_client_or_staff_read" on public.tebelopele_conversations for select to authenticated using(client_user_id=(select auth.uid()) or public.tebelopele_has_capability('conversations.read') or public.tebelopele_has_capability('support.handle'));
create policy "messages_client_or_staff_read" on public.tebelopele_messages for select to authenticated using(exists(select 1 from public.tebelopele_conversations c where c.id=conversation_id and (c.client_user_id=(select auth.uid()) or public.tebelopele_has_capability('conversations.read') or public.tebelopele_has_capability('support.handle'))));
create policy "feedback_own" on public.tebelopele_message_feedback for all to authenticated using(client_user_id=(select auth.uid())) with check(client_user_id=(select auth.uid()) and exists(select 1 from public.tebelopele_messages m join public.tebelopele_conversations c on c.id=m.conversation_id where m.id=message_id and c.client_user_id=(select auth.uid()) and m.sender_type='assistant'));
grant select on public.tebelopele_conversations,public.tebelopele_messages,public.tebelopele_message_feedback to authenticated; grant insert,update on public.tebelopele_message_feedback to authenticated;
revoke execute on function public.tebelopele_create_web_conversation(text),public.tebelopele_append_client_message(uuid,text,text) from public,anon;
grant execute on function public.tebelopele_create_web_conversation(text),public.tebelopele_append_client_message(uuid,text,text) to authenticated;
revoke execute on function public.tebelopele_append_assistant_message(uuid,uuid,text,text,jsonb,text,uuid) from public,anon,authenticated;
grant execute on function public.tebelopele_append_assistant_message(uuid,uuid,text,text,jsonb,text,uuid) to service_role;
commit;
