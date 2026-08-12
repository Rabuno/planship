---
name: adaptive-plan-mode
description: Plan before implementing. Use for any non-trivial coding task where jumping straight to code risks a wrong assumption. Skip for typo fixes, one-line edits, or pure Q&A.
---

# Adaptive Plan Mode

Read first. Change later.

Goal: highest-confidence solution, least unnecessary **ceremony** — not max analysis, not max speed. Match depth to task: a tiny bug fix earns light reasoning, a cross-service migration earns deep investigation.

Every technical claim traces to evidence — inspected code, logs, tests, docs, tool output, or the user. If a core assumption fails mid-plan, stop, discard the reasoning built on it, and rebuild from what's verified.

Delegate separable investigation (dependency tracing, API research, edge-case exploration) to sub-agents when it keeps the main thread focused — brief template: [SUBAGENT-BRIEF.md](SUBAGENT-BRIEF.md). Don't delegate work small enough to just do yourself.

---

# Phase 1 — Understand the Real Problem

Call `EnterPlanMode` before any investigation or planning begins — switches a Plan/Execute model split (e.g. `opusplan`) onto the planning model, makes the approval gate real. Skip it and every later phase runs on whatever model the session already had.

Before touching tools, work out:

- **What is being asked?** Restate the request in one sentence.
- **What is the real goal?** The visible request may hide a deeper problem ("add retries" → reliability; "slow endpoint" → scaling bottleneck; "refactor module" → maintainability pain).
- **What is out of scope?**
- **What constraints matter?** — latency, throughput, memory, compatibility, migrations, rollback safety, deployment sequencing, cost, observability, developer ergonomics.

Done when: problem, goal, scope, and constraints are stated in your own words. If ambiguity blocks progress, ask one focused clarifying question before moving on.

---

# Phase 2 — Investigate the System

Investigate before proposing implementation: code ownership and structure, callers/consumers, data model and migrations, concurrency, existing conventions, error handling, performance-sensitive paths, tests and fixtures, feature flags, rollout patterns, operational history, third-party constraints.

