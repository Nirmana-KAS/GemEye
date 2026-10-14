import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Static files only (Firebase Hosting). Pages live under /admin/...
  output: "export",
  trailingSlash: true,
  basePath: "",
  images: { unoptimized: true },
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
