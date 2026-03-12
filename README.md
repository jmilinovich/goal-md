# GOAL.md

**Give an AI agent a number to make go up and a loop to do it in. Then go to sleep.**

![The GOAL.md pattern: fitness function → improvement loop → action catalog → operating mode → constraints](assets/pattern.svg)

Karpathy's [autoresearch](https://github.com/karpathy/autoresearch) proved the formula: agent + fitness function + loop = overnight breakthroughs. But autoresearch only works when you already have a scalar metric. Loss goes down, paper gets better. Most software isn't like that. You have to *construct* the metric before you can optimize it.

GOAL.md is the pattern for doing that. One file you drop into a repo that turns a coding agent into an autonomous improver. This repo itself is designed to be consumed by agents — the template is a prompt, the examples are few-shot training data, and the CLAUDE.md teaches an agent how to write a good GOAL.md for *your* project.

## How I stumbled into this

I had 30 Playwright tests for a routing system. Half were broken, no way to tell which. I wanted Claude to fix them, not once but in a loop. Problem is there's no loss function for "is this test infrastructure trustworthy?" I had to build the ruler before I could measure.

```
═══════════════════════════════════════════
  routing confidence: 47 / 100 (47%)
═══════════════════════════════════════════

    health                       ✗ 0.42
    accuracy                     ◐ 0.61
    coverage                     ◐ 0.67
    consistency                  ✗ 0.38
```

So I wrote a file that told Claude: here's the score, here's how to make it go up, here's when to stop. Went to bed. Woke up to 12 commits, each atomic, each pushing the score higher. 47 → 83.

That file became GOAL.md. The wild part wasn't the pattern itself, it was waking up to a repo that was genuinely better than when I left it.

## Why not just a good CLAUDE.md?

CLAUDE.md is a manual. It tells an agent *how to work* in your repo. GOAL.md is a reward function. It tells an agent *what "better" means* and gives it a loop to get there. The agent measures, diagnoses, acts, and verifies on its own. You don't need to be in the room.

## The five elements

### 1. Fitness function

> Not a vibe. A number. The agent needs a computable definition of "better."

```bash
./scripts/score.sh    # → 47/100... then 52... then 61... then 83
```

autoresearch locks `evaluate_bpb()` in a read-only file. That's fine when you're optimizing loss. But most software metrics are made up by you, so who gets to change the ruler?

| Mode | What it means |
|------|---------------|
| **Locked** | Agent can't touch the scoring code. autoresearch does this. |
| **Split** | Agent can improve the *measurement instrument* but not the *definition of good*. |
| **Open** | Agent can modify everything, including how success is measured. |

Split mode is the one I actually use. I had two scores: "is the routing working?" (the thing) and "can we trust the tests?" (the instrument). The agent could sharpen the instrument (add tests, fix detection) without gaming the outcome. You need a dual-score setup when the agent is building its own telescope.

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

autoresearch leaves this implicit ("everything in `train.py` is fair game") which is fine for neural nets. For software, being explicit prevents the agent from burning cycles on 1-point changes when 5-point moves are sitting right there. The point estimates don't need to be precise. They're prioritization signals, not promises.

### 4. Operating mode

> How long is the leash? Same agent, different levels of autonomy.

![Three operating modes compared: Converge stops when the score hits a target, Continuous runs unattended overnight, Supervised pauses at human checkpoints](assets/modes.svg)

| Mode | When to use |
|------|-------------|
| **Converge** | Stop when criteria met. "Get every score above 80, then report." |
| **Continuous** | Run forever. autoresearch: "NEVER STOP... the human might be asleep." |
| **Supervised** | Pause at gates. For high-stakes changes or early iterations while building trust. |

### 5. Constraints

> The lines the agent must not cross. These are load-bearing, not suggestions.

```
- Never fabricate test results — they come from the test runner only
- Never modify credentials
- Always measure before and after — score must not decrease
- Atomic commits — one improvement each, so reverts are clean
```

