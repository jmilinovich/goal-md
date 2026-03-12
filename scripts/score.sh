#!/bin/bash
# Fitness function for the goal-md repo.
# Measures: is this pattern clear, credible, alive, and adoptable?
#
# Usage: ./scripts/score.sh [--json]

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON_MODE=false
[[ "${1:-}" == "--json" ]] && JSON_MODE=true

# ─── Helpers ───

score=0
max=0
details=()

check() {
  local points=$1 name=$2 result=$3
  max=$((max + points))
  if [[ "$result" == "pass" ]]; then
    score=$((score + points))
    details+=("{\"name\":\"$name\",\"points\":$points,\"max\":$points,\"status\":\"pass\"}")
  elif [[ "$result" == "partial" ]]; then
    local partial=$((points / 2))
    score=$((score + partial))
    details+=("{\"name\":\"$name\",\"points\":$partial,\"max\":$points,\"status\":\"partial\"}")
  else
    details+=("{\"name\":\"$name\",\"points\":0,\"max\":$points,\"status\":\"fail\"}")
  fi
}

# ─── Component 1: Spec Clarity (25 pts) ───
# Does the README define the pattern clearly?

five_elements=("Fitness function" "Improvement loop" "Action catalog" "Operating mode" "Constraints")
elements_found=0
for el in "${five_elements[@]}"; do
  grep -qi "$el" "$REPO_ROOT/README.md" 2>/dev/null && elements_found=$((elements_found + 1))
done

if [[ $elements_found -eq 5 ]]; then
  check 10 "five-elements-defined" "pass"
elif [[ $elements_found -ge 3 ]]; then
  check 10 "five-elements-defined" "partial"
else
  check 10 "five-elements-defined" "fail"
fi

# Prior art and lineage
if grep -q "## Prior art" "$REPO_ROOT/README.md" 2>/dev/null; then
  check 5 "prior-art-section" "pass"
else
  check 5 "prior-art-section" "fail"
fi

# Mutability + operating modes defined
modes_found=0
for mode in "Locked" "Split" "Open" "Converge" "Continuous" "Supervised"; do
  grep -q "$mode" "$REPO_ROOT/README.md" 2>/dev/null && modes_found=$((modes_found + 1))
done
if [[ $modes_found -eq 6 ]]; then
  check 5 "all-modes-defined" "pass"
elif [[ $modes_found -ge 4 ]]; then
  check 5 "all-modes-defined" "partial"
else
  check 5 "all-modes-defined" "fail"
fi

# When to use / when not to
if grep -q "## When you need" "$REPO_ROOT/README.md" 2>/dev/null; then
  check 5 "when-to-use" "pass"
else
  check 5 "when-to-use" "fail"
fi

# ─── Component 2: Resonance (30 pts) ───
# Does it feel real? Can you picture it working?

readme="$REPO_ROOT/README.md"

# Has images or screenshots (people need to SEE it)
img_in_readme=$(grep -c '!\[' "$readme" 2>/dev/null)
[[ -z "$img_in_readme" ]] && img_in_readme=0
img_in_assets=$(find "$REPO_ROOT/assets" -name "*.png" -o -name "*.gif" -o -name "*.jpg" -o -name "*.svg" 2>/dev/null | wc -l | tr -d ' ')
img_count=$((img_in_readme + img_in_assets))

if [[ $img_count -ge 3 ]]; then
  check 10 "has-visuals" "pass"
elif [[ $img_count -ge 1 ]]; then
  check 10 "has-visuals" "partial"
else
  check 10 "has-visuals" "fail"
fi

# Has an anchor story — a concrete narrative example that pulls through
# (detected by: a named project example woven into the prose, not just a link to examples/)
story_signals=0
# First-person voice ("I left it running", "I wrote", "we built", etc.)
grep -qi "I left\|I wrote\|I ran\|I woke\|we built\|we ran\|overnight\|next morning" "$readme" 2>/dev/null && story_signals=$((story_signals + 1))
# Concrete before/after numbers in prose (not just tables)
grep -qi "[0-9].*→.*[0-9]\|went from.*to\|started at.*ended" "$readme" 2>/dev/null && story_signals=$((story_signals + 1))
# Named project used as running example in the prose (not just in examples table)
grep -qi "browser-grid\|autoresearch" "$readme" 2>/dev/null && story_signals=$((story_signals + 1))

if [[ $story_signals -ge 3 ]]; then
  check 10 "anchor-story" "pass"
elif [[ $story_signals -ge 2 ]]; then
  check 10 "anchor-story" "partial"
