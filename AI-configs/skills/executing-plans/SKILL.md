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

Plan file uses checkboxes: tick them. Not optional.

- Preserve all original content except checkbox state
- Update each `- [ ]` to `- [x]` immediately after completing and verifying the
  step
- Do not batch checkbox updates at the end
- Also track progress with TodoWrite in parallel (harness-native task list)

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
   Skills load at the step that needs them - see step annotations
   `**Skills (load if not already loaded):**`. Do NOT load skills upfront
2. Run branch safety gate
3. Resolve commit policy
4. Review critically - identify any questions or concerns about the plan
5. If concerns: Raise them with your human partner before starting
6. If no concerns: Create TodoWrite and proceed

### Step 2: Execute tasks

For each task:

1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Tick each completed step immediately after verification
5. Dispatch spec compliance reviewer subagent with pointers (see
   `Reviewer dispatch pointers` below)
6. Spec reviewer flags issues -> fix -> re-dispatch reviewer -> repeat until ✅
7. Dispatch code quality reviewer subagent with pointers
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

Reviewer reads plan and reconstructs diff.

**Preconditions before dispatching:**

1. Worktree clean of unrelated changes. If dirty at task start, ask the user
   before proceeding (otherwise reviewers audit user's WIP edits)
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

**Dispatch payloads (do NOT load templates into your context):**

Reviewer subagents read their templates directly. Pass template path + values.

Conventions:

- `<skill_dir>` is the absolute path to the `subagent-driven-development` skill
  directory (the templates live there). Resolve it before sending (e.g.
  `realpath ~/.claude/skills/subagent-driven-development`) and reuse
- `changed_files` is a SPACE-separated list of paths suitable for use after `--`
  in git commands. No JSON, no commas, no brackets
- WRONG: pasting the template body into the prompt
- RIGHT: the prompt literally contains the `MUST read instructions at ...` line
  and the values

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
  task_summary         = <one-line summary of the task>
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
- Reuse a reviewer subagent across tasks (each review = fresh subagent)
- Let your own self-check replace the reviewer subagent (both are needed)

## Remember

- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when the plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent
- Reviewer subagents are neutral: never share session history. Pass plan_path,
  task_id, base_ref, changed_files
