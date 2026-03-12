# GOAL.md

**Give an AI agent a number to make go up and a loop to do it in. Then go to sleep.**

![The GOAL.md pattern: fitness function → improvement loop → action catalog → operating mode → constraints](assets/pattern.svg)

Karpathy's [autoresearch](https://github.com/karpathy/autoresearch) proved the formula: agent + fitness function + loop = overnight breakthroughs. But autoresearch only works when God hands you a scalar metric — loss goes down, paper gets better. Most software isn't like that. You have to *construct* the metric before you can optimize it.

GOAL.md is the pattern for doing that. One file, dropped into any repo, that turns a coding agent into an autonomous improver.

## How I stumbled into this

30 Playwright tests for a routing system. Half broken, no way to tell which. I wanted Claude to fix them — not once, but in a loop. The problem: there's no loss function for "is this test infrastructure trustworthy?" I had to build the ruler before I could measure.

```
═══════════════════════════════════════════
  routing confidence: 47 / 100 (47%)
═══════════════════════════════════════════

    health                       ✗ 0.42
    accuracy                     ◐ 0.61
    coverage                     ◐ 0.67
    consistency                  ✗ 0.38
```

Then I wrote a file that told Claude: here's the score, here's how to make it go up, here's when to stop. I went to bed. Woke up to 12 commits, each atomic, each pushing the score higher. 47 → 83.

That file became GOAL.md. Honestly, the wild part wasn't the pattern — it was waking up to a repo that was better than when I left it.

## Why not just a good CLAUDE.md?

CLAUDE.md is a manual — it tells an agent *how to work* in your repo. GOAL.md is a reward function — it tells an agent *what "better" means* and gives it a loop to get there. The agent measures, diagnoses, acts, and verifies on its own. You don't need to be in the room.

## The five elements

### 1. Fitness function

> Not a vibe — a number. The agent needs a computable definition of "better."

```bash
./scripts/score.sh    # → 47/100... then 52... then 61... then 83
```

autoresearch locks `evaluate_bpb()` in a read-only file. That works when the metric is God-given. Most software metrics aren't — you have to construct them.

The interesting question is *who can change the ruler:*

| Mode | What it means |
|------|---------------|
| **Locked** | Agent can't touch the scoring code. autoresearch does this. |
| **Split** | Agent can improve the *measurement instrument* but not the *definition of good*. |
| **Open** | Agent can modify everything, including how success is measured. |

Split mode is where it gets good. I had two scores: "is the routing working?" (the thing) and "can we trust the tests?" (the instrument). The agent could sharpen the instrument — add tests, fix detection — without gaming the outcome. You need a dual-score system when the agent is building its own telescope.

### 2. Improvement loop

> Measure → diagnose → act → verify → keep or revert. Every iteration leaves the repo better or unchanged, never worse.

```
repeat:
  1. Run the fitness function
  2. Find the weakest component
  3. Pick the highest-impact action
  4. Make the change
  5. Re-measure
  6. Improved? Commit. Regressed? Revert.
```

This is the same structure as autoresearch (`modify train.py → run → check val_bpb → keep or git reset`), just generalized beyond training runs.

### 3. Action catalog

> A menu of concrete moves, ranked by impact. Tells the agent *where to spend its time.*

```
| Action                          | Impact    | How                              |
|---------------------------------|-----------|----------------------------------|
| Fix and re-run a broken test    | +5 pts    | Diagnose failure, fix, re-run    |
| Add missing config page         | +3-5 pts  | Create from template             |
| Fix a bidirectional link        | +2-3 pts  | Add the missing side             |
```

autoresearch leaves this implicit — "everything in `train.py` is fair game." For neural nets, fine. For software, being explicit prevents the agent from burning cycles on 1-point changes when 5-point moves are sitting right there. The point estimates don't need to be precise; they're prioritization signals.

### 4. Operating mode

> How long is the leash? Same agent, different levels of autonomy.

| Mode | When to use |
|------|-------------|
| **Converge** | Stop when criteria met. "Get every score above 80, then report." |
| **Continuous** | Run forever. autoresearch: "NEVER STOP... the human might be asleep." |
| **Supervised** | Pause at gates. For high-stakes changes or early iterations while building trust. |

