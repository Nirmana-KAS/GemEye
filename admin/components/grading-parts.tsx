"use client";

import { ImageOff, ZoomIn, ZoomOut } from "lucide-react";
import { useState } from "react";
import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

import { tooltipStyle, useChartPalette } from "@/components/chart-card";
import { Button } from "@/components/ui/button";
import { fmtNum, fmtPct } from "@/lib/format";
import { GRADES } from "@/lib/grades";
import type { ColourValues } from "@/lib/types";
import { cn } from "@/lib/utils";

export function Row({ label, children, mono }: { label: string; children: React.ReactNode; mono?: boolean }) {
  return (
    <div className="flex items-baseline justify-between gap-4 border-b py-1.5 text-sm last:border-0">
      <span className="text-muted-foreground">{label}</span>
      <span className={mono ? "font-mono text-xs" : "text-right"}>{children ?? "-"}</span>
    </div>
  );
}

function NoPhoto({ text }: { text: string }) {
  return (
    <div className="flex aspect-square items-center justify-center rounded-lg bg-muted text-sm text-muted-foreground">
      <span className="flex flex-col items-center gap-2">
        <ImageOff className="size-6" />
        {text}
      </span>
    </div>
  );
}

export function Photo({ url, alt, empty }: { url: string | null | undefined; alt: string; empty: string }) {
  if (!url) return <NoPhoto text={empty} />;
  // Presigned S3 links are short-lived; a plain img avoids caching them.
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={url} alt={alt} className="aspect-square w-full rounded-lg bg-muted object-contain" />;
}

const ZOOMS = [1, 2, 4];

/** Photo with click-to-zoom at the clicked point (1x, 2x, 4x). */
export function ZoomPhoto({ url, alt, empty }: { url: string | null | undefined; alt: string; empty: string }) {
  const [zoom, setZoom] = useState(0);
  const [origin, setOrigin] = useState("50% 50%");
  if (!url) return <NoPhoto text={empty} />;
  const scale = ZOOMS[zoom];
  return (
    <div className="relative">
      <div className="aspect-square overflow-hidden rounded-lg bg-muted">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={url}
          alt={alt}
          onClick={(e) => {
            const r = e.currentTarget.getBoundingClientRect();
            setOrigin(`${((e.clientX - r.left) / r.width) * 100}% ${((e.clientY - r.top) / r.height) * 100}%`);
            setZoom((z) => (z + 1) % ZOOMS.length);
          }}
          className={cn(
            "h-full w-full object-contain transition-transform duration-150",
            scale < ZOOMS[ZOOMS.length - 1] ? "cursor-zoom-in" : "cursor-zoom-out",
          )}
          style={{ transform: `scale(${scale})`, transformOrigin: origin }}
        />
      </div>
      <div className="absolute right-2 bottom-2 flex items-center gap-1 rounded-md bg-background/90 p-0.5 shadow-sm">
        <Button variant="ghost" size="icon-sm" aria-label="Zoom out" disabled={zoom === 0} onClick={() => setZoom((z) => Math.max(0, z - 1))}>
          <ZoomOut />
        </Button>
        <span className="w-8 text-center text-xs tabular-nums">{scale}x</span>
        <Button
          variant="ghost"
          size="icon-sm"
          aria-label="Zoom in"
          disabled={zoom === ZOOMS.length - 1}
          onClick={() => setZoom((z) => Math.min(ZOOMS.length - 1, z + 1))}
        >
          <ZoomIn />
        </Button>
      </div>
    </div>
  );
}

export function ProbabilityChart({ probs, height = 220 }: { probs: number[]; height?: number }) {
  const palette = useChartPalette();
  const data = GRADES.map((g, i) => ({ grade: `G${g.grade}`, name: g.name, hex: g.hex, p: probs[i] ?? 0 }));
  return (
    <div style={{ height }}>
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data} margin={{ top: 8, right: 8, left: -8, bottom: 0 }}>
          <CartesianGrid stroke={palette.grid} vertical={false} />
          <XAxis dataKey="grade" stroke={palette.axis} fontSize={12} />
          <YAxis domain={[0, 1]} tickFormatter={(v: number) => `${Math.round(v * 100)}%`} stroke={palette.axis} fontSize={12} />
          <Tooltip
            {...tooltipStyle(palette)}
            cursor={{ fill: palette.grid, opacity: 0.4 }}
            formatter={(v) => fmtPct(Number(v))}
            labelFormatter={(_, p) => {
              const d = p?.[0]?.payload as { grade: string; name: string } | undefined;
              return d ? `${d.grade} - ${d.name}` : "";
            }}
          />
          <Bar dataKey="p" name="Probability" radius={[4, 4, 0, 0]}>
            {data.map((d) => (
              <Cell key={d.grade} fill={d.hex} stroke={palette.axis} strokeOpacity={0.25} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

/** Swatch plus CIELAB, HSB and (when stored) CIECAM02 values. */
export function ColourValuesView({ colour, deltaE }: { colour: ColourValues; deltaE?: number | null }) {
  return (
    <>
      <div className="mb-3 flex items-center gap-3">
        <span className="size-12 rounded-lg border" style={{ backgroundColor: colour.hex }} />
        <span className="font-mono text-sm">{colour.hex}</span>
      </div>
      <div className="grid gap-x-8 sm:grid-cols-2">
        <div>
          <Row label="L*" mono>{fmtNum(colour.L)}</Row>
          <Row label="a*" mono>{fmtNum(colour.a)}</Row>
          <Row label="b*" mono>{fmtNum(colour.b)}</Row>
          <Row label="Chroma C*" mono>{fmtNum(colour.C)}</Row>
          <Row label="ΔE00 to typical" mono>{fmtNum(deltaE)}</Row>
        </div>
        <div>
          <Row label="Hue" mono>{`${fmtNum(colour.H, 1)}°`}</Row>
          <Row label="Saturation" mono>{fmtNum(colour.S)}</Row>
          <Row label="Brightness" mono>{fmtNum(colour.B)}</Row>
          {colour.ciecam02 && (
            <>
              <Row label="CAM02 J / M" mono>{`${fmtNum(colour.ciecam02.J, 1)} / ${fmtNum(colour.ciecam02.M, 1)}`}</Row>
              <Row label="CAM02 h / s / C" mono>
                {`${fmtNum(colour.ciecam02.h, 1)} / ${fmtNum(colour.ciecam02.s, 1)} / ${fmtNum(colour.ciecam02.C, 1)}`}
              </Row>
            </>
          )}
        </div>
      </div>
    </>
  );
}
