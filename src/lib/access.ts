export const staffWorkspaceCapabilities = new Set([
  "users.read",
  "staff.read",
  "appointments.manage",
  "content.author",
  "content.review",
  "support.handle",
  "referrals.manage",
  "reports.read",
  "audit.read",
  "system.manage",
]);

export function destinationForCapabilities(capabilities: readonly string[]) {
  return capabilities.some((capability) => staffWorkspaceCapabilities.has(capability))
    ? "/staff"
    : "/client";
}
