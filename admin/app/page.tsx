"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

// The dashboard lives under /admin/.
export default function RootRedirect() {
  const router = useRouter();
  useEffect(() => router.replace("/admin/"), [router]);
  return null;
}
