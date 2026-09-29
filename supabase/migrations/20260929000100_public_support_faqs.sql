begin;

insert into public.tebelopele_content_categories(id,slug,name,description,sort_order)
values('22000000-0000-4000-8000-000000000001','support-and-counselling','Support and counselling','Approved service-navigation information about support, counselling and human assistance.',10)
on conflict(slug) do update set name=excluded.name,description=excluded.description,is_active=true,sort_order=excluded.sort_order;

insert into public.tebelopele_faqs(id,slug,category_id,visibility,status,published_at,sort_order) values
 ('42000000-0000-4000-8000-000000000001','how-counselling-can-support-me','22000000-0000-4000-8000-000000000001','public','published',now(),10),
 ('42000000-0000-4000-8000-000000000002','finding-the-right-tebelopele-service','22000000-0000-4000-8000-000000000001','public','published',now(),20),
 ('42000000-0000-4000-8000-000000000003','speaking-to-a-human-expert','22000000-0000-4000-8000-000000000001','public','published',now(),30),
 ('42000000-0000-4000-8000-000000000004','privacy-of-chat-conversations','22000000-0000-4000-8000-000000000001','public','published',now(),40)
on conflict(slug) do update set category_id=excluded.category_id,visibility=excluded.visibility,status=excluded.status,published_at=excluded.published_at,sort_order=excluded.sort_order;

insert into public.tebelopele_faq_versions(id,faq_id,version_number,question,answer,keywords) values
 ('43000000-0000-4000-8000-000000000001','42000000-0000-4000-8000-000000000001',1,'How can counselling support me?','Tebelopele can help you explore available counselling and wellness-support services. Digital guidance does not diagnose. For personal guidance, request a human expert so an appropriate staff member can continue with you.',array['counselling','wellness','support']),
 ('43000000-0000-4000-8000-000000000002','42000000-0000-4000-8000-000000000002',1,'How do I find the right service?','Start with the services directory to compare approved service information, then check locations. If you remain unsure, a Tebelopele support navigator can help you identify a suitable next step.',array['services','locations','navigation']),
 ('43000000-0000-4000-8000-000000000003','42000000-0000-4000-8000-000000000003',1,'Can I speak to a person?','Yes. Signed-in clients can request human support from chat. The conversation transcript follows the request so an eligible staff member can continue without asking the client to start again.',array['human','expert','escalation']),
 ('43000000-0000-4000-8000-000000000004','42000000-0000-4000-8000-000000000004',1,'Is my conversation private?','Access is restricted by role and operational need. Clients should avoid sharing information that is not required and review the privacy notice for how chat transcripts and service records are handled.',array['privacy','chat','information'])
on conflict(faq_id,version_number) do update set question=excluded.question,answer=excluded.answer,keywords=excluded.keywords;

update public.tebelopele_faqs f set published_version_id=v.id
from public.tebelopele_faq_versions v where v.faq_id=f.id and v.version_number=1 and f.id in (
 '42000000-0000-4000-8000-000000000001','42000000-0000-4000-8000-000000000002','42000000-0000-4000-8000-000000000003','42000000-0000-4000-8000-000000000004');

commit;
