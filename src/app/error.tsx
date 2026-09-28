"use client";

import { useEffect } from "react";
import Link from "next/link";

export default function ErrorPage({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => { console.error(error); }, [error]);
  return <main className="error-page"><p className="welcome-line">Something interrupted this page</p><h1>We could not load that information.</h1><p>Try again. If the problem continues, return to the home page and choose another route.</p><div><button className="button button--primary" onClick={reset}>Try again</button><Link className="button button--quiet" href="/">Return home</Link></div></main>;
}
