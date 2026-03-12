#!/usr/bin/env bash
# Video quality scoring: automated code checks (40 pts)
# See video/GOAL.md for the full rubric including LLM-as-judge (60 pts)

cd "$(dirname "$0")/.."

JSON=false
[[ "${1:-}" == "--json" ]] && JSON=true

total=0
max_total=0
details=()

check() {
  local name="$1" max="$2" score="$3" note="$4"
  total=$((total + score))
  max_total=$((max_total + max))
  details+=("{\"name\":\"$name\",\"max\":$max,\"score\":$score,\"note\":\"$note\"}")
}

# Helper: count grep matches safely (returns 0 on no match)
gcount() { grep -l "$@" 2>/dev/null | wc -l | tr -d ' '; }
gfiles() { grep -rl "$@" 2>/dev/null | wc -l | tr -d ' '; }

# ─── 1. Font Bundling (8 pts) ───
font_score=0
font_note="no fonts bundled"

woff2_count=$(find public src -name '*.woff2' 2>/dev/null | wc -l | tr -d ' ')
font_load=$(gfiles 'loadFont\|@remotion/google-fonts\|@font-face' src/)
font_ibm=$(grep -rl 'IBM.Plex\|IBMPlex\|ibm-plex' src/ public/ 2>/dev/null | grep -v 'styles.ts' | wc -l | tr -d ' ' 2>/dev/null || echo 0)

# @remotion/google-fonts handles bundling automatically (no separate woff2 needed)
remotion_google_fonts=$(grep -rl '@remotion/google-fonts' src/ 2>/dev/null | wc -l | tr -d ' ')
if [[ $remotion_google_fonts -gt 0 && $font_load -gt 0 ]]; then
  font_score=8; font_note="@remotion/google-fonts + loadFont used"
elif [[ $woff2_count -gt 0 && $font_load -gt 0 ]]; then
  font_score=8; font_note="woff2 bundled + loadFont used"
elif [[ $font_load -gt 0 || $font_ibm -gt 0 ]]; then
  font_score=4; font_note="font loading exists but incomplete"
elif grep -q "IBM Plex" src/styles.ts 2>/dev/null; then
  font_score=1; font_note="referenced in styles but not bundled"
fi
check "font-bundling" 8 $font_score "$font_note"

# ─── 2. Color Consistency (6 pts) ───
color_score=6
color_note="clean"

