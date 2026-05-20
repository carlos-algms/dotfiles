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
5. If commit policy is `One commit per task`, commit after the task is complete
   and verified
6. Mark as completed

### Step 3: Complete development

After all tasks complete and verified:

- Run final verification from the plan
- Run any additional relevant checks for the changed files
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

## Remember

- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when the plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent
