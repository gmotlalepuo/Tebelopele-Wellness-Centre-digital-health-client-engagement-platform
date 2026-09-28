import Link from "next/link";
import { ArrowLeft, CalendarDays, CircleCheck, MapPin } from "lucide-react";
import { notFound } from "next/navigation";
import { PreviewNotice, PublicShell } from "@/components/public-shell";
import { getService } from "@/lib/public-data";

export default async function ServiceDetailPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const result = await getService(slug);
  if (!result.item) notFound();
  const service = result.item;
  return <PublicShell><main className="detail-page">
    <Link href="/services" className="back-link"><ArrowLeft size={18}/> All services</Link>
    {result.preview && <PreviewNotice/>}
    <div className="detail-layout"><article><p className="welcome-line">Tebelopele service</p><h1>{service.name}</h1><p className="detail-lead">{service.summary}</p><div className="prose"><h2>About this service</h2><p>{service.description}</p>{service.eligibility && <><h2>Who it may help</h2><p>{service.eligibility}</p></>}{service.preparation && <><h2>Before your visit</h2><p>{service.preparation}</p></>}</div></article><aside className="next-step-panel"><h2>Choose your next step</h2><Link href="/locations"><MapPin/>Find a location</Link><Link href="/sign-in"><CalendarDays/>Sign in for client services</Link><p><CircleCheck/> Published service information will always show its approved status and source.</p></aside></div>
  </main></PublicShell>;
}
