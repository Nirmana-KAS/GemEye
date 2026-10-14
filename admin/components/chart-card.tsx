"use client";

import type { UseQueryResult } from "@tanstack/react-query";
import { useTheme } from "next-themes";

import { EmptyState, ErrorState } from "@/components/states";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

const LIGHT = {
  primary: "#1E3A8A",
  accent: "#2563EB",
  soft: "#60A5FA",
  warning: "#D97706",
  danger: "#DC2626",
  success: "#059669",
  grid: "#E2E8F0",
  axis: "#64748B",
  tooltipBg: "#FFFFFF",
  tooltipBorder: "#E2E8F0",
};

const DARK: typeof LIGHT = {
  primary: "#60A5FA",
  accent: "#3B82F6",
  soft: "#93C5FD",
  warning: "#FBBF24",
  danger: "#F87171",
  success: "#34D399",
  grid: "#1E293B",
  axis: "#94A3B8",
  tooltipBg: "#0F172A",
  tooltipBorder: "#334155",
};

/** Gate colours for the rejection reasons, in a fixed order. */
export const GATE_COLOURS: Record<string, string> = {
  invalid_image: "#64748B",
  no_stone: "#D97706",
  blurry: "#2563EB",
  not_blue: "#7C3AED",
  not_recognised: "#DC2626",
};
const EXTRA = ["#0891B2", "#DB2777", "#65A30D", "#EA580C"];

export function gateColour(gate: string, index: number): string {
  return GATE_COLOURS[gate] ?? EXTRA[index % EXTRA.length];
}

export function useChartPalette() {
  const { resolvedTheme } = useTheme();
  return resolvedTheme === "dark" ? DARK : LIGHT;
}

export function tooltipStyle(p: typeof LIGHT) {
  return {
    contentStyle: {
      background: p.tooltipBg,
      border: `1px solid ${p.tooltipBorder}`,
      borderRadius: 8,
      fontSize: 12,
    },
    labelStyle: { color: p.axis },
  };
}

export function ChartCard({
  title,
  description,
  query,
  isEmpty,
  children,
  height = 260,
}: {
  title: string;
  description?: string;
  query: Pick<UseQueryResult, "isPending" | "isError" | "error" | "refetch">;
  isEmpty?: boolean;
  children: React.ReactNode;
  height?: number;
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">{title}</CardTitle>
        {description && <CardDescription>{description}</CardDescription>}
      </CardHeader>
      <CardContent>
        <div style={{ height }}>
          {query.isPending ? (
            <Skeleton className="h-full w-full" />
          ) : query.isError ? (
            <ErrorState error={query.error} onRetry={() => void query.refetch()} />
          ) : isEmpty ? (
            <EmptyState title="No data in this range" />
          ) : (
            children
          )}
        </div>
      </CardContent>
    </Card>
  );
}
