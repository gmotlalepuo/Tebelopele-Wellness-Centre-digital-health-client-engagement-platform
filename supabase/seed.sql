insert into public.tebelopele_capabilities (slug, description) values
  ('users.read', 'View permitted user profiles'),
  ('roles.read', 'View role and capability assignments'),
  ('staff.read', 'View staff profiles, skills and facilities'),
  ('staff.manage', 'Manage staff profiles and routing attributes'),
  ('appointments.manage', 'Manage permitted appointments'),
  ('content.author', 'Create and edit content drafts'),
  ('content.review', 'Review and approve content versions'),
  ('support.handle', 'Handle assigned support conversations'),
  ('referrals.manage', 'Manage permitted referrals'),
  ('reports.read', 'View permitted operational reports'),
  ('audit.read', 'View the authorized audit trail'),
  ('system.manage', 'Manage operational configuration')
on conflict (slug) do update set description = excluded.description;

insert into public.tebelopele_roles (slug, name, description) values
  ('client', 'Client', 'Access own profile and client services'),
  ('reception_officer', 'Reception / Appointment Officer', 'Manage appointment workflows'),
  ('health_worker', 'Health Worker', 'Work with permitted health and support journeys'),
  ('support_agent', 'Support Agent', 'Handle assigned escalated conversations'),
  ('content_editor', 'Content Editor', 'Create and maintain content drafts'),
  ('content_reviewer', 'Content Reviewer', 'Review and approve exact content versions'),
  ('referral_officer', 'Referral Officer', 'Manage referral workflows'),
  ('reporting_user', 'Reporting User', 'View permitted reports'),
  ('system_administrator', 'System Administrator', 'Manage platform operations'),
  ('auditor', 'Auditor', 'Read approved audit and compliance information')
on conflict (slug) do update set name = excluded.name, description = excluded.description;

insert into public.tebelopele_role_capabilities (role_id, capability_id)
select r.id, c.id from public.tebelopele_roles r join public.tebelopele_capabilities c on
  (r.slug = 'reception_officer' and c.slug in ('staff.read', 'appointments.manage')) or
  (r.slug = 'health_worker' and c.slug in ('staff.read', 'support.handle')) or
  (r.slug = 'support_agent' and c.slug in ('staff.read', 'support.handle')) or
  (r.slug = 'content_editor' and c.slug = 'content.author') or
  (r.slug = 'content_reviewer' and c.slug in ('content.author', 'content.review')) or
  (r.slug = 'referral_officer' and c.slug = 'referrals.manage') or
  (r.slug = 'reporting_user' and c.slug = 'reports.read') or
  (r.slug = 'auditor' and c.slug in ('audit.read', 'reports.read')) or
  (r.slug = 'system_administrator')
on conflict do nothing;

insert into public.tebelopele_skills (slug, name, description) values
  ('general_navigation', 'General service navigation', 'Guide clients to appropriate Tebelopele services'),
  ('appointment_support', 'Appointment support', 'Help with booking and appointment administration'),
  ('content_guidance', 'Approved health content guidance', 'Explain approved organisational content'),
  ('referral_navigation', 'Referral navigation', 'Support approved referral journeys'),
  ('technical_support', 'Digital platform support', 'Help clients use the digital service')
on conflict (slug) do update set name = excluded.name, description = excluded.description;

insert into public.tebelopele_facilities (code, name)
values ('DEMO-GABORONE', 'Fictional Gaborone demonstration facility')
on conflict (code) do update set name = excluded.name;

update public.tebelopele_facilities set
  slug = 'gaborone-demonstration-facility',
  summary = 'Fictional local-development location used to exercise the Phase 2 directory.',
  address_line = 'Demonstration address',
  city = 'Gaborone',
  published_at = now()
where code = 'DEMO-GABORONE';

