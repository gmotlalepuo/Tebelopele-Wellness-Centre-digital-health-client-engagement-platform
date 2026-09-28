import { HelpCircle } from "lucide-react";
import { EmptyState, PageIntro, PreviewNotice, PublicShell } from "@/components/public-shell";
import { getFaqs } from "@/lib/public-data";

export const metadata = { title: "Frequently asked questions" };

export default async function FaqPage() {
  const result = await getFaqs();
  return <PublicShell><main className="public-page"><PageIntro title="Frequently asked questions"><p>Quick answers about using Tebelopele’s digital services, privacy and support.</p></PageIntro>{result.preview && <PreviewNotice/>}{result.error && <div className="alert alert--error">{result.error}</div>}{result.items.length ? <div className="faq-list">{result.items.map((faq) => <details key={faq.id}><summary><HelpCircle size={20}/><span>{faq.question}<small>{faq.category}</small></span></summary><p>{faq.answer}</p></details>)}</div> : <EmptyState title="No FAQs are published yet">Approved answers will appear here.</EmptyState>}</main></PublicShell>;
}
