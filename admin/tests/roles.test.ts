import { describe, expect, it } from "vitest";

import { environmentLabel } from "@/lib/env";
import { canAccess, guardDecision, homeFor, navFor, roleFromClaims, sectionFor } from "@/lib/roles";

describe("roleFromClaims", () => {
  it("maps claims to a dashboard role", () => {
    expect(roleFromClaims({ admin: true })).toBe("admin");
    expect(roleFromClaims({ reviewer: true })).toBe("reviewer");
    expect(roleFromClaims({ admin: true, reviewer: true })).toBe("admin");
  });

  it("rejects missing or non-boolean claims", () => {
    expect(roleFromClaims({})).toBeNull();
    expect(roleFromClaims(null)).toBeNull();
    expect(roleFromClaims({ admin: "true" })).toBeNull();
    expect(roleFromClaims({ role: "admin" })).toBeNull();
  });
});

describe("navigation by role", () => {
  it("reviewers see only the review queue and gradings", () => {
    expect(navFor("reviewer").map((n) => n.label)).toEqual(["Gradings", "Review queue"]);
    expect(navFor("admin")).toHaveLength(11);
  });

  it("detail pages belong to their section", () => {
    expect(sectionFor("/admin/gradings/detail/")?.label).toBe("Gradings");
    expect(sectionFor("/admin/users/detail")?.label).toBe("Users");
    expect(sectionFor("/admin")?.label).toBe("Overview");
    expect(sectionFor("/admin/unknown/")).toBeUndefined();
  });

  it("canAccess follows the section roles", () => {
    expect(canAccess("admin", "/admin/users/")).toBe(true);
    expect(canAccess("reviewer", "/admin/users/")).toBe(false);
    expect(canAccess("reviewer", "/admin/")).toBe(false);
    expect(canAccess("reviewer", "/admin/gradings/detail/?id=x")).toBe(true);
    expect(canAccess("reviewer", "/admin/review-queue/")).toBe(true);
    expect(canAccess(null, "/admin/gradings/")).toBe(false);
  });

  it("home page depends on role", () => {
    expect(homeFor("admin")).toBe("/admin/");
    expect(homeFor("reviewer")).toBe("/admin/gradings/");
  });
});

describe("guardDecision", () => {
  const base = { loading: false, signedIn: true, role: "admin" as const, pathname: "/admin/users/" };

  it("waits while auth is loading", () => {
    expect(guardDecision({ ...base, loading: true, signedIn: false, role: null })).toBe("loading");
  });

  it("sends signed-out users and users without a role to login", () => {
    expect(guardDecision({ ...base, signedIn: false, role: null })).toBe("login");
    expect(guardDecision({ ...base, role: null })).toBe("login");
  });

  it("shows no-access for a reviewer on an admin page or after a 403", () => {
    expect(guardDecision({ ...base, role: "reviewer" })).toBe("no-access");
    expect(guardDecision({ ...base, forbidden: true })).toBe("no-access");
  });

  it("allows permitted pages", () => {
    expect(guardDecision(base)).toBe("allow");
    expect(guardDecision({ ...base, role: "reviewer", pathname: "/admin/gradings/" })).toBe("allow");
  });
});

describe("environmentLabel", () => {
  it("is DEV for local APIs", () => {
    expect(environmentLabel("http://localhost:8000")).toBe("DEV");
    expect(environmentLabel("http://192.168.1.195:8000")).toBe("DEV");
    expect(environmentLabel("https://abc.execute-api.ap-south-1.amazonaws.com")).toBe("PROD");
  });
});
