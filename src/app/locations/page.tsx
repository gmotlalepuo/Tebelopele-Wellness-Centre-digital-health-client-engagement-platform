import { Clock3, Mail, MapPin, Phone, Search } from "lucide-react";
import { EmptyState, PageIntro, PreviewNotice, PublicShell } from "@/components/public-shell";
import { getFacilities } from "@/lib/public-data";

const weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

export const metadata = { title: "Find a facility" };

export default async function LocationsPage({ searchParams }: { searchParams: Promise<Record<string, string | undefined>> }) {
  const [result, params] = await Promise.all([getFacilities(), searchParams]);
  const query = (params.q ?? "").trim().toLocaleLowerCase();
  const selectedService = params.service ?? "";
  const selectedCity = params.city ?? "";
  const cities = [...new Set(result.items.map((facility) => facility.city))].sort();
  const services = [...new Set(result.items.flatMap((facility) => facility.services))].sort();
  const filtered = result.items.filter((facility) => {
    const matchesQuery = !query || [facility.name, facility.city, facility.summary, facility.address_line, ...facility.services].some((value) => value.toLocaleLowerCase().includes(query));
    return matchesQuery && (!selectedCity || facility.city === selectedCity) && (!selectedService || facility.services.includes(selectedService));
  });

  return <PublicShell><main className="public-page facility-finder"><PageIntro title="Find a Tebelopele facility"><p>Search by town or service, then check contact details and opening information before you travel.</p></PageIntro>
    {result.preview && <PreviewNotice/>}{result.error && <div className="alert alert--error">{result.error}</div>}
    <form className="facility-search" method="get" role="search">
      <label className="facility-search__query"><span>Search facilities</span><div><Search size={18}/><input name="q" type="search" defaultValue={params.q} placeholder="Facility, town or service"/></div></label>
      <label><span>Town</span><select name="city" defaultValue={selectedCity}><option value="">All towns</option>{cities.map((city) => <option value={city} key={city}>{city}</option>)}</select></label>
      <label><span>Service</span><select name="service" defaultValue={selectedService}><option value="">All services</option>{services.map((service) => <option value={service} key={service}>{service}</option>)}</select></label>
      <button className="button button--primary" type="submit">Find facilities</button>
      {(query || selectedCity || selectedService) && <a className="text-link" href="/locations">Clear search</a>}
    </form>
    <div className="facility-results-heading" aria-live="polite"><div><strong>{filtered.length} {filtered.length === 1 ? "facility" : "facilities"}</strong><span>{query || selectedCity || selectedService ? " match your search" : " currently published"}</span></div><small>Always confirm availability before travelling.</small></div>
    {filtered.length ? <div className="location-list">{filtered.map((facility) => <article key={facility.id}><div className="location-main"><p className="welcome-line"><MapPin size={17}/> {facility.city}</p><h2>{facility.name}</h2><p>{facility.summary}</p><address>{facility.address_line}</address><div className="contact-row">{facility.phone && <a href={`tel:${facility.phone.replaceAll(" ", "")}`}><Phone size={17}/>{facility.phone}</a>}{facility.email && <a href={`mailto:${facility.email}`}><Mail size={17}/>{facility.email}</a>}{!facility.phone && !facility.email && <span>Contact information is being confirmed.</span>}</div></div><div className="location-detail"><h3><Clock3 size={18}/>Opening information</h3>{facility.hours.length ? <ul>{facility.hours.map((hours) => <li key={hours.weekday}><strong>{weekdays[hours.weekday]}</strong><span>{hours.is_closed ? "Closed" : `${hours.opens_at?.slice(0,5)}–${hours.closes_at?.slice(0,5)}`}</span>{hours.note && <small>{hours.note}</small>}</li>)}</ul> : <p>Contact this service point to confirm its current opening hours.</p>}<h3>Available services</h3>{facility.services.length ? <ul className="plain-list">{facility.services.map((service) => <li key={service}>{service}</li>)}</ul> : <p>Service availability is being confirmed.</p>}</div></article>)}</div> : <EmptyState title="No facilities match your search">Try another town, service or search term.</EmptyState>}
  </main></PublicShell>;
}
