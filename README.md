# planship

A small, opinionated methodology for shipping code with an AI coding agent: **plan it, ship it, test it** — in that order, every time.

**Without planship:** "add retries to the payment call" turns into a 40-line change straight to `main` — no plan, no review, no one clicking through the flow before it ships. The bug (retry on a non-idempotent charge) surfaces in production.

**With planship:** `adaptive-plan-mode` investigates the call site first, flags the idempotency risk in the plan, gets it reviewed before a line is written; `ship-pr` runs an independent Standards/Spec review on the diff before opening the PR; `user-tester` clicks through the retry path in a real browser before anyone else does. Same request, same agent — the loop is what catches it.

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

## Modes

`/planship-mode [economy|normal|premium]` switches which model the two model-selectable spots in planship use — adaptive-plan-mode's Phase 6 plan-review agent, and the `oryna` agent. Nothing else changes; `ship-pr`, `user-tester`, and `grilling` don't spawn a model-selectable agent.

| Mode | Review agent | oryna |
|---|---|---|
| `economy` | `sonnet` | `sonnet` |
| `normal` (default) | `opus` | `opus` |
| `premium` | `opus`, effort/thinking max | `opus`, effort/thinking max |

State lives in `~/.claude/planship/mode.txt`; a `UserPromptSubmit` hook re-injects the current mode each turn (skill/agent instructions are static text and can't read state on their own). No file, or `normal`, means no reminder — planship's baseline behavior.

## Stats

`/planship-stats` prints a scoreboard from `~/.claude/planship/log.jsonl`: how many plans correctly skipped ceremony via the Trivial Gate, how many independent reviews caught findings before ship. Lines are written by the agent executing the skill — an interrupted or non-planship run logs nothing, so the numbers undercount, never overcount.

## External dependency

- **code-review** — adaptive-plan-mode (Phase 8) and ship-pr (step 3) call the `code-review` skill for Spec/Standards review of the diff. Not bundled here; install it separately if you don't already have it.

## Install

### Claude Code

```
/plugin marketplace add Rabuno/planship
/plugin install planship@planship
```

### Codex

Codex loads the shared skills through `.codex-plugin/plugin.json`:

```
codex plugin marketplace add C:\path\to\planship
codex plugin add planship@planship
```

Start a new Codex thread after installation so it loads the plugin. Claude-specific hooks, slash
commands, and agent configuration remain under `.claude-plugin/`; Codex uses the shared `skills/`
directory.

## Structure

Layout follows [obra/superpowers](https://github.com/obra/superpowers): skills and agents live at repo root, harness-agnostic; each harness gets its own thin plugin-config folder pointing at the same root content. Claude Code and Codex are wired up without duplicating the shared skills.

```
.codex-plugin/
  plugin.json                        # Codex plugin manifest
.claude-plugin/
  marketplace.json                   # Claude Code marketplace manifest
  plugin.json                        # Claude Code plugin manifest + hooks
commands/
  planship-mode.md                   # /planship-mode slash command
  planship-stats.md                  # /planship-stats slash command
hooks/                                # Claude-Code-specific (PreToolUse/UserPromptSubmit hooks)
  adaptive-plan-mode-reminder.ps1
  advisor-trigger.ps1
  planship-mode-reminder.ps1
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
