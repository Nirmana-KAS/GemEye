import { describe, expect, it, vi } from "vitest";

import { ApiError, buildQuery, createApiClient, errorFromResponse, fetchAllPages } from "@/lib/api";

function json(status: number, body: unknown): Response {
  return new Response(body === undefined ? null : JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function client(responses: Response[], extra: Partial<Parameters<typeof createApiClient>[0]> = {}) {
  const fetchImpl = vi.fn(async () => responses.shift() ?? json(500, {}));
  const getToken = vi.fn(async (force?: boolean) => (force ? "fresh-token" : "token"));
  const handlers = { onUnauthorized: vi.fn(), onForbidden: vi.fn(), onError: vi.fn() };
  const api = createApiClient({ baseUrl: "http://api", getToken, fetchImpl: fetchImpl as unknown as typeof fetch, ...handlers, ...extra });
  return { api, fetchImpl, getToken, ...handlers };
}

describe("errorFromResponse", () => {
  it("uses code and message from an ApiError body", () => {
    const e = errorFromResponse(400, { status: "error", code: "self_action", message: "Not on yourself.", detail: "x" });
    expect(e).toMatchObject({ status: 400, code: "self_action", message: "Not on yourself." });
  });

  it("falls back to detail and a status code", () => {
    const e = errorFromResponse(404, { status: "error", detail: "Not found." });
    expect(e).toMatchObject({ code: "not_found", message: "Not found." });
  });

  it("handles non-JSON and unknown statuses", () => {
    expect(errorFromResponse(502, null)).toMatchObject({ code: "http_502", message: "Server error. Please try again." });
    expect(errorFromResponse(429, "text").message).toMatch(/Too many requests/);
    expect(errorFromResponse(400, { detail: [{ loc: ["x"] }] }).message).toBe("The request was not accepted.");
  });
});

describe("buildQuery", () => {
  it("skips empty values", () => {
    expect(buildQuery({ a: 1, b: "", c: undefined, d: null, e: false, f: "x y" })).toBe("?a=1&e=false&f=x+y");
    expect(buildQuery({})).toBe("");
  });
});

describe("createApiClient", () => {
  it("sends the bearer token and parses JSON", async () => {
    const c = client([json(200, { ok: 1 })]);
    await expect(c.api("/admin/users", { query: { limit: 5 } })).resolves.toEqual({ ok: 1 });
    const [url, init] = c.fetchImpl.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe("http://api/admin/users?limit=5");
    expect((init.headers as Record<string, string>).Authorization).toBe("Bearer token");
  });

  it("returns text bodies unparsed (CSV export)", async () => {
    const c = client([new Response("a,b\r\n1,2\r\n", { status: 200, headers: { "Content-Type": "text/csv" } })]);
    await expect(c.api<string>("/admin/reviews/export", { text: true })).resolves.toBe("a,b\r\n1,2\r\n");
  });

  it("returns undefined for 204", async () => {
    const c = client([new Response(null, { status: 204 })]);
    await expect(c.api("/admin/users/u1", { method: "DELETE" })).resolves.toBeUndefined();
  });

  it("anonymous requests have no Authorization header", async () => {
    const c = client([json(200, { status: "ok" })]);
    await c.api("/health", { anonymous: true });
    const init = c.fetchImpl.mock.calls[0] as unknown as [string, RequestInit];
    expect((init[1].headers as Record<string, string>).Authorization).toBeUndefined();
    expect(c.getToken).not.toHaveBeenCalled();
  });

  it("retries a 401 once with a fresh token, then succeeds", async () => {
    const c = client([json(401, { detail: "expired" }), json(200, { ok: true })]);
    await expect(c.api("/admin/users")).resolves.toEqual({ ok: true });
    expect(c.getToken).toHaveBeenLastCalledWith(true);
    expect(c.onUnauthorized).not.toHaveBeenCalled();
  });

  it("calls onUnauthorized (not onError) when the retry is also 401", async () => {
    const c = client([json(401, {}), json(401, { status: "error", code: "account_disabled", message: "Disabled." })]);
    await expect(c.api("/admin/users")).rejects.toMatchObject({ status: 401, code: "account_disabled" });
    expect(c.onUnauthorized).toHaveBeenCalledOnce();
    expect(c.onError).not.toHaveBeenCalled();
  });

  it("calls onForbidden for 403 forbidden", async () => {
    const c = client([json(403, { status: "error", code: "forbidden", message: "Admins only." })]);
    await expect(c.api("/admin/users")).rejects.toBeInstanceOf(ApiError);
    expect(c.onForbidden).toHaveBeenCalledOnce();
    expect(c.onError).not.toHaveBeenCalled();
  });

  it("shows other errors through onError unless silent", async () => {
    const c = client([json(400, { code: "self_action", message: "No." }), json(500, null)]);
    await expect(c.api("/x", { method: "POST" })).rejects.toMatchObject({ code: "self_action" });
    expect(c.onError).toHaveBeenCalledWith(expect.objectContaining({ message: "No." }));
    await expect(c.api("/y", { silent: true })).rejects.toMatchObject({ status: 500 });
    expect(c.onError).toHaveBeenCalledOnce();
  });

  it("turns network failures into a network ApiError", async () => {
    const c = client([], { fetchImpl: (async () => { throw new TypeError("Failed to fetch"); }) as unknown as typeof fetch });
    await expect(c.api("/health")).rejects.toMatchObject({ status: 0, code: "network" });
    expect(c.onError).toHaveBeenCalledOnce();
  });

  it("sends a JSON body", async () => {
    const c = client([json(200, { uid: "u", role: "reviewer" })]);
    await c.api("/admin/users/u/role", { method: "POST", body: { role: "reviewer" } });
    const init = (c.fetchImpl.mock.calls[0] as unknown as [string, RequestInit])[1];
    expect(init.method).toBe("POST");
    expect(init.body).toBe('{"role":"reviewer"}');
    expect((init.headers as Record<string, string>)["Content-Type"]).toBe("application/json");
  });
});

describe("fetchAllPages", () => {
  it("follows cursors and caps the result", async () => {
    const pages: Record<string, { items: number[]; next_cursor: string | null }> = {
      start: { items: [1, 2], next_cursor: "b" },
      b: { items: [3, 4], next_cursor: "c" },
      c: { items: [5], next_cursor: null },
    };
    const all = await fetchAllPages(async (cur) => pages[cur ?? "start"]);
    expect(all).toEqual({ items: [1, 2, 3, 4, 5], truncated: false });
    const capped = await fetchAllPages(async (cur) => pages[cur ?? "start"], 3);
    expect(capped).toEqual({ items: [1, 2, 3], truncated: true });
  });
});
