import { Clock3, Mail, MapPin, Phone } from "lucide-react";
import { EmptyState, PageIntro, PreviewNotice, PublicShell } from "@/components/public-shell";
import { getFacilities } from "@/lib/public-data";

const weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

export const metadata = { title: "Locations" };

export default async function LocationsPage() {
  const result = await getFacilities();
  return <PublicShell><main className="public-page"><PageIntro title="Locations and service points"><p>Check where services are offered, when a location is open and how to contact it.</p></PageIntro>{result.preview && <PreviewNotice/>}{result.error && <div className="alert alert--error">{result.error}</div>}{result.items.length ? <div className="location-list">{result.items.map((facility) => <article key={facility.id}><div className="location-main"><p className="welcome-line"><MapPin size={17}/> {facility.city}</p><h2>{facility.name}</h2><p>{facility.summary}</p><address>{facility.address_line}</address><div className="contact-row">{facility.phone && <a href={`tel:${facility.phone}`}><Phone size={17}/>{facility.phone}</a>}{facility.email && <a href={`mailto:${facility.email}`}><Mail size={17}/>{facility.email}</a>}</div></div><div className="location-detail"><h3><Clock3 size={18}/>Opening information</h3>{facility.hours.length ? <ul>{facility.hours.map((hours) => <li key={hours.weekday}><strong>{weekdays[hours.weekday]}</strong><span>{hours.is_closed ? "Closed" : `${hours.opens_at?.slice(0,5)}–${hours.closes_at?.slice(0,5)}`}</span>{hours.note && <small>{hours.note}</small>}</li>)}</ul> : <p>Contact this service point to confirm availability.</p>}<h3>Available services</h3>{facility.services.length ? <ul className="plain-list">{facility.services.map((service) => <li key={service}>{service}</li>)}</ul> : <p>Service availability will be published after approval.</p>}</div></article>)}</div> : <EmptyState title="No locations are published yet">Confirmed facilities and outreach points will appear here.</EmptyState>}</main></PublicShell>;
}
