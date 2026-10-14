// Public build-time configuration (NEXT_PUBLIC_* values are inlined by Next.js).
export const API_BASE_URL = (process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000").replace(/\/+$/, "");

export const FIREBASE_CONFIG = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY ?? "",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ?? "",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? "",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET ?? "",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID ?? "",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID ?? "",
};

/** "DEV" when the API runs on this machine or the local network, else "PROD". */
export function environmentLabel(baseUrl: string = API_BASE_URL): "DEV" | "PROD" {
  try {
    const host = new URL(baseUrl).hostname;
    const local = host === "localhost" || host === "127.0.0.1" || host.startsWith("192.168.") || host.startsWith("10.");
    return local ? "DEV" : "PROD";
  } catch {
    return "DEV";
  }
}
