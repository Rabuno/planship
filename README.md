# planship

Three Claude Code skills that cover the full loop of a coding task: **plan** it, **ship** it, **test** it.

## Skills

- **adaptive-plan-mode** — Plan before implementing. Scales planning depth to task risk; skips ceremony for typo fixes and one-liners, forces a real plan before anything non-trivial.
- **ship-pr** — Ships the current branch through its full PR/MR life cycle on GitHub or GitLab: pre-PR review, PR creation, tracking, and merge-and-sync.
- **user-tester** — Tests a web project end-to-end by simulating a demanding real user (a "mystery shopper") in a browser before release.
- **grilling** — Interviews you relentlessly about a plan's open decisions, one question at a time, until there's a shared understanding. Used by adaptive-plan-mode and user-tester to settle judgment calls instead of guessing. Vendored from [mattpocock/skills](https://github.com/mattpocock/skills) (`skills/productivity/grill-me`), © Matt Pocock.

## Agents

- **oryna** — Grizzled senior advisor for decisions you're unsure about (architecture, tech selection, build-vs-buy, migrations). Researches how major OSS projects and forums settled the same question, then delivers an independent, evidence-backed verdict. adaptive-plan-mode spawns it for hard-to-reverse forks that codebase evidence alone can't settle. Runs on `opus`.

## External dependency

- **code-review** — adaptive-plan-mode (Phase 8) and ship-pr (step 3) call the `code-review` skill for Spec/Standards review of the diff. Not bundled here; install it separately if you don't already have it.

## Install

```
/plugin marketplace add Rabuno/planship
/plugin install planship@planship
```

## Structure

```
.claude-plugin/marketplace.json      # marketplace manifest
plugins/planship/
  .claude-plugin/plugin.json         # plugin manifest + hooks
  hooks/adaptive-plan-mode-reminder.ps1
  agents/
    oryna.md
  skills/
    adaptive-plan-mode/
    ship-pr/
    user-tester/
    grilling/
    self-improve-after-running.md    # shared by adaptive-plan-mode and ship-pr
```

## License

MIT for original content (adaptive-plan-mode, ship-pr, user-tester, oryna). The `grilling` skill is vendored from a third party — see its credit above; that file keeps its original terms.
