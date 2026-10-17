import { Providers } from "@/components/providers";

// Firebase sign-in, data fetching and toasts for the dashboard only; the public
// verify page (/v/) loads none of them.
export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return <Providers>{children}</Providers>;
}
