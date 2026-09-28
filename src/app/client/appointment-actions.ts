"use server";
import { redirect } from "next/navigation";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const uuid=z.uuid();
export async function bookAppointment(formData:FormData){
 const slot=uuid.safeParse(formData.get("slot_id")); const reason=z.string().trim().max(500).safeParse(formData.get("visit_reason")??"");
 if(!slot.success||!reason.success) redirect("/client/appointments/new?error=validation");
 const supabase=await createClient(); if(!supabase) redirect("/client/appointments/new?error=setup");
 const {error}=await supabase.rpc("tebelopele_book_appointment",{requested_slot_id:slot.data,requested_reason:reason.data||null});
 if(error) redirect(`/client/appointments/new?error=${error.message.includes("full")?"full":"save"}`);
 redirect("/client/appointments?booked=1");
}
export async function cancelAppointment(formData:FormData){
 const id=uuid.safeParse(formData.get("appointment_id")); if(!id.success) redirect("/client/appointments?error=validation");
 const supabase=await createClient(); if(!supabase) redirect("/client/appointments?error=setup");
 const {error}=await supabase.rpc("tebelopele_cancel_appointment",{target_appointment_id:id.data,cancellation_reason:String(formData.get("reason")??"")});
 if(error) redirect("/client/appointments?error=cancel"); redirect("/client/appointments?cancelled=1");
}
export async function rescheduleAppointment(formData:FormData){const p=z.object({appointmentId:z.uuid(),slotId:z.uuid()}).safeParse({appointmentId:formData.get("appointment_id"),slotId:formData.get("slot_id")});if(!p.success)redirect("/client/appointments?error=validation");const s=await createClient();if(!s)redirect("/client/appointments?error=setup");const {error}=await s.rpc("tebelopele_reschedule_appointment",{target_appointment_id:p.data.appointmentId,requested_slot_id:p.data.slotId});if(error)redirect("/client/appointments?error=reschedule");redirect("/client/appointments?rescheduled=1")}

