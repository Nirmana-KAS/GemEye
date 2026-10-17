import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Static files only (Firebase Hosting). Pages live under /admin/...
  output: "export",
  trailingSlash: true,
  basePath: "",
  images: { unoptimized: true },
  // Dev only: a phone on the same Wi-Fi opens the verify page at http://<laptop-LAN-IP>:3000.
  allowedDevOrigins: ["192.168.*.*", "10.*.*.*"],
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
