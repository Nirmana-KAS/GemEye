import { getApp, getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { getAuth, type Auth } from "firebase/auth";

import { FIREBASE_CONFIG } from "./env";

let app: FirebaseApp | undefined;

/** Firebase Auth for the browser only (never called during static prerender). */
export function firebaseAuth(): Auth {
  app ??= getApps().length ? getApp() : initializeApp(FIREBASE_CONFIG);
  return getAuth(app);
}
