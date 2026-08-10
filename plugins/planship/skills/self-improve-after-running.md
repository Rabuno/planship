# After running — improve this skill

External reference, pointed to by [`adaptive-plan-mode`](adaptive-plan-mode/SKILL.md) and [`ship-pr`](ship-pr/SKILL.md) as their final step — a real step, not an optional addendum: check this before telling Boss the task is finished.

Friction = any of:
- a step's instructions didn't match what you found
- you had to skip, reorder, or reinterpret a step
- Boss corrected an action or a plan mid-run
- an ambiguity got silently resolved by judgment call instead of a clear instruction — silent resolution still counts, even under Auto Mode's "don't stop, just decide" bias; it means the skill left a gap, not that there was nothing to log
- a feedback memory got written about this specific skill's steps during this run — that memory captures the lesson generally, it doesn't fix the source document; still do this pass

None of the above happened → stay silent, run is done.

Any hit → read `~/.claude/skills/writing-great-skills/SKILL.md` and its `GLOSSARY.md`, propose a specific edit to *the skill that just ran* that would have prevented that friction. Show Boss the diff, apply only on approval.
