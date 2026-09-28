begin;

insert into public.tebelopele_capabilities(slug,description) values
 ('support.assign','Assign and reassign support cases'),('support.notes','Read and write private support notes'),('whatsapp.manage','Manage WhatsApp flows and delivery operations')
on conflict(slug) do nothing;

create table public.tebelopele_support_cases(
 id uuid primary key default extensions.gen_random_uuid(), conversation_id uuid not null references public.tebelopele_conversations(id) on delete cascade,
 required_skill_id uuid references public.tebelopele_skills(id) on delete set null, facility_id uuid references public.tebelopele_facilities(id) on delete set null,
 assigned_staff_user_id uuid references public.tebelopele_staff_profiles(user_id) on delete set null,
 status text not null default 'open' check(status in ('open','assigned','waiting_user','resolved','closed')),
 priority text not null default 'normal' check(priority in ('low','normal','high','urgent')),
 reason_code text not null, language text not null default 'en', due_at timestamptz, accepted_at timestamptz, resolved_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index tebelopele_one_active_case_idx on public.tebelopele_support_cases(conversation_id) where status in ('open','assigned','waiting_user');
create index tebelopele_support_queue_idx on public.tebelopele_support_cases(status,priority,due_at,created_at);
create table public.tebelopele_support_events(
 id uuid primary key default extensions.gen_random_uuid(), case_id uuid not null references public.tebelopele_support_cases(id) on delete cascade,
 event_type text not null check(event_type in ('created','claimed','reassigned','takeover','released','waiting_user','resolved','closed')),
 from_staff_user_id uuid references public.tebelopele_staff_profiles(user_id) on delete set null, to_staff_user_id uuid references public.tebelopele_staff_profiles(user_id) on delete set null,
 reason text, actor_id uuid references public.tebelopele_profiles(id) on delete set null, created_at timestamptz not null default now()
);
create table public.tebelopele_support_internal_notes(
 id uuid primary key default extensions.gen_random_uuid(), case_id uuid not null references public.tebelopele_support_cases(id) on delete cascade,
 body text not null check(char_length(body) between 1 and 4000), created_by uuid not null references public.tebelopele_profiles(id) on delete restrict, created_at timestamptz not null default now()
);

create table public.tebelopele_channel_identities(
 id uuid primary key default extensions.gen_random_uuid(), channel text not null check(channel='whatsapp'), external_id text not null,
 client_user_id uuid references public.tebelopele_clients(user_id) on delete set null,
 verification_level text not null default 'unverified' check(verification_level in ('unverified','basic','verified')),
 verified_at timestamptz, created_at timestamptz not null default now(), unique(channel,external_id)
);
create table public.tebelopele_whatsapp_flow_versions(
 id uuid primary key default extensions.gen_random_uuid(), version_number integer not null unique, status text not null default 'draft' check(status in ('draft','published','retired')),
 definition jsonb not null check(jsonb_typeof(definition)='object'), published_at timestamptz, created_by uuid references public.tebelopele_profiles(id), created_at timestamptz not null default now()
);
create table public.tebelopele_whatsapp_flow_states(
 identity_id uuid primary key references public.tebelopele_channel_identities(id) on delete cascade,
 conversation_id uuid not null references public.tebelopele_conversations(id) on delete cascade,
 flow_version_id uuid not null references public.tebelopele_whatsapp_flow_versions(id) on delete restrict,
 current_node text not null default 'main_menu', selected_option_id text, locale text not null default 'en', expires_at timestamptz not null, updated_at timestamptz not null default now()
);
create table public.tebelopele_whatsapp_provider_events(
 id uuid primary key default extensions.gen_random_uuid(), provider text not null, provider_event_id text not null unique, event_type text not null,
 signature_valid boolean not null, payload jsonb not null, processing_status text not null default 'received' check(processing_status in ('received','processed','failed','ignored')),
 error_code text, received_at timestamptz not null default now(), processed_at timestamptz
);
create table public.tebelopele_message_deliveries(
 id uuid primary key default extensions.gen_random_uuid(), message_id uuid not null references public.tebelopele_messages(id) on delete cascade,
 channel text not null check(channel in ('web','whatsapp')), provider text, provider_message_id text unique,
 status text not null default 'queued' check(status in ('queued','accepted','sent','delivered','read','failed')),
 error_code text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(message_id,channel)
);

create or replace function public.tebelopele_escalate_conversation(target_conversation_id uuid,required_skill_slug text default 'general_navigation',escalation_reason text default 'client_request')
returns uuid language plpgsql security definer set search_path='' as $$
declare result_id uuid; skill_id uuid; current_user_id uuid := (select auth.uid());
begin
 if not exists(select 1 from public.tebelopele_conversations where id=target_conversation_id and client_user_id=current_user_id and control_state<>'closed') then raise exception 'Conversation unavailable'; end if;
 select id into skill_id from public.tebelopele_skills where slug=required_skill_slug and is_active;
 select id into result_id from public.tebelopele_support_cases where conversation_id=target_conversation_id and status in ('open','assigned','waiting_user') for update;
 if result_id is null then
  insert into public.tebelopele_support_cases(conversation_id,required_skill_id,reason_code,language,due_at)
  select id,skill_id,escalation_reason,locale,now()+interval '4 hours' from public.tebelopele_conversations where id=target_conversation_id returning id into result_id;
  insert into public.tebelopele_support_events(case_id,event_type,reason,actor_id) values(result_id,'created',escalation_reason,current_user_id);
 end if;
 update public.tebelopele_conversations set control_state='human_pending' where id=target_conversation_id;
 insert into public.tebelopele_audit_events(actor_id,action,entity_type,entity_id) values(current_user_id,'support.escalated','support_case',result_id);
 return result_id;
end; $$;

create or replace function public.tebelopele_claim_support_case(target_case_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare current_user_id uuid := (select auth.uid()); target_conversation uuid;
begin
 if not public.tebelopele_has_capability('support.handle') then raise exception 'Support capability required'; end if;
 update public.tebelopele_support_cases c set assigned_staff_user_id=current_user_id,status='assigned',accepted_at=now()
 where c.id=target_case_id and c.status='open' and (c.required_skill_id is null or exists(select 1 from public.tebelopele_staff_skills ss where ss.staff_user_id=current_user_id and ss.skill_id=c.required_skill_id and ss.is_verified))
 and exists(select 1 from public.tebelopele_staff_profiles sp where sp.user_id=current_user_id and sp.availability='available' and sp.is_accepting_cases and c.language=any(sp.languages)
   and (c.facility_id is null or exists(select 1 from public.tebelopele_staff_facilities sf where sf.staff_user_id=current_user_id and sf.facility_id=c.facility_id))
   and (select count(*) from public.tebelopele_support_cases active_case where active_case.assigned_staff_user_id=current_user_id and active_case.status in ('assigned','waiting_user'))<sp.max_active_cases)
 returning conversation_id into target_conversation;
 if not found then raise exception 'Case is unavailable or skill requirements are not met'; end if;
 update public.tebelopele_conversations set control_state='human_active' where id=target_conversation;
 insert into public.tebelopele_support_events(case_id,event_type,to_staff_user_id,actor_id) values(target_case_id,'claimed',current_user_id,current_user_id);
 insert into public.tebelopele_audit_events(actor_id,action,entity_type,entity_id) values(current_user_id,'support.claimed','support_case',target_case_id);
end; $$;

create or replace function public.tebelopele_agent_reply(target_case_id uuid,message_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare result_id uuid; target_conversation uuid; current_user_id uuid := (select auth.uid());
begin
 select conversation_id into target_conversation from public.tebelopele_support_cases where id=target_case_id and assigned_staff_user_id=current_user_id and status in ('assigned','waiting_user') for update;
 if not found or char_length(trim(message_body)) not between 1 and 4000 then raise exception 'Reply unavailable'; end if;
 insert into public.tebelopele_messages(conversation_id,sender_type,sender_user_id,body,source_label) values(target_conversation,'agent',current_user_id,trim(message_body),'human') returning id into result_id;
 update public.tebelopele_support_cases set status='waiting_user' where id=target_case_id; update public.tebelopele_conversations set last_message_at=now(),control_state='human_active' where id=target_conversation;
 return result_id;
end; $$;

create or replace function public.tebelopele_reassign_support_case(target_case_id uuid,new_staff_user_id uuid,reassignment_reason text)
returns void language plpgsql security definer set search_path='' as $$
declare current_user_id uuid := (select auth.uid()); old_staff uuid; target_case public.tebelopele_support_cases;
begin
 if not public.tebelopele_has_capability('support.assign') then raise exception 'Assignment capability required'; end if;
 select * into target_case from public.tebelopele_support_cases where id=target_case_id and status in ('open','assigned','waiting_user') for update;
 if not found then raise exception 'Case unavailable'; end if;
 if not exists(select 1 from public.tebelopele_staff_profiles sp where sp.user_id=new_staff_user_id and sp.availability='available' and sp.is_accepting_cases and target_case.language=any(sp.languages) and (target_case.required_skill_id is null or exists(select 1 from public.tebelopele_staff_skills ss where ss.staff_user_id=sp.user_id and ss.skill_id=target_case.required_skill_id and ss.is_verified)) and (target_case.facility_id is null or exists(select 1 from public.tebelopele_staff_facilities sf where sf.staff_user_id=sp.user_id and sf.facility_id=target_case.facility_id)) and (select count(*) from public.tebelopele_support_cases c where c.assigned_staff_user_id=sp.user_id and c.status in ('assigned','waiting_user'))<sp.max_active_cases) then raise exception 'New assignee is not eligible'; end if;
 old_staff:=target_case.assigned_staff_user_id; update public.tebelopele_support_cases set assigned_staff_user_id=new_staff_user_id,status='assigned',accepted_at=null where id=target_case_id;
 insert into public.tebelopele_support_events(case_id,event_type,from_staff_user_id,to_staff_user_id,reason,actor_id) values(target_case_id,'reassigned',old_staff,new_staff_user_id,nullif(trim(reassignment_reason),''),current_user_id);
end; $$;

create or replace function public.tebelopele_release_support_case(target_case_id uuid,resolution_note text default null)
returns void language plpgsql security definer set search_path='' as $$
declare target_conversation uuid; current_user_id uuid := (select auth.uid());
begin
 update public.tebelopele_support_cases set status='resolved',resolved_at=now() where id=target_case_id and assigned_staff_user_id=current_user_id and status in ('assigned','waiting_user') returning conversation_id into target_conversation;
 if not found then raise exception 'Case unavailable'; end if;
 update public.tebelopele_conversations set control_state='automated' where id=target_conversation;
 insert into public.tebelopele_support_events(case_id,event_type,reason,actor_id) values(target_case_id,'released',resolution_note,current_user_id);
end; $$;

create trigger tebelopele_support_cases_updated_at before update on public.tebelopele_support_cases for each row execute function public.tebelopele_set_updated_at();
create trigger tebelopele_deliveries_updated_at before update on public.tebelopele_message_deliveries for each row execute function public.tebelopele_set_updated_at();
alter table public.tebelopele_support_cases enable row level security; alter table public.tebelopele_support_events enable row level security; alter table public.tebelopele_support_internal_notes enable row level security; alter table public.tebelopele_channel_identities enable row level security; alter table public.tebelopele_whatsapp_flow_versions enable row level security; alter table public.tebelopele_whatsapp_flow_states enable row level security; alter table public.tebelopele_whatsapp_provider_events enable row level security; alter table public.tebelopele_message_deliveries enable row level security;
create policy "cases_client_read" on public.tebelopele_support_cases for select to authenticated using(exists(select 1 from public.tebelopele_conversations c where c.id=conversation_id and c.client_user_id=(select auth.uid())));
create policy "cases_staff_read" on public.tebelopele_support_cases for select to authenticated using(public.tebelopele_has_capability('support.assign') or assigned_staff_user_id=(select auth.uid()) or (status='open' and public.tebelopele_has_capability('support.handle') and exists(select 1 from public.tebelopele_staff_profiles sp where sp.user_id=(select auth.uid()) and sp.availability='available' and sp.is_accepting_cases and language=any(sp.languages) and (required_skill_id is null or exists(select 1 from public.tebelopele_staff_skills ss where ss.staff_user_id=sp.user_id and ss.skill_id=required_skill_id and ss.is_verified)) and (facility_id is null or exists(select 1 from public.tebelopele_staff_facilities sf where sf.staff_user_id=sp.user_id and sf.facility_id=facility_id)))));
create policy "events_client_or_staff_read" on public.tebelopele_support_events for select to authenticated using(exists(select 1 from public.tebelopele_support_cases sc join public.tebelopele_conversations c on c.id=sc.conversation_id where sc.id=case_id and (c.client_user_id=(select auth.uid()) or public.tebelopele_has_capability('support.handle'))));
create policy "notes_staff_only" on public.tebelopele_support_internal_notes for all to authenticated using(public.tebelopele_has_capability('support.notes') and exists(select 1 from public.tebelopele_support_cases c where c.id=case_id and (c.assigned_staff_user_id=(select auth.uid()) or public.tebelopele_has_capability('support.assign')))) with check(public.tebelopele_has_capability('support.notes') and created_by=(select auth.uid()) and exists(select 1 from public.tebelopele_support_cases c where c.id=case_id and (c.assigned_staff_user_id=(select auth.uid()) or public.tebelopele_has_capability('support.assign'))));
create policy "channel_identity_staff" on public.tebelopele_channel_identities for select to authenticated using(public.tebelopele_has_capability('whatsapp.manage'));
create policy "flow_staff" on public.tebelopele_whatsapp_flow_versions for all to authenticated using(public.tebelopele_has_capability('whatsapp.manage')) with check(public.tebelopele_has_capability('whatsapp.manage'));
create policy "flow_state_staff" on public.tebelopele_whatsapp_flow_states for select to authenticated using(public.tebelopele_has_capability('whatsapp.manage') or public.tebelopele_has_capability('support.handle'));
create policy "provider_events_staff" on public.tebelopele_whatsapp_provider_events for select to authenticated using(public.tebelopele_has_capability('whatsapp.manage'));
create policy "deliveries_scoped" on public.tebelopele_message_deliveries for select to authenticated using(exists(select 1 from public.tebelopele_messages m join public.tebelopele_conversations c on c.id=m.conversation_id where m.id=message_id and (c.client_user_id=(select auth.uid()) or public.tebelopele_has_capability('support.handle') or public.tebelopele_has_capability('whatsapp.manage'))));
drop policy "conversations_client_or_staff_read" on public.tebelopele_conversations;
create policy "conversations_client_or_assigned_staff_read" on public.tebelopele_conversations for select to authenticated using(client_user_id=(select auth.uid()) or public.tebelopele_has_capability('conversations.read') or exists(select 1 from public.tebelopele_support_cases sc where sc.conversation_id=id and (sc.assigned_staff_user_id=(select auth.uid()) or public.tebelopele_has_capability('support.assign'))));
drop policy "messages_client_or_staff_read" on public.tebelopele_messages;
create policy "messages_client_or_assigned_staff_read" on public.tebelopele_messages for select to authenticated using(exists(select 1 from public.tebelopele_conversations c where c.id=conversation_id and (c.client_user_id=(select auth.uid()) or public.tebelopele_has_capability('conversations.read') or exists(select 1 from public.tebelopele_support_cases sc where sc.conversation_id=c.id and (sc.assigned_staff_user_id=(select auth.uid()) or public.tebelopele_has_capability('support.assign'))))));
create policy "staff_profile_update_own_availability" on public.tebelopele_staff_profiles for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
grant select on public.tebelopele_support_cases,public.tebelopele_support_events,public.tebelopele_support_internal_notes,public.tebelopele_channel_identities,public.tebelopele_whatsapp_flow_versions,public.tebelopele_whatsapp_flow_states,public.tebelopele_whatsapp_provider_events,public.tebelopele_message_deliveries to authenticated;
grant insert on public.tebelopele_support_internal_notes to authenticated; grant select,insert,update,delete on public.tebelopele_whatsapp_flow_versions to authenticated;
grant update(availability,languages,max_active_cases,is_accepting_cases) on public.tebelopele_staff_profiles to authenticated;
revoke execute on function public.tebelopele_escalate_conversation(uuid,text,text),public.tebelopele_claim_support_case(uuid),public.tebelopele_agent_reply(uuid,text),public.tebelopele_reassign_support_case(uuid,uuid,text),public.tebelopele_release_support_case(uuid,text) from public,anon;
grant execute on function public.tebelopele_escalate_conversation(uuid,text,text),public.tebelopele_claim_support_case(uuid),public.tebelopele_agent_reply(uuid,text),public.tebelopele_reassign_support_case(uuid,uuid,text),public.tebelopele_release_support_case(uuid,text) to authenticated;
commit;
