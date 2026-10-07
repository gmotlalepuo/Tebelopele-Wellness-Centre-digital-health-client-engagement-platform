begin;

create or replace function public.tebelopele_owns_conversation(target_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.tebelopele_conversations conversation
    where conversation.id = target_conversation_id
      and conversation.client_user_id = (select auth.uid())
  );
$$;

revoke execute on function public.tebelopele_owns_conversation(uuid) from public, anon;
grant execute on function public.tebelopele_owns_conversation(uuid) to authenticated;

drop policy if exists "cases_client_read" on public.tebelopele_support_cases;
create policy "cases_client_read"
on public.tebelopele_support_cases
for select
to authenticated
using (public.tebelopele_owns_conversation(conversation_id));

commit;
