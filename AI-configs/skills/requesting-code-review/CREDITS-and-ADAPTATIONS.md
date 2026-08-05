# Credits and adaptations for requesting-code-review

Original source:
<https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/requesting-code-review/SKILL.md>

## Adaptations

- Added committed-range, uncommitted-work, and mixed-work review scopes
- Added `git status --porcelain` support for uncommitted work
- Replaced pasted diffs with base-ref and changed-file pointers
- Updated example to use `docs/plans/`
- Reduced reviewer output to `PASS` or terse actionable findings
- Documented that ad-hoc review has no baseline snapshot or task scope, unlike
  plan execution
