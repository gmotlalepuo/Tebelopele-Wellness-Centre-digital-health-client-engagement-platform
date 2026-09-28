import { describe, expect, it } from "vitest";
import { destinationForCapabilities } from "@/lib/access";

describe("destinationForCapabilities", () => {
  it("sends a client without staff capabilities to the client portal", () => {
    expect(destinationForCapabilities([])).toBe("/client");
  });

  it("sends support and operational staff to the staff workspace", () => {
    expect(destinationForCapabilities(["support.handle"])).toBe("/staff");
    expect(destinationForCapabilities(["content.review"])).toBe("/staff");
  });

  it("does not trust an arbitrary browser supplied role-like string", () => {
    expect(destinationForCapabilities(["system_administrator"])).toBe("/client");
  });
});