else
  check 10 "anchor-story" "fail"
fi

# Has a terminal/score output block people can imagine running
if grep -qi '═\|score.*quality\|✓\|✗' "$readme" 2>/dev/null; then
  check 5 "show-the-score" "pass"
else
  check 5 "show-the-score" "fail"
fi

# Voice — not dry spec language. Has personality.
voice_signals=0
grep -qi "beautiful\|love\|shit\|damn\|wild\|honestly\|the thing is\|here's the trick\|the magic" "$readme" 2>/dev/null && voice_signals=$((voice_signals + 1))
# Short punchy sentences (detect sentences under 8 words that aren't headers)
short_punchy=$(grep -v '^#\|^|\|^$\|^-\|^```' "$readme" 2>/dev/null | awk 'NF>0 && NF<8' | wc -l | tr -d ' ')
[[ $short_punchy -ge 5 ]] && voice_signals=$((voice_signals + 1))
# Questions to the reader
grep -c '?' "$readme" 2>/dev/null | awk '{exit ($1 >= 3 ? 0 : 1)}' && voice_signals=$((voice_signals + 1))

if [[ $voice_signals -ge 3 ]]; then
  check 5 "has-voice" "pass"
elif [[ $voice_signals -ge 2 ]]; then
  check 5 "has-voice" "partial"
else
  check 5 "has-voice" "fail"
fi

# ─── Component 3: Examples (25 pts) ───
# Real examples that show different facets of the pattern

