import {createClient} from "@supabase/supabase-js";
import {randomBytes} from "node:crypto";
import {writeFile} from "node:fs/promises";

const url=process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceKey=process.env.SUPABASE_SERVICE_ROLE_KEY;
if(!url||!serviceKey)throw new Error("Supabase administration environment is not configured");
const supabase=createClient(url,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});

const roles={
  client:[],
  reception_officer:["staff.read","appointments.manage","appointments.notes","notifications.manage"],
  support_agent:["staff.read","support.handle","support.notes"],
  referral_officer:["staff.read","referrals.manage"],
  content_editor:["content.author","knowledge.manage"],
  content_reviewer:["content.author","content.review","content.publish","knowledge.manage","ai.monitor"],
  reporting_user:["reports.read"],
  auditor:["reports.read","audit.read"],
  system_administrator:["users.read","roles.read","staff.read","staff.manage","appointments.manage","appointments.notes","notifications.manage","content.author","content.review","content.publish","knowledge.manage","support.handle","support.assign","support.notes","whatsapp.manage","conversations.read","ai.monitor","referrals.manage","reports.read","audit.read","system.manage"],
};
const roleNames={client:"Client",reception_officer:"Reception / Appointment Officer",support_agent:"Support Agent",referral_officer:"Referral Officer",content_editor:"Content Editor",content_reviewer:"Content Reviewer",reporting_user:"Reporting User",auditor:"Auditor",system_administrator:"System Administrator"};
const skills={
  general_navigation:["General service navigation","Guide clients to appropriate Tebelopele services"],
  appointment_support:["Appointment support","Help with booking and appointment administration"],
  content_guidance:["Approved health content guidance","Explain approved organisational content"],
  referral_navigation:["Referral navigation","Support approved referral journeys"],
  technical_support:["Digital platform support","Help clients use the digital service"],
};
const accounts=[
  {email:"tebelopele.demo.admin@example.com",name:"Demo System Administrator",role:"system_administrator",job:"System administrator",skills:["technical_support","general_navigation"]},
  {email:"tebelopele.demo.appointments@example.com",name:"Demo Appointment Officer",role:"reception_officer",job:"Appointment officer",skills:["appointment_support"]},
  {email:"tebelopele.demo.navigator@example.com",name:"Demo General Navigator",role:"support_agent",job:"Client support navigator",skills:["general_navigation","technical_support"]},
  {email:"tebelopele.demo.healthcontent@example.com",name:"Demo Health Content Agent",role:"support_agent",job:"Health information support agent",skills:["content_guidance"]},
  {email:"tebelopele.demo.referralsupport@example.com",name:"Demo Referral Support Agent",role:"support_agent",job:"Referral support agent",skills:["referral_navigation"]},
  {email:"tebelopele.demo.referralofficer@example.com",name:"Demo Referral Officer",role:"referral_officer",job:"Referral officer",skills:["referral_navigation"]},
  {email:"tebelopele.demo.editor@example.com",name:"Demo Content Editor",role:"content_editor",job:"Content editor",skills:["content_guidance"]},
  {email:"tebelopele.demo.reviewer@example.com",name:"Demo Content Reviewer",role:"content_reviewer",job:"Content reviewer",skills:["content_guidance"]},
  {email:"tebelopele.demo.reporting@example.com",name:"Demo Reporting User",role:"reporting_user",job:"Reporting officer",skills:[]},
  {email:"tebelopele.demo.auditor@example.com",name:"Demo Auditor",role:"auditor",job:"Auditor",skills:[]},
  {email:"tebelopele.demo.client1@example.com",name:"Naledi Moagi",surname:"Moagi",role:"client",preferredName:"Naledi",sharedWith:["epayment"]},
  {email:"tebelopele.demo.client2@example.com",name:"Kagiso Molefe",surname:"Molefe",role:"client",preferredName:"Kagiso"},
  {email:"tebelopele.demo.client3@example.com",name:"Lorato Kgosi",surname:"Kgosi",role:"client",preferredName:"Lorato"},
];

function password(){return `Tb!${randomBytes(12).toString("base64url")}9a`}
async function must(promise,label){const {data,error}=await promise;if(error)throw new Error(`${label}: ${error.message}`);return data}

