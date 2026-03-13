# Twitter Thread

5-tweet thread. Post as a thread, not individual tweets. Lowercase aesthetic, no hashtags, no emojis.

---

## Tweet 1 — The Hook

**Attach:** `assets/social/tweets/scene-240.png`

> the hard part of AI coding isn't writing code. it's that most things you'd want to improve don't have a number.
>
> "are my docs good?" is not a metric. "is this test suite trustworthy?" is not a metric. "is this API reliable?" is not a metric.
>
> you have to build the ruler before you can measure.

---

## Tweet 2 — The Origin

**Attach:** `assets/social/tweets/scene-500.png`

> started here. i had 30 playwright tests. some worked, some were broken, no way to tell which. the count didn't matter — what mattered was trustworthiness.
>
> wrote a scoring script that collapsed routing confidence into a single number. wrote a file that told claude: here's the score, here's how to raise it, here's what not to touch.
>
> went to sleep. woke up to 12 commits and a score that went from 47 to 83.

---

## Tweet 3 — The Power Move

**Attach:** `assets/social/tweets/scene-840.png`

> but tests are at least somewhat measurable. the pattern clicked when someone applied it to documentation quality.
>
> "are my docs good?" is genuinely not a number. so they built a dual scoring system — one score for the docs, one for the measurement tools themselves. the agent fixed the ruler first, THEN fixed the docs.
>
> that's when i realized this wasn't a testing trick. it was a general pattern for making the immeasurable measurable.

---

## Tweet 4 — The Pattern

**Attach:** `assets/social/score-card.png`

> five elements. one file. drop it in any repo.
>
> 1. fitness function — a script that outputs a number
> 2. improvement loop — measure, diagnose, act, verify, keep or revert
> 3. action catalog — ranked moves so the agent works on what matters
> 4. operating mode — converge, continuous, or supervised
> 5. constraints — lines the agent must not cross
>
> it's called GOAL.md.

---

## Tweet 5 — The CTA

**Attach:** `video/out/video.mp4` (upload as video attachment)

Also attach as fallback image if video not supported: `assets/social/tweets/scene-1300.png`

> give it a number. go to sleep.
>
> the pattern, template, and examples are all open source. the docs-quality example alone is worth reading — it shows how to score something that has no natural metric.
>
> point an agent at the repo and it writes a GOAL.md for your project in one pass.
>
> github.com/jmilinovich/goal-md
