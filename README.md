# GOAL.md

**A goal-specification file for autonomous coding agents.**

Karpathy's [autoresearch](https://github.com/karpathy/autoresearch) showed that an agent + a fitness function + a loop = overnight research. But it only works when the metric is obvious — loss goes down. What about everything else?

Most software domains don't have a natural scalar metric. You have to *construct* one. And that construction is itself part of the work.

GOAL.md is the pattern that emerges when you generalize `program.md` to domains with constructed metrics.

## The problem

autoresearch works because LLM training has a god-given fitness function: `val_bpb`. Lower is better. The agent can't argue with it, can't game it, can't redefine it. The metric lives in `prepare.py`, which is read-only. Beautiful.

But most software work doesn't have this. "Is this npm package closer to publishable?" "Is the test infrastructure more trustworthy?" "Is the documentation complete enough?" These are real goals, but there's no `loss.backward()` to call. You have to build the ruler before you can measure.

This creates a problem autoresearch doesn't have: **the agent needs to improve the measurement instrument and the thing being measured, simultaneously, without confusing the two.**

## The pattern

A GOAL.md file has five elements:

### 1. Fitness function

A computable definition of "better." Not a vibe — a number. Something the agent can run, get a score, and compare to the previous score.

```
node scripts/score.js    # → quality: 47.2, instrument: 63.1
```

autoresearch has this as executable Python (`evaluate_bpb()` in `prepare.py`). In domains with constructed metrics, you define it in a script and reference it from GOAL.md.

**The key question is whether the agent can modify the fitness function.** This is a spectrum:

| Mode | Metric mutability | Example |
|------|-------------------|---------|
| **Locked** | Agent cannot touch the scoring code | autoresearch: `prepare.py` is read-only |
| **Split** | Agent can improve the *instrument* but not the *definition of good* | Dual scores: instrument quality is improvable, outcome formula is fixed |
| **Open** | Agent can modify everything, including how success is measured | Early-stage projects where the metric itself is being designed |

The dual-score pattern (thing-being-measured vs. measurement-instrument) is the innovation that makes the "split" mode safe. You get one score for "is the thing good?" and one for "can we trust what we're seeing?" The agent can improve its own instruments without gaming the outcome metric.

### 2. Improvement loop

A closed cycle the agent follows without human intervention. The canonical form:

```
repeat:
  1. Measure (run the fitness function)
  2. Diagnose (find the weakest component)
  3. Act (pick the highest-impact action)
  4. Verify (re-measure)
  5. Gate (improved? keep. regressed? revert.)
```

autoresearch: modify `train.py` → commit → `uv run train.py` → check `val_bpb` → keep or `git reset`.

Your version can be more structured because software domains have richer state than a single scalar. The diagnose step can inspect component breakdowns, read error logs, look at screenshots.

### 3. Action catalog

The set of concrete moves the agent can make, ideally with estimated impact.

autoresearch leaves this implicit: "Everything in `train.py` is fair game." This works because the action space (modify neural network code) is well-understood by the agent.

In constructed-metric domains, being explicit helps:

```
| Action                          | Impact    | How                                    |
|---------------------------------|-----------|----------------------------------------|
| Fix and re-run a broken test    | +5 pts    | Diagnose failure, fix, re-run          |
| Add missing config page         | +3-5 pts  | Create from template                   |
| Fix a bidirectional link        | +2-3 pts  | Add the missing side of the pair       |
```

The point estimates aren't precise — they're **prioritization signals**. They tell the agent "this is a 5-point move, that's a 1-point move" so it doesn't thrash between high-impact and low-impact work.

### 4. Operating mode

How autonomous is the agent? This is analogous to Claude Code's permission modes.

| Mode | Behavior | When to use |
|------|----------|-------------|
| **Converge** | Run until stopping conditions are met, then report | Bounded improvement tasks with clear "done" criteria |
| **Continuous** | Run forever until human interrupts | Monitoring, ongoing optimization (autoresearch style) |
| **Supervised** | Pause at gates for human approval | High-stakes changes, early iterations while building trust |

autoresearch is pure continuous: "NEVER STOP... the human might be asleep."

Most software GOAL.md files will use converge mode with explicit stopping conditions:
- All components above threshold (e.g., every score ≥ 80)
- N consecutive iterations with no improvement (diminishing returns)
- Max iterations (time-box)
- External dependency hit (auth expired, rate limited, blocked)

### 5. Constraints

What the agent must not do. These are load-bearing guardrails, not suggestions.

```
- Never hand-edit captures/ — test results are produced by the test runner only
- Never modify auth.json or credentials
- Always run score.js before and after — composite must not decrease
- Atomic commits — one improvement per commit, so reverts are clean
```

autoresearch: "don't modify `prepare.py`", "don't add dependencies", "simpler is better."

## Prior art

GOAL.md sits at an intersection of several existing concepts:

| Concept | What it contributes | What it lacks |
|---------|-------------------|---------------|
| **autoresearch** (Karpathy, 2026) | Immutable fitness function, keep/discard gate, "never stop" loop | Domain-specific, no action catalog, single scalar only |
| **Eval-Driven Development** ([evaldriven.org](https://evaldriven.org/)) | Correctness specs with measurable thresholds | No agent-facing file format, no improvement loop |
| **AGENTS.md** (Google, OpenAI, 20k+ repos) | Conventions and build commands for AI agents | Purely descriptive — no goals, no scores, no loop |
| **Ralph Wiggum** (Huntley, Claude Code plugin) | Persistent bash loop, circuit breaker, session restarts | No numeric fitness function, no action catalog |
| **GOAP** (game AI, 2003) | Action inventory with preconditions and effects | Not LLM-oriented, no file-based spec |
| **SAGA** (arxiv, 2025) | Bi-level architecture: agents define AND optimize scoring functions | Academic, not practical |

The **autoresearch-anything** fork (by zkarimi22) is the closest existing attempt to generalize this — it asks "what metric?" and "how do I extract the score?" and generates an agent spec. GOAL.md is the formalization of what that fork was reaching for.

## When you need a GOAL.md

You probably need one when:

- An AI agent will work on your project **across multiple sessions** (the goal persists beyond any single conversation)
- "Better" requires a **constructed metric**, not just "tests pass"
- The work is an **optimization loop**, not a one-shot task
- You want the agent to be **autonomous** — measure, decide, act, verify without asking you

You probably don't need one when:

- The task is a single well-defined change ("add a dark mode toggle")
- "Done" is obvious (tests pass, types check, PR approved)
- A CLAUDE.md with good instructions is sufficient

## Template

See [`template/GOAL.md`](template/GOAL.md) for a starter template.

## Real examples

| Project | Domain | Metric | Link |
|---------|--------|--------|------|
| browser-grid | npm package development | 10-criterion checklist (binary per criterion) | [`examples/browser-grid.md`](examples/browser-grid.md) |

## The lineage

```
autoresearch (Karpathy, Mar 2026)
  program.md + prepare.py + train.py
  Single scalar metric (val_bpb), immutable eval, infinite loop
  Domain: LLM training
      │
      ├── autoresearch-anything (zkarimi22)
      │     Generalized to any codebase: "what metric? how to extract?"
      │
      └── GOAL.md (this pattern)
            Generalized to constructed metrics
            Added: dual scores, action catalog, operating modes, stopping conditions
            Domain: any software project with an optimization goal
```

## Contributing

This is a new pattern. If you're using something like this, open an issue or PR with your example. The more real-world GOAL.md files we collect, the better we understand what the pattern needs.

## License

MIT
