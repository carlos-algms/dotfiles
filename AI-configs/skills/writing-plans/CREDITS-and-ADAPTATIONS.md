# Credits and adaptations for writing-plans

Original source:
<https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/writing-plans/SKILL.md>

## Adaptations

- Removed `superpowers` namespace references
- Removed isolated worktree skill requirement
- Changed default saved plan path from `docs/superpowers/plans/` to
  `docs/plans/`
- Added plan location prompt for memory vs `docs/plans/`
- Added existing-plan-file prompt before adapting format
- Added pre-plan commit policy prompt with one commit per task, one commit at
  the end, or no commits
- Restored optional commit checkpoint step with removal guidance
- Added immediate checkbox ticking requirement
