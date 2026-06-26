---
name: executing-plans
description: >
  Use when you have a written implementation plan to execute in a separate
  session with review checkpoints
---

# Executing plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this
plan."

## Execution workflow gate

If subagents are available and the plan has mostly independent tasks, ask which
workflow to use before implementation:

1. Continue inline with `executing-plans`
2. Switch to `subagent-driven-development`

Do not start task execution until the user answers. Do not switch workflows
without user approval. Skip this gate only when the user already explicitly
chose inline execution for this plan.

## Branch safety

Before implementation, inspect the current branch.

If on `main` or `master`, ask which path to use:

1. Create a feature branch in the current working tree
2. Create a worktree under `.worktrees/<branch-name>/` in the current working
   directory
3. Continue on `main` or `master`

Recommend a feature branch for simple work. Recommend a worktree for risky work,
parallel work, or changes that need stronger isolation.

Continuing on `main` or `master` requires explicit user consent.

When creating a worktree, ensure `.worktrees/` is listed in the target repo
`.gitignore`. Add it first if missing.

## Plan tracking

Plan file uses checkboxes: tick them. Mandatory.

- Preserve all original content except checkbox state
- Update exactly one `- [ ]` to `- [x]` immediately after completing and
  verifying that step, before starting the next step
- Never batch checkbox updates; one box per completed step, in order
- If the harness has a native task/todo list, also track progress there in
  parallel

## Commit policy

Read the plan for its commit policy.

If the plan has no commit policy, ask before implementation:

```markdown
How should commits be handled for this plan?

**A**. One commit per task **B**. One commit at the end **C**. No commits
```

Follow the selected policy. Never commit when the policy is `No commits`.

## The process

### Step 1: Load and review plan

1. Read plan file. STOP if `plan_path` was not provided OR the file does not
   exist OR is empty. Ask the user for a valid plan file before proceeding.
   Skills load at the step that needs them - see the plan file's step
   annotations `**Skills (load if not already loaded):**`. Do NOT load skills
   upfront
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. Run the execution workflow gate
5. Run branch safety gate
6. Resolve commit policy
7. If no concerns: Create TodoWrite and proceed

### Step 2: Execute tasks

For each task:

1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Tick each completed step immediately after verification
5. Dispatch spec compliance reviewer subagent with pointers (see
   `Reviewer dispatch pointers` below)
6. Spec reviewer flags issues -> fix -> apply the re-review decision rule below
7. Dispatch code quality reviewer subagent with pointers
8. Code reviewer flags issues -> fix -> apply the re-review decision rule below
9. If commit policy is `One commit per task`, commit after both review stages
   are resolved
10. Mark as completed

**Never move to the next task while either reviewer has unfixed issues.** Spec
compliance must be resolved before dispatching the code quality reviewer.

A review stage is resolved when the reviewer approves, or when every issue has
been fixed, verified, and explicitly self-closed under the re-review decision
rule.

**Diminishing returns / re-review decision rule:** Always dispatch the first
fresh reviewer for each required review stage. After fixing reviewer issues,
re-dispatch only when the fix could plausibly introduce new defects or when the
reviewer raised Critical / Important concerns that need independent
confirmation. Skip the second reviewer run when the fix is narrow, verified, and
does not change architecture, task direction, public behavior, public API,
cross-module contracts, or the plan/code ownership boundaries.

Use stricter judgment for spec compliance:

- Re-dispatch when the fix changes what the task delivers, reinterprets the
  plan, adds/removes behavior, changes file boundaries, or alters verification
- Skip re-review only for unambiguous mechanical fixes that satisfy the finding
  and pass the plan's targeted checks

Use diminishing returns more readily for code quality:

- Re-dispatch when the fix changes behavior, architecture, public API,
  cross-module contracts, concurrency/state flow, error handling, security,
  persistence, or test strategy
- Skip re-review for style, formatting, naming, import/dead-code cleanup, or
  narrow behavior-preserving changes whose risk is fully covered by targeted
  checks that passed

When skipping re-review, record the reviewer issue, the fix, and the
verification command that closed it in the final report. If committing before
the final report, also record it in the commit body or task handoff note. Do not
edit the plan solely to log skipped re-reviews.

**Review retry budget:** 3 rounds per reviewer. One round = one dispatch + one
fix attempt. If round 4 would be needed, STOP. Escalate to the user with the
reviewer's latest issues and the implementer's latest attempt. Do not silently
continue.

## Reviewer dispatch pointers

Reviewer reads plan and reconstructs diff.

**Preconditions before dispatching:**

