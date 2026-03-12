#!/bin/bash
# Fitness function for the goal-md repo.
# Measures spec quality: is the pattern well-defined, consistent, and demonstrated?
#
# Usage: ./scripts/score.sh [--json]

set -euo pipefail
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

file_mentions() {
  grep -qc "$1" "$2" 2>/dev/null && echo "yes" || echo "no"
}

# ─── Component 1: Spec Completeness (40 pts) ───
# Does the README define all five elements clearly?

five_elements=("Fitness function" "Improvement loop" "Action catalog" "Operating mode" "Constraints")
elements_found=0
for el in "${five_elements[@]}"; do
  if grep -qi "$el" "$REPO_ROOT/README.md" 2>/dev/null; then
    elements_found=$((elements_found + 1))
  fi
done

if [[ $elements_found -eq 5 ]]; then
  check 15 "readme-five-elements" "pass"
elif [[ $elements_found -ge 3 ]]; then
  check 15 "readme-five-elements" "partial"
else
  check 15 "readme-five-elements" "fail"
fi

# Does the README have a prior art section?
if grep -q "## Prior art" "$REPO_ROOT/README.md" 2>/dev/null; then
  check 5 "readme-prior-art" "pass"
else
  check 5 "readme-prior-art" "fail"
fi

# Does the README have a "when you need" section?
if grep -q "## When you need" "$REPO_ROOT/README.md" 2>/dev/null; then
  check 5 "readme-when-to-use" "pass"
else
  check 5 "readme-when-to-use" "fail"
fi

# Does the README reference autoresearch lineage?
if grep -q "autoresearch" "$REPO_ROOT/README.md" 2>/dev/null; then
  check 5 "readme-lineage" "pass"
else
  check 5 "readme-lineage" "fail"
fi

# Does the README define the three metric mutability modes?
modes_found=0
for mode in "Locked" "Split" "Open"; do
  if grep -q "$mode" "$REPO_ROOT/README.md" 2>/dev/null; then
    modes_found=$((modes_found + 1))
  fi
done
if [[ $modes_found -eq 3 ]]; then
  check 5 "readme-mutability-modes" "pass"
else
  check 5 "readme-mutability-modes" "fail"
fi

# Does the README define the three operating modes?
op_modes_found=0
for mode in "Converge" "Continuous" "Supervised"; do
  if grep -q "$mode" "$REPO_ROOT/README.md" 2>/dev/null; then
    op_modes_found=$((op_modes_found + 1))
  fi
done
if [[ $op_modes_found -eq 3 ]]; then
  check 5 "readme-operating-modes" "pass"
else
  check 5 "readme-operating-modes" "fail"
fi

# ─── Component 2: Template Quality (25 pts) ───
# Does the template cover all five elements?

template="$REPO_ROOT/template/GOAL.md"
if [[ -f "$template" ]]; then
  check 5 "template-exists" "pass"

  tmpl_sections=0
  for section in "Fitness Function" "Improvement Loop" "Action Catalog" "Operating Mode" "Constraints"; do
    if grep -qi "$section" "$template" 2>/dev/null; then
      tmpl_sections=$((tmpl_sections + 1))
    fi
  done

  if [[ $tmpl_sections -eq 5 ]]; then
    check 10 "template-five-sections" "pass"
  elif [[ $tmpl_sections -ge 3 ]]; then
    check 10 "template-five-sections" "partial"
  else
    check 10 "template-five-sections" "fail"
  fi

  # Does template have a file map?
  if grep -qi "File Map" "$template" 2>/dev/null; then
    check 5 "template-file-map" "pass"
  else
    check 5 "template-file-map" "fail"
  fi

  # Does template have a stop report format?
  if grep -qi "When to Stop\|Stop.*report\|Starting score" "$template" 2>/dev/null; then
    check 5 "template-stop-report" "pass"
  else
    check 5 "template-stop-report" "fail"
  fi
else
  check 5 "template-exists" "fail"
  check 10 "template-five-sections" "fail"
  check 5 "template-file-map" "fail"
  check 5 "template-stop-report" "fail"
fi

# ─── Component 3: Example Coverage (25 pts) ───
# How many real examples exist and do they demonstrate different modes?

