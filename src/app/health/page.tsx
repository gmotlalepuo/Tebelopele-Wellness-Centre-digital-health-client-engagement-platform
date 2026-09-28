import Link from "next/link";
import { ArrowRight, BookOpenCheck } from "lucide-react";
import { EmptyState, PageIntro, PreviewNotice, PublicShell } from "@/components/public-shell";
import { getArticles } from "@/lib/public-data";

export const metadata = { title: "Health information" };

export default async function HealthPage() {
  const result = await getArticles();
  return <PublicShell><main className="public-page"><PageIntro title="Health information"><p>Read clear guidance from Tebelopele-approved sources. Published articles will show where their information comes from.</p></PageIntro>{result.preview && <PreviewNotice/>}{result.error && <div className="alert alert--error">{result.error}</div>}{result.items.length ? <div className="article-index">{result.items.map((article) => <article key={article.id}><BookOpenCheck aria-hidden="true"/><div><span>{article.category}</span><h2>{article.title}</h2><p>{article.summary}</p><Link href={`/health/${article.slug}`}>Read article <ArrowRight size={18}/></Link></div></article>)}</div> : <EmptyState title="No health articles are published yet">Only reviewed and approved information will be displayed.</EmptyState>}</main></PublicShell>;
}
