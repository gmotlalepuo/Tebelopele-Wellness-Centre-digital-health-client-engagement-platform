import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { PublicShell } from "@/components/public-shell";

export default function NotFound() {
  return <PublicShell><main className="error-page"><p className="welcome-line">Page not found</p><h1>That information is not available.</h1><p>The page may have moved, may not be published, or the address may be incorrect.</p><Link href="/" className="button button--primary"><ArrowLeft size={18}/>Return home</Link></main></PublicShell>;
}
