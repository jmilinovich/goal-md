import { CSSProperties } from "react";
import { monoFontFamily, sansFontFamily } from "./fonts";

// White background, black foreground, punchy primary accents
export const colors = {
  bg: "#FFFFFF",
  bgLight: "#FAFAFA",
  border: "#E0E0E0",
  text: "#000000",
  textDim: "#555555",
  muted: "#AAAAAA",

  // Bold primary highlights — used sparingly for depth
  blue: "#0055FF",
  red: "#FF3333",
  amber: "#FFAA00",
  green: "#00AA44",
};

// Layout constants — consistent spacing grid
export const FRAME_PADDING = 64; // px from edge of frame
export const CONTENT_WIDTH = 1280 - FRAME_PADDING * 2; // 1152px usable

// Type scale — use these instead of magic numbers
export const FONT_SIZES = {
  hero: 88,
  title: 48,
  subtitle: 40,
  heading: 34,
  body: 20,
  label: 16,
  caption: 15,
  small: 13,
  micro: 11,
} as const;

// BPM config for timing (ambient, not strict beat-matching)
export const BPM = 120;
export const FRAMES_PER_BEAT = (30 * 60) / BPM; // 15 frames

export const mono: CSSProperties = {
  fontFamily: `${monoFontFamily}, 'SF Mono', monospace`,
};

export const sans: CSSProperties = {
  fontFamily: `${sansFontFamily}, 'Inter', -apple-system, sans-serif`,
};

export const terminalContainer: CSSProperties = {
  ...mono,
  backgroundColor: colors.bgLight,
  border: `1.5px solid ${colors.border}`,
  borderRadius: 16,
  padding: "28px 32px",
  fontSize: 18,
  color: colors.text,
  lineHeight: 1.7,
  boxSizing: "border-box" as const,
};

export const heading: CSSProperties = {
  ...sans,
  fontWeight: 700,
  color: colors.text,
  letterSpacing: "-0.03em",
};

// Centered content wrapper — use for consistent horizontal alignment
export const centeredContent: CSSProperties = {
  position: "absolute" as const,
  left: FRAME_PADDING,
  right: FRAME_PADDING,
};
