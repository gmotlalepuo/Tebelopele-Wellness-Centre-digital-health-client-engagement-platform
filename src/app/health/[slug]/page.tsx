import Link from "next/link";
import { ArrowLeft, ShieldCheck } from "lucide-react";
import { notFound } from "next/navigation";
import { PreviewNotice, PublicShell } from "@/components/public-shell";
import { getArticles } from "@/lib/public-data";

export default async function ArticlePage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const result = await getArticles();
  const article = result.items.find((item) => item.slug === slug);
  if (!article) notFound();
  return <PublicShell><main className="reading-page"><Link href="/health" className="back-link"><ArrowLeft size={18}/> Health information</Link>{result.preview && <PreviewNotice/>}<article><span>{article.category}</span><h1>{article.title}</h1><p className="detail-lead">{article.summary}</p><div className="source-status"><ShieldCheck/> {result.preview ? "Preview content — not approved for production use" : "Published Tebelopele information"}</div><div className="prose">{article.body.split(/\n\n+/).map((paragraph) => <p key={paragraph}>{paragraph}</p>)}</div></article></main></PublicShell>;
}
