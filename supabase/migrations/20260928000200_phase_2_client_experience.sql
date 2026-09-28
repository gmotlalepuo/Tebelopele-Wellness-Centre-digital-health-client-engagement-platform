begin;

alter table public.tebelopele_facilities
  add column slug text unique,
  add column summary text,
  add column address_line text,
  add column city text,
  add column phone text,
  add column email text,
  add column latitude numeric(9,6),
  add column longitude numeric(9,6),
  add column published_at timestamptz;

alter table public.tebelopele_facilities
  add constraint tebelopele_facilities_slug_format check (slug is null or slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  add constraint tebelopele_facilities_coordinates check (
    (latitude is null and longitude is null) or
    (latitude between -90 and 90 and longitude between -180 and 180)
  );

create table public.tebelopele_services (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  name text not null,
  summary text not null,
  description text not null,
  eligibility text,
  preparation text,
  is_active boolean not null default true,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tebelopele_facility_hours (
  id uuid primary key default extensions.gen_random_uuid(),
  facility_id uuid not null references public.tebelopele_facilities(id) on delete cascade,
  weekday smallint not null check (weekday between 0 and 6),
  opens_at time,
  closes_at time,
  is_closed boolean not null default false,
  note text,
  unique (facility_id, weekday),
  check (is_closed or (opens_at is not null and closes_at is not null and opens_at < closes_at))
);

create table public.tebelopele_facility_services (
  facility_id uuid not null references public.tebelopele_facilities(id) on delete cascade,
  service_id uuid not null references public.tebelopele_services(id) on delete cascade,
  is_available boolean not null default true,
  availability_note text,
  primary key (facility_id, service_id)
);

create table public.tebelopele_outreach_activities (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  title text not null,
  summary text not null,
  location_name text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  contact_text text,
  is_cancelled boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or ends_at > starts_at)
);

create table public.tebelopele_content_categories (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  name text not null unique,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tebelopele_health_articles (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  category_id uuid references public.tebelopele_content_categories(id) on delete set null,
  visibility text not null default 'public' check (visibility in ('public', 'authenticated', 'restricted', 'admin')),
  status text not null default 'draft' check (status in ('draft', 'in_review', 'published', 'rejected', 'superseded', 'archived')),
  published_version_id uuid,
  published_at timestamptz,
  created_by uuid references public.tebelopele_profiles(id) on delete set null,
  updated_by uuid references public.tebelopele_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tebelopele_health_article_versions (
  id uuid primary key default extensions.gen_random_uuid(),
  article_id uuid not null references public.tebelopele_health_articles(id) on delete cascade,
  version_number integer not null check (version_number > 0),
  title text not null,
  summary text not null,
  body text not null,
  source_name text,
  effective_at timestamptz,
  expires_at timestamptz,
  created_by uuid references public.tebelopele_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (article_id, version_number),
  check (expires_at is null or effective_at is null or expires_at > effective_at)
);

alter table public.tebelopele_health_articles
  add constraint tebelopele_health_articles_published_version_fk
  foreign key (published_version_id) references public.tebelopele_health_article_versions(id) on delete restrict;

create table public.tebelopele_faqs (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  category_id uuid references public.tebelopele_content_categories(id) on delete set null,
  visibility text not null default 'public' check (visibility in ('public', 'authenticated', 'restricted', 'admin')),
  status text not null default 'draft' check (status in ('draft', 'in_review', 'published', 'rejected', 'superseded', 'archived')),
  published_version_id uuid,
  published_at timestamptz,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tebelopele_faq_versions (
  id uuid primary key default extensions.gen_random_uuid(),
  faq_id uuid not null references public.tebelopele_faqs(id) on delete cascade,
  version_number integer not null check (version_number > 0),
  question text not null,
  answer text not null,
  keywords text[] not null default '{}'::text[],
  created_by uuid references public.tebelopele_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (faq_id, version_number)
);

alter table public.tebelopele_faqs
  add constraint tebelopele_faqs_published_version_fk
  foreign key (published_version_id) references public.tebelopele_faq_versions(id) on delete restrict;

create table public.tebelopele_clients (
  user_id uuid primary key references public.tebelopele_profiles(id) on delete cascade,
  preferred_name text check (preferred_name is null or char_length(preferred_name) between 1 and 120),
  date_of_birth date check (date_of_birth is null or date_of_birth <= current_date),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tebelopele_client_contacts (
  id uuid primary key default extensions.gen_random_uuid(),
  client_user_id uuid not null references public.tebelopele_clients(user_id) on delete cascade,
  contact_type text not null check (contact_type in ('phone', 'email')),
  contact_value text not null check (char_length(contact_value) between 3 and 254),
  is_primary boolean not null default false,
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index tebelopele_client_primary_contact_type_idx
  on public.tebelopele_client_contacts(client_user_id, contact_type) where is_primary;

create table public.tebelopele_client_preferences (
  client_user_id uuid primary key references public.tebelopele_clients(user_id) on delete cascade,
  preferred_language text not null default 'en' check (preferred_language ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  preferred_channel text not null default 'in_app' check (preferred_channel in ('in_app', 'email', 'sms', 'whatsapp')),
  allow_email boolean not null default false,
  allow_sms boolean not null default false,
  allow_whatsapp boolean not null default false,
  updated_at timestamptz not null default now()
);

create table public.tebelopele_consent_versions (
  id uuid primary key default extensions.gen_random_uuid(),
  consent_type text not null,
  version_number integer not null check (version_number > 0),
  title text not null,
  summary text not null,
  full_text text not null,
  effective_at timestamptz not null,
  retired_at timestamptz,
  created_at timestamptz not null default now(),
  unique (consent_type, version_number),
  check (retired_at is null or retired_at > effective_at)
);

create unique index tebelopele_active_consent_type_idx
  on public.tebelopele_consent_versions(consent_type) where retired_at is null;

create table public.tebelopele_client_consent_events (
  id uuid primary key default extensions.gen_random_uuid(),
  client_user_id uuid not null references public.tebelopele_clients(user_id) on delete cascade,
  consent_version_id uuid not null references public.tebelopele_consent_versions(id) on delete restrict,
  decision text not null check (decision in ('accepted', 'declined', 'withdrawn')),
  channel text not null default 'web' check (channel in ('web', 'whatsapp', 'staff_assisted')),
  occurred_at timestamptz not null default now(),
  correlation_id uuid
);

create index tebelopele_client_consent_latest_idx
  on public.tebelopele_client_consent_events(client_user_id, consent_version_id, occurred_at desc);

create or replace function public.tebelopele_validate_consent_event()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.tebelopele_consent_versions cv
    where cv.id = new.consent_version_id
      and cv.effective_at <= now()
      and cv.retired_at is null
  ) then
    raise exception 'Consent version is not active';
  end if;
  if new.decision = 'withdrawn' and not exists (
    select 1 from public.tebelopele_client_consent_events ce
    where ce.client_user_id = new.client_user_id
      and ce.consent_version_id = new.consent_version_id
      and ce.decision = 'accepted'
  ) then
    raise exception 'Consent cannot be withdrawn before acceptance';
  end if;
  return new;
end;
$$;

create trigger tebelopele_consent_event_validate before insert on public.tebelopele_client_consent_events
for each row execute function public.tebelopele_validate_consent_event();

create or replace function public.tebelopele_update_own_client_profile(
  profile_display_name text,
  client_preferred_name text,
  profile_phone text,
  client_date_of_birth date
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  current_user_id uuid := (select auth.uid());
begin
  if current_user_id is null then raise exception 'Authentication required'; end if;
  if char_length(trim(profile_display_name)) not between 1 and 120 then raise exception 'Invalid display name'; end if;
  if client_date_of_birth is not null and client_date_of_birth > current_date then raise exception 'Invalid date of birth'; end if;

  update public.tebelopele_profiles
    set display_name = trim(profile_display_name), phone = nullif(trim(profile_phone), '')
    where id = current_user_id;
  if not found then raise exception 'Profile not found'; end if;

  insert into public.tebelopele_clients(user_id, preferred_name, date_of_birth)
  values (current_user_id, nullif(trim(client_preferred_name), ''), client_date_of_birth)
  on conflict (user_id) do update set
    preferred_name = excluded.preferred_name,
    date_of_birth = excluded.date_of_birth;

  if nullif(trim(profile_phone), '') is null then
    delete from public.tebelopele_client_contacts
    where client_user_id = current_user_id and contact_type = 'phone' and is_primary;
  elsif exists (
    select 1 from public.tebelopele_client_contacts
    where client_user_id = current_user_id and contact_type = 'phone' and is_primary
  ) then
    update public.tebelopele_client_contacts
      set contact_value = trim(profile_phone)
      where client_user_id = current_user_id and contact_type = 'phone' and is_primary;
  else
    insert into public.tebelopele_client_contacts(client_user_id, contact_type, contact_value, is_primary)
    values (current_user_id, 'phone', trim(profile_phone), true);
  end if;
end;
$$;

create trigger tebelopele_services_updated_at before update on public.tebelopele_services
for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_outreach_updated_at before update on public.tebelopele_outreach_activities
for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_categories_updated_at before update on public.tebelopele_content_categories
for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_articles_updated_at before update on public.tebelopele_health_articles
for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_faqs_updated_at before update on public.tebelopele_faqs
for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_clients_updated_at before update on public.tebelopele_clients
for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_client_contacts_updated_at before update on public.tebelopele_client_contacts
for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_preferences_updated_at before update on public.tebelopele_client_preferences
for each row execute function public.tebelopele_set_updated_at();

alter table public.tebelopele_services enable row level security;
alter table public.tebelopele_facility_hours enable row level security;
alter table public.tebelopele_facility_services enable row level security;
alter table public.tebelopele_outreach_activities enable row level security;
alter table public.tebelopele_content_categories enable row level security;
alter table public.tebelopele_health_articles enable row level security;
alter table public.tebelopele_health_article_versions enable row level security;
alter table public.tebelopele_faqs enable row level security;
alter table public.tebelopele_faq_versions enable row level security;
alter table public.tebelopele_clients enable row level security;
alter table public.tebelopele_client_contacts enable row level security;
alter table public.tebelopele_client_preferences enable row level security;
alter table public.tebelopele_consent_versions enable row level security;
alter table public.tebelopele_client_consent_events enable row level security;

drop policy "facilities_read_active" on public.tebelopele_facilities;
create policy "facilities_read_published" on public.tebelopele_facilities for select to anon, authenticated
using (is_active and published_at is not null and published_at <= now());
create policy "services_read_published" on public.tebelopele_services for select to anon, authenticated
using (is_active and published_at is not null and published_at <= now());
create policy "hours_read_for_published_facility" on public.tebelopele_facility_hours for select to anon, authenticated
using (exists (select 1 from public.tebelopele_facilities f where f.id = facility_id and f.is_active and f.published_at is not null and f.published_at <= now()));
create policy "facility_services_read_published" on public.tebelopele_facility_services for select to anon, authenticated
using (is_available and exists (select 1 from public.tebelopele_facilities f where f.id = facility_id and f.is_active and f.published_at is not null and f.published_at <= now()) and exists (select 1 from public.tebelopele_services s where s.id = service_id and s.is_active and s.published_at is not null and s.published_at <= now()));
create policy "outreach_read_published" on public.tebelopele_outreach_activities for select to anon, authenticated
using (not is_cancelled and published_at is not null and published_at <= now());
create policy "categories_read_active" on public.tebelopele_content_categories for select to anon, authenticated using (is_active);
create policy "articles_read_published_public" on public.tebelopele_health_articles for select to anon, authenticated
using (status = 'published' and visibility = 'public' and published_at is not null and published_at <= now());
create policy "article_versions_read_published_public" on public.tebelopele_health_article_versions for select to anon, authenticated
using (exists (select 1 from public.tebelopele_health_articles a where a.published_version_id = id and a.status = 'published' and a.visibility = 'public' and a.published_at <= now()) and (effective_at is null or effective_at <= now()) and (expires_at is null or expires_at > now()));
create policy "faqs_read_published_public" on public.tebelopele_faqs for select to anon, authenticated
using (status = 'published' and visibility = 'public' and published_at is not null and published_at <= now());
create policy "faq_versions_read_published_public" on public.tebelopele_faq_versions for select to anon, authenticated
using (exists (select 1 from public.tebelopele_faqs f where f.published_version_id = id and f.status = 'published' and f.visibility = 'public' and f.published_at <= now()));

create policy "clients_read_own" on public.tebelopele_clients for select to authenticated
using (user_id = (select auth.uid()));
create policy "clients_insert_own" on public.tebelopele_clients for insert to authenticated
with check (user_id = (select auth.uid()));
create policy "clients_update_own" on public.tebelopele_clients for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "client_contacts_manage_own" on public.tebelopele_client_contacts for all to authenticated
using (client_user_id = (select auth.uid())) with check (client_user_id = (select auth.uid()));
create policy "client_preferences_manage_own" on public.tebelopele_client_preferences for all to authenticated
using (client_user_id = (select auth.uid())) with check (client_user_id = (select auth.uid()));
create policy "consent_versions_read_effective" on public.tebelopele_consent_versions for select to authenticated
using (effective_at <= now());
create policy "consent_events_read_own" on public.tebelopele_client_consent_events for select to authenticated
using (client_user_id = (select auth.uid()));
create policy "consent_events_append_own" on public.tebelopele_client_consent_events for insert to authenticated
with check (client_user_id = (select auth.uid()) and exists (
  select 1 from public.tebelopele_consent_versions cv
  where cv.id = consent_version_id and cv.effective_at <= now() and cv.retired_at is null
));

revoke all on public.tebelopele_services, public.tebelopele_facility_hours, public.tebelopele_facility_services,
  public.tebelopele_outreach_activities, public.tebelopele_content_categories, public.tebelopele_health_articles,
  public.tebelopele_health_article_versions, public.tebelopele_faqs, public.tebelopele_faq_versions,
  public.tebelopele_clients, public.tebelopele_client_contacts, public.tebelopele_client_preferences,
  public.tebelopele_consent_versions, public.tebelopele_client_consent_events from anon, authenticated;
revoke execute on function public.tebelopele_validate_consent_event() from public, anon, authenticated;
revoke execute on function public.tebelopele_update_own_client_profile(text, text, text, date) from public, anon;

grant select on public.tebelopele_services, public.tebelopele_facility_hours, public.tebelopele_facility_services,
  public.tebelopele_outreach_activities, public.tebelopele_content_categories, public.tebelopele_health_articles,
  public.tebelopele_health_article_versions, public.tebelopele_faqs, public.tebelopele_faq_versions to anon, authenticated;
grant select, insert, update on public.tebelopele_clients to authenticated;
grant select, insert, update, delete on public.tebelopele_client_contacts, public.tebelopele_client_preferences to authenticated;
grant select on public.tebelopele_consent_versions, public.tebelopele_client_consent_events to authenticated;
grant insert on public.tebelopele_client_consent_events to authenticated;
grant execute on function public.tebelopele_update_own_client_profile(text, text, text, date) to authenticated;

commit;
