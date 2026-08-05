# Credits and adaptations for executing-plans

Original source:
<https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/executing-plans/SKILL.md>

## Adaptations

- Removed `superpowers` namespace references
- Replaced subagent redirect with an inline/subagent execution handoff
- Added immediate checkbox ticking after verified steps
- Added plan-owned commit cadence with inline or delegated checkpoint ownership
- Added final whole-plan review and fresh `verification-before-completion` gate
- Added a single-runner rule for final verification, owned per execution mode
- Added a shared baseline-snapshot lifecycle with per-mode cleanup ownership
- Removed integration section
