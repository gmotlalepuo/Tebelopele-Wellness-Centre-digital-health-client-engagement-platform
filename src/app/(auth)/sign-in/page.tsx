import Link from "next/link";
import { ArrowLeft, LockKeyhole } from "lucide-react";
import { BrandLogo } from "@/components/brand-logo";
import { signIn } from "@/app/auth/actions";

type Props = { searchParams: Promise<{ error?: string; next?: string }> };

const messages: Record<string, string> = {
  setup: "Supabase is not configured for this environment yet.",
  credentials: "The email or password was not recognized.",
  callback: "That sign-in link could not be completed. Please try again.",
  inactive: "This account is not active. Please contact Tebelopele support.",
};

export default async function SignInPage({ searchParams }: Props) {
  const params = await searchParams;
  return (
    <main className="auth-layout">
      <section className="auth-context">
        <Link href="/" className="back-link"><ArrowLeft size={18}/> Back to Tebelopele</Link>
        <div>
          <p className="welcome-line">Secure client access</p>
          <h1>Continue your care journey.</h1>
          <p>See your permitted services and keep future conversations connected to your account.</p>
        </div>
        <p className="privacy-note"><LockKeyhole size={20}/> Tebelopele staff only see information allowed by their role and assignment.</p>
      </section>
      <section className="auth-form-wrap">
        <BrandLogo />
        <div className="auth-form-heading"><h2>Sign in</h2><p>Use the email address connected to your account.</p></div>
        {params.error && <div className="alert alert--error" role="alert">{messages[params.error] ?? "Sign in could not be completed."}</div>}
        <form action={signIn} className="form-stack">
          <input type="hidden" name="next" value={params.next ?? ""}/>
          <label>Email address<input name="email" type="email" autoComplete="email" required placeholder="name@example.com"/></label>
          <label>Password<input name="password" type="password" autoComplete="current-password" required minLength={8}/></label>
          <Link className="text-link form-assist" href="/forgot-password">Forgot your password?</Link>
          <button className="button button--primary button--large" type="submit">Sign in</button>
        </form>
        <p className="form-footnote">Accounts are currently created through the Tebelopele onboarding and staff invitation process.</p>
      </section>
    </main>
  );
}
