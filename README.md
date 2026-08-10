# planship

Three Claude Code skills that cover the full loop of a coding task: **plan** it, **ship** it, **test** it.

## Skills

- **adaptive-plan-mode** — Plan before implementing. Scales planning depth to task risk; skips ceremony for typo fixes and one-liners, forces a real plan before anything non-trivial.
- **ship-pr** — Ships the current branch through its full PR/MR life cycle on GitHub or GitLab: pre-PR review, PR creation, tracking, and merge-and-sync.
- **user-tester** — Tests a web project end-to-end by simulating a demanding real user (a "mystery shopper") in a browser before release.

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
  skills/
    adaptive-plan-mode/
    ship-pr/
    user-tester/
    self-improve-after-running.md    # shared by adaptive-plan-mode and ship-pr
```

## License

MIT