inline_hex=$(grep -oE '#[0-9A-Fa-f]{3,8}' src/scenes/*.tsx 2>/dev/null | wc -l | tr -d ' ')
inline_hex_main=$(grep -oE '#[0-9A-Fa-f]{3,8}' src/GoalMdExplainer.tsx 2>/dev/null | wc -l | tr -d ' ')
inline_total=$((inline_hex + inline_hex_main))

if [[ $inline_total -gt 5 ]]; then
  color_score=0; color_note="$inline_total inline hex codes in scenes"
elif [[ $inline_total -gt 2 ]]; then
  color_score=3; color_note="$inline_total inline hex codes"
elif [[ $inline_total -gt 0 ]]; then
  color_score=5; color_note="$inline_total inline hex code(s)"
fi
check "color-consistency" 6 $color_score "$color_note"

# ─── 3. Terminal Component (4 pts) ───
term_score=0
term_note="no shared component"

term_comp=$(find src/components -name '*Terminal*' 2>/dev/null | wc -l | tr -d ' ')
if [[ $term_comp -gt 0 ]]; then
  term_usage=$(gfiles 'TerminalChrome\|Terminal' src/scenes/)
  if [[ $term_usage -ge 3 ]]; then
    term_score=4; term_note="shared component used by $term_usage scenes"
  elif [[ $term_usage -ge 1 ]]; then
    term_score=2; term_note="component exists, used by $term_usage scene(s)"
  else
    term_score=1; term_note="component exists but unused"
  fi
fi
check "terminal-component" 4 $term_score "$term_note"

# ─── 4. Type Scale (4 pts) ───
type_score=0
type_note="no type scale defined"

type_scale=$(gcount 'FONT_SIZE\|typeScale\|fontScale\|TYPE_SCALE' src/styles.ts)
if [[ $type_scale -gt 0 ]]; then
  type_usage=$(grep -rl 'FONT_SIZE\|typeScale\|fontScale\|TYPE_SCALE' src/scenes/ 2>/dev/null | wc -l | tr -d ' ')
  if [[ $type_usage -ge 2 ]]; then
    type_score=4; type_note="scale defined and used"
  else
    type_score=2; type_note="scale defined, underused"
  fi
fi
check "type-scale" 4 $type_score "$type_note"

# ─── 5. Scene Transitions (6 pts) ───
trans_score=0
trans_note="no transitions"

seq_count=$(grep -c 'Sequence' src/GoalMdExplainer.tsx 2>/dev/null || echo 0)
fade_logic=$(gcount 'crossfade\|CrossFade\|fadeIn\|fadeOut\|TransitionSeries' src/GoalMdExplainer.tsx)

if [[ $fade_logic -gt 0 && $seq_count -ge 4 ]]; then
  trans_score=6; trans_note="fade logic + sequences"
elif [[ $fade_logic -gt 0 ]]; then
  trans_score=3; trans_note="some fade logic"
elif [[ $seq_count -ge 4 ]]; then
  trans_score=1; trans_note="sequences exist but no transitions"
fi
check "scene-transitions" 6 $trans_score "$trans_note"

# ─── 6. Audio Fades (4 pts) ───
audio_score=0
audio_note="no audio fades"

audio_interp=$(gcount 'volume.*interpolate\|interpolate.*volume' src/GoalMdExplainer.tsx)
if [[ $audio_interp -gt 0 ]]; then
  audio_score=4; audio_note="volume interpolation with fades"
elif grep -q 'volume' src/GoalMdExplainer.tsx 2>/dev/null; then
  audio_score=2; audio_note="static volume set"
fi
check "audio-fades" 4 $audio_score "$audio_note"

# ─── 7. Spring Variety (4 pts) ───
spring_score=0
spring_note="no springs"

spring_configs=$(grep -oE 'config:\s*\{[^}]+\}' src/scenes/*.tsx src/GoalMdExplainer.tsx 2>/dev/null | sort -u | wc -l | tr -d ' ')

if [[ $spring_configs -ge 4 ]]; then
  spring_score=4; spring_note="$spring_configs distinct configs"
elif [[ $spring_configs -ge 2 ]]; then
  spring_score=2; spring_note="$spring_configs configs (need 4+)"
elif [[ $spring_configs -ge 1 ]]; then
  spring_score=1; spring_note="only $spring_configs config"
fi
check "spring-variety" 4 $spring_score "$spring_note"

# ─── 8. Animation Variety (4 pts) ───
anim_score=0
anim_note="no variety"

has_translateY=$(grep -l 'translateY' src/scenes/*.tsx 2>/dev/null | wc -l | tr -d ' ')
has_translateX=$(grep -l 'translateX' src/scenes/*.tsx 2>/dev/null | wc -l | tr -d ' ')
has_scale=$(grep -l 'scale(' src/scenes/*.tsx 2>/dev/null | wc -l | tr -d ' ')
has_clipPath=$(grep -lE 'clipPath|clip-path' src/scenes/*.tsx 2>/dev/null | wc -l | tr -d ' ')
has_rotate=$(grep -l 'rotate' src/scenes/*.tsx 2>/dev/null | wc -l | tr -d ' ')

anim_types=0
[[ $has_translateY -gt 0 ]] && anim_types=$((anim_types + 1))
[[ $has_translateX -gt 0 ]] && anim_types=$((anim_types + 1))
[[ $has_scale -gt 0 ]] && anim_types=$((anim_types + 1))
[[ $has_clipPath -gt 0 ]] && anim_types=$((anim_types + 1))
[[ $has_rotate -gt 0 ]] && anim_types=$((anim_types + 1))

if [[ $anim_types -ge 3 ]]; then
  anim_score=4; anim_note="$anim_types distinct entrance types"
elif [[ $anim_types -ge 2 ]]; then
  anim_score=2; anim_note="$anim_types types (need 3+)"
elif [[ $anim_types -ge 1 ]]; then
  anim_score=1; anim_note="only translateY+opacity"
fi
check "animation-variety" 4 $anim_score "$anim_note"

# ─── Output ───
if $JSON; then
  echo "{"
  echo "  \"score\": $total,"
  echo "  \"max\": $max_total,"
  echo "  \"pct\": $(echo "scale=1; $total * 100 / $max_total" | bc),"
  echo "  \"checks\": ["
  for i in "${!details[@]}"; do
    comma=","
    [[ $i -eq $((${#details[@]} - 1)) ]] && comma=""
    echo "    ${details[$i]}$comma"
  done
  echo "  ]"
  echo "}"
else
  echo "═══════════════════════════════════════"
  echo "  VIDEO CODE CHECKS   $total / $max_total"
  echo "═══════════════════════════════════════"
  for d in "${details[@]}"; do
    name=$(echo "$d" | sed 's/.*"name":"\([^"]*\)".*/\1/')
    max=$(echo "$d" | sed 's/.*"max":\([0-9]*\).*/\1/')
    score=$(echo "$d" | sed 's/.*"score":\([0-9]*\).*/\1/')
    note=$(echo "$d" | sed 's/.*"note":"\([^"]*\)".*/\1/')
    printf "  %-22s %2d / %2d  %s\n" "$name" "$score" "$max" "$note"
  done
  echo "═══════════════════════════════════════"
fi
