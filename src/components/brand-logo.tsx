import Image from "next/image";

export function BrandLogo({ compact = false }: { compact?: boolean }) {
  return (
    <span className="brand-logo">
      <Image
        src="/tebelopele-logo.png"
        width={compact ? 150 : 210}
        height={compact ? 64 : 90}
        alt="Tebelopele"
        priority
      />
    </span>
  );
}
