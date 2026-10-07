begin;

-- Replace the early fictional directory records with Botswana-based demonstration
-- data. Operational owners must still confirm addresses, hours and contacts before
-- production publication.
update public.tebelopele_facilities
set is_active = false, published_at = null
where code = 'DEMO-GABORONE';

update public.tebelopele_services
set is_active = false, published_at = null
where slug like 'demonstration-%';

update public.tebelopele_appointment_slots slot
set status = 'closed'
where exists (
  select 1 from public.tebelopele_services service
  where service.id = slot.service_id and service.slug like 'demonstration-%'
);

insert into public.tebelopele_services
  (id, slug, name, summary, description, eligibility, preparation, is_active, published_at)
values
  ('11000000-0000-4000-8000-000000000001', 'hiv-testing-counselling', 'HIV testing and counselling', 'Confidential HIV testing, counselling and linkage to appropriate care.', 'A confidential service that supports clients to know their HIV status, understand the result and discuss appropriate prevention, treatment or referral options.', 'Available to clients seeking confidential HIV testing and counselling. A health worker will confirm service-specific requirements.', 'Bring identification only when the booking confirmation says it is required. You may ask questions before any test is performed.', true, now()),
  ('11000000-0000-4000-8000-000000000002', 'sti-screening-treatment', 'STI screening and treatment', 'Confidential screening, clinical guidance and treatment support for sexually transmitted infections.', 'A qualified provider assesses symptoms and risk, explains appropriate testing and discusses treatment or referral where required.', 'Clinical suitability and available tests are confirmed during the consultation.', 'Avoid sharing highly sensitive clinical details in the booking reason. A clinician will discuss these privately.', true, now()),
  ('11000000-0000-4000-8000-000000000003', 'family-planning', 'Family planning services', 'Confidential information and support to consider suitable family planning options.', 'A health worker provides accurate information, discusses available options and supports an informed, voluntary choice.', 'Available options depend on clinical suitability and stock at the selected facility.', 'Bring details of any current medication if available.', true, now()),
  ('11000000-0000-4000-8000-000000000004', 'prep-pep-support', 'PrEP and PEP support', 'HIV prevention guidance, eligibility assessment and linkage for PrEP or PEP.', 'A qualified provider explains pre-exposure and post-exposure prophylaxis, assesses urgency and eligibility, and supports next steps.', 'PEP is time-sensitive. Do not wait for an online appointment if exposure was recent; contact a facility or urgent health service promptly.', 'For time-sensitive PEP support, contact a facility immediately rather than waiting for chat.', true, now()),
  ('11000000-0000-4000-8000-000000000005', 'tb-screening-prevention', 'TB screening and prevention', 'Tuberculosis screening, prevention information and referral support.', 'A provider discusses symptoms and exposure, conducts available screening and explains prevention or referral steps.', 'The attending provider will determine the appropriate screening pathway.', 'If you feel severely unwell or have difficulty breathing, seek urgent medical care.', true, now()),
  ('11000000-0000-4000-8000-000000000006', 'ncd-screening', 'Non-communicable disease screening', 'Wellness screening for common non-communicable disease risks.', 'Screening may include approved checks and a discussion of health risks, prevention and referral options.', 'Available checks vary by facility and outreach schedule.', 'Follow any fasting or preparation instruction included in your appointment confirmation.', true, now()),
  ('11000000-0000-4000-8000-000000000007', 'sexual-reproductive-health', 'Sexual and reproductive health', 'Respectful, confidential sexual and reproductive health information and services.', 'A client-centred service offering information, screening and referral based on individual needs and available facility services.', 'Service scope is confirmed by the selected facility.', 'You may request a private conversation with a qualified staff member.', true, now()),
  ('11000000-0000-4000-8000-000000000008', 'wellness-navigation', 'Wellness and service navigation', 'Speak with a team member about the most appropriate Tebelopele service or next step.', 'A navigation appointment helps clients understand available services, facilities and referrals without requiring them to choose a clinical pathway alone.', 'Open to clients who need help finding the right service.', 'Write down the questions you would like to discuss.', true, now())
on conflict (slug) do update set
  name = excluded.name,
  summary = excluded.summary,
  description = excluded.description,
  eligibility = excluded.eligibility,
  preparation = excluded.preparation,
  is_active = excluded.is_active,
  published_at = excluded.published_at;

insert into public.tebelopele_facilities
  (id, code, slug, name, summary, address_line, city, phone, email, is_active, published_at)
values
  ('12000000-0000-4000-8000-000000000001', 'TWC-GAB', 'tebelopele-gaborone', 'Tebelopele Wellness Clinic — Gaborone', 'Integrated HIV and sexual and reproductive health services in Gaborone.', 'Plot 39, Unit 4, Gaborone International Commerce Park', 'Gaborone', '+267 391 4023', null, true, now()),
  ('12000000-0000-4000-8000-000000000002', 'TWC-MOL', 'tebelopele-molepolole', 'Tebelopele Wellness Clinic — Molepolole', 'Integrated wellness services serving Molepolole and Kweneng East.', 'Contact the facility to confirm current directions before travelling', 'Molepolole', '+267 591 0585', null, true, now()),
  ('12000000-0000-4000-8000-000000000003', 'TWC-FTN', 'tebelopele-francistown', 'Tebelopele Wellness Clinic — Francistown', 'Integrated wellness services for clients in Francistown and surrounding communities.', 'Contact the facility to confirm current directions before travelling', 'Francistown', '+267 241 8202', null, true, now()),
  ('12000000-0000-4000-8000-000000000004', 'TWC-MAU', 'tebelopele-maun', 'Tebelopele Wellness Clinic — Maun', 'Integrated wellness services for clients in Maun and surrounding communities.', 'Contact Tebelopele to confirm current directions and contact details', 'Maun', null, null, true, now()),
  ('12000000-0000-4000-8000-000000000005', 'TWC-PAL', 'tebelopele-palapye', 'Tebelopele Wellness Clinic — Palapye', 'Integrated wellness services for clients in Palapye and surrounding communities.', 'Contact Tebelopele to confirm current directions and contact details', 'Palapye', null, null, true, now())
