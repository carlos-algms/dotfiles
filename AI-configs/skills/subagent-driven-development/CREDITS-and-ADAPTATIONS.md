# Credits and adaptations for subagent-driven-development

Original source:
<https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/subagent-driven-development/SKILL.md>

## Adaptations

- Removed `superpowers` namespace references
- Delegated each complete task/review/commit loop to its implementer
- Added terse implementer/reviewer result contracts
- Added a finalizer implementer for whole-plan review and final commit
- Replaced finishing workflow with `verification-before-completion`
- Replaced code quality reviewer prompt reference with `requesting-code-review`
- Removed `test-driven-development` skill reference while keeping TDD references
- Scoped the `HANDOFF` relay to the finalizer, the only subagent that emits it
- Barred the orchestrator from running final verification or the full gate
- Delegated snapshot lifecycle to the shared `executing-plans` rule
- Removed alternative workflow references
