import { ArrowRight, Clock3, HeartHandshake, Languages, MessageSquareText, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { requestHumanSupport } from "@/app/client/support-actions";

const topics = [
  { value: "general_navigation", title: "Finding the right service", detail: "Help choosing a service, facility or next step." },
  { value: "appointment_support", title: "Appointment support", detail: "Help booking, changing or preparing for a visit." },
  { value: "content_guidance", title: "Health information and counselling", detail: "A person to explain approved information or discuss support options." },
  { value: "referral_navigation", title: "Referral navigation", detail: "Help understanding or following an existing referral journey." },
  { value: "technical_support", title: "Using this platform", detail: "Help with your account or a feature that is not working." },
] as const;

export default async function ClientSupportPage({ searchParams }: { searchParams: Promise<Record<string, string | undefined>> }) {
  const params = await searchParams;
  return <div className="portal-page form-page support-request-page">
    <div className="portal-heading"><div><p className="welcome-line">Human assistance</p><h1>Find a person to speak to</h1><p>Tell us what you need so we can route your request to a suitable Tebelopele team member.</p></div><span className="status-label"><ShieldCheck size={16}/> Transcript protected</span></div>
    {params.requested && <div className="support-confirmation" role="status"><HeartHandshake/><div><strong>Your support request is in the queue</strong><p>An eligible team member can review your message and continue in the same transcript.</p><Link href="/client/chat">Open your conversation <ArrowRight size={15}/></Link></div></div>}
    {params.error && <p className="alert alert--error" role="alert">We could not submit that request. Check the form and try again, or use the published facility contact details.</p>}
    <div className="support-form-layout">
      <form action={requestHumanSupport} className="settings-form support-request-form">
        <fieldset>
          <legend>What would you like help with?</legend>
          <div className="support-topic-list">{topics.map((topic, index) => <label key={topic.value}><input type="radio" name="topic" value={topic.value} required defaultChecked={index === 0}/><span><strong>{topic.title}</strong><small>{topic.detail}</small></span></label>)}</div>
          <div className="field-grid support-details">
            <label><span><Languages size={16}/> Preferred language</span><select name="language" defaultValue="en"><option value="en">English</option><option value="tn">Setswana</option></select></label>
            <label className="field-span"><span><MessageSquareText size={16}/> What should the team know?</span><textarea name="message" rows={5} minLength={10} maxLength={1500} required placeholder="Briefly describe the help you need. Do not include passwords or emergency information."/><small>10–1,500 characters. Your message becomes part of the protected support transcript.</small></label>
          </div>
          <div className="form-actions"><button className="button button--primary" type="submit">Request human support <ArrowRight size={17}/></button></div>
        </fieldset>
      </form>
      <aside className="support-expectations"><h2>What happens next</h2><ol><li><span>1</span><div><strong>We match the skill</strong><p>Your topic and language determine which available staff can see the request.</p></div></li><li><span>2</span><div><strong>A staff member accepts</strong><p>Automated replies pause when a qualified person takes control.</p></div></li><li><span>3</span><div><strong>The conversation continues</strong><p>You do not need to repeat information already included in the transcript.</p></div></li></ol><p className="support-hours"><Clock3 size={17}/><span><strong>Not an emergency channel</strong> If someone is in immediate danger, contact Botswana emergency services or visit the nearest emergency facility.</span></p></aside>
    </div>
  </div>;
}
