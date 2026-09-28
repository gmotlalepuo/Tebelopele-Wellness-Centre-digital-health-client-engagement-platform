import "server-only";
import {createAdminClient} from "@/lib/supabase/admin";

export type ApplicationMembership={id:"tebelopele"|"epayment"|"jobs";name:string;description:string;href:string};
export async function getApplicationMemberships(userId:string){const admin=createAdminClient();if(!admin)return [];
  const [tebelopele,epayment,jobs]=await Promise.all([
    admin.from("tebelopele_profiles").select("id").eq("id",userId).maybeSingle(),
    admin.from("users").select("id").eq("id",userId).maybeSingle(),
    admin.from("job_profiles").select("id").eq("id",userId).maybeSingle(),
  ]);
  const apps:ApplicationMembership[]=[];
  if(tebelopele.data)apps.push({id:"tebelopele",name:"Tebelopele Digital Health",description:"Health information, appointments, support and referrals",href:"/"});
  if(epayment.data)apps.push({id:"epayment",name:"ePayment",description:"Payments and transaction services",href:process.env.TEBELOPELE_EPAYMENT_URL??"#unconfigured"});
  if(jobs.data)apps.push({id:"jobs",name:"Bermuda Jobs",description:"Recruitment and employment services",href:process.env.TEBELOPELE_JOBS_URL??"#unconfigured"});
  return apps;
}
