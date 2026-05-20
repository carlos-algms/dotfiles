# Credits and adaptations for subagent-driven-development

Original source:
<https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/subagent-driven-development/SKILL.md>

## Adaptations

- Removed `superpowers` namespace references
- Added branch safety gate with feature branch, `.worktrees/<branch-name>/`, or
  explicit `main`/`master` consent
- Added instruction to ensure `.worktrees/` exists in target repo `.gitignore`
  when creating worktrees
- Added plan-file edit permission before checkbox tracking
- Added immediate task checkbox ticking after implementation, verification, and
  review approval
- Added commit policy gate for one commit per task, one commit at the end, or no
  commits
- Replaced finishing workflow with `verification-before-completion`
- Replaced code quality reviewer prompt reference with `requesting-code-review`
- Removed `test-driven-development` skill reference while keeping TDD references
- Removed alternative workflow references