on conflict (code) do update set
  slug = excluded.slug,
  name = excluded.name,
  summary = excluded.summary,
  address_line = excluded.address_line,
  city = excluded.city,
  phone = excluded.phone,
  email = excluded.email,
  is_active = excluded.is_active,
  published_at = excluded.published_at;

insert into public.tebelopele_facility_hours (facility_id, weekday, opens_at, closes_at, is_closed, note)
select f.id, h.weekday,
  case when h.weekday between 1 and 4 then '07:30'::time when h.weekday = 5 then '07:30'::time end,
  case when h.weekday between 1 and 4 then '17:00'::time when h.weekday = 5 then '13:30'::time end,
  h.weekday in (0, 6),
  'Demonstration hours based on published service information; confirm before travelling'
from public.tebelopele_facilities f
cross join generate_series(0, 6) as h(weekday)
where f.code in ('TWC-GAB', 'TWC-MOL', 'TWC-FTN', 'TWC-MAU', 'TWC-PAL')
on conflict (facility_id, weekday) do update set
  opens_at = excluded.opens_at,
  closes_at = excluded.closes_at,
  is_closed = excluded.is_closed,
  note = excluded.note;

insert into public.tebelopele_facility_services (facility_id, service_id, is_available, availability_note)
select f.id, s.id, true, 'Availability is demonstrated for platform validation and must be operationally confirmed'
from public.tebelopele_facilities f
cross join public.tebelopele_services s
where f.code in ('TWC-GAB', 'TWC-MOL', 'TWC-FTN', 'TWC-MAU', 'TWC-PAL')
  and s.slug in ('hiv-testing-counselling', 'sti-screening-treatment', 'family-planning', 'prep-pep-support', 'tb-screening-prevention', 'ncd-screening', 'sexual-reproductive-health', 'wellness-navigation')
on conflict (facility_id, service_id) do update set
  is_available = excluded.is_available,
  availability_note = excluded.availability_note;

-- Generate a useful Botswana-time booking horizon. These are demonstration
-- slots, not a claim about live clinic capacity.
insert into public.tebelopele_appointment_slots
  (service_id, facility_id, starts_at, ends_at, capacity, status)
select s.id, f.id,
  (d.booking_day + t.start_time) at time zone 'Africa/Gaborone',
  (d.booking_day + t.start_time + interval '30 minutes') at time zone 'Africa/Gaborone',
  3,
  'open'
from public.tebelopele_services s
cross join public.tebelopele_facilities f
cross join lateral (
  select day::date as booking_day
  from generate_series(current_date + 1, current_date + 28, interval '1 day') day
  where extract(isodow from day) between 1 and 5
) d
cross join (values ('09:00'::time), ('11:00'::time), ('14:00'::time)) as t(start_time)
where s.slug in ('hiv-testing-counselling', 'family-planning', 'wellness-navigation')
  and f.code in ('TWC-GAB', 'TWC-MOL', 'TWC-FTN', 'TWC-MAU', 'TWC-PAL')
on conflict (service_id, facility_id, starts_at) do update set
  ends_at = excluded.ends_at,
  capacity = excluded.capacity,
  status = 'open';

create or replace function public.tebelopele_request_human_support(
  required_skill_slug text,
  preferred_language text,
  request_message text
)
returns table(conversation_id uuid, case_id uuid)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := (select auth.uid());
  selected_skill_id uuid;
  new_conversation_id uuid;
  new_case_id uuid;
begin
  if current_user_id is null then raise exception 'Authentication required'; end if;
  if preferred_language not in ('en', 'tn') then raise exception 'Unsupported language'; end if;
  if char_length(trim(request_message)) not between 10 and 1500 then raise exception 'Invalid support message'; end if;
  if not exists(select 1 from public.tebelopele_clients where user_id = current_user_id) then raise exception 'Client profile required'; end if;

  select id into selected_skill_id
  from public.tebelopele_skills
  where slug = required_skill_slug and is_active;
  if selected_skill_id is null then raise exception 'Support skill unavailable'; end if;

  insert into public.tebelopele_conversations(client_user_id, channel, control_state, locale, title)
  values(current_user_id, 'web', 'human_pending', preferred_language, 'Human support request')
  returning id into new_conversation_id;

  insert into public.tebelopele_messages(conversation_id, sender_type, body, idempotency_key)
  values(new_conversation_id, 'client', trim(request_message), extensions.gen_random_uuid());

  insert into public.tebelopele_support_cases(conversation_id, required_skill_id, status, priority, reason_code, language, due_at)
  values(new_conversation_id, selected_skill_id, 'open', 'normal', 'client_request', preferred_language, now() + interval '4 hours')
  returning id into new_case_id;

  insert into public.tebelopele_support_events(case_id, event_type, reason, actor_id)
  values(new_case_id, 'created', 'client_request', current_user_id);

  return query select new_conversation_id, new_case_id;
end;
$$;

revoke execute on function public.tebelopele_request_human_support(text, text, text) from public, anon;
grant execute on function public.tebelopele_request_human_support(text, text, text) to authenticated;

commit;
