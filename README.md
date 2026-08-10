# planship

A small, opinionated methodology for shipping code with an AI coding agent: **plan it, ship it, test it** — in that order, every time.

Most skill collections are a grab-bag you invoke ad hoc. planship is a loop: don't write code until the plan is right-sized to the risk; don't call a change done until an independent pass has reviewed the diff; don't ship a feature without a demanding user actually clicking through it first. Each stage hands off evidence to the next — a plan the review checks against, a diff the tests verify, a working build the user-tester interrogates. Skip a stage and the next one has nothing to check against.

## The loop

1. **Plan** — `adaptive-plan-mode` scales planning depth to what's actually at stake. A typo fix skips ceremony; an irreversible schema change gets investigated, grilled for open decisions, and reviewed before a line of code is written.
2. **Ship** — `ship-pr` takes the implemented change through self-review, PR creation, and merge-and-sync — the full PR/MR life cycle on GitHub or GitLab, not just "open a PR and walk away."
3. **Test** — `user-tester` drives the shipped feature in a real browser like a demanding, skeptical user would, before anyone else finds the bug.

Two supporting pieces feed the loop when it hits a decision it can't resolve alone:

- **grilling** — interviews you one question at a time until an open decision has a shared answer, instead of guessing.
- **oryna** (agent) — for the rare fork that's expensive to reverse and codebase evidence alone can't settle: researches how major OSS projects and production post-mortems handled the same call, then delivers a committed verdict.

## Skills

- **adaptive-plan-mode** — Plan before implementing. Skips ceremony for typo fixes and one-liners, forces a real plan before anything non-trivial.
- **ship-pr** — Ships the current branch through its full PR/MR life cycle: pre-PR review, PR creation, tracking, and merge-and-sync.
- **user-tester** — Tests a web project end-to-end by simulating a demanding real user (a "mystery shopper") in a browser before release.
- **grilling** — Interviews you relentlessly about a plan's open decisions, one question at a time. Vendored from [mattpocock/skills](https://github.com/mattpocock/skills) (`skills/productivity/grill-me`), © Matt Pocock.

## Agents

- **oryna** — Grizzled senior advisor for decisions you're unsure about (architecture, tech selection, build-vs-buy, migrations). Researches how major OSS projects and forums settled the same question, then delivers an independent, evidence-backed verdict. Runs on `opus`.

## External dependency

- **code-review** — adaptive-plan-mode (Phase 8) and ship-pr (step 3) call the `code-review` skill for Spec/Standards review of the diff. Not bundled here; install it separately if you don't already have it.

## Install

```
/plugin marketplace add Rabuno/planship
/plugin install planship@planship
```

## Structure

Layout follows [obra/superpowers](https://github.com/obra/superpowers): skills and agents live at repo root, harness-agnostic; each harness gets its own thin plugin-config folder pointing at the same root content. Currently only `.claude-plugin/` is wired up — folders for other harnesses (Codex, opencode, agy) can be added later without touching `skills/` or `agents/`.

```
.claude-plugin/
  marketplace.json                   # Claude Code marketplace manifest
  plugin.json                        # Claude Code plugin manifest + hooks
hooks/                                # Claude-Code-specific (PreToolUse/UserPromptSubmit hooks)
  adaptive-plan-mode-reminder.ps1
  advisor-trigger.ps1
agents/
  oryna.md
skills/
  adaptive-plan-mode/
  ship-pr/
  user-tester/
  grilling/
  self-improve-after-running.md      # shared by adaptive-plan-mode and ship-pr
```

## License

MIT for original content (adaptive-plan-mode, ship-pr, user-tester, oryna). The `grilling` skill is vendored from a third party — see its credit above; that file keeps its original terms.
