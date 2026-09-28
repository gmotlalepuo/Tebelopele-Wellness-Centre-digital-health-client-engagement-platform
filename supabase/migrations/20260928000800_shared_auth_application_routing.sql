begin;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = 'public'
as $$
begin
  if new.raw_user_meta_data ->> 'app' in ('bermuda','tebelopele') then
    return new;
  end if;
  insert into public.users(id,email,first_name,last_name,phone_number,role,password_hash)
  values(new.id,new.email,coalesce(new.raw_user_meta_data ->> 'first_name','User'),coalesce(new.raw_user_meta_data ->> 'last_name',''),nullif(new.raw_user_meta_data ->> 'phone_number',''),'customer','')
  on conflict(id) do update set email=new.email,first_name=coalesce(new.raw_user_meta_data ->> 'first_name',excluded.first_name),last_name=coalesce(new.raw_user_meta_data ->> 'last_name',excluded.last_name),updated_at=now();
  return new;
end;
$$;

create or replace function public.tebelopele_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.raw_user_meta_data ->> 'app' is distinct from 'tebelopele' then
    return new;
  end if;
  insert into public.tebelopele_profiles(id,display_name,phone)
  values(new.id,coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'),''),split_part(new.email,'@',1),'Tebelopele client'),nullif(trim(new.raw_user_meta_data ->> 'phone'),''))
  on conflict(id) do update set display_name=excluded.display_name,phone=coalesce(excluded.phone,public.tebelopele_profiles.phone);
  return new;
end;
$$;

commit;