1. Worktree clean of unrelated changes. Expected plan checkbox updates and
   prior-task changes are allowed under `No commits` and
   `One commit at the end`. If unrelated dirty changes exist at task start, ask
   the user before proceeding (otherwise reviewers audit user's WIP edits)
2. `changed_files` captured at task end, BEFORE any per-task commit. After
   `git commit`, `git status --porcelain` returns empty; capture from
   `git diff --name-only <task_base_ref>...HEAD` instead

**Pointer set per dispatch:**

1. `plan_path` - absolute path to plan file
2. `task_id` - task number/name in the plan
3. `base_ref` - see `base_ref discovery` below
4. `changed_files[]` - paths for the task scope (rename `A -> B` -> use `B`)
5. Reviewer role: `spec-compliance` or `code-quality`

**`base_ref` discovery:**

1. Plan-level (final reviewer): `git merge-base HEAD <default-branch>` where
   default-branch is detected via `git symbolic-ref refs/remotes/origin/HEAD`
2. Per-task (per-task reviewer): capture `git rev-parse HEAD` at task start,
   before any edits. Per-task `base_ref` = that SHA
3. With `One commit per task`, per-task base shifts after each commit; recapture
   at the start of each task

**Dispatch payloads. Do NOT read or open the template files yourself — the
reviewer subagents read them. Reading them into your context defeats the
offload:**

Reviewer subagents read their templates directly. Pass template path + values.

Conventions:

- `<skill_dir>` is the absolute path to the `subagent-driven-development` skill
  directory (the templates live there). Resolve it before sending (e.g.
  `realpath ~/.claude/skills/subagent-driven-development`) and reuse
- `changed_files` is a SPACE-separated list of paths suitable for use after `--`
  in git commands. No JSON, no commas, no brackets
- Pass the `MUST read instructions at ...` line plus values; never paste the
  template body into the prompt

```text
# Spec compliance reviewer
MUST read instructions at <skill_dir>/spec-reviewer-prompt.md FIRST.
Do not act until you have read it. Then apply:
  task_summary  = <one-line summary of the task>
  plan_path     = <abs path>
  task_id       = <task number / heading>
  base_ref      = <SHA at task start>
  changed_files = <space-separated paths>
```

```text
# Code quality reviewer
MUST read instructions at <skill_dir>/code-quality-reviewer-prompt.md
FIRST. Do not act until you have read it. Then apply:
  description          = <one-line task summary>
  plan_or_requirements = "Task <task_id> from <plan_path>"
  base_ref             = <SHA>
  changed_files        = <space-separated paths>
```

If `base_ref` is unclear: ask the user before dispatching.

### Step 3: Complete development

After all tasks complete and verified:

- Run final verification from the plan
- Run any additional relevant checks for the changed files
- Dispatch final code quality reviewer subagent. Scope = all files changed by
  the plan (`base_ref` = branch base, `changed_files` = full plan diff)
- Fix any issues, then apply the same diminishing returns / re-review decision
  rule using the code-quality branch. If the fix changes delivered behavior or
  spec compliance, re-dispatch the final reviewer and consider a spec compliance
  re-check for the affected task. Retry budget (3 rounds) applies; round 4
  escalates to user
- Under `One commit per task`, final reviewer fixes create extra commits.
  Acceptable. Do not amend prior commits
- **Mandatory gate — load and run `verification-before-completion`.** Loading
  the skill and running its Gate Function is required, not optional. Running the
  plan's verification commands does NOT satisfy this gate; the skill is the
  discipline, the commands are its input. Until the skill is loaded and its Gate
  Function passes, you may not: claim the plan complete, express completion,
  commit, or open a PR. No exceptions ("just this once", "commands already ran",
  "different words" are the exact rationalizations the skill forbids)
- If commit policy is `One commit at the end`, commit after final verification
- Report changed files, verification results, and any remaining risk

## When to stop and ask for help

**STOP executing immediately when:**

- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly
- A required reviewer cannot be dispatched

**Ask for clarification rather than guessing.**

## When to revisit earlier steps

**Return to Review (Step 1) when:**

- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Red flags

**Never:**

- Skip the required first-pass reviewer (spec compliance OR code quality)
- Start code quality review before spec compliance is resolved (wrong order)
- Move to the next task while either reviewer has unfixed issues
- Reuse a reviewer subagent across tasks (each review = fresh subagent)
- Let your own self-check replace the reviewer subagent (both are needed)
- Claim the plan complete, commit, or open a PR with
  `verification-before-completion` skipped (running its commands ≠ loading the
  skill; the load + Gate Function is mandatory)

## Remember

- Review plan critically first, then follow steps exactly
- Don't skip verifications; reference skills when the plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master without explicit user consent
- Reviewer subagents are neutral: never share session history. Pass plan_path,
  task_id, base_ref, changed_files
