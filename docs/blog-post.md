# Give an Agent a Number and Go to Sleep

I had thirty Playwright tests for a routing system. Half of them were broken. The problem wasn't fixing them — any decent agent can fix a test if you point at it and say "fix this." The problem was that I had no way to express *trustworthiness* as a number. No metric meant no loop, and no loop meant I was the loop. Sitting there, prompting, checking, prompting again.

So before I could let the agent work, I had to build the ruler. Not a checklist, not a spec — a script. Something that could run without me and output a single number. I spent an evening collapsing ten dimensions of routing confidence — health checks, accuracy, coverage, consistency — into one score. That was the real work. Not the fixes. The metric. Once I had that, I wrote a file that said: here's the score, here's how to make it go up, here's what you're not allowed to touch. Pointed Claude at it. Went to bed.

Woke up to twelve commits. Each one atomic, each one pushing the number higher. 47 to 83. The repo was genuinely better than when I left it.

---

Karpathy's **autoresearch** proved the formula earlier this year: agent plus fitness function plus loop equals overnight breakthroughs. He had Claude optimizing a language model's training pipeline while he slept, and the results were striking — the agent found improvements that Karpathy himself said he wouldn't have tried. The key insight was dead simple. Give an agent a scalar metric that it can compute, a loop that runs measure-act-verify-keep/revert, and the instruction to never stop. The agent does the rest.

But autoresearch has a constraint that's easy to miss. It only works when the metric already exists. In ML training, it does — loss goes down, model gets better. The evaluation function is locked in a read-only file. The agent optimizes against it but can never change it.

Most software isn't like that. There is no pre-existing loss function for "is this test suite trustworthy" or "are these docs actually good" or "is this API performant under real-world load." The metric doesn't exist until someone builds it. You have to decide what "better" means, decompose it into things a script can check, and write the script that computes the number. That construction step turns out to be where all the leverage is. Get the metric right and the agent does the rest. Get it wrong — or skip it — and you're back to being the loop yourself.

---

The routing story was proof of concept. The moment I knew the pattern was general was when I watched it work on documentation quality. Not test coverage — documentation. "Are these docs actually good?" isn't remotely a number. There's no test runner for prose quality, no coverage metric for "do the prop tables match the actual TypeScript interfaces."

But it turns out you can build that ruler too. A scoring script that checks prop accuracy against the source code, tests whether code examples actually compile, measures whether every public component has a doc page with the right sections. Suddenly "are the docs good?" has a score: 45 out of 100.

And here's what made it interesting: the measurement tools themselves were broken. The linter flagged `onChange` as a spelling error. The prop checker couldn't parse `Pick<>` types. An agent that trusted those tools blindly would do the wrong work — "fixing" docs to satisfy a broken linter instead of fixing the docs that were actually wrong. So the GOAL.md had two scores: one for the docs, one for the instruments. The agent calibrated the telescope, then pointed it at the sky.

That was the moment I stopped thinking of this as a testing trick. Building the ruler *is* the trick. The loop is just measure-act-verify — that part's almost boring. The hard part, the part that unlocks autonomous work on things nobody thought were measurable, is constructing the number in the first place.

---

The pattern I landed on has five elements, and they all live in a single file called **GOAL.md** that you drop into a repo.

First, a **fitness function**. Not a description of quality. A script that outputs a number. The agent runs it, gets a score, and now has something concrete to optimize. This is the hard part — the part most people skip. They write elaborate instructions about what they want and then wonder why the agent spins its wheels. Building the ruler is the real work. Once you have a number, you've turned an open-ended conversation into a closed-loop optimization. Everything after that is mechanical.

Second, an **improvement loop** — the same measure-diagnose-act-verify cycle from autoresearch, but generalized. Every iteration leaves the repo better or unchanged, never worse. If a change regresses the score, the agent reverts it. No human needed in that decision.

Third, an **action catalog**. This is where it diverges from autoresearch significantly. In ML training, the search space is implicit — everything in the training script is fair game. In software, being explicit about what moves are available and what each one is worth prevents the agent from burning cycles on low-impact changes when high-impact ones are sitting right there. In the docs example, "write missing component pages" is worth 10-12 points while "add interactive examples" is worth 2-3. Without the catalog, the agent will happily spend an hour on interactive examples while three components have no docs at all. You're giving it a ranked menu, not an open buffet.

