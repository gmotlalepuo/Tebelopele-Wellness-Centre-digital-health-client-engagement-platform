import { describe, expect, it } from "vitest";
import { isRoleSlug, roleNavigation, rolePresentation } from "@/lib/roles";

describe("role presentation", () => {
  it("rejects browser-supplied values outside the configured roles", () => {
    expect(isRoleSlug("support_agent")).toBe(true);
    expect(isRoleSlug("superuser")).toBe(false);
  });

  it("routes client and operational roles to the correct workspaces", () => {
    expect(rolePresentation.client.destination).toBe("/client");
    expect(rolePresentation.support_agent.destination).toBe("/staff/support");
    expect(rolePresentation.system_administrator.destination).toBe("/staff/admin");
  });

  it("keeps role navigation narrower than the administrator view", () => {
    expect(roleNavigation.support_agent).toEqual(["/staff", "/staff/support", "/staff/profile"]);
    expect(roleNavigation.system_administrator).toContain("/staff/admin");
  });
});
