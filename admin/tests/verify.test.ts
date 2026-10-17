import { createHash } from "node:crypto";

import { describe, expect, it, vi } from "vitest";

import {
  certNoOf,
  checkPdf,
  DISCLAIMER,
  fetchVerify,
  parseVerifySlug,
  sameSha256,
  sha256Hex,
  verifyRedirectTarget,
  verifyStateFrom,
} from "@/lib/verify";

const SLUG = "GE-202610-00042-Zj9_N2O-EoqD3ZJQ";
const base = { cert_no: "GE-202610-00042", issued_at: "2026-10-17T05:00:00Z", disclaimer: DISCLAIMER };

describe("parseVerifySlug", () => {
  it("reads ?c= and the /v/{slug} path", () => {
    expect(parseVerifySlug("/v/", `?c=${SLUG}`)).toBe(SLUG);
    expect(parseVerifySlug("/v/", `?c=${encodeURIComponent(SLUG)}`)).toBe(SLUG);
    expect(parseVerifySlug(`/v/${SLUG}`, "")).toBe(SLUG);
    expect(parseVerifySlug(`/v/${SLUG}/`, "")).toBe(SLUG);
  });

  it("rejects missing or malformed slugs", () => {
    for (const [p, q] of [
      ["/v/", ""],
      ["/v/", "?c=GE-202610-00042"],
      ["/v/", "?c=GE-2026-00042-abcdef"],
      ["/v/", "?c=GE-202610-00042-ab<script>"],
      ["/v/", "?c=%E0%A4%A"],
      ["/v/a/b", ""],
    ]) {
      expect(parseVerifySlug(p, q)).toBeNull();
    }
  });

  it("redirects only well-formed /v/{slug} paths from the 404 page", () => {
    expect(verifyRedirectTarget(`/v/${SLUG}`)).toBe(`/v/?c=${encodeURIComponent(SLUG)}`);
    expect(verifyRedirectTarget(`/v/${SLUG}/`)).toBe(`/v/?c=${encodeURIComponent(SLUG)}`);
    expect(verifyRedirectTarget("/v/nonsense")).toBeNull();
    expect(verifyRedirectTarget("/admin/nope")).toBeNull();
    expect(certNoOf(SLUG)).toBe("GE-202610-00042");
  });
});

describe("verifyStateFrom", () => {
  it("maps each certificate status", () => {
    expect(verifyStateFrom(200, { ...base, status: "valid" }).kind).toBe("valid");
    expect(verifyStateFrom(200, { ...base, status: "revoked", revoked_reason: "x" }).kind).toBe("revoked");
    expect(verifyStateFrom(200, { ...base, status: "revoked", superseded_by: "GE-202610-00043" }).kind).toBe(
      "superseded",
    );
    expect(verifyStateFrom(200, { ...base, status: "withdrawn" }).kind).toBe("withdrawn");
  });

  it("maps not found, rate limit and unreachable", () => {
    expect(verifyStateFrom(404, { detail: "Not found." })).toEqual({ kind: "not_found" });
    expect(verifyStateFrom(429, null)).toEqual({ kind: "unreachable", rateLimited: true });
    expect(verifyStateFrom(0, null)).toEqual({ kind: "unreachable", rateLimited: false });
    expect(verifyStateFrom(503, {})).toEqual({ kind: "unreachable", rateLimited: false });
    expect(verifyStateFrom(200, { ...base, status: "odd" })).toEqual({ kind: "unreachable", rateLimited: false });
  });

  it("fetches without credentials and handles a network error", async () => {
    const ok = vi.fn(async () => new Response(JSON.stringify({ ...base, status: "valid" }), { status: 200 }));
    const s = await fetchVerify("http://api", SLUG, ok as unknown as typeof fetch);
    expect(s.kind).toBe("valid");
    expect(ok).toHaveBeenCalledWith(`http://api/public/v/${SLUG}`, expect.objectContaining({ credentials: "omit" }));
    const down = vi.fn(async () => {
      throw new TypeError("Failed to fetch");
    });
    expect(await fetchVerify("http://api", SLUG, down as unknown as typeof fetch)).toEqual({
      kind: "unreachable",
      rateLimited: false,
    });
  });
});

describe("SHA-256 compare", () => {
  const pdf = new TextEncoder().encode("%PDF-1.7 GemEye test certificate");
  const expected = createHash("sha256").update(pdf).digest("hex");

  it("hashes like the server (hashlib.sha256)", async () => {
    expect(await sha256Hex(pdf)).toBe(expected);
    expect(await sha256Hex(pdf.buffer.slice(0))).toBe(expected);
  });

  it("matches only the same file", async () => {
    expect(await checkPdf(pdf, expected)).toEqual({ actual: expected, match: true });
    expect((await checkPdf(pdf, ` ${expected.toUpperCase()} `)).match).toBe(true);
    const edited = new TextEncoder().encode("%PDF-1.7 GemEye test certificatE");
    expect((await checkPdf(edited, expected)).match).toBe(false);
  });

  it("never matches an empty or malformed hash", () => {
    expect(sameSha256("", "")).toBe(false);
    expect(sameSha256(null, null)).toBe(false);
    expect(sameSha256("abc", "abc")).toBe(false);
  });
});
