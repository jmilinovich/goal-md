# Scoring Script Recipes

Fitness functions are the hardest part of a GOAL.md to write. These are copy-paste-adapt patterns for common scenarios. Each script outputs a single JSON object with `score` and `max` so the agent can track progress.

### Anti-patterns

Avoid binary metrics (pass/fail) — the agent has no gradient for partial progress. Avoid metrics that saturate (coverage above ~95% becomes asymptotic and generates diminishing returns). Avoid metrics the agent can trivially game (line count, file count). The best fitness functions have a smooth gradient across the range you care about.

---

## 1. Test Coverage (pytest or jest)

```bash
#!/bin/bash
# Score = line coverage percentage across the project
pytest tests/ --cov=src --cov-report=json:coverage.json -q 2>/dev/null
SCORE=$(python3 -c "
import json
data = json.load(open('coverage.json'))
print(int(data['totals']['percent_covered']))
")
echo "{\"score\": $SCORE, \"max\": 100}"
```

Output: `{"score": 63, "max": 100}`

---

## 2. Documentation Completeness (undocumented exports)

```bash
#!/bin/bash
# Score = % of exported functions that have a docstring/JSDoc comment.
# Lower undocumented count = higher score.
TOTAL=$(grep -r "^export " src/ --include="*.ts" | wc -l | tr -d ' ')
UNDOC=$(grep -r -B1 "^export " src/ --include="*.ts" \
  | grep -c "^[^*/]" || true)
if [ "$TOTAL" -eq 0 ]; then echo '{"score": 100, "max": 100}'; exit 0; fi
SCORE=$(( (TOTAL - UNDOC) * 100 / TOTAL ))
echo "{\"score\": $SCORE, \"max\": 100, \"total_exports\": $TOTAL, \"undocumented\": $UNDOC}"
```

Output: `{"score": 72, "max": 100, "total_exports": 89, "undocumented": 25}`

---

## 3. Build Health (TypeScript errors + lint warnings)

```bash
#!/bin/bash
# Score starts at 100 and loses points per issue.
# -3 per TS error, -1 per lint warning.
TS_ERRORS=$(npx tsc --noEmit 2>&1 | grep -c " error TS" || true)
LINT_WARNS=$(npx eslint src/ --format compact 2>&1 | grep -c "Warning" || true)
PENALTY=$(( TS_ERRORS * 3 + LINT_WARNS ))
SCORE=$(( 100 - PENALTY ))
[ "$SCORE" -lt 0 ] && SCORE=0
echo "{\"score\": $SCORE, \"max\": 100, \"ts_errors\": $TS_ERRORS, \"lint_warnings\": $LINT_WARNS}"
```

Output: `{"score": 82, "max": 100, "ts_errors": 2, "lint_warnings": 12}`

---

## 4. API Reliability (response time + error rate from logs)

```bash
#!/bin/bash
# Parse last 1000 requests from access log.
# Score = weighted blend: 60% success rate + 40% latency score.
LOG="${1:-/var/log/api/access.log}"
TAIL=$(tail -1000 "$LOG")
TOTAL=$(echo "$TAIL" | wc -l | tr -d ' ')
ERRORS=$(echo "$TAIL" | awk '$9 >= 500' | wc -l | tr -d ' ')
SUCCESS_PCT=$(( (TOTAL - ERRORS) * 100 / TOTAL ))
AVG_MS=$(echo "$TAIL" | awk '{sum += $NF} END {printf "%d", sum/NR}')
# Latency score: 100 if <200ms, 0 if >2000ms, linear between
LAT_SCORE=$(( AVG_MS < 200 ? 100 : AVG_MS > 2000 ? 0 : (2000 - AVG_MS) / 18 ))
SCORE=$(( SUCCESS_PCT * 60 / 100 + LAT_SCORE * 40 / 100 ))
echo "{\"score\": $SCORE, \"max\": 100, \"success_pct\": $SUCCESS_PCT, \"avg_ms\": $AVG_MS}"
```

Output: `{"score": 91, "max": 100, "success_pct": 99, "avg_ms": 340}`

---

## 5. Code Quality (TODOs + dead code + complexity)

```bash
#!/bin/bash
# Composite score penalizing tech debt signals.
# -2 per TODO/FIXME, -5 per function with cyclomatic complexity >10.
TODOS=$(grep -r "TODO\|FIXME\|HACK\|XXX" src/ --include="*.ts" | wc -l | tr -d ' ')
# Requires `cr` (complexity-report) or similar; adapt to your tool
COMPLEX=$(npx cr src/**/*.ts 2>/dev/null \
  | grep "cyclomatic" | awk '$NF > 10' | wc -l | tr -d ' ')
PENALTY=$(( TODOS * 2 + COMPLEX * 5 ))
SCORE=$(( 100 - PENALTY ))
[ "$SCORE" -lt 0 ] && SCORE=0
echo "{\"score\": $SCORE, \"max\": 100, \"todos\": $TODOS, \"complex_fns\": $COMPLEX}"
```

Output: `{"score": 74, "max": 100, "todos": 8, "complex_fns": 1}`

---

## Conventions

All scoring scripts in this repo follow three rules:

1. **Output is JSON** with at least `score` and `max` keys.
2. **Score is an integer** between 0 and `max`. No floats.
3. **Exit 0 even on bad scores.** A non-zero exit means the script itself broke, not that the codebase is unhealthy. The agent needs to distinguish "score is low" from "scoring is broken."
