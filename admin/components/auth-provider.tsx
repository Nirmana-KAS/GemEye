"use client";

import {
  GoogleAuthProvider,
  onIdTokenChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut as fbSignOut,
  type User,
} from "firebase/auth";
import { usePathname, useRouter } from "next/navigation";
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

import { createApiClient, type ApiClient } from "@/lib/api";
import { API_BASE_URL } from "@/lib/env";
import { firebaseAuth } from "@/lib/firebase";
import { LOGIN_PATH, roleFromClaims, samePath } from "@/lib/roles";
import type { Role } from "@/lib/types";

export const NO_ACCESS_MESSAGE = "This account has no dashboard access.";

interface AuthState {
  user: User | null;
  role: Role | null;
  loading: boolean;
  /** Set when the API answered 403 forbidden for the current page. */
  forbidden: boolean;
  api: ApiClient;
  signInWithGoogle: () => Promise<void>;
  signInWithEmail: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthState | null>(null);

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth outside AuthProvider");
  return ctx;
}

export function useApi(): ApiClient {
  return useAuth().api;
}

class NoAccessError extends Error {}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [user, setUser] = useState<User | null>(null);
  const [role, setRole] = useState<Role | null>(null);
  const [loading, setLoading] = useState(true);
  const [forbiddenPath, setForbiddenPath] = useState<string | null>(null);

  // Keeps the user and role in sync; Firebase refreshes the ID token hourly.
  useEffect(() => {
    return onIdTokenChanged(firebaseAuth(), async (u) => {
      if (!u) {
        setUser(null);
        setRole(null);
        setLoading(false);
        return;
      }
      try {
        const r = roleFromClaims((await u.getIdTokenResult()).claims);
        setUser(u);
        setRole(r);
      } catch {
        setUser(null);
        setRole(null);
      } finally {
        setLoading(false);
      }
    });
  }, []);

  const signOut = useCallback(async () => {
    await fbSignOut(firebaseAuth());
    router.replace(LOGIN_PATH);
  }, [router]);

  const api = useMemo(
    () =>
      createApiClient({
        baseUrl: API_BASE_URL,
        getToken: async (force) => {
          const u = firebaseAuth().currentUser;
          return u ? u.getIdToken(force) : null;
        },
        onUnauthorized: (err) => {
          toast.error(err.message);
          void signOut();
        },
        onForbidden: () => setForbiddenPath(window.location.pathname),
        onError: (err) => toast.error(err.message, { id: `${err.code}:${err.message}` }),
      }),
    [signOut],
  );

  // Signs in, then allows only accounts with the admin or reviewer claim.
  const finishSignIn = useCallback(async (u: User) => {
    const r = roleFromClaims((await u.getIdTokenResult(true)).claims);
    if (!r) {
      await fbSignOut(firebaseAuth());
      throw new NoAccessError(NO_ACCESS_MESSAGE);
    }
    setUser(u);
    setRole(r);
  }, []);

  const signInWithGoogle = useCallback(async () => {
    const cred = await signInWithPopup(firebaseAuth(), new GoogleAuthProvider());
    await finishSignIn(cred.user);
  }, [finishSignIn]);

  const signInWithEmail = useCallback(
    async (email: string, password: string) => {
      const cred = await signInWithEmailAndPassword(firebaseAuth(), email, password);
      await finishSignIn(cred.user);
    },
    [finishSignIn],
  );

  const value = useMemo<AuthState>(
    () => ({
      user,
      role,
      loading,
      forbidden: forbiddenPath !== null && samePath(forbiddenPath, pathname),
      api,
      signInWithGoogle,
      signInWithEmail,
      signOut,
    }),
    [user, role, loading, forbiddenPath, pathname, api, signInWithGoogle, signInWithEmail, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

/** Friendly text for Firebase sign-in errors (never the raw error). */
export function signInErrorMessage(e: unknown): string {
  if (e instanceof NoAccessError) return e.message;
  const code = (e as { code?: string })?.code ?? "";
  if (code === "auth/popup-closed-by-user" || code === "auth/cancelled-popup-request") return "Sign-in was cancelled.";
  if (code === "auth/invalid-credential" || code === "auth/wrong-password" || code === "auth/user-not-found")
    return "Wrong email or password.";
  if (code === "auth/too-many-requests") return "Too many attempts. Please try again later.";
  if (code === "auth/user-disabled") return "This account is disabled.";
  if (code === "auth/network-request-failed") return "Network error. Check your connection.";
  if (code === "auth/popup-blocked") return "The sign-in popup was blocked. Allow popups for this site and try again.";
  if (code === "auth/unauthorized-domain")
    return "This address is not an authorised sign-in domain. Open the dashboard from an authorised address.";
  if (code === "auth/operation-not-allowed") return "This sign-in method is turned off for the dashboard.";
  if (code === "auth/web-storage-unsupported") return "Allow cookies and site data for this site, then try again.";
  // Dev only: the raw code is the only way to diagnose an unmapped failure.
  if (process.env.NODE_ENV !== "production") console.warn("Sign-in failed:", code || e);
  return "Sign-in failed. Please try again.";
}
