begin;

create extension if not exists pgcrypto with schema extensions;

create type public.tebelopele_account_status as enum ('invited', 'active', 'suspended', 'disabled');
create type public.tebelopele_staff_availability as enum ('available', 'busy', 'offline');
create type public.tebelopele_skill_proficiency as enum ('foundation', 'competent', 'advanced', 'expert');

create table public.tebelopele_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 120),
  phone text,
  locale text not null default 'en' check (locale ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  account_status public.tebelopele_account_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tebelopele_roles (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z][a-z0-9_]*$'),
  name text not null unique,
  description text not null,
  is_system boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.tebelopele_capabilities (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z][a-z0-9_.]*$'),
  description text not null,
  created_at timestamptz not null default now()
);

create table public.tebelopele_user_roles (
  user_id uuid not null references public.tebelopele_profiles(id) on delete cascade,
  role_id uuid not null references public.tebelopele_roles(id) on delete cascade,
  assigned_by uuid references public.tebelopele_profiles(id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key (user_id, role_id)
);

create table public.tebelopele_role_capabilities (
  role_id uuid not null references public.tebelopele_roles(id) on delete cascade,
  capability_id uuid not null references public.tebelopele_capabilities(id) on delete cascade,
  primary key (role_id, capability_id)
);

create table public.tebelopele_facilities (
  id uuid primary key default extensions.gen_random_uuid(),
  code text not null unique,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tebelopele_staff_profiles (
  user_id uuid primary key references public.tebelopele_profiles(id) on delete cascade,
  staff_number text unique,
  job_title text,
  availability public.tebelopele_staff_availability not null default 'offline',
  languages text[] not null default array['en']::text[],
  max_active_cases integer not null default 5 check (max_active_cases between 1 and 100),
  is_accepting_cases boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tebelopele_skills (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z][a-z0-9_]*$'),
  name text not null unique,
  description text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.tebelopele_staff_skills (
  staff_user_id uuid not null references public.tebelopele_staff_profiles(user_id) on delete cascade,
  skill_id uuid not null references public.tebelopele_skills(id) on delete restrict,
  proficiency public.tebelopele_skill_proficiency not null default 'competent',
  is_verified boolean not null default false,
  verified_by uuid references public.tebelopele_profiles(id) on delete set null,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (staff_user_id, skill_id),
  check ((is_verified and verified_at is not null) or (not is_verified))
);

create table public.tebelopele_staff_facilities (
  staff_user_id uuid not null references public.tebelopele_staff_profiles(user_id) on delete cascade,
  facility_id uuid not null references public.tebelopele_facilities(id) on delete restrict,
  is_primary boolean not null default false,
  assigned_at timestamptz not null default now(),
  primary key (staff_user_id, facility_id)
);

create unique index tebelopele_staff_one_primary_facility
  on public.tebelopele_staff_facilities(staff_user_id) where is_primary;

create table public.tebelopele_audit_events (
  id uuid primary key default extensions.gen_random_uuid(),
  actor_id uuid references public.tebelopele_profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  detail jsonb not null default '{}'::jsonb,
  correlation_id uuid,
  occurred_at timestamptz not null default now()
);

create index tebelopele_audit_entity_idx on public.tebelopele_audit_events(entity_type, entity_id, occurred_at desc);
create index tebelopele_user_roles_user_idx on public.tebelopele_user_roles(user_id);
create index tebelopele_staff_skills_skill_idx on public.tebelopele_staff_skills(skill_id, staff_user_id);

create or replace function public.tebelopele_set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger tebelopele_profiles_updated_at before update on public.tebelopele_profiles
for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_facilities_updated_at before update on public.tebelopele_facilities
for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_staff_profiles_updated_at before update on public.tebelopele_staff_profiles
for each row execute function public.tebelopele_set_updated_at();

create or replace function public.tebelopele_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.tebelopele_profiles (id, display_name, phone)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), split_part(new.email, '@', 1), 'Tebelopele client'),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), '')
  );
  return new;
end;
$$;

create trigger tebelopele_auth_user_created
after insert on auth.users
for each row execute function public.tebelopele_handle_new_user();

create or replace function public.tebelopele_has_capability(required_capability text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.tebelopele_user_roles ur
    join public.tebelopele_role_capabilities rc on rc.role_id = ur.role_id
    join public.tebelopele_capabilities c on c.id = rc.capability_id
    join public.tebelopele_profiles p on p.id = ur.user_id
    where ur.user_id = (select auth.uid())
      and c.slug = required_capability
      and p.account_status = 'active'
  );
$$;

create or replace function public.tebelopele_my_capabilities()
returns setof text
language sql
stable
security definer
set search_path = ''
as $$
  select distinct c.slug
  from public.tebelopele_user_roles ur
  join public.tebelopele_role_capabilities rc on rc.role_id = ur.role_id
  join public.tebelopele_capabilities c on c.id = rc.capability_id
  join public.tebelopele_profiles p on p.id = ur.user_id
  where ur.user_id = (select auth.uid()) and p.account_status = 'active';
$$;

