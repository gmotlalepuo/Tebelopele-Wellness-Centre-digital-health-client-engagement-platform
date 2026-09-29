export const rolePresentation = {
  client: { label: "Client", destination: "/client" },
  reception_officer: { label: "Appointment officer", destination: "/staff/appointments" },
  support_agent: { label: "Support agent", destination: "/staff/support" },
  referral_officer: { label: "Referral officer", destination: "/staff/referrals" },
  content_editor: { label: "Content editor", destination: "/staff/content" },
  content_reviewer: { label: "Content reviewer", destination: "/staff/content" },
  reporting_user: { label: "Reporting user", destination: "/staff/reports" },
  auditor: { label: "Auditor", destination: "/staff/assurance" },
  system_administrator: { label: "System administrator", destination: "/staff/admin" },
} as const;

export type RoleSlug = keyof typeof rolePresentation;

export function isRoleSlug(value: string): value is RoleSlug {
  return value in rolePresentation;
}

export const roleNavigation: Record<RoleSlug, readonly string[]> = {
  client: [],
  reception_officer: ["/staff", "/staff/appointments", "/staff/profile"],
  support_agent: ["/staff", "/staff/support", "/staff/profile"],
  referral_officer: ["/staff", "/staff/referrals", "/staff/profile"],
  content_editor: ["/staff", "/staff/content", "/staff/knowledge", "/staff/profile"],
  content_reviewer: ["/staff", "/staff/content", "/staff/knowledge", "/staff/profile"],
  reporting_user: ["/staff", "/staff/reports", "/staff/profile"],
  auditor: ["/staff", "/staff/assurance", "/staff/profile"],
  system_administrator: [
    "/staff", "/staff/appointments", "/staff/support", "/staff/referrals",
    "/staff/whatsapp", "/staff/content", "/staff/knowledge", "/staff/reports",
    "/staff/assurance", "/staff/admin", "/staff/profile",
  ],
};