example_count=$(find "$REPO_ROOT/examples" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

if [[ $example_count -ge 3 ]]; then
  check 10 "example-count" "pass"
elif [[ $example_count -ge 2 ]]; then
  check 10 "example-count" "partial"
elif [[ $example_count -ge 1 ]]; then
  details+=("{\"name\":\"example-count\",\"points\":3,\"max\":10,\"status\":\"minimal\"}")
  score=$((score + 3))
  max=$((max + 10))
else
  check 10 "example-count" "fail"
fi

# Mode variety across examples
converge_ex=false
continuous_ex=false
checklist_ex=false
for ex in "$REPO_ROOT/examples"/*.md; do
  [[ -f "$ex" ]] || continue
  grep -qi "converge\|stopping condition\|stop.*when\|when to stop" "$ex" 2>/dev/null && converge_ex=true
  grep -qi "continuous\|never stop\|run forever\|NEVER STOP" "$ex" 2>/dev/null && continuous_ex=true
  grep -qi "criterion\|checklist\|definition of done" "$ex" 2>/dev/null && checklist_ex=true
done

mode_variety=0
$converge_ex && mode_variety=$((mode_variety + 1))
$continuous_ex && mode_variety=$((mode_variety + 1))
$checklist_ex && mode_variety=$((mode_variety + 1))

if [[ $mode_variety -ge 2 ]]; then
  check 10 "example-mode-variety" "pass"
elif [[ $mode_variety -ge 1 ]]; then
  check 10 "example-mode-variety" "partial"
else
  check 10 "example-mode-variety" "fail"
fi

# Real projects (30+ lines of substance)
real_count=0
for ex in "$REPO_ROOT/examples"/*.md; do
  [[ -f "$ex" ]] || continue
  lines=$(wc -l < "$ex" | tr -d ' ')
  [[ $lines -gt 30 ]] && real_count=$((real_count + 1))
done
if [[ $real_count -ge 2 ]]; then
  check 5 "real-projects" "pass"
elif [[ $real_count -ge 1 ]]; then
  check 5 "real-projects" "partial"
else
  check 5 "real-projects" "fail"
fi

# ─── Component 4: Integrity (20 pts) ───
# Does it all hang together? Does it practice what it preaches?

# No broken internal links
broken_links=0
while IFS= read -r link; do
  target="$REPO_ROOT/$link"
  [[ ! -f "$target" ]] && broken_links=$((broken_links + 1))
done < <(sed -n 's/.*](\([^)]*\)).*/\1/p' "$REPO_ROOT/README.md" 2>/dev/null | grep -v '^http' || true)

if [[ $broken_links -eq 0 ]]; then
  check 5 "no-broken-links" "pass"
else
  check 5 "no-broken-links" "fail"
fi

# Dogfoods its own pattern
if [[ -f "$REPO_ROOT/GOAL.md" ]]; then
  check 5 "dogfood-goal-md" "pass"
else
  check 5 "dogfood-goal-md" "fail"
fi

# Template exists and covers all sections
template="$REPO_ROOT/template/GOAL.md"
if [[ -f "$template" ]]; then
  tmpl_sections=0
  for section in "Fitness Function" "Improvement Loop" "Action Catalog" "Operating Mode" "Constraints"; do
    grep -qi "$section" "$template" 2>/dev/null && tmpl_sections=$((tmpl_sections + 1))
  done
  if [[ $tmpl_sections -eq 5 ]]; then
    check 5 "template-complete" "pass"
  elif [[ $tmpl_sections -ge 3 ]]; then
    check 5 "template-complete" "partial"
  else
    check 5 "template-complete" "fail"
  fi
else
  check 5 "template-complete" "fail"
fi

# Score script itself is documented (this file has a usage comment)
if head -5 "$0" | grep -qi "usage\|fitness"; then
  check 5 "score-documented" "pass"
else
  check 5 "score-documented" "fail"
fi

# ─── Output ───

pct=$(( (score * 100) / max ))

if $JSON_MODE; then
  echo "{"
  echo "  \"score\": $score,"
  echo "  \"max\": $max,"
  echo "  \"pct\": $pct,"
  echo "  \"details\": [$(IFS=,; echo "${details[*]}")]"
  echo "}"
else
  echo ""
  echo "═══════════════════════════════════════════"
  echo "  goal-md: $score / $max ($pct%)"
  echo "═══════════════════════════════════════════"
  echo ""
  echo "  CLARITY (is the pattern well-defined?)"
  for d in "${details[@]}"; do
    name=$(echo "$d" | sed 's/.*"name":"\([^"]*\)".*/\1/')
    case "$name" in five-elements*|prior-art*|all-modes*|when-to-use*)
      pts=$(echo "$d" | sed 's/.*"points":\([0-9]*\).*/\1/')
      mx=$(echo "$d" | sed 's/.*"max":\([0-9]*\).*/\1/')
      status=$(echo "$d" | sed 's/.*"status":"\([^"]*\)".*/\1/')
      case $status in pass) icon="✓";; partial) icon="◐";; *) icon="✗";; esac
      printf "    %-28s %s %s/%s\n" "$name" "$icon" "$pts" "$mx"
    ;; esac
  done
  echo ""
  echo "  RESONANCE (would someone feel something?)"
  for d in "${details[@]}"; do
    name=$(echo "$d" | sed 's/.*"name":"\([^"]*\)".*/\1/')
    case "$name" in has-visuals|anchor-story|show-the-score|has-voice)
      pts=$(echo "$d" | sed 's/.*"points":\([0-9]*\).*/\1/')
      mx=$(echo "$d" | sed 's/.*"max":\([0-9]*\).*/\1/')
      status=$(echo "$d" | sed 's/.*"status":"\([^"]*\)".*/\1/')
      case $status in pass) icon="✓";; partial) icon="◐";; *) icon="✗";; esac
      printf "    %-28s %s %s/%s\n" "$name" "$icon" "$pts" "$mx"
    ;; esac
  done
  echo ""
  echo "  EXAMPLES (does it show the pattern working?)"
  for d in "${details[@]}"; do
    name=$(echo "$d" | sed 's/.*"name":"\([^"]*\)".*/\1/')
    case "$name" in example-*|real-*)
      pts=$(echo "$d" | sed 's/.*"points":\([0-9]*\).*/\1/')
      mx=$(echo "$d" | sed 's/.*"max":\([0-9]*\).*/\1/')
      status=$(echo "$d" | sed 's/.*"status":"\([^"]*\)".*/\1/')
      case $status in pass) icon="✓";; partial|minimal) icon="◐";; *) icon="✗";; esac
      printf "    %-28s %s %s/%s\n" "$name" "$icon" "$pts" "$mx"
    ;; esac
  done
  echo ""
  echo "  INTEGRITY (does it practice what it preaches?)"
  for d in "${details[@]}"; do
    name=$(echo "$d" | sed 's/.*"name":"\([^"]*\)".*/\1/')
    case "$name" in no-broken*|dogfood*|template-*|score-*)
      pts=$(echo "$d" | sed 's/.*"points":\([0-9]*\).*/\1/')
      mx=$(echo "$d" | sed 's/.*"max":\([0-9]*\).*/\1/')
      status=$(echo "$d" | sed 's/.*"status":"\([^"]*\)".*/\1/')
      case $status in pass) icon="✓";; partial) icon="◐";; *) icon="✗";; esac
      printf "    %-28s %s %s/%s\n" "$name" "$icon" "$pts" "$mx"
    ;; esac
  done
  echo ""
fi
