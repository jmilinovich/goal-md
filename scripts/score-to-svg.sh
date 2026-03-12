#!/bin/bash
# Renders score.sh output as an SVG terminal card for the README.
# Usage: ./scripts/score-to-svg.sh > assets/score.svg

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Capture the score output
output=$("$REPO_ROOT/scripts/score.sh" 2>/dev/null)

# Escape for XML
output=$(echo "$output" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

# Count lines for height calculation
line_count=$(echo "$output" | wc -l | tr -d ' ')
height=$(( (line_count + 3) * 20 + 40 ))

# Map check marks and X marks to colors
# ✓ = green, ◐ = yellow, ✗ = red
colorize() {
  echo "$1" \
    | sed 's/✓/<tspan fill="#4ade80">✓<\/tspan>/g' \
    | sed 's/◐/<tspan fill="#facc15">◐<\/tspan>/g' \
    | sed 's/✗/<tspan fill="#f87171">✗<\/tspan>/g'
}

colored_output=$(colorize "$output")

# Build SVG
cat <<SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" width="580" height="$height" viewBox="0 0 580 $height">
  <style>
    .bg { fill: #1e1e2e; rx: 12; }
    .title-bar { fill: #313244; }
    .dot-red { fill: #f38ba8; }
    .dot-yellow { fill: #f9e2af; }
    .dot-green { fill: #a6e3a1; }
    .text { fill: #cdd6f4; font-family: 'SF Mono', 'Fira Code', 'JetBrains Mono', monospace; font-size: 13px; }
    .header { fill: #89b4fa; font-family: 'SF Mono', 'Fira Code', 'JetBrains Mono', monospace; font-size: 13px; font-weight: bold; }
  </style>
  <rect class="bg" width="580" height="$height" />
  <rect class="title-bar" x="0" y="0" width="580" height="36" rx="12" />
  <rect class="title-bar" x="0" y="24" width="580" height="12" />
  <circle class="dot-red" cx="20" cy="18" r="6" />
  <circle class="dot-yellow" cx="40" cy="18" r="6" />
  <circle class="dot-green" cx="60" cy="18" r="6" />
  <text class="header" x="290" y="22" text-anchor="middle">./scripts/score.sh</text>
  <text class="text" x="16" y="62" xml:space="preserve">
SVGEOF

y=62
while IFS= read -r line; do
  if [[ -z "$line" ]]; then
    y=$((y + 20))
    continue
  fi
  colored_line=$(colorize "$line")
  echo "    <tspan x=\"16\" dy=\"20\">$colored_line</tspan>"
  y=$((y + 20))
done <<< "$output"

cat <<SVGEOF2
  </text>
</svg>
SVGEOF2
