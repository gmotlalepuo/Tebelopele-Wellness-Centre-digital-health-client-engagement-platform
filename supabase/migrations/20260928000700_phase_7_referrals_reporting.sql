begin;

create type public.tebelopele_referral_status as enum
  ('draft','pending','accepted','scheduled','completed','declined','cancelled');

create table public.tebelopele_referrals (
  id uuid primary key default extensions.gen_random_uuid(),
  client_user_id uuid not null references public.tebelopele_clients(user_id) on delete restrict,
  service_id uuid references public.tebelopele_services(id) on delete set null,
  originating_facility_id uuid references public.tebelopele_facilities(id) on delete set null,
  destination_facility_id uuid references public.tebelopele_facilities(id) on delete set null,
  assigned_staff_user_id uuid references public.tebelopele_staff_profiles(user_id) on delete set null,
  status public.tebelopele_referral_status not null default 'pending',
  urgency text not null default 'routine' check (urgency in ('routine','priority','urgent')),
  referral_reason text not null check (char_length(referral_reason) between 1 and 1000),
  consent_confirmed_at timestamptz not null,
  external_reference text,
  next_follow_up_at timestamptz,
  completed_at timestamptz,
  created_by uuid not null references public.tebelopele_profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tebelopele_referral_events (
  id uuid primary key default extensions.gen_random_uuid(),
  referral_id uuid not null references public.tebelopele_referrals(id) on delete cascade,
  from_status public.tebelopele_referral_status,
  to_status public.tebelopele_referral_status not null,
  note text check (note is null or char_length(note) <= 2000),
  actor_id uuid not null references public.tebelopele_profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.tebelopele_referral_follow_ups (
  id uuid primary key default extensions.gen_random_uuid(),
  referral_id uuid not null references public.tebelopele_referrals(id) on delete cascade,
  outcome text not null check (outcome in ('contacted','no_answer','rescheduled','information_received','closed')),
  note text not null check (char_length(note) between 1 and 2000),
  next_follow_up_at timestamptz,
  created_by uuid not null references public.tebelopele_profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.tebelopele_system_settings (
  key text primary key check (key ~ '^tebelopele_[a-z0-9_]+$'),
  value jsonb not null,
  description text not null,
  is_sensitive boolean not null default false,
  updated_by uuid references public.tebelopele_profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

create index tebelopele_referrals_queue_idx on public.tebelopele_referrals(status, urgency, next_follow_up_at, created_at);
create index tebelopele_referrals_client_idx on public.tebelopele_referrals(client_user_id, created_at desc);
create index tebelopele_referral_events_idx on public.tebelopele_referral_events(referral_id, created_at);

create trigger tebelopele_referrals_updated_at before update on public.tebelopele_referrals
for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_settings_updated_at before update on public.tebelopele_system_settings
for each row execute function public.tebelopele_set_updated_at();

create or replace function public.tebelopele_update_referral_status(target_referral_id uuid, next_status public.tebelopele_referral_status, status_note text default null)
returns void language plpgsql security definer set search_path='' as $$
declare current_status public.tebelopele_referral_status; current_user_id uuid := (select auth.uid());
begin
  if not public.tebelopele_has_capability('referrals.manage') then raise exception 'Referral capability required'; end if;
  select status into current_status from public.tebelopele_referrals where id=target_referral_id for update;
  if not found then raise exception 'Referral unavailable'; end if;
  if current_status in ('completed','declined','cancelled') then raise exception 'Closed referral cannot transition'; end if;
  if (current_status='pending' and next_status not in ('accepted','declined','cancelled')) or
     (current_status='accepted' and next_status not in ('scheduled','declined','cancelled')) or
     (current_status='scheduled' and next_status not in ('completed','cancelled')) or
     (current_status='draft' and next_status not in ('pending','cancelled')) then raise exception 'Invalid referral transition'; end if;
  update public.tebelopele_referrals set status=next_status, completed_at=case when next_status='completed' then now() else completed_at end where id=target_referral_id;
  insert into public.tebelopele_referral_events(referral_id,from_status,to_status,note,actor_id)
  values(target_referral_id,current_status,next_status,nullif(trim(status_note),''),current_user_id);
  insert into public.tebelopele_audit_events(actor_id,action,entity_type,entity_id,detail)
  values(current_user_id,'referral.status_changed','referral',target_referral_id,jsonb_build_object('from',current_status,'to',next_status));
end; $$;

alter table public.tebelopele_referrals enable row level security;
alter table public.tebelopele_referral_events enable row level security;
alter table public.tebelopele_referral_follow_ups enable row level security;
alter table public.tebelopele_system_settings enable row level security;

create policy "referrals_authorized_staff_read" on public.tebelopele_referrals for select to authenticated
using (public.tebelopele_has_capability('referrals.manage'));
create policy "referrals_authorized_staff_insert" on public.tebelopele_referrals for insert to authenticated
with check (public.tebelopele_has_capability('referrals.manage') and created_by=(select auth.uid()));
create policy "referrals_authorized_staff_update" on public.tebelopele_referrals for update to authenticated
using (public.tebelopele_has_capability('referrals.manage')) with check (public.tebelopele_has_capability('referrals.manage'));
create policy "referral_events_authorized_staff" on public.tebelopele_referral_events for select to authenticated
using (public.tebelopele_has_capability('referrals.manage') or public.tebelopele_has_capability('audit.read'));
create policy "follow_ups_authorized_staff" on public.tebelopele_referral_follow_ups for all to authenticated
using (public.tebelopele_has_capability('referrals.manage')) with check (public.tebelopele_has_capability('referrals.manage') and created_by=(select auth.uid()));
create policy "settings_authorized_admin" on public.tebelopele_system_settings for all to authenticated
using (public.tebelopele_has_capability('system.manage')) with check (public.tebelopele_has_capability('system.manage'));

create policy "facilities_admin_write" on public.tebelopele_facilities for update to authenticated
using (public.tebelopele_has_capability('system.manage')) with check (public.tebelopele_has_capability('system.manage'));
create policy "services_admin_write" on public.tebelopele_services for update to authenticated
using (public.tebelopele_has_capability('system.manage')) with check (public.tebelopele_has_capability('system.manage'));
create policy "staff_admin_write" on public.tebelopele_staff_profiles for update to authenticated
using (public.tebelopele_has_capability('staff.manage')) with check (public.tebelopele_has_capability('staff.manage'));

grant select,insert,update on public.tebelopele_referrals to authenticated;
grant select on public.tebelopele_referral_events to authenticated;
grant select,insert on public.tebelopele_referral_follow_ups to authenticated;
grant select,insert,update,delete on public.tebelopele_system_settings to authenticated;
grant update(is_active,name) on public.tebelopele_facilities to authenticated;
grant update(is_active,name,summary) on public.tebelopele_services to authenticated;
revoke execute on function public.tebelopele_update_referral_status(uuid,public.tebelopele_referral_status,text) from public,anon;
grant execute on function public.tebelopele_update_referral_status(uuid,public.tebelopele_referral_status,text) to authenticated;

insert into public.tebelopele_system_settings(key,value,description) values
 ('tebelopele_referral_follow_up_hours','48'::jsonb,'Default hours before referral follow-up'),
 ('tebelopele_support_sla_hours','4'::jsonb,'Default hours before an escalated support case is due')
on conflict(key) do nothing;

commit;