### 5. Constraints

> Load-bearing guardrails, not suggestions. The lines the agent must never cross.

```
- Never fabricate test results — they come from the test runner only
- Never modify credentials
- Always measure before and after — score must not decrease
- Atomic commits — one improvement each, so reverts are clean
```

autoresearch has the same idea: "don't modify `prepare.py`", "don't add dependencies", "simpler is better." Every autonomous system needs a fence.

## The lineage

```
autoresearch (Karpathy, Mar 2026)
  program.md + prepare.py + train.py
  Single scalar metric, immutable eval, infinite loop
  Domain: LLM training
      │
      ├── autoresearch-anything (zkarimi22)
      │     "what metric? how to extract?" — first attempt at generalizing
      │
      └── GOAL.md (this)
            Constructed metrics, dual scores, action catalog, operating modes
            Domain: any software project with an optimization goal
```

## Prior art — what we learned

**autoresearch** (Karpathy, 2026) is the direct ancestor. It nailed the core insight: immutable fitness function + keep/discard gate + "never stop" loop. GOAL.md exists because that formula is domain-locked to LLM training. We generalized the fitness function (constructed metrics, dual scores) and added the parts autoresearch leaves implicit (action catalog, operating modes).

**Eval-Driven Development** ([evaldriven.org](https://evaldriven.org/)) showed that correctness specs with measurable thresholds are powerful. But it's a methodology for humans, not a file format for agents. No loop, no autonomy.

**AGENTS.md** (Google, OpenAI, adopted by 20k+ repos) proved that agents need repo-level context files. But AGENTS.md is purely descriptive — build commands and conventions. It tells an agent *how your repo works*, not *what to optimize*. GOAL.md and AGENTS.md are complementary, not competing.

**Ralph Wiggum** (Huntley, Claude Code plugin) got the "persistent bash loop with a circuit breaker" part right — keep the agent running, stop it if things go sideways. What's missing is the numeric fitness function that tells the loop whether it's actually making progress.

**GOAP** (game AI, 2003) invented the action catalog with preconditions and effects two decades ago. Great idea, wrong era. LLM agents don't need formal precondition graphs — they need a prioritized menu and the judgment to pick from it.

## This repo dogfoods itself

This repo has its own [`GOAL.md`](GOAL.md) and scoring script:

![Current score output from ./scripts/score.sh](assets/score.svg)

A future Claude session can pick up the GOAL.md in this repo and work autonomously to improve the score. Turtles all the way down.

## When you need a GOAL.md

You probably need one when:
- The work is an **optimization loop**, not a one-shot task
- "Better" requires a **constructed metric**, not just "tests pass"
- You want the agent to be **autonomous** across multiple sessions
- You want to go to sleep and wake up to progress

You probably don't need one when:
- It's a single well-defined change ("add a dark mode toggle")
- "Done" is obvious (tests pass, types check, PR approved)
- A CLAUDE.md with good instructions is enough

## Get started

1. Copy [`template/GOAL.md`](template/GOAL.md) into your repo
2. Define your fitness function (a script that outputs a number)
3. Fill in the improvement loop and action catalog
4. Point an agent at it and let it run

## Real examples

| Project | Domain | Metric | Mode | Link |
|---------|--------|--------|------|------|
| browser-grid | Playwright plugin | 10-criterion checklist | Converge | [`examples/browser-grid.md`](examples/browser-grid.md) |
| api-test-coverage | REST API testing | Coverage score (pytest --cov) | Converge | [`examples/api-test-coverage.md`](examples/api-test-coverage.md) |
| perf-optimization | Web service perf | Latency/throughput composite (wrk + k6) | Continuous | [`examples/perf-optimization.md`](examples/perf-optimization.md) |
| docs-quality | React component lib docs | Dual: docs quality + instrument quality | Split/Converge | [`examples/docs-quality.md`](examples/docs-quality.md) |

More examples welcome — open a PR.

## License

MIT