create or replace function public.tebelopele_audit_assignment_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_id text;
begin
  target_id := coalesce(to_jsonb(new) ->> 'user_id', to_jsonb(new) ->> 'staff_user_id', to_jsonb(old) ->> 'user_id', to_jsonb(old) ->> 'staff_user_id');
  insert into public.tebelopele_audit_events(actor_id, action, entity_type, entity_id)
  values ((select auth.uid()), lower(tg_op), tg_table_name, target_id);
  return coalesce(new, old);
end;
$$;

create trigger tebelopele_user_roles_audit after insert or update or delete on public.tebelopele_user_roles
for each row execute function public.tebelopele_audit_assignment_change();
create trigger tebelopele_staff_skills_audit after insert or update or delete on public.tebelopele_staff_skills
for each row execute function public.tebelopele_audit_assignment_change();
create trigger tebelopele_staff_facilities_audit after insert or update or delete on public.tebelopele_staff_facilities
for each row execute function public.tebelopele_audit_assignment_change();

alter table public.tebelopele_profiles enable row level security;
alter table public.tebelopele_roles enable row level security;
alter table public.tebelopele_capabilities enable row level security;
alter table public.tebelopele_user_roles enable row level security;
alter table public.tebelopele_role_capabilities enable row level security;
alter table public.tebelopele_facilities enable row level security;
alter table public.tebelopele_staff_profiles enable row level security;
alter table public.tebelopele_skills enable row level security;
alter table public.tebelopele_staff_skills enable row level security;
alter table public.tebelopele_staff_facilities enable row level security;
alter table public.tebelopele_audit_events enable row level security;

create policy "profiles_read_own_or_authorized" on public.tebelopele_profiles for select to authenticated
using ((select auth.uid()) = id or (select public.tebelopele_has_capability('users.read')));
create policy "profiles_update_own" on public.tebelopele_profiles for update to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "roles_read_assigned_or_authorized" on public.tebelopele_roles for select to authenticated
using (exists (select 1 from public.tebelopele_user_roles ur where ur.role_id = id and ur.user_id = (select auth.uid())) or (select public.tebelopele_has_capability('roles.read')));
create policy "capabilities_read_assigned_or_authorized" on public.tebelopele_capabilities for select to authenticated
using (exists (select 1 from public.tebelopele_role_capabilities rc join public.tebelopele_user_roles ur on ur.role_id = rc.role_id where rc.capability_id = id and ur.user_id = (select auth.uid())) or (select public.tebelopele_has_capability('roles.read')));
create policy "user_roles_read_own_or_authorized" on public.tebelopele_user_roles for select to authenticated
using (user_id = (select auth.uid()) or (select public.tebelopele_has_capability('roles.read')));
create policy "role_capabilities_read_assigned_or_authorized" on public.tebelopele_role_capabilities for select to authenticated
using (exists (select 1 from public.tebelopele_user_roles ur where ur.role_id = role_id and ur.user_id = (select auth.uid())) or (select public.tebelopele_has_capability('roles.read')));

create policy "facilities_read_active" on public.tebelopele_facilities for select to anon, authenticated using (is_active);
create policy "staff_profiles_read_own_or_authorized" on public.tebelopele_staff_profiles for select to authenticated
using (user_id = (select auth.uid()) or (select public.tebelopele_has_capability('staff.read')));
create policy "skills_read_active" on public.tebelopele_skills for select to authenticated using (is_active);
create policy "staff_skills_read_own_or_authorized" on public.tebelopele_staff_skills for select to authenticated
using (staff_user_id = (select auth.uid()) or (select public.tebelopele_has_capability('staff.read')));
create policy "staff_facilities_read_own_or_authorized" on public.tebelopele_staff_facilities for select to authenticated
using (staff_user_id = (select auth.uid()) or (select public.tebelopele_has_capability('staff.read')));
create policy "audit_read_authorized" on public.tebelopele_audit_events for select to authenticated
using ((select public.tebelopele_has_capability('audit.read')));

revoke all on all tables in schema public from anon, authenticated;
revoke execute on function public.tebelopele_set_updated_at() from public, anon, authenticated;
revoke execute on function public.tebelopele_handle_new_user() from public, anon, authenticated;
revoke execute on function public.tebelopele_audit_assignment_change() from public, anon, authenticated;
revoke execute on function public.tebelopele_has_capability(text) from public, anon;
revoke execute on function public.tebelopele_my_capabilities() from public, anon;
grant select on public.tebelopele_facilities to anon, authenticated;
grant select on public.tebelopele_profiles, public.tebelopele_roles, public.tebelopele_capabilities,
  public.tebelopele_user_roles, public.tebelopele_role_capabilities, public.tebelopele_staff_profiles,
  public.tebelopele_skills, public.tebelopele_staff_skills, public.tebelopele_staff_facilities,
  public.tebelopele_audit_events to authenticated;
grant update (display_name, phone, locale) on public.tebelopele_profiles to authenticated;
grant execute on function public.tebelopele_has_capability(text) to authenticated;
grant execute on function public.tebelopele_my_capabilities() to authenticated;

commit;
