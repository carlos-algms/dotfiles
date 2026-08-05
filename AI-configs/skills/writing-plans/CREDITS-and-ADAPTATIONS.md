# Credits and adaptations for writing-plans

Original source:
<https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/writing-plans/SKILL.md>

## Adaptations

- Removed `superpowers` namespace references
- Removed isolated worktree skill requirement
- Changed default saved plan path from `docs/superpowers/plans/` to
  `docs/plans/`
- Added pre-plan commit policy prompt with per-task commits, one commit at the
  end, or no commits
- Added commit policy metadata and plan-owned commit checkpoints
- Added immediate checkbox ticking requirement
- Added single-writer task ownership for nested implementer review loops
- Moved the execution-mode prompt before writing so the header never saves an
  unresolved mode
- Added plan-reviewer checks for exact header literals, exact final-verification
  commands, and final verification duplicated outside its checkpoint
