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
