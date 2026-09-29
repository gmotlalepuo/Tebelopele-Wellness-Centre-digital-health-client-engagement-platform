import Link from "next/link";
import { ArrowRight, CalendarDays, HeartHandshake, MapPin, ShieldCheck } from "lucide-react";
import { SiteHeader } from "@/components/site-header";

export default function HomePage() {
  return (
    <>
      <SiteHeader />
      <main>
        <section className="hero">
          <div className="hero__content">
            <p className="welcome-line">Your wellbeing. Your choices. Support when you need it.</p>
            <h1>A clearer way to reach Tebelopele care.</h1>
            <p className="hero__lead">Find services, trustworthy health information and a real person to help you take the next step.</p>
            <div className="hero__actions">
            <Link className="button button--primary button--large" href="/sign-in">Access client services <ArrowRight size={19}/></Link>
              <Link className="text-link" href="/demo">Try the platform demo</Link>
            </div>
            <p className="trust-note"><ShieldCheck size={18} aria-hidden="true"/> Your information is handled with care and protected access.</p>
          </div>
          <div className="sunrise-panel" aria-label="Tebelopele support pathways">
            <div className="sunrise-panel__sun" aria-hidden="true" />
            <div className="pathway-list">
              <span><CalendarDays size={20}/>Plan a visit</span>
              <span><MapPin size={20}/>Find a service</span>
              <span><HeartHandshake size={20}/>Reach a person</span>
            </div>
          </div>
        </section>

        <section className="service-band" id="services">
          <div>
            <h2>Start with what you need today</h2>
            <p>These pathways will grow as each service phase is approved and connected.</p>
          </div>
          <div className="service-links">
            <Link href="/services"><span>01</span><strong>Services</strong><small>Find the right place to start</small><ArrowRight/></Link>
            <Link href="/health"><span>02</span><strong>Health information</strong><small>Read approved guidance</small><ArrowRight/></Link>
            <Link href="/sign-in"><span>03</span><strong>Human support</strong><small>Continue with the right expert</small><ArrowRight/></Link>
          </div>
        </section>

        <section className="location-section" id="locations">
          <div className="section-copy">
            <h2>Care that stays connected</h2>
            <p>Your web, chat and future WhatsApp conversations will follow one support journey, so you do not need to start over when a human joins.</p>
          </div>
          <div className="connection-line" aria-hidden="true"><span>Information</span><i/><span>Service</span><i/><span>Human help</span></div>
        </section>

        <section className="support-banner" id="support">
          <HeartHandshake size={34} aria-hidden="true"/>
          <div><h2>Need help choosing where to start?</h2><p>Open the Tebelopele assistant for approved guidance, or sign in and ask for an eligible human expert.</p></div>
          <Link className="button button--light" href="/sign-in">Continue securely</Link>
        </section>
      </main>
      <footer className="site-footer"><p>© 2026 Tebelopele Wellness Centre</p><p>Secure digital health platform · Implementation preview</p></footer>
    </>
  );
}
