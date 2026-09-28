import {NextResponse} from "next/server";
import {createAdminClient} from "@/lib/supabase/admin";
import {resolveMenu,validWebhookSignature,whatsappEventSchema} from "@/lib/whatsapp";

export async function GET(request:Request){const url=new URL(request.url),token=process.env.WHATSAPP_VERIFY_TOKEN;if(token&&url.searchParams.get("hub.verify_token")===token)return new NextResponse(url.searchParams.get("hub.challenge")??"");return NextResponse.json({error:"verification_failed"},{status:403})}

export async function POST(request:Request){
 const secret=process.env.WHATSAPP_WEBHOOK_SECRET;if(!secret)return NextResponse.json({error:"provider_not_configured"},{status:503});
 const raw=await request.text();if(!validWebhookSignature(raw,request.headers.get("x-whatsapp-signature"),secret))return NextResponse.json({error:"invalid_signature"},{status:401});
 let payload:unknown;try{payload=JSON.parse(raw)}catch{return NextResponse.json({error:"invalid_json"},{status:400})}
 const parsed=whatsappEventSchema.safeParse(payload);if(!parsed.success)return NextResponse.json({error:"invalid_event"},{status:400});
 const s=createAdminClient();if(!s)return NextResponse.json({error:"storage_unavailable"},{status:503});const event=parsed.data;
 const {error:eventError}=await s.from("tebelopele_whatsapp_provider_events").insert({provider:process.env.WHATSAPP_PROVIDER??"unconfigured",provider_event_id:event.event_id,event_type:event.event_type,signature_valid:true,payload:event});
 if(eventError?.code==="23505")return NextResponse.json({accepted:true,duplicate:true});if(eventError)return NextResponse.json({error:"event_persistence_failed"},{status:500});
 if(event.event_type==="delivery"){await s.from("tebelopele_message_deliveries").update({status:event.delivery?.status}).eq("provider_message_id",event.provider_message_id);await markProcessed(s,event.event_id);return NextResponse.json({accepted:true})}
 let {data:identity}=await s.from("tebelopele_channel_identities").select("id,verification_level").eq("channel","whatsapp").eq("external_id",event.sender_id).maybeSingle();
 if(!identity){const {data}=await s.from("tebelopele_channel_identities").insert({channel:"whatsapp",external_id:event.sender_id}).select("id,verification_level").single();identity=data}if(!identity)return NextResponse.json({error:"identity_failed"},{status:500});
 let {data:state}=await s.from("tebelopele_whatsapp_flow_states").select("conversation_id,flow_version_id,current_node").eq("identity_id",identity.id).maybeSingle();
 if(!state){const [{data:conversation},{data:flow}]=await Promise.all([s.from("tebelopele_conversations").insert({channel:"whatsapp",locale:"en"}).select("id").single(),s.from("tebelopele_whatsapp_flow_versions").select("id").eq("status","published").order("version_number",{ascending:false}).limit(1).single()]);if(!conversation||!flow)return NextResponse.json({error:"flow_unavailable"},{status:503});const {data}=await s.from("tebelopele_whatsapp_flow_states").insert({identity_id:identity.id,conversation_id:conversation.id,flow_version_id:flow.id,current_node:"main_menu",expires_at:new Date(Date.now()+86400000).toISOString()}).select("conversation_id,flow_version_id,current_node").single();state=data}if(!state)return NextResponse.json({error:"state_failed"},{status:500});
 const {data:conversation}=await s.from("tebelopele_conversations").select("control_state").eq("id",state.conversation_id).single();const inbound=event.message?.option_id??event.message?.text??"Unsupported message";
 await s.from("tebelopele_messages").insert({conversation_id:state.conversation_id,sender_type:"client",message_type:event.message?.type==="option"?"menu":"text",body:inbound,provider_message_id:event.provider_message_id});
 if(conversation?.control_state==="human_active"){await markProcessed(s,event.event_id);return NextResponse.json({accepted:true,routed:"human"})}
 const response=resolveMenu(inbound);const {data:outbound}=await s.from("tebelopele_messages").insert({conversation_id:state.conversation_id,sender_type:"menu",message_type:"menu",body:response.text,source_label:"menu",citations:[]}).select("id").single();
 if(outbound)await s.from("tebelopele_message_deliveries").insert({message_id:outbound.id,channel:"whatsapp",provider:process.env.WHATSAPP_PROVIDER??"unconfigured"});
 await s.from("tebelopele_whatsapp_flow_states").update({current_node:response.node,selected_option_id:inbound,expires_at:new Date(Date.now()+86400000).toISOString()}).eq("identity_id",identity.id);
 if(response.node==="human_handoff"){await s.from("tebelopele_conversations").update({control_state:"human_pending"}).eq("id",state.conversation_id);const {data:skill}=await s.from("tebelopele_skills").select("id").eq("slug","general_navigation").maybeSingle();const {data:existing}=await s.from("tebelopele_support_cases").select("id").eq("conversation_id",state.conversation_id).in("status",["open","assigned","waiting_user"]).maybeSingle();if(!existing)await s.from("tebelopele_support_cases").insert({conversation_id:state.conversation_id,required_skill_id:skill?.id??null,reason_code:"whatsapp_client_request",language:"en",due_at:new Date(Date.now()+14400000).toISOString()})}
 await markProcessed(s,event.event_id);return NextResponse.json({accepted:true,reply:{...response,fallback:[response.text,...response.options.map((o,i)=>`${i+1}. ${o.label}`)].join("\n")}})
}

async function markProcessed(s:NonNullable<ReturnType<typeof createAdminClient>>,eventId:string){await s.from("tebelopele_whatsapp_provider_events").update({processing_status:"processed",processed_at:new Date().toISOString()}).eq("provider_event_id",eventId)}
