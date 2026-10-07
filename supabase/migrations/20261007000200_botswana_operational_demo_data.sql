begin;

do $$
declare
  client_one uuid;
  client_two uuid;
  client_three uuid;
  navigator uuid;
  referral_officer uuid;
  content_editor uuid;
  gaborone uuid;
  molepolole uuid;
  francistown uuid;
  hiv_service uuid;
  family_service uuid;
  navigation_service uuid;
  navigation_skill uuid;
  appointment_skill uuid;
begin
  select id into client_one from auth.users where email = 'tebelopele.demo.client1@example.com';
  select id into client_two from auth.users where email = 'tebelopele.demo.client2@example.com';
  select id into client_three from auth.users where email = 'tebelopele.demo.client3@example.com';
  select id into navigator from auth.users where email = 'tebelopele.demo.navigator@example.com';
  select id into referral_officer from auth.users where email = 'tebelopele.demo.referralofficer@example.com';
  select id into content_editor from auth.users where email = 'tebelopele.demo.editor@example.com';

  select id into gaborone from public.tebelopele_facilities where code = 'TWC-GAB';
  select id into molepolole from public.tebelopele_facilities where code = 'TWC-MOL';
  select id into francistown from public.tebelopele_facilities where code = 'TWC-FTN';
  select id into hiv_service from public.tebelopele_services where slug = 'hiv-testing-counselling';
  select id into family_service from public.tebelopele_services where slug = 'family-planning';
  select id into navigation_service from public.tebelopele_services where slug = 'wellness-navigation';
  select id into navigation_skill from public.tebelopele_skills where slug = 'general_navigation';
  select id into appointment_skill from public.tebelopele_skills where slug = 'appointment_support';

  if client_one is null or client_two is null or client_three is null then
    raise exception 'Demo client accounts must be provisioned before operational seed data';
  end if;

  -- Three Botswana-time appointments for the current demonstration day.
  insert into public.tebelopele_appointment_slots
    (id, service_id, facility_id, starts_at, ends_at, capacity, status)
  values
    ('61000000-0000-4000-8000-000000000001', hiv_service, gaborone, (current_date + '09:00'::time) at time zone 'Africa/Gaborone', (current_date + '09:30'::time) at time zone 'Africa/Gaborone', 3, 'open'),
    ('61000000-0000-4000-8000-000000000002', family_service, molepolole, (current_date + '11:00'::time) at time zone 'Africa/Gaborone', (current_date + '11:30'::time) at time zone 'Africa/Gaborone', 3, 'open'),
    ('61000000-0000-4000-8000-000000000003', navigation_service, francistown, (current_date + '14:00'::time) at time zone 'Africa/Gaborone', (current_date + '14:30'::time) at time zone 'Africa/Gaborone', 3, 'open')
  on conflict (id) do update set
    service_id = excluded.service_id,
    facility_id = excluded.facility_id,
    starts_at = excluded.starts_at,
    ends_at = excluded.ends_at,
    capacity = excluded.capacity,
    status = excluded.status;

  insert into public.tebelopele_appointments
    (id, client_user_id, slot_id, service_id, facility_id, starts_at, ends_at, status, visit_reason, external_reference)
  values
    ('62000000-0000-4000-8000-000000000001', client_one, '61000000-0000-4000-8000-000000000001', hiv_service, gaborone, (current_date + '09:00'::time) at time zone 'Africa/Gaborone', (current_date + '09:30'::time) at time zone 'Africa/Gaborone', 'confirmed', 'Routine confidential testing appointment', 'DEMO-BW-APT-001'),
    ('62000000-0000-4000-8000-000000000002', client_two, '61000000-0000-4000-8000-000000000002', family_service, molepolole, (current_date + '11:00'::time) at time zone 'Africa/Gaborone', (current_date + '11:30'::time) at time zone 'Africa/Gaborone', 'confirmed', 'Discuss available family planning options', 'DEMO-BW-APT-002'),
    ('62000000-0000-4000-8000-000000000003', client_three, '61000000-0000-4000-8000-000000000003', navigation_service, francistown, (current_date + '14:00'::time) at time zone 'Africa/Gaborone', (current_date + '14:30'::time) at time zone 'Africa/Gaborone', 'requested', 'Help choosing an appropriate wellness service', 'DEMO-BW-APT-003')
  on conflict (id) do update set
    client_user_id = excluded.client_user_id,
    slot_id = excluded.slot_id,
    service_id = excluded.service_id,
    facility_id = excluded.facility_id,
    starts_at = excluded.starts_at,
    ends_at = excluded.ends_at,
    status = excluded.status,
    visit_reason = excluded.visit_reason,
    external_reference = excluded.external_reference;

  insert into public.tebelopele_appointment_status_events
    (id, appointment_id, from_status, to_status, reason, actor_id)
  values
    ('62100000-0000-4000-8000-000000000001', '62000000-0000-4000-8000-000000000001', null, 'confirmed', 'Botswana operational demonstration booking', client_one),
    ('62100000-0000-4000-8000-000000000002', '62000000-0000-4000-8000-000000000002', null, 'confirmed', 'Botswana operational demonstration booking', client_two),
    ('62100000-0000-4000-8000-000000000003', '62000000-0000-4000-8000-000000000003', null, 'requested', 'Botswana operational demonstration booking', client_three)
  on conflict (id) do nothing;

  -- Two active support transcripts: one open for matching and one already assigned.
  insert into public.tebelopele_conversations
    (id, client_user_id, channel, control_state, locale, title, last_message_at)
  values
    ('63000000-0000-4000-8000-000000000001', client_one, 'web', 'human_pending', 'en', 'Finding the right service in Gaborone', now() - interval '35 minutes'),
    ('63000000-0000-4000-8000-000000000002', client_two, 'web', 'human_active', 'tn', 'Appointment assistance request', now() - interval '18 minutes')
  on conflict (id) do update set
    client_user_id = excluded.client_user_id,
    control_state = excluded.control_state,
    locale = excluded.locale,
    title = excluded.title,
    last_message_at = excluded.last_message_at;

  insert into public.tebelopele_messages
    (id, conversation_id, sender_type, sender_user_id, body, source_label, idempotency_key, created_at)
  values
    ('63100000-0000-4000-8000-000000000001', '63000000-0000-4000-8000-000000000001', 'client', client_one, 'I would like help finding the most suitable Tebelopele service near Gaborone.', null, 'demo-bw-support-message-001', now() - interval '35 minutes'),
    ('63100000-0000-4000-8000-000000000002', '63000000-0000-4000-8000-000000000002', 'client', client_two, 'Ke kopa thuso ya go fetola nako ya appointment ya me.', null, 'demo-bw-support-message-002', now() - interval '20 minutes'),
    ('63100000-0000-4000-8000-000000000003', '63000000-0000-4000-8000-000000000002', 'agent', navigator, 'Re ka go thusa. Ke lebelela dinako tse dingwe tse di leng teng.', 'human', 'demo-bw-support-message-003', now() - interval '18 minutes')
  on conflict (id) do nothing;

  insert into public.tebelopele_support_cases
    (id, conversation_id, required_skill_id, facility_id, assigned_staff_user_id, status, priority, reason_code, language, due_at, accepted_at)
  values
    ('64000000-0000-4000-8000-000000000001', '63000000-0000-4000-8000-000000000001', navigation_skill, gaborone, null, 'open', 'normal', 'client_request', 'en', now() + interval '3 hours', null),
    ('64000000-0000-4000-8000-000000000002', '63000000-0000-4000-8000-000000000002', appointment_skill, molepolole, navigator, 'assigned', 'normal', 'appointment_change', 'tn', now() + interval '2 hours', now() - interval '18 minutes')
  on conflict (id) do update set
    required_skill_id = excluded.required_skill_id,
    facility_id = excluded.facility_id,
    assigned_staff_user_id = excluded.assigned_staff_user_id,
    status = excluded.status,
    priority = excluded.priority,
    reason_code = excluded.reason_code,
    language = excluded.language,
    due_at = excluded.due_at,
    accepted_at = excluded.accepted_at;

  insert into public.tebelopele_support_events
    (id, case_id, event_type, to_staff_user_id, reason, actor_id, created_at)
  values
    ('64100000-0000-4000-8000-000000000001', '64000000-0000-4000-8000-000000000001', 'created', null, 'client_request', client_one, now() - interval '35 minutes'),
    ('64100000-0000-4000-8000-000000000002', '64000000-0000-4000-8000-000000000002', 'created', null, 'appointment_change', client_two, now() - interval '20 minutes'),
    ('64100000-0000-4000-8000-000000000003', '64000000-0000-4000-8000-000000000002', 'claimed', navigator, 'Matched on appointment support and Setswana', navigator, now() - interval '18 minutes')
  on conflict (id) do nothing;

  -- Three active referrals at different workflow stages.
  if referral_officer is not null then
    insert into public.tebelopele_referrals
      (id, client_user_id, service_id, originating_facility_id, destination_facility_id, assigned_staff_user_id, status, urgency, referral_reason, consent_confirmed_at, external_reference, next_follow_up_at, created_by)
    values
      ('65000000-0000-4000-8000-000000000001', client_one, hiv_service, gaborone, francistown, referral_officer, 'pending', 'routine', 'Coordinate continuation of confidential support after client travel.', now() - interval '2 days', 'DEMO-BW-REF-001', now() + interval '24 hours', referral_officer),
      ('65000000-0000-4000-8000-000000000002', client_two, family_service, molepolole, gaborone, referral_officer, 'accepted', 'priority', 'Arrange an appropriate follow-up consultation at the Gaborone service point.', now() - interval '1 day', 'DEMO-BW-REF-002', now() + interval '12 hours', referral_officer),
      ('65000000-0000-4000-8000-000000000003', client_three, navigation_service, francistown, gaborone, referral_officer, 'scheduled', 'routine', 'Support a coordinated service-navigation follow-up.', now() - interval '3 days', 'DEMO-BW-REF-003', now() + interval '48 hours', referral_officer)
    on conflict (id) do update set
      status = excluded.status,
      urgency = excluded.urgency,
      referral_reason = excluded.referral_reason,
      next_follow_up_at = excluded.next_follow_up_at,
      assigned_staff_user_id = excluded.assigned_staff_user_id;

    insert into public.tebelopele_referral_events
      (id, referral_id, from_status, to_status, note, actor_id)
    values
      ('65100000-0000-4000-8000-000000000001', '65000000-0000-4000-8000-000000000001', null, 'pending', 'Referral created with client consent.', referral_officer),
      ('65100000-0000-4000-8000-000000000002', '65000000-0000-4000-8000-000000000002', 'pending', 'accepted', 'Destination facility accepted the referral.', referral_officer),
      ('65100000-0000-4000-8000-000000000003', '65000000-0000-4000-8000-000000000003', 'accepted', 'scheduled', 'Follow-up appointment coordinated.', referral_officer)
    on conflict (id) do nothing;
  end if;

  -- Two governed content drafts awaiting reviewer action.
  insert into public.tebelopele_content_categories (id, slug, name, description, sort_order)
  values
    ('66000000-0000-4000-8000-000000000001', 'botswana-service-guidance', 'Botswana service guidance', 'Approved operational guidance for accessing Tebelopele services in Botswana.', 10)
  on conflict (slug) do update set name = excluded.name, description = excluded.description, sort_order = excluded.sort_order;

  insert into public.tebelopele_health_articles
    (id, slug, category_id, visibility, status, created_by, updated_by)
  values
    ('66100000-0000-4000-8000-000000000001', 'what-to-expect-at-hiv-testing', '66000000-0000-4000-8000-000000000001', 'public', 'in_review', content_editor, content_editor),
    ('66100000-0000-4000-8000-000000000002', 'preparing-for-a-wellness-appointment', '66000000-0000-4000-8000-000000000001', 'public', 'in_review', content_editor, content_editor)
  on conflict (id) do update set
    category_id = excluded.category_id,
    visibility = excluded.visibility,
    status = excluded.status,
    updated_by = excluded.updated_by;

  insert into public.tebelopele_health_article_versions
    (id, article_id, version_number, title, summary, body, source_name, effective_at, created_by)
  values
    ('66200000-0000-4000-8000-000000000001', '66100000-0000-4000-8000-000000000001', 1, 'What to expect at an HIV testing appointment', 'A draft guide to the confidential testing and counselling journey.', 'This Botswana demonstration draft explains arrival, consent, confidential counselling, testing and discussion of next steps. A Tebelopele content reviewer must verify the wording and operational details before publication.', 'Tebelopele operational review required', now(), content_editor),
    ('66200000-0000-4000-8000-000000000002', '66100000-0000-4000-8000-000000000002', 1, 'Preparing for a wellness appointment', 'A draft checklist for clients attending a Tebelopele service point.', 'This Botswana demonstration draft reminds clients to confirm the facility, time and preparation instructions, and to avoid including urgent or highly sensitive details in online forms. A reviewer must approve it before publication.', 'Tebelopele operational review required', now(), content_editor)
  on conflict (article_id, version_number) do update set
    title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    source_name = excluded.source_name,
    effective_at = excluded.effective_at;
end;
$$;

commit;