Fourth, an **operating mode** — converge, continuous, or supervised. Converge means stop when you hit the target. Continuous means run until I wake up. Supervised means pause at checkpoints for human approval. Same agent, different lengths of leash depending on how much you trust the metric and the domain.

Fifth, **constraints**. The lines the agent must not cross. Never fabricate test results. Never modify credentials. Always commit atomically so reverts are clean. Without these, the agent will absolutely find creative ways to make the number go up that you did not intend. Goodhart's Law applies to silicon as much as carbon.

The piece that surprised me most was what I ended up calling **split scoring**. The docs example is where it clicked. The GOAL.md had two metrics: "are the docs good?" and "can we trust the tools that check the docs?" Vale was flagging `onChange` as misspelled. The prop checker silently skipped any component that used `Pick<>` types. An agent that trusted those tools at face value would spend half its iterations chasing false positives — or worse, rewriting correct documentation to make a broken linter happy. So the agent got permission to improve the instrument — add terms to the linter vocabulary, teach the prop checker new type patterns — without redefining what "good docs" means. It calibrated the telescope, then pointed it at the sky. A single locked metric can't handle that. A dual-score system, where the agent can sharpen the instrument but not redefine what it's pointed at, turned out to be the key innovation.

---

This connects to something I've been thinking about for a while. We keep framing agents as better chatbots — faster responses, longer context, tool use. But the interesting shift isn't in the conversation. It's in what happens when you close the laptop.

A GOAL.md session isn't a chat. It's a **process**. It runs while you sleep. It makes commits. It has a fitness function that tells it whether it's making progress or just making changes. The agent isn't waiting for your next message. It's running its loop, and the repo is the artifact, and the score is the proof.

I think this is why the docs example feels more important than the routing one, even though routing came first. Everyone already believes agents can write tests — tests have pass/fail, agents understand pass/fail, it's a natural fit. But documentation? Design consistency? Developer onboarding quality? Those feel fundamentally human, fundamentally subjective. "Good docs" is a vibe, not a metric. Except it doesn't have to be. You can decompose "good docs" into prop accuracy, example compilability, section completeness, and linter precision — four things a script can check — and suddenly it's a number. The vibe became a score. And the agent that was useless when the instruction was "make the docs better" became relentless when the instruction was "make 45 go up."

That's what autonomous computing actually looks like in practice. Not a general intelligence that understands everything, but a focused optimizer with a clear metric, a bounded action space, and a loop that never stops until the number hits the target. It's less dramatic than the AGI narratives and far more useful right now.

---

The repo is open. An agent can read the template and the examples, look at your codebase, write a GOAL.md for your project, and start the loop — all in one session. The pattern bootstraps itself. You don't need to understand how it works any more than you need to understand backpropagation to fine-tune a model. You just need a codebase with a meaningful "better" and the willingness to let an agent chase it.

Here's the thing people get wrong when they first see this. They think the insight is the loop. Measure, act, verify, keep or revert — that's just control theory. Thermostats do it. The insight is that you can take something that feels unmeasurable — "are my docs actually good?" — and build a script that makes it a number. Not a perfect number. Not a number that captures every nuance of quality. But a number that's correlated enough with reality that an agent optimizing for it will make things genuinely better. A 45 that becomes a 78 over twelve commits isn't a perfect score. It's a repo where the prop tables match the code, the examples compile, and every component has a doc page. That's better. Measurably.

The question isn't whether agents can do this kind of work. Karpathy already answered that. The question is whether you can build the ruler. Test coverage, API latency, training loss — those are easy. The interesting problems are the ones where there's no natural metric. Documentation quality. Design consistency. Developer experience. Things that feel subjective until someone writes the script that makes them a number. That's the gap GOAL.md fills. Not the loop — the construction of the thing the loop optimizes.

---

*The GOAL.md pattern is at [github.com/jmilinovich/goal-md](https://github.com/jmilinovich/goal-md). It's MIT licensed and designed to be consumed by agents directly.*

Tags: writing, genAI
