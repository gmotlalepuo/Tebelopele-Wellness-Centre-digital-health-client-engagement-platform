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
