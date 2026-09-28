import Image from "next/image";

export function BrandLogo({ compact = false }: { compact?: boolean }) {
  return (
    <span className="brand-logo">
      <Image
        src="/tebelopele-logo.png"
        width={compact ? 98 : 129}
        height={compact ? 64 : 84}
        alt="Tebelopele"
        priority
      />
    </span>
  );
}
