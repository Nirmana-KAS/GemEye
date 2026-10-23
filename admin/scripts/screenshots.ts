/**
 * Captures dashboard screenshots for the thesis.
 * Usage: npm run screenshots -- [--valid <code>] [--revoked <code>]
 * Needs the API and `npm run dev` running, and Chrome started with
 * scripts/start-chrome-for-screenshots.bat (remote debugging on port 9222).
 */
import { chromium, type Page } from "@playwright/test";
import { mkdirSync } from "node:fs";
import path from "node:path";
import { createInterface } from "node:readline/promises";

const BASE = "http://localhost:3000";
const CDP = "http://localhost:9222";
const OUT = path.resolve(import.meta.dirname, "../../docs/screenshots/dashboard");

const PAGES: Array<[string, string]> = [
  ["overview", "/admin/"],
  ["users", "/admin/users/"],
  ["gradings", "/admin/gradings/"],
  ["review-queue", "/admin/review-queue/"],
  ["model-monitoring", "/admin/model-monitoring/"],
  ["calibrations", "/admin/calibrations/"],
  ["app-control", "/admin/app-control/"],
  ["announcements", "/admin/announcements/"],
  ["notifications", "/admin/notifications/"],
  ["feedback", "/admin/feedback/"],
  ["certificates", "/admin/certificates/"],
  ["audit-log", "/admin/audit-log/"],
];

// Blurs anything that looks like an email address (text nodes and inputs).
const BLUR_SCRIPT = `
(() => {
  const re = /[\w.+-]+@[\w-]+(\.[\w-]+)+/;
  const style = document.getElementById('shot-blur') || document.head.appendChild(Object.assign(document.createElement('style'), { id: 'shot-blur' }));
  style.textContent = '.shot-blur{filter:blur(6px)!important}';
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  let n;
  while ((n = walker.nextNode())) {
    if (re.test(n.nodeValue || '') && n.parentElement) n.parentElement.classList.add('shot-blur');
  }
  document.querySelectorAll('input').forEach((i) => { if (re.test(i.value)) i.classList.add('shot-blur'); });
})();
`;

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(`--${name}`);
  return i > -1 ? process.argv[i + 1] : undefined;
}

async function waitForEnter(message: string) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  await rl.question(message);
  rl.close();
}

async function settle(page: Page) {
  await page.waitForLoadState("networkidle").catch(() => undefined);
  await page.waitForTimeout(1200);
}

async function shot(page: Page, n: number, name: string) {
  await settle(page);
  await page.evaluate(BLUR_SCRIPT);
  const file = path.join(OUT, `${String(n).padStart(2, "0")}-${name}.png`);
  await page.screenshot({ path: file, fullPage: true });
  console.log("saved", path.relative(process.cwd(), file));
}

async function openFirstRow(page: Page, listPath: string): Promise<boolean> {
  await page.goto(BASE + listPath);
  await settle(page);
  const row = page.locator("tbody tr").first();
  if (!(await row.count())) return false;
  await row.locator("td").last().click();
  await settle(page);
  return true;
}

async function main() {
  mkdirSync(OUT, { recursive: true });
  const browser = await chromium.connectOverCDP(CDP).catch(() => {
    throw new Error("Chrome not reachable on port 9222: run scripts/start-chrome-for-screenshots.bat first.");
  });
  const ctx = browser.contexts()[0];
  const page = ctx?.pages()[0] ?? (await ctx?.newPage());
  if (!page) throw new Error("No browser context found in the attached Chrome.");
  await page.setViewportSize({ width: 1440, height: 900 });

  await waitForEnter("Sign in in the Chrome window, then press Enter here");
  let n = 1;

  for (const [name, route] of PAGES) {
    await page.goto(BASE + route);
    if (page.url().includes("/admin/login")) {
      throw new Error("Not signed in: sign in in the Chrome window and run again.");
    }
    await shot(page, n++, name);
  }

  if (await openFirstRow(page, "/admin/users/")) await shot(page, n++, "user-detail");
  else console.log("skip user detail (no rows)");

  if (await openFirstRow(page, "/admin/gradings/")) await shot(page, n++, "grading-detail");
  else console.log("skip grading detail (no rows)");

  if (await openFirstRow(page, "/admin/review-queue/")) await shot(page, n++, "review-panel");
  else console.log("skip review panel (no referred stones)");

  const valid = arg("valid");
  const revoked = arg("revoked");
  for (const [code, name] of [[valid, "verify-valid"], [revoked, "verify-revoked"]] as const) {
    if (!code) continue;
    await page.goto(`${BASE}/v/?c=${encodeURIComponent(code)}`);
    await shot(page, n++, name);
  }

  await browser.close();
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : e);
  process.exit(1);
});
