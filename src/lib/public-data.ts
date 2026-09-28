import { createClient } from "@/lib/supabase/server";

export type Service = {
  id: string;
  slug: string;
  name: string;
  summary: string;
  description: string;
  eligibility: string | null;
  preparation: string | null;
};

export type FacilityHours = { weekday: number; opens_at: string | null; closes_at: string | null; is_closed: boolean; note: string | null };
export type Facility = {
  id: string;
  slug: string;
  name: string;
  summary: string;
  address_line: string;
  city: string;
  phone: string | null;
  email: string | null;
  hours: FacilityHours[];
  services: string[];
};
export type Article = { id: string; slug: string; title: string; summary: string; body: string; category: string; publishedAt: string | null };
export type Faq = { id: string; slug: string; question: string; answer: string; category: string };
export type PublicData<T> = { items: T[]; preview: boolean; error?: string };

const previewServices: Service[] = [
  { id: "preview-service-1", slug: "hiv-testing-counselling", name: "HIV testing and counselling", summary: "Confidential support to understand your status and the next appropriate step.", description: "A preview of how Tebelopele service information will explain what the service offers, what to expect and how to reach an appropriate facility.", eligibility: "Final eligibility guidance will be confirmed by Tebelopele.", preparation: "Bring any information requested when your appointment is confirmed." },
  { id: "preview-service-2", slug: "sexual-reproductive-health", name: "Sexual and reproductive health", summary: "Clear information and confidential guidance for sexual and reproductive wellbeing.", description: "This preview demonstrates a service page. Approved service scope and client guidance will replace this text before launch.", eligibility: "Service criteria will be published after operational approval.", preparation: null },
  { id: "preview-service-3", slug: "wellness-support", name: "Wellness support", summary: "Find the right place to begin when you need information, navigation or human support.", description: "Tebelopele will publish approved pathways and available support once service owners confirm the operating model.", eligibility: null, preparation: null },
];

const previewFacilities: Facility[] = [
  { id: "preview-facility-1", slug: "gaborone-preview", name: "Gaborone service point — preview", summary: "Demonstration location content awaiting Tebelopele confirmation.", address_line: "Address to be confirmed", city: "Gaborone", phone: null, email: null, services: ["HIV testing and counselling", "Wellness support"], hours: [{ weekday: 1, opens_at: "08:00", closes_at: "17:00", is_closed: false, note: "Preview hours" }] },
  { id: "preview-facility-2", slug: "outreach-preview", name: "Community outreach — preview", summary: "A preview of how outreach and mobile service information will appear.", address_line: "Schedule and locations to be confirmed", city: "Botswana", phone: null, email: null, services: ["Sexual and reproductive health"], hours: [] },
];

const previewArticles: Article[] = [
  { id: "preview-article-1", slug: "preparing-for-a-health-visit", title: "Preparing for a health visit", summary: "A simple checklist for getting ready to speak with a health professional.", body: "Write down what you want to discuss and any questions you have. Bring information requested by the service. If you are unsure what is needed, contact the service before travelling. This demonstration content requires Tebelopele approval before publication.", category: "Using services", publishedAt: null },
  { id: "preview-article-2", slug: "confidential-support", title: "Understanding confidential support", summary: "How private conversations and access controls support safer service journeys.", body: "The platform is designed to limit access according to role and assignment. Final privacy wording and service-specific confidentiality guidance will be published after approval.", category: "Privacy and support", publishedAt: null },
  { id: "preview-article-3", slug: "when-to-request-human-help", title: "When to request human help", summary: "You can ask for a person whenever automated guidance is not enough.", body: "A future support option will allow you to ask for a human expert. Urgent and clinical escalation wording will be approved by Tebelopele professionals before the feature is activated.", category: "Getting help", publishedAt: null },
];

const previewFaqs: Faq[] = [
  { id: "preview-faq-1", slug: "who-can-use-platform", question: "Who can use the Tebelopele platform?", answer: "Public information will be available to visitors. Personal services will require a secure account and the appropriate consent.", category: "Accounts" },
  { id: "preview-faq-2", slug: "is-information-private", question: "Is my information private?", answer: "The platform uses role and assignment controls. Final privacy notices will explain exactly how each type of information is used and retained.", category: "Privacy" },
  { id: "preview-faq-3", slug: "talk-to-person", question: "Can I ask to speak to a person?", answer: "Yes. Human escalation will preserve the permitted conversation history so an assigned staff member can continue from the same context.", category: "Support" },
  { id: "preview-faq-4", slug: "emergency-service", question: "Is this an emergency service?", answer: "No. The platform must not give the impression that emergency assistance has been dispatched. Approved urgent-care wording and contacts will be added before launch.", category: "Safety" },
];

export async function getServices(): Promise<PublicData<Service>> {
  if (process.env.NODE_ENV !== "production" && process.env.TEBELOPELE_PREVIEW_MODE === "1") return { items: previewServices, preview: true };
  const supabase = await createClient();
  if (!supabase) return { items: previewServices, preview: true };
  const { data, error } = await supabase.from("tebelopele_services").select("id,slug,name,summary,description,eligibility,preparation").order("name");
  return error ? { items: [], preview: false, error: "Services could not be loaded." } : { items: (data ?? []) as Service[], preview: false };
}

export async function getService(slug: string): Promise<{ item: Service | null; preview: boolean }> {
  const all = await getServices();
  return { item: all.items.find((item) => item.slug === slug) ?? null, preview: all.preview };
}

