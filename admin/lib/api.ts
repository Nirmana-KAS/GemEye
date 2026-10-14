import type { ApiErrorBody, Page } from "./types";

/** Error from the API (or the network), always with a code and a user-facing message. */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

const STATUS_MESSAGES: Record<number, string> = {
  400: "The request was not accepted.",
  401: "Your session has expired. Please sign in again.",
  403: "You do not have access to this.",
  404: "Not found.",
  409: "This conflicts with the current state.",
  429: "Too many requests. Please wait a minute.",
  503: "The server is unavailable. Please try again later.",
};

const STATUS_CODES: Record<number, string> = {
  400: "bad_request",
  401: "unauthorized",
  403: "forbidden",
  404: "not_found",
  409: "conflict",
  413: "too_large",
  422: "invalid",
  429: "rate_limited",
  503: "unavailable",
};

/** Turns any error response into an ApiError. Accepts {code, message} (ApiError on
 * the server), {detail: string} (HTTPException) or a non-JSON body. */
export function errorFromResponse(status: number, body: unknown): ApiError {
  const b = (body && typeof body === "object" ? body : {}) as ApiErrorBody;
  const code = typeof b.code === "string" && b.code ? b.code : (STATUS_CODES[status] ?? `http_${status}`);
  const message =
    (typeof b.message === "string" && b.message) ||
    (typeof b.detail === "string" && b.detail) ||
    STATUS_MESSAGES[status] ||
    (status >= 500 ? "Server error. Please try again." : "Request failed.");
  return new ApiError(status, code, message);
}

export type QueryValue = string | number | boolean | null | undefined;

export function buildQuery(params?: Record<string, QueryValue>): string {
  if (!params) return "";
  const q = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v === undefined || v === null || v === "") continue;
    q.set(k, String(v));
  }
  const s = q.toString();
  return s ? `?${s}` : "";
}

export interface RequestOptions {
  method?: "GET" | "POST" | "PUT" | "DELETE";
  query?: Record<string, QueryValue>;
  body?: unknown;
  /** Do not call onError (the caller shows its own message). */
  silent?: boolean;
  /** Skip the Authorization header (public endpoints such as /health). */
  anonymous?: boolean;
}

export interface ApiClientOptions {
  baseUrl: string;
  /** Returns the Firebase ID token; forceRefresh after a 401. */
  getToken: (forceRefresh?: boolean) => Promise<string | null>;
  onUnauthorized?: (err: ApiError) => void;
  onForbidden?: (err: ApiError) => void;
  onError?: (err: ApiError) => void;
  fetchImpl?: typeof fetch;
}

export type ApiClient = <T>(path: string, opts?: RequestOptions) => Promise<T>;

export function createApiClient(o: ApiClientOptions): ApiClient {
  const doFetch = o.fetchImpl ?? ((...a: Parameters<typeof fetch>) => fetch(...a));

  async function send(path: string, opts: RequestOptions, forceRefresh: boolean): Promise<Response> {
    const headers: Record<string, string> = { Accept: "application/json" };
    if (!opts.anonymous) {
      const token = await o.getToken(forceRefresh);
      if (token) headers.Authorization = `Bearer ${token}`;
    }
    if (opts.body !== undefined) headers["Content-Type"] = "application/json";
    return doFetch(`${o.baseUrl}${path}${buildQuery(opts.query)}`, {
      method: opts.method ?? "GET",
      headers,
      body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
      cache: "no-store",
    });
  }

  return async function request<T>(path: string, opts: RequestOptions = {}): Promise<T> {
    let res: Response;
    try {
      res = await send(path, opts, false);
      // One retry with a fresh token: the old one may have expired or lost a claim.
      if (res.status === 401 && !opts.anonymous) res = await send(path, opts, true);
    } catch {
      const err = new ApiError(0, "network", "Cannot reach the server. Check that the API is running.");
      if (!opts.silent) o.onError?.(err);
      throw err;
    }
    if (res.ok) {
      if (res.status === 204) return undefined as T;
      const text = await res.text();
      return (text ? JSON.parse(text) : undefined) as T;
    }
    let body: unknown = null;
    try {
      body = await res.json();
    } catch {
      body = null;
    }
    const err = errorFromResponse(res.status, body);
    if (res.status === 401) o.onUnauthorized?.(err);
    else if (res.status === 403 && err.code === "forbidden") o.onForbidden?.(err);
    else if (!opts.silent) o.onError?.(err);
    throw err;
  };
}

/** Follows next_cursor until there are no more pages or `maxItems` rows are collected. */
export async function fetchAllPages<T>(
  fetchPage: (cursor: string | undefined) => Promise<Page<T>>,
  maxItems = 2000,
): Promise<{ items: T[]; truncated: boolean }> {
  const items: T[] = [];
  let cursor: string | undefined;
  for (;;) {
    const page = await fetchPage(cursor);
    items.push(...page.items);
    if (!page.next_cursor) return { items, truncated: false };
    if (items.length >= maxItems) return { items: items.slice(0, maxItems), truncated: true };
    cursor = page.next_cursor;
  }
}
