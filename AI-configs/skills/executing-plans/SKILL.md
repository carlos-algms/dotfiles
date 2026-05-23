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

**Note:** If subagents are available and the plan has mostly independent tasks,
offer `subagent-driven-development` as an alternative. Do not switch workflows
without user approval.

## Plan location

If plan is saved to a file: reviewer dispatch uses pointer-style (see
`Reviewer dispatch pointers`).

If plan is chat-memory only: reviewer dispatch falls back to paste-style.
Controller pastes the task spec into the reviewer prompt; pointer fields
(`base_ref`, `changed_files`) still apply for diff reconstruction.

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

If the plan file uses checkboxes, ask before editing it to track progress.

If approved, preserve all original content except checkbox state. Update each
checkbox from `- [ ]` to `- [x]` immediately after completing and verifying that
step. Do not batch checkbox updates at the end.

If not approved, track progress with TodoWrite and chat status only.

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

1. Read plan file
2. Run branch safety gate
3. Run plan tracking gate
4. Resolve commit policy
5. Review critically - identify any questions or concerns about the plan
6. If concerns: Raise them with your human partner before starting
7. If no concerns: Create TodoWrite and proceed

### Step 2: Execute tasks

For each task:

1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. If plan tracking was approved, tick each completed step immediately after
   verification
5. Dispatch spec compliance reviewer subagent (cold, fresh context) with
   pointers only (see `Reviewer dispatch pointers` below)
6. Spec reviewer flags issues -> fix -> re-dispatch reviewer -> repeat until ✅
7. Dispatch code quality reviewer subagent (cold, fresh context) with pointers
   only
8. Code reviewer flags issues -> fix -> re-dispatch reviewer -> repeat until ✅
9. If commit policy is `One commit per task`, commit after both reviews approve
10. Mark as completed

**Never move to the next task while either reviewer has open issues.** Spec
compliance must approve before dispatching the code quality reviewer.

**Review retry budget:** 3 rounds per reviewer. One round = one dispatch + one
fix attempt. If round 4 would be needed, STOP. Escalate to the user with the
reviewer's latest issues and the implementer's latest attempt. Do not silently
continue.

## Reviewer dispatch pointers

Dispatch pointers only when plan is on disk. Reviewer reads plan and
reconstructs diff. Paste-style fallback for memory plans (see `Plan location`).

**Preconditions before dispatching:**

1. Worktree clean of unrelated changes. If dirty at task start, ask the user
   before proceeding (otherwise reviewers audit user's WIP edits)
2. `changed_files` captured at task end, BEFORE any per-task commit. After
   `git commit`, `git status --porcelain` returns empty; capture from
   `git diff --name-only <task_base_ref>...HEAD` instead

**Pointer set per dispatch:**

1. `plan_path` - absolute path to plan file (or `task_spec` paste for memory)
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

**Subagent instructions (include verbatim in dispatch):**

```text
You are a cold reviewer. You have no prior context.

1. Read the plan at <plan_path>. Locate task <task_id>. That is the spec
2. Reconstruct the change set:
   - Committed diff: `git diff <base_ref>...HEAD -- <changed_files>`
   - Staged diff:    `git diff --cached -- <changed_files>`
   - Unstaged diff:  `git diff -- <changed_files>`
   - Untracked files: read each path in <changed_files> not tracked by git
3. One-hop scope: identify exported/changed symbols in <changed_files>, run
   `rg --hidden -F '<symbol>'` to find importers/callers, read each, flag
   issues caused by the change. Do not flag pre-existing issues in callers
4. Role:
   - spec-compliance: report MISSING (spec items absent) and EXTRA (work not in
     spec). Reference task spec lines
   - code-quality: load `requesting-code-review` and apply it
5. Output: ✅ approved, or a list of issues with file:line refs
```

Fallback if `base_ref` is unclear: ask the user before dispatching.

### Step 3: Complete development

After all tasks complete and verified:

- Run final verification from the plan
- Run any additional relevant checks for the changed files
- Dispatch final code quality reviewer subagent (cold, fresh context) with
  pointers only. Scope = all files changed by the plan (`base_ref` = branch
  base, `changed_files` = full plan diff)
- Fix any issues, re-dispatch reviewer, repeat until ✅. Retry budget (3 rounds)
  applies; round 4 escalates to user
- Under `One commit per task`, final reviewer fixes create extra commits.
  Acceptable. Do not amend prior commits
- Use `verification-before-completion` before claiming the plan is complete
- If commit policy is `One commit at the end`, commit after final verification
- Report changed files, verification results, and any remaining risk

## When to stop and ask for help

**STOP executing immediately when:**

- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to revisit earlier steps

**Return to Review (Step 1) when:**

- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Red flags

**Never:**

- Skip either reviewer (spec compliance OR code quality)
- Start code quality review before spec compliance is ✅ (wrong order)
- Move to the next task while either reviewer has open issues
- Reuse a reviewer subagent across tasks (each review = fresh cold subagent)
- Let your own self-check replace the reviewer subagent (both are needed)

## Remember

- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when the plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent
- Reviewer subagents are cold and neutral: never share session history. Pass
  pointers (plan path, task id, base ref, changed files), not pasted text/diffs
