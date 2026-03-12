#!/bin/bash
# Fitness function for the goal-md repo.
# Measures: is this pattern clear, credible, alive, adoptable, and seen?
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
feedback=()

check() {
  local points=$1 name=$2 result=$3 hint="${4:-}"
  max=$((max + points))
  if [[ "$result" == "pass" ]]; then
    score=$((score + points))
    details+=("{\"name\":\"$name\",\"points\":$points,\"max\":$points,\"status\":\"pass\"}")
  elif [[ "$result" == "partial" ]]; then
    local partial=$((points / 2))
    score=$((score + partial))
    details+=("{\"name\":\"$name\",\"points\":$partial,\"max\":$points,\"status\":\"partial\"}")
    [[ -n "$hint" ]] && feedback+=("$name (partial): $hint")
  else
    details+=("{\"name\":\"$name\",\"points\":0,\"max\":$points,\"status\":\"fail\"}")
    [[ -n "$hint" ]] && feedback+=("$name: $hint")
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
  check 10 "five-elements-defined" "partial" "README mentions only $elements_found/5 elements — add missing ones"
else
  check 10 "five-elements-defined" "fail" "README must mention all 5 elements: fitness function, improvement loop, action catalog, operating mode, constraints"
fi

# Prior art and lineage
if grep -q "## Prior art" "$REPO_ROOT/README.md" 2>/dev/null || \
   grep -q "Eval-Driven Development" "$REPO_ROOT/README.md" 2>/dev/null; then
  check 5 "prior-art-section" "pass"
else
  check 5 "prior-art-section" "fail" "Add a prior art section referencing Eval-Driven Development or autoresearch lineage"
fi

# Mutability + operating modes defined
modes_found=0
for mode in "Locked" "Split" "Open" "Converge" "Continuous" "Supervised"; do
  grep -q "$mode" "$REPO_ROOT/README.md" 2>/dev/null && modes_found=$((modes_found + 1))
done
if [[ $modes_found -eq 6 ]]; then
  check 5 "all-modes-defined" "pass"
elif [[ $modes_found -ge 4 ]]; then
  check 5 "all-modes-defined" "partial" "README defines $modes_found/6 modes — add Locked, Split, Open, Converge, Continuous, Supervised"
else
  check 5 "all-modes-defined" "fail" "README must define all 6 modes: Locked, Split, Open, Converge, Continuous, Supervised"
fi

# When to use / when not to
if grep -q "## When you need" "$REPO_ROOT/README.md" 2>/dev/null; then
  check 5 "when-to-use" "pass"
else
  check 5 "when-to-use" "fail" "Add a '## When you need' section explaining when GOAL.md is appropriate"
fi

# ─── Component 2: Resonance (30 pts) ───
# Does it feel real? Can you picture it working?

readme="$REPO_ROOT/README.md"

# Has images or screenshots (people need to SEE it)
img_in_readme=$(grep -c '!\[' "$readme" 2>/dev/null)
[[ -z "$img_in_readme" ]] && img_in_readme=0
img_in_assets=$(find "$REPO_ROOT/assets" -name "*.png" -o -name "*.gif" -o -name "*.jpg" -o -name "*.svg" 2>/dev/null | wc -l | tr -d ' ')
img_count=$img_in_assets

if [[ $img_count -ge 3 ]]; then
  check 10 "has-visuals" "pass"
elif [[ $img_count -ge 1 ]]; then
  check 10 "has-visuals" "partial" "Only $img_count image(s) in assets/ — add 3+ (screenshots, diagrams, SVGs)"
else
  check 10 "has-visuals" "fail" "Add 3+ images to assets/ (screenshots, diagrams, SVGs)"
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
  check 10 "anchor-story" "partial" "Anchor story needs all 3: first-person voice, before/after numbers, named project"
else
  check 10 "anchor-story" "fail" "Add a first-person narrative with concrete numbers and a named project example"
fi

# Has a terminal/score output block people can imagine running
if grep -qi '═\|score.*quality\|✓\|✗' "$readme" 2>/dev/null; then
  check 5 "show-the-score" "pass"
else
  check 5 "show-the-score" "fail" "Add a terminal output block showing what score.sh looks like when you run it"
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
  check 5 "has-voice" "partial" "Add more personality — short punchy sentences, questions to the reader, vivid language"
else
  check 5 "has-voice" "fail" "README needs personality — short sentences, questions, words with energy"
fi

# ─── Component 3: Examples (25 pts) ───
# Real examples that show different facets of the pattern

example_count=$(find "$REPO_ROOT/examples" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

if [[ $example_count -ge 3 ]]; then
  check 10 "example-count" "pass"
elif [[ $example_count -ge 2 ]]; then
  check 10 "example-count" "partial" "Only $example_count examples — add a 3rd covering a different domain"
elif [[ $example_count -ge 1 ]]; then
  details+=("{\"name\":\"example-count\",\"points\":3,\"max\":10,\"status\":\"minimal\"}")
  score=$((score + 3))
  max=$((max + 10))
else
  check 10 "example-count" "fail" "Add example GOAL.md files in examples/ — need 3+ for full marks"
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
  check 10 "example-mode-variety" "partial" "Examples cover only 1 mode — add converge, continuous, or checklist variety"
else
  check 10 "example-mode-variety" "fail" "Examples need mode variety — include converge, continuous, and checklist styles"
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
  check 5 "real-projects" "partial" "Only $real_count example with 30+ lines — add another substantial example"
else
  check 5 "real-projects" "fail" "Examples need substance — at least 2 should be 30+ lines with real detail"
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
  check 5 "no-broken-links" "fail" "$broken_links broken internal link(s) in README — fix or remove them"
fi

# Dogfoods its own pattern
if [[ -f "$REPO_ROOT/GOAL.md" ]]; then
  check 5 "dogfood-goal-md" "pass"
else
  check 5 "dogfood-goal-md" "fail" "Add a GOAL.md to this repo — dogfood the pattern"
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
    check 5 "template-complete" "partial" "Template covers $tmpl_sections/5 sections — add missing ones"
  else
    check 5 "template-complete" "fail" "Template must include all 5 sections: Fitness Function, Improvement Loop, Action Catalog, Operating Mode, Constraints"
  fi
else
  check 5 "template-complete" "fail" "Add template/GOAL.md with all 5 required sections"
fi

# Score script itself is documented (this file has a usage comment)
if head -5 "$0" | grep -qi "usage\|fitness"; then
  check 5 "score-documented" "pass"
else
  check 5 "score-documented" "fail" "Add a usage or fitness comment in the first 5 lines of score.sh"
fi

# ─── Component 5: Distribution (30 pts) ───
# Can someone discover this pattern outside GitHub?

# Video explainer — quality checks, not just existence (~10 pts)
# Must have: rendered mp4, 4+ scene files, real audio (not generated),
# consistent style system, render script, and scene transitions
video_signals=0

# 1. Rendered output exists
[[ -f "$REPO_ROOT/video/out/video.mp4" ]] && video_signals=$((video_signals + 1))

# 2. 4+ scene files (real narrative structure, not just a scaffold)
if [[ -d "$REPO_ROOT/video/src/scenes" ]]; then
  scene_count=$(find "$REPO_ROOT/video/src/scenes" -name "Scene*.tsx" 2>/dev/null | wc -l | tr -d ' ')
  [[ $scene_count -ge 4 ]] && video_signals=$((video_signals + 1))
fi

# 3. Uses a real audio file (not a generated beat script)
# Check: public/ has a real audio file AND no generate-beat script
has_real_audio=false
if [[ -d "$REPO_ROOT/video/public" ]]; then
  audio_files=$(find "$REPO_ROOT/video/public" -name "*.mp3" -o -name "*.wav" -o -name "*.m4a" 2>/dev/null | wc -l | tr -d ' ')
  # Penalize if a generate-beat script exists (means audio is procedural)
  if [[ $audio_files -ge 1 ]] && ! [[ -f "$REPO_ROOT/video/scripts/generate-beat.mjs" ]]; then
    has_real_audio=true
    video_signals=$((video_signals + 1))
  fi
fi

# 4. Consistent design system (styles.ts exports colors + typography + spacing)
if [[ -f "$REPO_ROOT/video/src/styles.ts" ]]; then
  style_signals=0
  grep -q "IBM Plex\|ibm-plex" "$REPO_ROOT/video/src/styles.ts" 2>/dev/null && style_signals=$((style_signals + 1))
  grep -q "bg.*#\|background" "$REPO_ROOT/video/src/styles.ts" 2>/dev/null && style_signals=$((style_signals + 1))
  grep -q "FRAMES_PER_BEAT\|BPM\|bpm" "$REPO_ROOT/video/src/styles.ts" 2>/dev/null && style_signals=$((style_signals + 1))
  [[ $style_signals -ge 3 ]] && video_signals=$((video_signals + 1))
fi

# 5. Has render script
[[ -f "$REPO_ROOT/video/package.json" ]] && grep -q '"render"\|"build"' "$REPO_ROOT/video/package.json" 2>/dev/null && video_signals=$((video_signals + 1))

# 6. Scene transitions or crossfades (grep for Sequence + interpolate patterns suggesting transitions)
if grep -rq "crossfade\|fadeIn\|fadeOut\|transition" "$REPO_ROOT/video/src/" 2>/dev/null; then
  video_signals=$((video_signals + 1))
fi

# Infrastructure signals get you to partial (5/10).
# Full marks require human quality sign-off in video/QUALITY.md
# (because grep can't tell good video from AI slop)
has_quality_signoff=false
if [[ -f "$REPO_ROOT/video/QUALITY.md" ]]; then
  # Must contain "APPROVED" and review of all 7 criteria
  grep -q "APPROVED" "$REPO_ROOT/video/QUALITY.md" 2>/dev/null && has_quality_signoff=true
fi

if $has_quality_signoff && [[ $video_signals -ge 4 ]]; then
  check 10 "video-explainer" "pass"
elif [[ $video_signals -ge 3 ]]; then
  check 10 "video-explainer" "partial" "Video infra exists but needs QUALITY.md with APPROVED sign-off for full marks"
else
  check 10 "video-explainer" "fail" "Add a Remotion video explainer in video/ with 4+ scenes, real audio, and render script"
fi

# Twitter-optimized social images (~10 pts)
# Check: assets/social/ has at least 2 PNG images
social_dir="$REPO_ROOT/assets/social"
social_count=0
if [[ -d "$social_dir" ]]; then
  social_count=$(find "$social_dir" -name "*.png" -o -name "*.jpg" 2>/dev/null | wc -l | tr -d ' ')
fi

# Check: a generation script exists (not hand-designed)
has_gen_script=false
# Look for any script that could generate social images
for f in "$REPO_ROOT/scripts/generate-social"* "$REPO_ROOT/scripts/social"*; do
  [[ -f "$f" ]] && has_gen_script=true && break
done
# Also check if video/package.json has a still/thumbnail script
[[ -f "$REPO_ROOT/video/package.json" ]] && grep -q '"still"\|"thumbnail"\|"social"' "$REPO_ROOT/video/package.json" 2>/dev/null && has_gen_script=true

if [[ $social_count -ge 2 ]] && $has_gen_script; then
  check 10 "social-images" "pass"
elif [[ $social_count -ge 1 ]] || $has_gen_script; then
  check 10 "social-images" "partial" "Need 2+ social images in assets/social/ AND a generation script"
else
  check 10 "social-images" "fail" "Add Twitter-optimized images (1200x675) in assets/social/ with a generation script"
fi

# Blog-ready assets and metadata (~10 pts)
blog_signals=0
# Blog post draft exists
[[ -f "$REPO_ROOT/docs/blog-post.md" ]] && blog_signals=$((blog_signals + 1))
# Social cards referenced in README (so GitHub renders good OG previews)
grep -qi 'assets/social' "$REPO_ROOT/README.md" 2>/dev/null && blog_signals=$((blog_signals + 1))
# Video is hostable (rendered mp4 exists or a YouTube/external link in README)
if [[ -f "$REPO_ROOT/video/out/video.mp4" ]] || grep -qi 'youtube.com\|youtu.be\|vimeo.com' "$REPO_ROOT/README.md" 2>/dev/null; then
  blog_signals=$((blog_signals + 1))
fi

if [[ $blog_signals -ge 3 ]]; then
  check 10 "blog-ready" "pass"
elif [[ $blog_signals -ge 2 ]]; then
  check 10 "blog-ready" "partial" "Need all 3: blog post draft, social cards in README, hostable video"
elif [[ $blog_signals -ge 1 ]]; then
  details+=("{\"name\":\"blog-ready\",\"points\":3,\"max\":10,\"status\":\"minimal\"}")
  score=$((score + 3))
  max=$((max + 10))
  feedback+=("blog-ready (minimal): Need docs/blog-post.md, social card refs in README, and hostable video")
else
  check 10 "blog-ready" "fail" "Add docs/blog-post.md, reference social cards in README, render or link a video"
fi

# ─── Output ───

pct=$(( (score * 100) / max ))

if $JSON_MODE; then
  # Build feedback JSON array
  fb_json=""
  for fb in "${feedback[@]+"${feedback[@]}"}"; do
    [[ -z "$fb" ]] && continue
    escaped=$(echo "$fb" | sed 's/"/\\"/g')
    [[ -n "$fb_json" ]] && fb_json="$fb_json,"
    fb_json="$fb_json\"$escaped\""
  done
  echo "{"
  echo "  \"score\": $score,"
  echo "  \"max\": $max,"
  echo "  \"pct\": $pct,"
  echo "  \"details\": [$(IFS=,; echo "${details[*]}")],"
  echo "  \"feedback\": [$fb_json]"
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
  echo "  DISTRIBUTION (can someone find this outside GitHub?)"
  for d in "${details[@]}"; do
    name=$(echo "$d" | sed 's/.*"name":"\([^"]*\)".*/\1/')
    case "$name" in video-*|social-*|blog-*)
      pts=$(echo "$d" | sed 's/.*"points":\([0-9]*\).*/\1/')
      mx=$(echo "$d" | sed 's/.*"max":\([0-9]*\).*/\1/')
      status=$(echo "$d" | sed 's/.*"status":"\([^"]*\)".*/\1/')
      case $status in pass) icon="✓";; partial) icon="◐";; minimal) icon="◐";; *) icon="✗";; esac
      printf "    %-28s %s %s/%s\n" "$name" "$icon" "$pts" "$mx"
    ;; esac
  done
  echo ""
  if [[ ${feedback[@]+x} ]]; then
    echo "  FEEDBACK (top actions to improve score)"
    count=0
    for fb in "${feedback[@]+"${feedback[@]}"}"; do
      [[ -z "$fb" ]] && continue
      printf "    → %s\n" "$fb"
      count=$((count + 1))
      [[ $count -ge 3 ]] && break
    done
    echo ""
  fi
fi
