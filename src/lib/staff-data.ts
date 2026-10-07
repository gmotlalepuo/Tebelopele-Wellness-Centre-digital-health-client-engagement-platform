import "server-only";
import {createClient} from "@/lib/supabase/server";
import {isPreview} from "@/lib/appointment-data";

export async function requireCapability(capability:string){
  if(isPreview()) return null;
  const s=await createClient();
  if(!s) return null;
  const {data}=await s.rpc("tebelopele_my_capabilities");
  if(!Array.isArray(data)||!data.includes(capability)) return null;
  return s;
}

export async function getOperationalMetrics(){
  const preview=isPreview();
  if(preview)return {configured:false,appointments:0,openSupport:0,activeReferrals:0,reviewItems:0};
  const s=await createClient(); if(!s)return {configured:false,appointments:0,openSupport:0,activeReferrals:0,reviewItems:0};
  const start=new Date(); start.setHours(0,0,0,0); const end=new Date(start); end.setDate(end.getDate()+1);
  const [a,support,referrals,reviews]=await Promise.all([
    s.from("tebelopele_appointments").select("id",{count:"exact",head:true}).gte("starts_at",start.toISOString()).lt("starts_at",end.toISOString()),
    s.from("tebelopele_support_cases").select("id",{count:"exact",head:true}).in("status",["open","assigned","waiting_user"]),
    s.from("tebelopele_referrals").select("id",{count:"exact",head:true}).in("status",["pending","accepted","scheduled"]),
    s.from("tebelopele_health_articles").select("id",{count:"exact",head:true}).eq("status","in_review")]);
  return {configured:true,appointments:a.count??0,openSupport:support.count??0,activeReferrals:referrals.count??0,reviewItems:reviews.count??0};
}

const reportingDateFormatter=new Intl.DateTimeFormat("en-CA",{timeZone:"Africa/Gaborone",year:"numeric",month:"2-digit",day:"2-digit"});
const reportingDayFormatter=new Intl.DateTimeFormat("en-BW",{timeZone:"Africa/Gaborone",weekday:"short"});

export async function getReportingDashboard(){
  if(isPreview())return {configured:false,trend:[],support:[],referrals:[],appointmentStatuses:[]};
  const s=await createClient();
  if(!s)return {configured:false,trend:[],support:[],referrals:[],appointmentStatuses:[]};

  const todayKey=reportingDateFormatter.format(new Date());
  const todayStart=new Date(`${todayKey}T00:00:00+02:00`);
  const rangeStart=new Date(todayStart); rangeStart.setUTCDate(rangeStart.getUTCDate()-6);
  const rangeEnd=new Date(todayStart); rangeEnd.setUTCDate(rangeEnd.getUTCDate()+1);
  const [appointments,support,referrals,reviews]=await Promise.all([
    s.from("tebelopele_appointments").select("starts_at,status").gte("starts_at",rangeStart.toISOString()).lt("starts_at",rangeEnd.toISOString()),
    s.from("tebelopele_support_cases").select("status").in("status",["open","assigned","waiting_user"]),
    s.from("tebelopele_referrals").select("status").in("status",["pending","accepted","scheduled"]),
    s.from("tebelopele_health_articles").select("id").eq("status","in_review")
  ]);
  const appointmentRows=appointments.data??[];
  const trend=Array.from({length:7},(_,index)=>{
    const date=new Date(rangeStart); date.setUTCDate(date.getUTCDate()+index);
    const key=reportingDateFormatter.format(date);
    return {key,label:reportingDayFormatter.format(date),value:appointmentRows.filter(row=>reportingDateFormatter.format(new Date(row.starts_at))===key).length};
  });
  const countStatuses=(rows:{status:string}[],statuses:string[])=>statuses.map(status=>({label:status.replace("_"," "),value:rows.filter(row=>row.status===status).length}));
  const appointmentStatusOrder=["scheduled","confirmed","completed","cancelled","no_show"];
  const appointmentStatuses=[...new Set(appointmentRows.map(row=>row.status))].sort((a,b)=>{
    const aIndex=appointmentStatusOrder.indexOf(a); const bIndex=appointmentStatusOrder.indexOf(b);
    return (aIndex<0?appointmentStatusOrder.length:aIndex)-(bIndex<0?appointmentStatusOrder.length:bIndex)||a.localeCompare(b);
  });
  return {
    configured:true,
    trend,
    support:countStatuses(support.data??[],["open","assigned","waiting_user"]),
    referrals:countStatuses(referrals.data??[],["pending","accepted","scheduled"]),
    appointmentStatuses:countStatuses(appointmentRows,appointmentStatuses),
    reviewItems:reviews.data?.length??0
  };
}
