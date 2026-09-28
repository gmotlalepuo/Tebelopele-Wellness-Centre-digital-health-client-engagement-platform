import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { BrandLogo } from "@/components/brand-logo";
import { requestPasswordReset } from "@/app/auth/actions";

type Props = { searchParams: Promise<{ sent?: string; error?: string }> };

export default async function ForgotPasswordPage({ searchParams }: Props) {
  const params = await searchParams;
  return (
    <main className="single-auth">
      <section className="auth-form-wrap">
        <BrandLogo />
        <Link href="/sign-in" className="back-link"><ArrowLeft size={18}/> Back to sign in</Link>
        <div className="auth-form-heading"><h1>Reset your password</h1><p>We will send reset instructions if an account matches the email address.</p></div>
        {params.sent && <div className="alert alert--success" role="status">Check your email for the next step.</div>}
        {params.error && <div className="alert alert--error" role="alert">Supabase is not configured for this environment yet.</div>}
        <form action={requestPasswordReset} className="form-stack">
          <label>Email address<input name="email" type="email" autoComplete="email" required placeholder="name@example.com"/></label>
          <button className="button button--primary button--large" type="submit">Send reset instructions</button>
        </form>
      </section>
    </main>
  );
}