const capabilityRows=[...new Set(Object.values(roles).flat())].map(slug=>({slug,description:`Demo authorization capability: ${slug}`}));
await must(supabase.from("tebelopele_capabilities").upsert(capabilityRows,{onConflict:"slug"}),"capabilities");
await must(supabase.from("tebelopele_roles").upsert(Object.entries(roleNames).map(([slug,name])=>({slug,name,description:`Demonstration role for ${name.toLowerCase()}`})),{onConflict:"slug"}),"roles");
await must(supabase.from("tebelopele_skills").upsert(Object.entries(skills).map(([slug,[name,description]])=>({slug,name,description,is_active:true})),{onConflict:"slug"}),"skills");
const roleRows=await must(supabase.from("tebelopele_roles").select("id,slug").in("slug",Object.keys(roles)),"read roles");
const capRows=await must(supabase.from("tebelopele_capabilities").select("id,slug").in("slug",capabilityRows.map(x=>x.slug)),"read capabilities");
const skillRows=await must(supabase.from("tebelopele_skills").select("id,slug"),"read skills");
const roleBySlug=new Map(roleRows.map(x=>[x.slug,x.id])); const capBySlug=new Map(capRows.map(x=>[x.slug,x.id])); const skillBySlug=new Map(skillRows.map(x=>[x.slug,x.id]));
await must(supabase.from("tebelopele_role_capabilities").upsert(Object.entries(roles).flatMap(([role,caps])=>caps.map(cap=>({role_id:roleBySlug.get(role),capability_id:capBySlug.get(cap)}))),{onConflict:"role_id,capability_id"}),"role capabilities");

const allUsers=[];for(let page=1;;page++){const data=await must(supabase.auth.admin.listUsers({page,perPage:100}),"list users");allUsers.push(...data.users);if(data.users.length<100)break}
const existing=new Map(allUsers.map(u=>[u.email,u])); const credentials=[];
for(const account of accounts){
  const pass=password(); let user=existing.get(account.email);
  if(user){user=await must(supabase.auth.admin.updateUserById(user.id,{password:pass,email_confirm:true,user_metadata:{app:"tebelopele",display_name:account.name}}),`update ${account.email}`)}
  else user=await must(supabase.auth.admin.createUser({email:account.email,password:pass,email_confirm:true,user_metadata:{app:"tebelopele",display_name:account.name}}),`create ${account.email}`);
  await must(supabase.from("tebelopele_profiles").upsert({id:user.user.id,display_name:account.name,account_status:"active"},{onConflict:"id"}),`profile ${account.email}`);
  await must(supabase.from("tebelopele_user_roles").delete().eq("user_id",user.user.id),`clear roles ${account.email}`);
  await must(supabase.from("tebelopele_user_roles").insert({user_id:user.user.id,role_id:roleBySlug.get(account.role)}),`role ${account.email}`);
  if(account.role==="client"){
    await must(supabase.from("tebelopele_clients").upsert({user_id:user.user.id,preferred_name:account.preferredName},{onConflict:"user_id"}),`client ${account.email}`);
    await must(supabase.from("tebelopele_client_preferences").upsert({client_user_id:user.user.id,preferred_language:"en",preferred_channel:"in_app"},{onConflict:"client_user_id"}),`preferences ${account.email}`);
    if(account.sharedWith?.includes("epayment"))await must(supabase.from("users").upsert({id:user.user.id,email:account.email,first_name:account.preferredName,last_name:account.surname,phone_number:null,role:"customer",password_hash:""},{onConflict:"id"}),`shared ePayment membership ${account.email}`);
  }else{
    await must(supabase.from("tebelopele_staff_profiles").upsert({user_id:user.user.id,staff_number:`DEMO-${String(accounts.indexOf(account)+1).padStart(3,"0")}`,job_title:account.job,availability:"available",languages:["en"],max_active_cases:5,is_accepting_cases:account.role==="support_agent"},{onConflict:"user_id"}),`staff ${account.email}`);
    await must(supabase.from("tebelopele_staff_skills").delete().eq("staff_user_id",user.user.id),`clear skills ${account.email}`);
    if(account.skills.length)await must(supabase.from("tebelopele_staff_skills").insert(account.skills.map(slug=>({staff_user_id:user.user.id,skill_id:skillBySlug.get(slug),proficiency:"advanced",is_verified:true,verified_by:user.user.id,verified_at:new Date().toISOString()}))),`skills ${account.email}`);
  }
  credentials.push({email:account.email,password:pass,role:account.role,skills:account.skills??[]});
}
await writeFile(".test-accounts.local.json",JSON.stringify({generatedAt:new Date().toISOString(),warning:"Demonstration accounts. Rotate or remove before launch.",accounts:credentials},null,2));
console.log(JSON.stringify({createdOrUpdated:credentials.length,staff:credentials.filter(x=>x.role!=="client").length,clients:credentials.filter(x=>x.role==="client").length,credentialFile:".test-accounts.local.json"}));
