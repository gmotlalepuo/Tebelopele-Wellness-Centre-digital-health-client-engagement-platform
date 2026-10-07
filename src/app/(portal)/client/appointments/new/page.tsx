import Link from "next/link";
import { ArrowLeft, CalendarDays, Clock, MapPin, Search } from "lucide-react";
import { getOpenSlots } from "@/lib/appointment-data";
import { bookAppointment } from "@/app/client/appointment-actions";

const formatDay = new Intl.DateTimeFormat("en-BW", { weekday: "long", day: "numeric", month: "long" });
const formatTime = new Intl.DateTimeFormat("en-BW", { hour: "2-digit", minute: "2-digit" });

export default async function NewAppointmentPage({ searchParams }: { searchParams: Promise<Record<string, string | undefined>> }) {
  const [{ configured, items }, params] = await Promise.all([getOpenSlots(), searchParams]);
  const services = [...new Map(items.flatMap((slot) => slot.service ? [[slot.service.id, slot.service] as const] : [])).values()];
  const facilities = [...new Map(items.flatMap((slot) => slot.facility ? [[slot.facility.id, slot.facility] as const] : [])).values()];
  const dates = [...new Set(items.map((slot) => slot.starts_at.slice(0, 10)))];
  const selectedService = params.service ?? "";
  const selectedFacility = params.facility ?? "";
  const selectedDate = params.date ?? dates[0] ?? "";
  const filtered = items.filter((slot) =>
    (!selectedService || slot.service?.id === selectedService) &&
    (!selectedFacility || slot.facility?.id === selectedFacility) &&
    (!selectedDate || slot.starts_at.slice(0, 10) === selectedDate)
  );
  const displayed = filtered.slice(0, 30);

  return <div className="portal-page appointment-booking-page">
    <Link className="back-link" href="/client/appointments"><ArrowLeft size={16}/>Appointments</Link>
    <div className="portal-heading"><div><p className="welcome-line">New booking</p><h1>Schedule an appointment</h1><p>Choose the service and location that suit you, then reserve an available Botswana-time appointment.</p></div><span className="status-label"><CalendarDays size={16}/>{dates.length} days with availability</span></div>
    {!configured && <div className="preview-notice"><strong>Preview only</strong><span>Connect the project database to create a booking.</span></div>}
    {params.error && <p className="alert alert--error" role="alert">{params.error === "full" ? "That time was just taken. Please choose another appointment." : "We could not reserve that appointment. Review your selection and try again."}</p>}

    <form className="appointment-filters" method="get">
      <label><span>Service</span><select name="service" defaultValue={selectedService}><option value="">All services</option>{services.map((service) => <option key={service.id} value={service.id}>{service.name}</option>)}</select></label>
      <label><span>Facility</span><select name="facility" defaultValue={selectedFacility}><option value="">All facilities</option>{facilities.map((facility) => <option key={facility.id} value={facility.id}>{facility.name}</option>)}</select></label>
      <label><span>Date</span><select name="date" defaultValue={selectedDate}><option value="">Any available date</option>{dates.map((date) => <option key={date} value={date}>{formatDay.format(new Date(`${date}T12:00:00+02:00`))}</option>)}</select></label>
      <button className="button button--quiet" type="submit"><Search size={17}/>Show times</button>
      {(selectedService || selectedFacility || selectedDate) && <Link className="text-link appointment-filter-reset" href="/client/appointments/new">Clear filters</Link>}
    </form>

    <form action={bookAppointment} className="settings-form appointment-selection">
      <fieldset disabled={!configured || !filtered.length}>
        <legend>{filtered.length ? `Choose from ${filtered.length} available ${filtered.length === 1 ? "time" : "times"}` : "No matching times"}</legend>
        {filtered.length > displayed.length && <p className="result-guidance">Showing the first {displayed.length} times. Choose a service or facility to narrow the list.</p>}
        {displayed.length ? <div className="slot-list slot-list--detailed">{displayed.map((slot, index) => <label key={slot.id}>
          <input type="radio" name="slot_id" value={slot.id} required defaultChecked={index === 0}/>
          <span className="slot-date"><strong>{formatDay.format(new Date(slot.starts_at))}</strong><small><Clock size={14}/>{formatTime.format(new Date(slot.starts_at))}–{formatTime.format(new Date(slot.ends_at))}</small></span>
          <span className="slot-service"><strong>{slot.service?.name}</strong><small>{slot.service?.summary}</small><small><MapPin size={14}/>{slot.facility?.name}, {slot.facility?.city}</small></span>
        </label>)}</div> : <div className="inline-empty"><CalendarDays/><div><strong>No appointments match those filters</strong><p>Clear one or more filters, or check again when more availability is published.</p></div></div>}
        <label className="wide-field">Reason for visit <textarea name="visit_reason" maxLength={500} rows={4} placeholder="Optional — briefly tell the team how they can prepare for your visit. Do not include urgent details."/><small>This is visible to authorized appointment staff.</small></label>
        <div className="booking-assurance"><span aria-hidden="true">✓</span><p><strong>Your time is checked again when you confirm.</strong> If another client reserves it first, you will be asked to choose a different time.</p></div>
        <div className="form-actions"><button className="button button--primary" type="submit">Confirm appointment</button></div>
      </fieldset>
    </form>
  </div>;
}