export async function getFacilities(): Promise<PublicData<Facility>> {
  if (process.env.NODE_ENV !== "production" && process.env.TEBELOPELE_PREVIEW_MODE === "1") return { items: previewFacilities, preview: true };
  const supabase = await createClient();
  if (!supabase) return { items: previewFacilities, preview: true };
  const { data, error } = await supabase.from("tebelopele_facilities").select("id,slug,name,summary,address_line,city,phone,email").order("name");
  if (error) return { items: [], preview: false, error: "Locations could not be loaded." };
  const facilities = (data ?? []) as Omit<Facility, "hours" | "services">[];
  const ids = facilities.map((facility) => facility.id);
  if (!ids.length) return { items: [], preview: false };
  const [{ data: hours }, { data: availability }] = await Promise.all([
    supabase.from("tebelopele_facility_hours").select("facility_id,weekday,opens_at,closes_at,is_closed,note").in("facility_id", ids).order("weekday"),
    supabase.from("tebelopele_facility_services").select("facility_id,tebelopele_services(name)").in("facility_id", ids),
  ]);
  return { items: facilities.map((facility) => ({
    ...facility,
    hours: (hours ?? []).filter((row) => row.facility_id === facility.id) as FacilityHours[],
    services: (availability ?? []).filter((row) => row.facility_id === facility.id).map((row) => {
      const service = row.tebelopele_services as unknown as { name?: string } | null;
      return service?.name ?? "";
    }).filter(Boolean),
  })), preview: false };
}

export async function getArticles(): Promise<PublicData<Article>> {
  if (process.env.NODE_ENV !== "production" && process.env.TEBELOPELE_PREVIEW_MODE === "1") return { items: previewArticles, preview: true };
  const supabase = await createClient();
  if (!supabase) return { items: previewArticles, preview: true };
  const { data: articles, error } = await supabase.from("tebelopele_health_articles").select("id,slug,published_version_id,published_at,category_id").order("published_at", { ascending: false });
  if (error) return { items: [], preview: false, error: "Health information could not be loaded." };
  const versionIds = (articles ?? []).map((article) => article.published_version_id).filter(Boolean) as string[];
  const categoryIds = (articles ?? []).map((article) => article.category_id).filter(Boolean) as string[];
  const [{ data: versions }, { data: categories }] = await Promise.all([
    versionIds.length ? supabase.from("tebelopele_health_article_versions").select("id,title,summary,body").in("id", versionIds) : Promise.resolve({ data: [] }),
    categoryIds.length ? supabase.from("tebelopele_content_categories").select("id,name").in("id", categoryIds) : Promise.resolve({ data: [] }),
  ]);
  return { items: (articles ?? []).flatMap((article) => {
    const version = (versions ?? []).find((item) => item.id === article.published_version_id);
    if (!version) return [];
    return [{ id: article.id, slug: article.slug, title: version.title, summary: version.summary, body: version.body, category: (categories ?? []).find((item) => item.id === article.category_id)?.name ?? "Health information", publishedAt: article.published_at }];
  }), preview: false };
}

export async function getFaqs(): Promise<PublicData<Faq>> {
  if (process.env.NODE_ENV !== "production" && process.env.TEBELOPELE_PREVIEW_MODE === "1") return { items: previewFaqs, preview: true };
  const supabase = await createClient();
  if (!supabase) return { items: previewFaqs, preview: true };
  const { data: faqs, error } = await supabase.from("tebelopele_faqs").select("id,slug,published_version_id,category_id").order("sort_order");
  if (error) return { items: [], preview: false, error: "Frequently asked questions could not be loaded." };
  const versionIds = (faqs ?? []).map((faq) => faq.published_version_id).filter(Boolean) as string[];
  const categoryIds = (faqs ?? []).map((faq) => faq.category_id).filter(Boolean) as string[];
  const [{ data: versions }, { data: categories }] = await Promise.all([
    versionIds.length ? supabase.from("tebelopele_faq_versions").select("id,question,answer").in("id", versionIds) : Promise.resolve({ data: [] }),
    categoryIds.length ? supabase.from("tebelopele_content_categories").select("id,name").in("id", categoryIds) : Promise.resolve({ data: [] }),
  ]);
  return { items: (faqs ?? []).flatMap((faq) => {
    const version = (versions ?? []).find((item) => item.id === faq.published_version_id);
    if (!version) return [];
    return [{ id: faq.id, slug: faq.slug, question: version.question, answer: version.answer, category: (categories ?? []).find((item) => item.id === faq.category_id)?.name ?? "General" }];
  }), preview: false };
}

export async function searchPublicContent(query: string) {
  const normalized = query.trim().toLocaleLowerCase();
  if (!normalized) return { services: [], articles: [], faqs: [], preview: false };
  const [services, articles, faqs] = await Promise.all([getServices(), getArticles(), getFaqs()]);
  const includes = (...values: (string | null)[]) => values.some((value) => value?.toLocaleLowerCase().includes(normalized));
  return {
    services: services.items.filter((item) => includes(item.name, item.summary, item.description)),
    articles: articles.items.filter((item) => includes(item.title, item.summary, item.body, item.category)),
    faqs: faqs.items.filter((item) => includes(item.question, item.answer, item.category)),
    preview: services.preview || articles.preview || faqs.preview,
  };
}