example_count=$(find "$REPO_ROOT/examples" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

if [[ $example_count -ge 3 ]]; then
  check 10 "example-count" "pass"
elif [[ $example_count -ge 2 ]]; then
  check 10 "example-count" "partial"
elif [[ $example_count -ge 1 ]]; then
  # 1 example = 3 pts (less than partial)
  details+=("{\"name\":\"example-count\",\"points\":3,\"max\":10,\"status\":\"minimal\"}")
  score=$((score + 3))
  max=$((max + 10))
else
  check 10 "example-count" "fail"
fi

# Do examples demonstrate different operating modes?
converge_example=false
continuous_example=false
checklist_example=false
for ex in "$REPO_ROOT/examples"/*.md; do
  [[ -f "$ex" ]] || continue
  grep -qi "converge\|stopping condition\|stop.*when\|when to stop" "$ex" 2>/dev/null && converge_example=true
  grep -qi "continuous\|never stop\|run forever" "$ex" 2>/dev/null && continuous_example=true
  grep -qi "criterion\|checklist\|definition of done" "$ex" 2>/dev/null && checklist_example=true
done

mode_variety=0
$converge_example && mode_variety=$((mode_variety + 1))
$continuous_example && mode_variety=$((mode_variety + 1))
$checklist_example && mode_variety=$((mode_variety + 1))

if [[ $mode_variety -ge 2 ]]; then
  check 10 "example-mode-variety" "pass"
elif [[ $mode_variety -ge 1 ]]; then
  check 10 "example-mode-variety" "partial"
else
  check 10 "example-mode-variety" "fail"
fi

# Do examples come from real projects (not synthetic)?
real_count=0
for ex in "$REPO_ROOT/examples"/*.md; do
  [[ -f "$ex" ]] || continue
  # Real examples tend to have specific tool commands, file paths, concrete details
  lines=$(wc -l < "$ex" | tr -d ' ')
  if [[ $lines -gt 30 ]]; then
    real_count=$((real_count + 1))
  fi
done
if [[ $real_count -ge 2 ]]; then
  check 5 "example-real-projects" "pass"
elif [[ $real_count -ge 1 ]]; then
  check 5 "example-real-projects" "partial"
else
  check 5 "example-real-projects" "fail"
fi

# ─── Component 4: Self-Consistency (10 pts) ───
# Does everything hang together?

# No broken internal links in README
broken_links=0
while IFS= read -r link; do
  target="$REPO_ROOT/$link"
  if [[ ! -f "$target" ]]; then
    broken_links=$((broken_links + 1))
  fi
done < <(sed -n 's/.*](\([^)]*\)).*/\1/p' "$REPO_ROOT/README.md" 2>/dev/null | grep -v '^http' || true)

if [[ $broken_links -eq 0 ]]; then
  check 5 "no-broken-links" "pass"
else
  check 5 "no-broken-links" "fail"
fi

# Does this repo have its own GOAL.md? (dogfooding)
if [[ -f "$REPO_ROOT/GOAL.md" ]]; then
  check 5 "dogfood-goal-md" "pass"
else
  check 5 "dogfood-goal-md" "fail"
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
  echo "═══════════════════════════════════"
  echo "  goal-md spec quality: $score / $max ($pct%)"
  echo "═══════════════════════════════════"
  echo ""
  printf "  %-30s %s\n" "CHECK" "RESULT"
  printf "  %-30s %s\n" "─────" "──────"
  for d in "${details[@]}"; do
    name=$(echo "$d" | sed 's/.*"name":"\([^"]*\)".*/\1/')
    pts=$(echo "$d" | sed 's/.*"points":\([0-9]*\).*/\1/')
    mx=$(echo "$d" | sed 's/.*"max":\([0-9]*\).*/\1/')
    status=$(echo "$d" | sed 's/.*"status":"\([^"]*\)".*/\1/')
    case $status in
      pass)    icon="✓" ;;
      partial) icon="◐" ;;
      fail)    icon="✗" ;;
      *)       icon="◐" ;;
    esac
    printf "  %-30s %s %s/%s\n" "$name" "$icon" "$pts" "$mx"
  done
  echo ""
fi
