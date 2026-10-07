-- Give demonstration clients realistic Botswana names without changing their
-- login email addresses, identities, credentials or linked service records.

update public.tebelopele_profiles as profile
set display_name = names.display_name
from (
  values
    ('tebelopele.demo.client1@example.com', 'Naledi Moagi'),
    ('tebelopele.demo.client2@example.com', 'Kagiso Molefe'),
    ('tebelopele.demo.client3@example.com', 'Lorato Kgosi')
) as names(email, display_name)
join auth.users as account on account.email = names.email
where profile.id = account.id;

update auth.users as account
set raw_user_meta_data = coalesce(account.raw_user_meta_data, '{}'::jsonb)
  || jsonb_build_object('display_name', names.display_name)
from (
  values
    ('tebelopele.demo.client1@example.com', 'Naledi Moagi'),
    ('tebelopele.demo.client2@example.com', 'Kagiso Molefe'),
    ('tebelopele.demo.client3@example.com', 'Lorato Kgosi')
) as names(email, display_name)
where account.email = names.email;

update public.users as shared_user
set first_name = 'Naledi',
    last_name = 'Moagi',
    updated_at = now()
from auth.users as account
where account.email = 'tebelopele.demo.client1@example.com'
  and shared_user.id = account.id;