autoresearch has the same idea: "don't modify `prepare.py`", "don't add dependencies", "simpler is better." Without constraints the agent will absolutely find creative ways to make the number go up that you did not intend.

## The lineage

![Lineage timeline from autoresearch to autoresearch-anything to GOAL.md, showing each project's contributions: fitness function and loop, generalized metric, then dual scores, action catalog, and modes](assets/lineage.svg)

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

## Prior art

**autoresearch** (Karpathy, 2026) is the direct ancestor and the reason this exists. Immutable fitness function + keep/discard gate + "never stop" loop. GOAL.md generalizes the fitness function (constructed metrics, dual scores) and makes explicit the parts autoresearch doesn't need to spell out because it's only doing one thing (action catalog, operating modes).

**Eval-Driven Development** ([evaldriven.org](https://evaldriven.org/)) — correctness specs with measurable thresholds. Good ideas but it's a methodology for humans, not a file format for agents. No loop, no autonomy.

**AGENTS.md** (Google, OpenAI, adopted by 20k+ repos) proved agents need repo-level context files. But AGENTS.md is descriptive: build commands, conventions, "here's how we do things." It tells an agent *how your repo works*, not *what to optimize*. You want both.

**Ralph Wiggum** (Huntley, Claude Code plugin) nailed the "persistent bash loop with a circuit breaker" part. Keep the agent running, stop it when things go sideways. What it doesn't have is a numeric fitness function that tells the loop whether it's making progress or just making changes.

**GOAP** (game AI, 2003) invented the action catalog with preconditions and effects two decades ago. LLM agents don't need formal precondition graphs though. A prioritized menu and enough judgment to pick from it is plenty.

## This repo dogfoods itself

This repo has its own [`GOAL.md`](GOAL.md) and scoring script:

![Current score output from ./scripts/score.sh](assets/score.svg)

A future Claude session can pick up the GOAL.md in this repo and keep improving the score. The scoring script is just bash and `jq` so it's not exactly robust, but it works.

## When you need a GOAL.md

You need one when the work is an optimization loop, not a one-shot task. When "better" requires a metric you have to construct, not just "tests pass." When you want to go to sleep and wake up to progress.

You don't need one for a single well-defined change ("add a dark mode toggle") or when "done" is obvious. If a CLAUDE.md with good instructions is enough, it's enough.

## Get started

The fastest way: point an agent at this repo and let it do the work.

```
Look at github.com/jmilinovich/goal-md — read the template and examples.
Then write me a GOAL.md for this repo and start working on it.
```

The agent reads the template as a prompt and the examples as few-shot demonstrations. It pattern-matches your codebase against them, writes the fitness function, and starts the loop. You don't need to understand the pattern yourself — you just need to point an agent here and let it learn from the examples the same way you'd give a junior engineer a style guide and three PRs to reference.

Or do it manually:

1. Copy [`template/GOAL.md`](template/GOAL.md) into your repo
2. Define your fitness function (a script that outputs a number)
3. Fill in the improvement loop and action catalog
4. Point an agent at it and let it run

## Real examples

These aren't just documentation — they're the few-shot examples an agent uses to pattern-match when writing a GOAL.md for your project. Each one demonstrates a different domain, metric style, and operating mode so the agent has enough variety to generalize.

| Project | Domain | Metric | Mode | Link |
|---------|--------|--------|------|------|
| browser-grid | Playwright plugin | 10-criterion checklist | Converge | [`examples/browser-grid.md`](examples/browser-grid.md) |
| api-test-coverage | REST API testing | Coverage score (pytest --cov) | Converge | [`examples/api-test-coverage.md`](examples/api-test-coverage.md) |
| perf-optimization | Web service perf | Latency/throughput composite (wrk + k6) | Continuous | [`examples/perf-optimization.md`](examples/perf-optimization.md) |
| docs-quality | React component lib docs | Dual: docs quality + instrument quality | Split/Converge | [`examples/docs-quality.md`](examples/docs-quality.md) |

More examples welcome. Open a PR — more variety here means better GOAL.md files for everyone's projects.

## License

MIT
