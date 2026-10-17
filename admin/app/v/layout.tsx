import type { Metadata, Viewport } from "next";

export const metadata: Metadata = {
  title: "GemEye Certificate Verification",
  description: "Check that a GemEye colour grading certificate is genuine.",
  robots: { index: false, follow: false },
};

export const viewport: Viewport = { width: "device-width", initialScale: 1, themeColor: "#1B3A8C" };

export default function VerifyLayout({ children }: { children: React.ReactNode }) {
  return children;
}
