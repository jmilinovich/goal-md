#!/bin/bash
# Generates social card images for the goal-md repo, matching the video's creative direction.
# Outputs: assets/social/hero-card.svg (.png) and assets/social/score-card.svg (.png)
# Colors sourced from STYLE.md.
#
# Usage: ./scripts/social-cards.sh

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOCIAL_DIR="$REPO_ROOT/assets/social"
mkdir -p "$SOCIAL_DIR"

# ─── Colors (from STYLE.md) ───
BG="#FFFFFF"
BG_LIGHT="#FAFAFA"
BORDER="#E0E0E0"
TEXT="#000000"
TEXT_DIM="#555555"
MUTED="#AAAAAA"
BLUE="#0055FF"
RED="#FF3333"
AMBER="#FFAA00"
GREEN="#00AA44"

# ═══════════════════════════════════════════
#  Card 1: Hero Card (link preview / OG image)
# ═══════════════════════════════════════════

generate_hero_card() {
  local out="$SOCIAL_DIR/hero-card.svg"

  cat > "$out" <<SVGHERO
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="675" viewBox="0 0 1200 675">
  <defs>
    <style>
      @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;700&amp;family=IBM+Plex+Sans:wght@400;600;700&amp;display=swap');
    </style>
  </defs>

  <!-- White background -->
  <rect width="1200" height="675" fill="$BG" />

  <!-- Top accent stripe -->
  <rect width="1200" height="4" fill="$BLUE" />

  <!-- GOAL.md headline -->
  <text x="48" y="160" font-family="'IBM Plex Sans', sans-serif" font-weight="700" font-size="88" letter-spacing="-0.03em" fill="$BLUE">GOAL.md</text>

  <!-- Tagline -->
  <text x="48" y="218" font-family="'IBM Plex Sans', sans-serif" font-weight="700" font-size="32" letter-spacing="-0.03em" fill="$TEXT">give it a number. go to sleep.</text>

  <!-- Subtitle -->
  <text x="48" y="264" font-family="'IBM Plex Sans', sans-serif" font-weight="400" font-size="22" fill="$TEXT_DIM">A fitness function for autonomous coding agents</text>

  <!-- Terminal box -->
  <rect x="48" y="310" width="1104" height="120" rx="16" fill="$BG_LIGHT" stroke="$BORDER" stroke-width="1.5" />

  <!-- Terminal dots -->
  <circle cx="76" cy="342" r="5" fill="$RED" opacity="0.8" />
  <circle cx="94" cy="342" r="5" fill="$AMBER" opacity="0.8" />
  <circle cx="112" cy="342" r="5" fill="$GREEN" opacity="0.8" />

  <!-- Terminal command -->
  <text x="76" y="400" font-family="'IBM Plex Mono', monospace" font-weight="400" font-size="20" fill="$TEXT_DIM">
    <tspan fill="$BLUE">\$ </tspan>claude "Read goal-md and write me a GOAL.md"</text>

  <!-- Bottom branding -->
  <text x="48" y="620" font-family="'IBM Plex Mono', monospace" font-weight="400" font-size="16" fill="$MUTED">github.com/jmilinovich/goal-md</text>

</svg>
SVGHERO

  echo "  Generated: $out"
}

# ═══════════════════════════════════════════
#  Card 2: Score Card (score demonstration)
# ═══════════════════════════════════════════

generate_score_card() {
  local out="$SOCIAL_DIR/score-card.svg"

  cat > "$out" <<SVGSCORE
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="675" viewBox="0 0 1200 675">
  <defs>
    <style>
      @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;700&amp;family=IBM+Plex+Sans:wght@400;600;700&amp;display=swap');
    </style>
  </defs>

  <!-- White background -->
  <rect width="1200" height="675" fill="$BG" />

  <!-- Top accent stripe -->
  <rect width="1200" height="4" fill="$BLUE" />

  <!-- GOAL.md brand mark top-right -->
  <text x="1152" y="60" text-anchor="end" font-family="'IBM Plex Sans', sans-serif" font-weight="700" font-size="28" letter-spacing="-0.03em" fill="$BLUE">GOAL.md</text>

  <!-- Score climbing display -->
  <!-- Old score -->
  <text x="200" y="320" text-anchor="middle" font-family="'IBM Plex Mono', monospace" font-weight="700" font-size="160" fill="$RED">47</text>
  <text x="200" y="360" text-anchor="middle" font-family="'IBM Plex Mono', monospace" font-weight="400" font-size="20" fill="$MUTED">before</text>

  <!-- Arrow -->
  <line x1="360" y1="270" x2="520" y2="270" stroke="$BORDER" stroke-width="3" />
  <polygon points="520,255 550,270 520,285" fill="$BORDER" />

  <!-- New score -->
  <text x="740" y="320" text-anchor="middle" font-family="'IBM Plex Mono', monospace" font-weight="700" font-size="160" fill="$GREEN">83</text>
  <text x="740" y="360" text-anchor="middle" font-family="'IBM Plex Mono', monospace" font-weight="400" font-size="20" fill="$MUTED">after</text>

  <!-- Delta badge -->
  <rect x="900" y="235" width="120" height="48" rx="24" fill="$GREEN" />
  <text x="960" y="266" text-anchor="middle" font-family="'IBM Plex Mono', monospace" font-weight="700" font-size="22" fill="$BG">+36</text>

  <!-- Headline -->
  <text x="600" y="460" text-anchor="middle" font-family="'IBM Plex Sans', sans-serif" font-weight="700" font-size="36" letter-spacing="-0.03em" fill="$BLUE">12 atomic commits while you slept</text>

  <!-- Tagline -->
  <text x="600" y="510" text-anchor="middle" font-family="'IBM Plex Sans', sans-serif" font-weight="400" font-size="22" fill="$TEXT_DIM">give it a number. go to sleep.</text>

  <!-- Bottom branding -->
  <text x="48" y="640" font-family="'IBM Plex Mono', monospace" font-weight="400" font-size="16" fill="$MUTED">github.com/jmilinovich/goal-md</text>

</svg>
SVGSCORE

  echo "  Generated: $out"
}

# ═══════════════════════════════════════════
#  Main
# ═══════════════════════════════════════════

echo ""
echo "Generating social cards..."
echo ""

generate_hero_card
generate_score_card

# Convert to PNG if rsvg-convert is available
if command -v rsvg-convert &>/dev/null; then
  echo ""
  echo "Converting to PNG (1200x675)..."
  rsvg-convert -w 1200 -h 675 "$SOCIAL_DIR/hero-card.svg" -o "$SOCIAL_DIR/hero-card.png"
  echo "  Generated: $SOCIAL_DIR/hero-card.png"
  rsvg-convert -w 1200 -h 675 "$SOCIAL_DIR/score-card.svg" -o "$SOCIAL_DIR/score-card.png"
  echo "  Generated: $SOCIAL_DIR/score-card.png"
else
  echo ""
  echo "  rsvg-convert not found — SVGs generated but PNGs skipped."
  echo "  Install librsvg (brew install librsvg) for PNG output."
fi

echo ""
echo "Done."