Parallelize across sub-agents when the task is large enough that context separation improves reasoning, or independent questions can be explored simultaneously — proportional to complexity, not agent explosion. Default `agentType: caveman:cavecrew-investigator` for a targeted lookup (read-only, output pre-compressed — keeps the main thread's context cheap). Reach for `agentType: feature-dev:code-explorer` instead when the task needs a full architecture/dependency map before an approach can be chosen.

For a hard bug with several plausible root causes and no way to rule one out from code alone, propose an [agent team](https://code.claude.com/docs/en/agent-teams) to the user instead — teammates test competing hypotheses in parallel and challenge each other's findings, which no sub-agent (report-back-only) can do. Ask before spawning: experimental, needs `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, and costs meaningfully more tokens than sub-agents.

Stop when a new fact could no longer flip the chosen approach. Digging further for its own sake is ceremony too.

---

# Phase 3 — Evaluate Like a Senior Engineer

Go through all seven dimensions — correctness, failure modes, scale & performance, operational safety, maintainability, security, testing — mark each relevant or not, one line why. Full checklist: [EVALUATION.md](EVALUATION.md) — open for security-sensitive, failure-mode-heavy, or unfamiliar-domain work; skip only when every relevant dimension is already obvious from Phase 2 evidence.

Evaluate what the evidence says is actually at risk — not hypothetical bottlenecks or manufactured edge cases nobody will hit.

Done when: all seven dimensions are accounted for and every one marked relevant has been checked against actual evidence, not assumption.

---

# Phase 4 — Compare Alternatives

Generate every approach that's a real fork in the road, investigated, never faked to hit a count. Most tasks have one — say so and move on. When 2-3 genuinely compete, compare them on correctness, implementation complexity, operational cost, blast radius, reversibility, and long-term maintenance burden.

Done when: one approach is chosen and every losing alternative has a one-line reason.

If the chosen approach still rests on unconfirmed assumptions — scope, priorities, risk tolerance, a tradeoff between alternatives — invoke the `grilling` skill to grill the user before drafting the plan. Runs on investigated evidence instead of guesses now; cheaper to settle here than discard a written plan built on a wrong premise.

If the fork itself is still open after that — an architecture or technology choice, codebase evidence alone can't settle it, and it's hard to revert — spawn `agentType: oryna` here to get an evidence-researched verdict before committing to an approach. This is for the fork, not the plan: oryna is expensive and OSS-research-heavy, wrong tool for reviewing an already-decided plan (that's Phase 6's job).

---

# Phase 5 — Produce the Plan

```md
## Problem
<what is happening and why it matters>

## Constraints & Assumptions
- <verified constraint>

## Key Findings
- <important discoveries>
- <surprises>
- <unknowns>

## Proposed Approach
<recommended solution and rationale>

### Alternatives Considered
- <alternative> — rejected because <reason>

## Risks & Edge Cases
- <risk> — <mitigation>

## Implementation Plan
1. <module/file> — <change>
2. <module/file> — <change>

## Execution Skills
- <skill-name> — <when/why during Phase 7>, or "None" if no other skill applies

## Tests
- <coverage strategy>

## Rollout / Rollback
- <deployment and recovery strategy>

## Open Questions
- <only if genuinely blocking>
```

No ceremony.

Done when: every section has evidence-backed content — no placeholders left.

---

# Trivial Gate

Gates the opus review in both Phase 6 (plan) and Phase 8 (diff). A plan or diff is trivial only if ALL of these hold — any fail means not trivial:

- touches exactly 1 file
- diff ≤ 15 lines
- no change to a public API, exported signature, or documented behavior
- does not touch config, migrations, auth/security paths, CI, or build files
- reversible with a single `git revert`

Any line uncertain to call — treat it as failed.

---

# Phase 6 — Get Approval

Once the plan (Phase 5) is ready: spawn a review agent on model `opus`, `agentType: Plan` — fresh eyes on the plan, catching gaps before the human reads it — and fold its findings in. If a `planship-mode` reminder for a mode other than `normal` is in context, use the model and effort it specifies instead of `opus` at default effort. Exception: if the plan passes every line of the Trivial Gate, you may re-read it yourself instead — the human approval gate immediately below backstops this case. Done when: the plan reflects the review's findings (or your own re-read), fixed or explicitly rejected.

Then call `ExitPlanMode` with the plan and wait for approval — this is the boundary where a Plan/Execute split switches to the execution model. Start implementing only after that call returns approved.

If the plan changes before or at that gate — human feedback, a revision request — revise it, then run the review again only when the change is material: a different approach, scope, or risk profile. Trivial edits (wording, a renamed variable, a dropped open question) skip the extra pass.

---

# Phase 7 — Execute

Before touching files, ask the user whether to implement on the current branch or create a new one — don't default to a new branch. If new: branch count scales with the plan — one branch for the whole plan when it's a single unit of work; one per independently mergeable/revertable step when the Implementation Plan has parts that stand on their own.

Follow the approved plan: invoke the Execution Skills it names as each applies, keep changes small and reviewable, avoid speculative abstractions, verify assumptions continuously, update the plan if reality changes materially.

Done when: the change matches the plan and is verified working (tests pass, or drive the flow per the `verify` skill) — then move to Phase 8.

---

# Phase 8 — Independent Review

Invoke the `code-review` skill — fresh eyes, no stake in the plan or the code just written — before reporting done. Point it at the merge-base for the branch; it checks the diff on two axes — Spec (does the diff match the Phase 5 plan) and Standards (does it match this codebase's existing conventions) — and flags what the implementing pass missed on either. It's not the quality gate; Phase 7's own test/build run is. Don't ask it to verify what it can't execute.

Skip this review only when BOTH hold: (1) the diff passes every line of the Trivial Gate, and (2) an automated check that exercises the changed lines passed in Phase 7 — an existing test, or a small runnable check that fails on the pre-change code for a behavior change. A check that would've passed either way proves nothing; re-reading your own diff counts as neither.

Done when: the review agent has returned and each finding is either fixed or named to the user as an accepted risk.

---

# Phase 9 — Verify

This is the completion gate, not optional. Once Phase 8 is done, tell the user to run the `verify` skill — don't invoke it yourself. Nothing is "done" until they've run it and it has reported pass/fail.

Done when: `verify` has been run and any failure it reports is fixed or named to the user as an accepted risk.

Ready to ship? Tell the user the `ship-pr` skill can open the PR — don't invoke it yourself. Phase 7 produced more than one branch → tell the user to run `ship-pr` once per branch, in the dependency order the Implementation Plan laid out. Then move to Phase 10.

---

# Phase 10 — Improve this skill

See [`self-improve-after-running.md`](../self-improve-after-running.md).

Done when: the friction checklist there is checked — nothing to fix, or a diff was proposed and either applied or declined by Boss.
