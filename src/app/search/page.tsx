import Link from "next/link";
import { ArrowRight, Search } from "lucide-react";
import { PageIntro, PreviewNotice, PublicShell } from "@/components/public-shell";
import { searchPublicContent } from "@/lib/public-data";

export const metadata = { title: "Search" };

export default async function SearchPage({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const query = (await searchParams).q?.trim() ?? "";
  const result = await searchPublicContent(query);
  const total = result.services.length + result.articles.length + result.faqs.length;
  return <PublicShell><main className="public-page"><PageIntro title="Search Tebelopele"><form action="/search" className="inline-search" role="search"><label htmlFor="site-search" className="sr-only">Search Tebelopele</label><input id="site-search" name="q" defaultValue={query} type="search" placeholder="Search services and information"/><button className="button button--primary"><Search size={18}/>Search</button></form></PageIntro>{result.preview && query && <PreviewNotice/>}{query && <p className="result-count" role="status">{total} {total === 1 ? "result" : "results"} for “{query}”</p>}{query && !total && <div className="empty-state"><h2>Nothing matched that search</h2><p>Try a shorter phrase, browse <Link href="/services">services</Link>, or review the <Link href="/faqs">frequently asked questions</Link>.</p></div>}<div className="search-results">{result.services.map((item) => <article key={item.id}><span>Service</span><h2>{item.name}</h2><p>{item.summary}</p><Link href={`/services/${item.slug}`}>View service <ArrowRight size={17}/></Link></article>)}{result.articles.map((item) => <article key={item.id}><span>Health information</span><h2>{item.title}</h2><p>{item.summary}</p><Link href={`/health/${item.slug}`}>Read article <ArrowRight size={17}/></Link></article>)}{result.faqs.map((item) => <article key={item.id}><span>FAQ</span><h2>{item.question}</h2><p>{item.answer}</p><Link href="/faqs">View FAQs <ArrowRight size={17}/></Link></article>)}</div></main></PublicShell>;
}
