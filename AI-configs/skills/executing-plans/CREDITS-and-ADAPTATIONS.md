# Credits and adaptations for executing-plans

Original source:
<https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/executing-plans/SKILL.md>

## Adaptations

- Removed `superpowers` namespace references
- Replaced subagent redirect with optional `subagent-driven-development` offer
- Replaced worktree requirement with branch safety gate
- Added `.worktrees/<branch-name>/` worktree preference
- Added instruction to ensure `.worktrees/` exists in target repo `.gitignore`
  when creating worktrees
- Added plan-file edit permission before checkbox tracking
- Added immediate checkbox ticking after verified steps
- Added commit policy gate for one commit per task, one commit at the end, or no
  commits
- Replaced mandatory finishing skill with final verification and report
- Added explicit `verification-before-completion` use before claiming completion
- Removed integration section