insert into public.tebelopele_services (id, slug, name, summary, description, eligibility, preparation, published_at) values
  ('10000000-0000-4000-8000-000000000001', 'demonstration-testing-support', 'Demonstration testing support', 'Fictional service used to verify directory and detail-page behaviour.', 'This record is local development seed data. Replace it with approved Tebelopele service information before any production use.', 'Demonstration eligibility is not operational guidance.', 'No preparation guidance is approved for this demonstration.', now()),
  ('10000000-0000-4000-8000-000000000002', 'demonstration-wellness-navigation', 'Demonstration wellness navigation', 'Fictional navigation service for local interface testing.', 'This service exists only to verify public search, location relationships and responsive layouts.', null, null, now())
on conflict (slug) do update set name = excluded.name, summary = excluded.summary, description = excluded.description, published_at = excluded.published_at;

insert into public.tebelopele_facility_hours (facility_id, weekday, opens_at, closes_at, note)
select id, day, '08:00'::time, '17:00'::time, 'Fictional local-development hours'
from public.tebelopele_facilities cross join generate_series(1, 5) as days(day)
where code = 'DEMO-GABORONE'
on conflict (facility_id, weekday) do update set opens_at = excluded.opens_at, closes_at = excluded.closes_at, note = excluded.note;

insert into public.tebelopele_facility_services (facility_id, service_id)
select f.id, s.id from public.tebelopele_facilities f cross join public.tebelopele_services s
where f.code = 'DEMO-GABORONE' and s.slug like 'demonstration-%'
on conflict do nothing;

insert into public.tebelopele_content_categories (id, slug, name, description) values
  ('20000000-0000-4000-8000-000000000001', 'using-services', 'Using services', 'Development category for service-navigation content'),
  ('20000000-0000-4000-8000-000000000002', 'privacy-support', 'Privacy and support', 'Development category for privacy and support content')
on conflict (slug) do update set name = excluded.name, description = excluded.description;

insert into public.tebelopele_health_articles (id, slug, category_id, visibility, status, published_at) values
  ('30000000-0000-4000-8000-000000000001', 'demonstration-preparing-for-a-visit', '20000000-0000-4000-8000-000000000001', 'public', 'published', now())
on conflict (slug) do update set status = excluded.status, published_at = excluded.published_at;

insert into public.tebelopele_health_article_versions (id, article_id, version_number, title, summary, body, source_name, effective_at) values
  ('31000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 1, 'Demonstration: preparing for a visit', 'Fictional content used to verify the public health-information experience.', 'This is development-only content. Approved Tebelopele information must replace it before production.', 'Local development seed', now())
on conflict (article_id, version_number) do update set title = excluded.title, summary = excluded.summary, body = excluded.body;

update public.tebelopele_health_articles set published_version_id = '31000000-0000-4000-8000-000000000001'
where id = '30000000-0000-4000-8000-000000000001';

insert into public.tebelopele_faqs (id, slug, category_id, visibility, status, published_at) values
  ('40000000-0000-4000-8000-000000000001', 'demonstration-platform-privacy', '20000000-0000-4000-8000-000000000002', 'public', 'published', now())
on conflict (slug) do update set status = excluded.status, published_at = excluded.published_at;

insert into public.tebelopele_faq_versions (id, faq_id, version_number, question, answer, keywords) values
  ('41000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', 1, 'How is information protected in this demonstration?', 'Role, ownership and Row Level Security policies restrict database access. Final privacy notices require Tebelopele approval.', array['privacy', 'security'])
on conflict (faq_id, version_number) do update set question = excluded.question, answer = excluded.answer, keywords = excluded.keywords;

update public.tebelopele_faqs set published_version_id = '41000000-0000-4000-8000-000000000001'
where id = '40000000-0000-4000-8000-000000000001';

insert into public.tebelopele_consent_versions (id, consent_type, version_number, title, summary, full_text, effective_at) values
  ('50000000-0000-4000-8000-000000000001', 'digital_service', 1, 'Demonstration digital-service consent', 'Local-development consent used to verify accept, decline and withdrawal events.', 'This wording is not approved production consent. It exists only for local workflow testing and must be replaced following Tebelopele legal and privacy review.', now())
on conflict (consent_type, version_number) do update set title = excluded.title, summary = excluded.summary, full_text = excluded.full_text;
