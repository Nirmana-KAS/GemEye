"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

import { verifyRedirectTarget } from "@/lib/verify";

// Static export: unknown paths serve 404.html. /v/{cert}-{token} (an old or direct link
// without the Firebase rewrite, or `npm run dev`) is sent to /v/?c={cert}-{token}.
export default function NotFound() {
  const [redirecting, setRedirecting] = useState(true);

  useEffect(() => {
    const target = verifyRedirectTarget(window.location.pathname);
    if (target) window.location.replace(target);
    // eslint-disable-next-line react-hooks/set-state-in-effect -- the path is only known in the browser
    else setRedirecting(false);
  }, []);

  if (redirecting) return null;
  return (
    <main className="mx-auto max-w-md px-4 py-16 text-center">
      <h1 className="text-lg font-semibold">Page not found</h1>
      <p className="mt-2 text-sm text-muted-foreground">This page does not exist.</p>
      <Link href="/admin/" className="mt-4 inline-block text-sm text-primary underline">
        GemEye Admin
      </Link>
    </main>
  );
}
