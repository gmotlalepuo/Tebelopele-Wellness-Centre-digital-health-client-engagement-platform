import { describe, expect, it } from "vitest";
import { searchPublicContent } from "@/lib/public-data";

describe("public content search in preview mode", () => {
  it("returns matching service and article content", async () => {
    const result = await searchPublicContent("support");
    expect(result.preview).toBe(true);
    expect(result.services.length + result.articles.length + result.faqs.length).toBeGreaterThan(0);
  });

  it("does not return the whole catalogue for an empty query", async () => {
    const result = await searchPublicContent("   ");
    expect(result.services).toEqual([]);
    expect(result.articles).toEqual([]);
    expect(result.faqs).toEqual([]);
  });
});
