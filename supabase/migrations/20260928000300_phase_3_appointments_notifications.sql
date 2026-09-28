begin;

insert into public.tebelopele_capabilities(slug, description) values
  ('appointments.manage', 'Manage appointment schedules and client bookings'),
  ('appointments.notes', 'Read and write restricted appointment notes'),
  ('notifications.manage', 'Manage notification templates and delivery')
on conflict (slug) do nothing;

create table public.tebelopele_appointment_slots (
  id uuid primary key default extensions.gen_random_uuid(),
  service_id uuid not null references public.tebelopele_services(id) on delete restrict,
  facility_id uuid not null references public.tebelopele_facilities(id) on delete restrict,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  capacity integer not null default 1 check (capacity between 1 and 100),
  status text not null default 'open' check (status in ('open','closed','cancelled')),
  created_by uuid references public.tebelopele_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(service_id, facility_id, starts_at),
  check (ends_at > starts_at)
);

create table public.tebelopele_appointments (
  id uuid primary key default extensions.gen_random_uuid(),
  client_user_id uuid not null references public.tebelopele_clients(user_id) on delete restrict,
  slot_id uuid not null references public.tebelopele_appointment_slots(id) on delete restrict,
  service_id uuid not null references public.tebelopele_services(id) on delete restrict,
  facility_id uuid not null references public.tebelopele_facilities(id) on delete restrict,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'confirmed' check (status in ('requested','confirmed','rescheduled','cancelled','completed','no_show')),
  visit_reason text check (visit_reason is null or char_length(visit_reason) <= 500),
  external_reference text,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
create index tebelopele_appointments_client_idx on public.tebelopele_appointments(client_user_id, starts_at desc);
create index tebelopele_appointments_slot_active_idx on public.tebelopele_appointments(slot_id) where status in ('requested','confirmed');

create table public.tebelopele_appointment_status_events (
  id uuid primary key default extensions.gen_random_uuid(),
  appointment_id uuid not null references public.tebelopele_appointments(id) on delete cascade,
  from_status text,
  to_status text not null,
  reason text,
  actor_id uuid references public.tebelopele_profiles(id) on delete set null,
  occurred_at timestamptz not null default now()
);

create table public.tebelopele_appointment_notes (
  id uuid primary key default extensions.gen_random_uuid(),
  appointment_id uuid not null references public.tebelopele_appointments(id) on delete cascade,
  note text not null check (char_length(note) between 1 and 4000),
  created_by uuid not null references public.tebelopele_profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.tebelopele_notification_templates (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null,
  channel text not null check (channel in ('in_app','email','sms','whatsapp')),
  locale text not null default 'en',
  subject_template text,
  body_template text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(slug, channel, locale)
);

create table public.tebelopele_notifications (
  id uuid primary key default extensions.gen_random_uuid(),
  recipient_user_id uuid not null references public.tebelopele_profiles(id) on delete cascade,
  appointment_id uuid references public.tebelopele_appointments(id) on delete cascade,
  template_slug text not null,
  channel text not null check (channel in ('in_app','email','sms','whatsapp')),
  destination text,
  subject text,
  body text not null,
  status text not null default 'queued' check (status in ('queued','processing','sent','delivered','failed','cancelled')),
  scheduled_at timestamptz not null default now(),
  sent_at timestamptz,
  read_at timestamptz,
  idempotency_key text not null unique,
  attempt_count integer not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index tebelopele_notifications_due_idx on public.tebelopele_notifications(status, scheduled_at) where status in ('queued','failed');

create table public.tebelopele_notification_attempts (
  id uuid primary key default extensions.gen_random_uuid(),
  notification_id uuid not null references public.tebelopele_notifications(id) on delete cascade,
  provider text not null,
  provider_message_id text,
  outcome text not null check (outcome in ('accepted','delivered','failed')),
  response_code text,
  error_message text,
  attempted_at timestamptz not null default now()
);

create or replace function public.tebelopele_book_appointment(requested_slot_id uuid, requested_reason text default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare s public.tebelopele_appointment_slots; appointment_id uuid; current_user_id uuid := (select auth.uid());
begin
  if current_user_id is null then raise exception 'Authentication required'; end if;
  select * into s from public.tebelopele_appointment_slots where id = requested_slot_id for update;
  if not found or s.status <> 'open' or s.starts_at <= now() then raise exception 'Slot is unavailable'; end if;
  if not exists(select 1 from public.tebelopele_facility_services fs where fs.facility_id=s.facility_id and fs.service_id=s.service_id and fs.is_available) then raise exception 'Service is unavailable at this facility'; end if;
  if (select count(*) from public.tebelopele_appointments a where a.slot_id=s.id and a.status in ('requested','confirmed')) >= s.capacity then raise exception 'Slot is full'; end if;
  if exists(select 1 from public.tebelopele_appointments a where a.client_user_id=current_user_id and a.status in ('requested','confirmed') and tstzrange(a.starts_at,a.ends_at,'[)') && tstzrange(s.starts_at,s.ends_at,'[)')) then raise exception 'Appointment overlaps an existing booking'; end if;
  insert into public.tebelopele_appointments(client_user_id,slot_id,service_id,facility_id,starts_at,ends_at,visit_reason)
  values(current_user_id,s.id,s.service_id,s.facility_id,s.starts_at,s.ends_at,nullif(trim(requested_reason),'')) returning id into appointment_id;
  insert into public.tebelopele_appointment_status_events(appointment_id,to_status,actor_id) values(appointment_id,'confirmed',current_user_id);
  insert into public.tebelopele_notifications(recipient_user_id,appointment_id,template_slug,channel,body,idempotency_key)
  values(current_user_id,appointment_id,'appointment-confirmed','in_app','Your appointment has been confirmed.','appointment-confirmed:'||appointment_id);
  insert into public.tebelopele_notifications(recipient_user_id,appointment_id,template_slug,channel,body,scheduled_at,idempotency_key)
  values(current_user_id,appointment_id,'appointment-reminder','in_app','Reminder: you have an upcoming Tebelopele appointment.',greatest(now(),s.starts_at-interval '24 hours'),'appointment-reminder:'||appointment_id||':'||s.starts_at::text);
  insert into public.tebelopele_audit_events(actor_id,action,entity_type,entity_id) values(current_user_id,'appointment.booked','appointment',appointment_id);
  return appointment_id;
end; $$;

create or replace function public.tebelopele_cancel_appointment(target_appointment_id uuid, cancellation_reason text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare old_status text; current_user_id uuid := (select auth.uid());
begin
  update public.tebelopele_appointments set status='cancelled',cancelled_at=now()
  where id=target_appointment_id and (client_user_id=current_user_id or public.tebelopele_has_capability('appointments.manage')) and status in ('requested','confirmed')
  returning status into old_status;
  if not found then raise exception 'Appointment cannot be cancelled'; end if;
  insert into public.tebelopele_appointment_status_events(appointment_id,from_status,to_status,reason,actor_id) values(target_appointment_id,'confirmed','cancelled',nullif(trim(cancellation_reason),''),current_user_id);
  update public.tebelopele_notifications set status='cancelled' where appointment_id=target_appointment_id and status='queued';
  insert into public.tebelopele_notifications(recipient_user_id,appointment_id,template_slug,channel,body,idempotency_key)
  select client_user_id,id,'appointment-cancelled','in_app','Your appointment has been cancelled.','appointment-cancelled:'||id from public.tebelopele_appointments where id=target_appointment_id;
  insert into public.tebelopele_audit_events(actor_id,action,entity_type,entity_id) values(current_user_id,'appointment.cancelled','appointment',target_appointment_id);
end; $$;

create or replace function public.tebelopele_reschedule_appointment(target_appointment_id uuid, requested_slot_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare old_record public.tebelopele_appointments; s public.tebelopele_appointment_slots; current_user_id uuid := (select auth.uid());
begin
  select * into old_record from public.tebelopele_appointments where id=target_appointment_id and (client_user_id=current_user_id or public.tebelopele_has_capability('appointments.manage')) for update;
  if not found or old_record.status not in ('requested','confirmed') then raise exception 'Appointment cannot be rescheduled'; end if;
  select * into s from public.tebelopele_appointment_slots where id=requested_slot_id for update;
  if not found or s.status<>'open' or s.starts_at<=now() or s.service_id<>old_record.service_id then raise exception 'Slot is unavailable'; end if;
  if (select count(*) from public.tebelopele_appointments where slot_id=s.id and status in ('requested','confirmed') and id<>target_appointment_id)>=s.capacity then raise exception 'Slot is full'; end if;
  update public.tebelopele_appointments set slot_id=s.id,facility_id=s.facility_id,starts_at=s.starts_at,ends_at=s.ends_at,status='confirmed' where id=target_appointment_id;
  insert into public.tebelopele_appointment_status_events(appointment_id,from_status,to_status,reason,actor_id) values(target_appointment_id,old_record.status,'rescheduled','Slot changed',current_user_id);
  insert into public.tebelopele_appointment_status_events(appointment_id,from_status,to_status,reason,actor_id) values(target_appointment_id,'rescheduled','confirmed','New slot confirmed',current_user_id);
  update public.tebelopele_notifications set status='cancelled' where appointment_id=target_appointment_id and status='queued';
  insert into public.tebelopele_notifications(recipient_user_id,appointment_id,template_slug,channel,body,idempotency_key)
  values(old_record.client_user_id,target_appointment_id,'appointment-rescheduled','in_app','Your appointment has been rescheduled.','appointment-rescheduled:'||target_appointment_id||':'||s.starts_at::text);
  insert into public.tebelopele_notifications(recipient_user_id,appointment_id,template_slug,channel,body,scheduled_at,idempotency_key)
  values(old_record.client_user_id,target_appointment_id,'appointment-reminder','in_app','Reminder: you have an upcoming Tebelopele appointment.',greatest(now(),s.starts_at-interval '24 hours'),'appointment-reminder:'||target_appointment_id||':'||s.starts_at::text);
  insert into public.tebelopele_audit_events(actor_id,action,entity_type,entity_id) values(current_user_id,'appointment.rescheduled','appointment',target_appointment_id);
end; $$;

create trigger tebelopele_slots_updated_at before update on public.tebelopele_appointment_slots for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_appointments_updated_at before update on public.tebelopele_appointments for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_templates_updated_at before update on public.tebelopele_notification_templates for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_notifications_updated_at before update on public.tebelopele_notifications for each row execute function public.tebelopele_set_updated_at();

alter table public.tebelopele_appointment_slots enable row level security;
alter table public.tebelopele_appointments enable row level security;
alter table public.tebelopele_appointment_status_events enable row level security;
alter table public.tebelopele_appointment_notes enable row level security;
alter table public.tebelopele_notification_templates enable row level security;
alter table public.tebelopele_notifications enable row level security;
alter table public.tebelopele_notification_attempts enable row level security;
create policy "slots_read_authenticated" on public.tebelopele_appointment_slots for select to authenticated using (status='open' or public.tebelopele_has_capability('appointments.manage'));
create policy "slots_manage" on public.tebelopele_appointment_slots for all to authenticated using (public.tebelopele_has_capability('appointments.manage')) with check (public.tebelopele_has_capability('appointments.manage'));
create policy "appointments_read_scoped" on public.tebelopele_appointments for select to authenticated using (client_user_id=(select auth.uid()) or public.tebelopele_has_capability('appointments.manage'));
create policy "status_read_scoped" on public.tebelopele_appointment_status_events for select to authenticated using (exists(select 1 from public.tebelopele_appointments a where a.id=appointment_id and (a.client_user_id=(select auth.uid()) or public.tebelopele_has_capability('appointments.manage'))));
create policy "notes_staff_only" on public.tebelopele_appointment_notes for all to authenticated using (public.tebelopele_has_capability('appointments.notes')) with check (public.tebelopele_has_capability('appointments.notes') and created_by=(select auth.uid()));
create policy "templates_staff_only" on public.tebelopele_notification_templates for all to authenticated using (public.tebelopele_has_capability('notifications.manage')) with check (public.tebelopele_has_capability('notifications.manage'));
create policy "notifications_read_own_or_staff" on public.tebelopele_notifications for select to authenticated using (recipient_user_id=(select auth.uid()) or public.tebelopele_has_capability('notifications.manage'));
create policy "notifications_mark_own_read" on public.tebelopele_notifications for update to authenticated using (recipient_user_id=(select auth.uid())) with check (recipient_user_id=(select auth.uid()));
create policy "attempts_staff_only" on public.tebelopele_notification_attempts for select to authenticated using (public.tebelopele_has_capability('notifications.manage'));

grant select on public.tebelopele_appointment_slots,public.tebelopele_appointments,public.tebelopele_appointment_status_events,public.tebelopele_appointment_notes,public.tebelopele_notification_templates,public.tebelopele_notifications,public.tebelopele_notification_attempts to authenticated;
grant insert,update,delete on public.tebelopele_appointment_slots,public.tebelopele_appointment_notes,public.tebelopele_notification_templates to authenticated;
grant update(read_at) on public.tebelopele_notifications to authenticated;
revoke execute on function public.tebelopele_book_appointment(uuid,text),public.tebelopele_cancel_appointment(uuid,text),public.tebelopele_reschedule_appointment(uuid,uuid) from public,anon;
grant execute on function public.tebelopele_book_appointment(uuid,text),public.tebelopele_cancel_appointment(uuid,text),public.tebelopele_reschedule_appointment(uuid,uuid) to authenticated;
commit;
