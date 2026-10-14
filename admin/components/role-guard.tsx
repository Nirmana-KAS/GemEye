"use client";

import { Loader2 } from "lucide-react";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";

import { useAuth } from "@/components/auth-provider";
import { NoAccess } from "@/components/states";
import { guardDecision, LOGIN_PATH } from "@/lib/roles";

/** Shows the page only to signed-in admins/reviewers allowed on this path. */
export function RoleGuard({ children }: { children: React.ReactNode }) {
  const { user, role, loading, forbidden } = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const decision = guardDecision({ loading, signedIn: !!user, role, pathname, forbidden });

  useEffect(() => {
    if (decision === "login") router.replace(LOGIN_PATH);
  }, [decision, router]);

  if (decision === "loading" || decision === "login") {
    return (
      <div className="flex min-h-[50vh] items-center justify-center text-muted-foreground">
        <Loader2 className="size-6 animate-spin" />
      </div>
    );
  }
  if (decision === "no-access") return <NoAccess />;
  return <>{children}</>;
}
