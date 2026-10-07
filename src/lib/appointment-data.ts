import { createClient } from "@/lib/supabase/server";

export type AppointmentRow = { id:string; starts_at:string; ends_at:string; status:string; visit_reason:string|null; service:{id:string;name:string}|null; facility:{name:string}|null };
export type SlotRow = { id:string; starts_at:string; ends_at:string; capacity:number; service:{id:string;name:string;summary:string}|null; facility:{id:string;name:string;city:string}|null };

const previewAppointments: AppointmentRow[] = [{ id:"preview-appointment", starts_at:"2026-10-06T08:30:00+02:00", ends_at:"2026-10-06T09:00:00+02:00", status:"confirmed", visit_reason:"Wellness consultation", service:{id:"preview-service",name:"Wellness screening"}, facility:{name:"Tebelopele Gaborone Centre"} }];
const previewSlots: SlotRow[] = [
 {id:"preview-slot-1",starts_at:"2026-10-08T08:30:00+02:00",ends_at:"2026-10-08T09:00:00+02:00",capacity:1,service:{id:"preview-service",name:"Wellness screening",summary:"A confidential wellness check and guidance on next steps."},facility:{id:"preview-facility",name:"Tebelopele Gaborone Centre",city:"Gaborone"}},
 {id:"preview-slot-2",starts_at:"2026-10-09T10:00:00+02:00",ends_at:"2026-10-09T10:30:00+02:00",capacity:2,service:{id:"preview-service-2",name:"HIV testing and counselling",summary:"Confidential testing, counselling and linkage support."},facility:{id:"preview-facility",name:"Tebelopele Gaborone Centre",city:"Gaborone"}},
];
export const isPreview = () => process.env.NODE_ENV !== "production" && process.env.TEBELOPELE_PREVIEW_MODE === "1";

export async function getAppointments(): Promise<{configured:boolean;items:AppointmentRow[]}> {
 if(isPreview()) return {configured:false,items:previewAppointments};
 const supabase=await createClient(); if(!supabase) return {configured:false,items:[]};
 const {data}=await supabase.from("tebelopele_appointments").select("id,starts_at,ends_at,status,visit_reason,service:tebelopele_services(id,name),facility:tebelopele_facilities(name)").order("starts_at");
 return {configured:true,items:(data??[]) as unknown as AppointmentRow[]};
}
export async function getOpenSlots(): Promise<{configured:boolean;items:SlotRow[]}> {
 if(isPreview()) return {configured:false,items:previewSlots};
 const supabase=await createClient(); if(!supabase) return {configured:false,items:[]};
 const {data}=await supabase.from("tebelopele_appointment_slots").select("id,starts_at,ends_at,capacity,service:tebelopele_services(id,name,summary),facility:tebelopele_facilities(id,name,city)").eq("status","open").gt("starts_at",new Date().toISOString()).order("starts_at");
 return {configured:true,items:(data??[]) as unknown as SlotRow[]};
}

