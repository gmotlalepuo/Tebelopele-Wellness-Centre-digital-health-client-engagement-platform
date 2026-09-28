import Link from "next/link";
import { ArrowRight, Search } from "lucide-react";
import { EmptyState, PageIntro, PreviewNotice, PublicShell } from "@/components/public-shell";
import { getServices } from "@/lib/public-data";

export const metadata = { title: "Services" };

export default async function ServicesPage() {
  const result = await getServices();
  return <PublicShell><main className="public-page">
    <PageIntro title="Find a service"><p>Browse available support and learn what to expect before taking the next step.</p><form action="/search" className="inline-search" role="search"><label htmlFor="service-search" className="sr-only">Search services</label><input id="service-search" name="q" type="search" placeholder="What are you looking for?"/><button className="button button--primary"><Search size={18}/>Search</button></form></PageIntro>
    {result.preview && <PreviewNotice/>}
    {result.error && <div className="alert alert--error" role="alert">{result.error}</div>}
    {result.items.length ? <div className="directory-list">{result.items.map((service, index) => <article key={service.id}><span>{String(index + 1).padStart(2, "0")}</span><div><h2>{service.name}</h2><p>{service.summary}</p></div><Link href={`/services/${service.slug}`}>View service <ArrowRight size={18}/></Link></article>)}</div> : <EmptyState title="No services are published yet">Approved Tebelopele services will appear here when they are ready.</EmptyState>}
  </main></PublicShell>;
}
