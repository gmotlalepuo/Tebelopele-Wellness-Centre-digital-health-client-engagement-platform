import {Activity,CalendarDays,Download,MessageSquareText,Waypoints} from "lucide-react";
import {getOperationalMetrics,getReportingDashboard,requireCapability} from "@/lib/staff-data";

function TrendChart({items}:{items:{key:string;label:string;value:number}[]}){
  const peak=Math.max(1,...items.map(item=>item.value));
  return <div className="report-trend" role="img" aria-label={`Appointments during the last seven days: ${items.map(item=>`${item.label} ${item.value}`).join(", ")}`}>
    <div className="report-trend__plot">{items.map(item=><div className="report-trend__column" key={item.key}><strong>{item.value}</strong><span style={{height:`${Math.max(item.value?12:2,(item.value/peak)*100)}%`}}/><small>{item.label}</small></div>)}</div>
  </div>;
}

function Breakdown({title,items,tone}:{title:string;items:{label:string;value:number}[];tone:"plum"|"orange"}){
  const total=items.reduce((sum,item)=>sum+item.value,0);
  return <section className="report-breakdown"><header><h3>{title}</h3><strong>{total}</strong></header><div>{items.map(item=>{const percentage=total?Math.round(item.value/total*100):0;return <div className="report-breakdown__row" key={item.label}><span><span>{item.label}</span><strong>{item.value}</strong></span><div className="report-progress" role="progressbar" aria-label={`${item.label}: ${item.value}`} aria-valuemin={0} aria-valuemax={total||1} aria-valuenow={item.value}><span className={`report-progress__fill report-progress__fill--${tone}`} style={{width:`${percentage}%`}}/></div></div>})}</div></section>;
}

export default async function Reports(){
  const [m,dashboard,s]=await Promise.all([getOperationalMetrics(),getReportingDashboard(),requireCapability("reports.read")]);
  return <div className="portal-page reports-page"><div className="portal-heading"><div><p className="welcome-line">Operations and assurance</p><h1>Reporting</h1><p>Monitor demand, active workloads and governed content across the records visible to your account.</p></div>{s&&<a className="button button--quiet" href="/api/reports/operations.csv"><Download size={16}/>Export CSV</a>}</div>
    {!m.configured&&<div className="preview-notice"><strong>Preview mode</strong><span>Real operational counts require Supabase.</span></div>}
    <section className="report-summary" aria-label="Current operational totals"><article><span><CalendarDays/><small>Today</small></span><strong>{m.appointments}</strong><p>Appointments</p></article><article><span><MessageSquareText/><small>Active</small></span><strong>{m.openSupport}</strong><p>Support cases</p></article><article><span><Waypoints/><small>Active</small></span><strong>{m.activeReferrals}</strong><p>Referrals</p></article><article><span><Activity/><small>In review</small></span><strong>{m.reviewItems}</strong><p>Content items</p></article></section>
    <div className="report-dashboard">
      <section className="report-panel report-panel--trend"><header><div><h2>Appointment volume</h2><p>Bookings scheduled over the last seven days</p></div><span className="report-panel__total"><strong>{dashboard.trend.reduce((sum,item)=>sum+item.value,0)}</strong> total</span></header><TrendChart items={dashboard.trend}/></section>
      <section className="report-panel report-panel--mix"><header><div><h2>Operational workload</h2><p>Current work by stage</p></div></header><Breakdown title="Support" items={dashboard.support} tone="plum"/><Breakdown title="Referrals" items={dashboard.referrals} tone="orange"/></section>
    </div>
    <section className="report-status"><div><h2>Appointment status</h2><p>Seven-day schedule composition</p></div><div className="report-status__items">{dashboard.appointmentStatuses.map(item=><span key={item.label}><i aria-hidden="true"/><strong>{item.value}</strong><small>{item.label}</small></span>)}</div></section>
    <section className="assurance-panel report-assurance"><div><h2>Traceable by design</h2><p>Figures respect row-level security and include only records authorized for the signed-in staff member.</p></div><p>The CSV export repeats authentication and capability checks independently.</p></section>
  </div>;
}
