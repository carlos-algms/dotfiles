---
name: subagent-driven-development
description: >
  Use when executing implementation plans with independent tasks in the current
  session
---

# Subagent-driven development

Execute plan by dispatching fresh subagent per task, with two-stage review after
each: spec compliance review first, then code quality review.

**Why subagents:** Isolated context per task. Controller coordinates only.
Subagents never inherit session history; controller constructs exactly what they
need. Preserves controller context for orchestration.

**Core principle:** Fresh subagent per task + two-stage review (spec then
quality) = high quality, fast iteration

**Continuous execution:** Do not pause to check in with your human partner
between tasks. Execute all tasks from the plan without stopping. The only
reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely
prevents progress, or all tasks complete. "Should I continue?" prompts and
progress summaries waste their time — they asked you to execute the plan, so
execute it.

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
task checkbox from `- [ ]` to `- [x]` immediately after the task is implemented,
verified, and approved by both reviewers. Do not batch checkbox updates at the
end.

If not approved, track progress with TodoWrite and chat status only.

## Commit policy

Read the plan for its commit policy.

If the plan has no commit policy, ask before implementation:

```markdown
How should commits be handled for this plan?

**A**. One commit per task **B**. One commit at the end **C**. No commits
```

Follow the selected policy. Never commit when the policy is `No commits`.

## When to use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "subagent-driven-development" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
}
```

## The process

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task";
        "Dispatch implementer subagent (./implementer-prompt.md)" [shape=box];
        "Implementer subagent asks questions?" [shape=diamond];
        "Answer questions, provide context" [shape=box];
        "Implementer subagent implements, tests, maybe commits, self-reviews" [shape=box];
        "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [shape=box];
        "Spec reviewer subagent confirms code matches spec?" [shape=diamond];
        "Implementer subagent fixes spec gaps" [shape=box];
        "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [shape=box];
        "Code quality reviewer subagent approves?" [shape=diamond];
        "Implementer subagent fixes quality issues" [shape=box];
        "Mark task complete in TodoWrite" [shape=box];
    }

    "Read plan, run safety gates, note plan_path + task ids + scene-setting context, create TodoWrite" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Dispatch final code reviewer subagent for entire implementation" [shape=box];
    "Use verification-before-completion and report final status" [shape=box style=filled fillcolor=lightgreen];

    "Read plan, run safety gates, note plan_path + task ids + scene-setting context, create TodoWrite" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, maybe commits, self-reviews" [label="no"];
    "Implementer subagent implements, tests, maybe commits, self-reviews" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)";
    "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" -> "Spec reviewer subagent confirms code matches spec?";
    "Spec reviewer subagent confirms code matches spec?" -> "Implementer subagent fixes spec gaps" [label="no"];
    "Implementer subagent fixes spec gaps" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [label="re-review"];
    "Spec reviewer subagent confirms code matches spec?" -> "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [label="yes"];
    "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" -> "Code quality reviewer subagent approves?";
    "Code quality reviewer subagent approves?" -> "Implementer subagent fixes quality issues" [label="no"];
    "Implementer subagent fixes quality issues" -> "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [label="re-review"];
    "Code quality reviewer subagent approves?" -> "Mark task complete in TodoWrite" [label="yes"];
    "Mark task complete in TodoWrite" -> "More tasks remain?";
    "More tasks remain?" -> "Dispatch implementer subagent (./implementer-prompt.md)" [label="yes"];
    "More tasks remain?" -> "Dispatch final code reviewer subagent for entire implementation" [label="no"];
    "Dispatch final code reviewer subagent for entire implementation" -> "Use verification-before-completion and report final status";
}
```

Before dispatching subagents:

1. Read the plan file once. STOP if `plan_path` was not provided OR the file
   does not exist OR is empty. Ask the user for a valid plan file before
   proceeding. Skills load at the step that needs them (see step annotations
   `**Skills (load if not already loaded):**` in the plan) - implementer
   subagents handle that themselves. Do NOT pre-load skills upfront
2. Run branch safety gate
3. Run plan tracking gate
4. Resolve commit policy
5. Note `plan_path`, task ids, and scene-setting context per task. Do NOT
   extract task text verbatim - subagents read the plan themselves via pointers
6. Create TodoWrite

Tell implementer subagents the selected commit policy:

- `One commit per task`: commit after that task is implemented and verified
- `One commit at the end`: do not commit during individual tasks
- `No commits`: do not commit

## `base_ref` discovery

Capture two values:

1. Plan-level (final reviewer): `git merge-base HEAD <default-branch>` where
   default-branch is `main` or `master` (detect with
   `git symbolic-ref refs/remotes/origin/HEAD`)
2. Per-task (per-task reviewers): capture `git rev-parse HEAD` at task start,
   before dispatching the implementer. Per-task `base_ref` = that SHA. Task 1's
   base equals the plan-level merge-base only on a clean branch with no prior
   commits; otherwise it's whatever HEAD is at task start
3. With `One commit per task`, per-task base shifts after each commit; recapture
   at the start of each task

**Preconditions before dispatching:**

1. Worktree clean of unrelated changes. Dirty at task start: ask the user before
   proceeding (otherwise reviewers audit user's WIP edits)
2. `changed_files` captured at task end, BEFORE any per-task commit. After
   `git commit`, `git status --porcelain` returns empty; derive from
   `git diff --name-only <task_base_ref>...HEAD` instead. For renames, use the
   destination path

## Model selection

Use the least powerful model that handles each role.

- 1-2 files, complete spec, mechanical implementation → cheap/fast model
- Multi-file integration, pattern matching, debugging → standard model
- Architecture, design, review, broad codebase reasoning → most capable model

## Handling implementer status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts.
Read the concerns before proceeding. If the concerns are about correctness or
scope, address them before review. If they're observations (e.g., "this file is
getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided.
Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:

1. If it's a context problem, provide more context and re-dispatch with the same
   model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, escalate to the human

**Never** ignore an escalation or force the same model to retry without changes.
If the implementer said it's stuck, something needs to change.

## Review retry budget

3 rounds per reviewer (spec, code-quality, AND final reviewer). One round = one
dispatch + one implementer fix attempt. Round 4: STOP. Escalate with the
reviewer's latest issues and the implementer's latest attempt.

Repeated rejection often signals a plan defect, not a fix defect. Escalation
gives the user a chance to update the plan.

## Dispatch payloads

Do NOT load template files into your own context. Each subagent reads its
template directly. Pass the absolute template path + the values it needs.

Conventions:

- `<skill_dir>` resolves to the directory of THIS SKILL.md (e.g.
  `/Users/me/.claude/skills/subagent-driven-development`). Substitute the real
  absolute path before sending
- `changed_files` is a SPACE-separated list of paths suitable for use after `--`
  in git commands (e.g. `src/a.ts src/b.ts`). No JSON, no commas, no brackets
- WRONG: pasting the template body into the prompt
- RIGHT: the prompt literally contains the `MUST read instructions at ...` line
  and the values

**Implementer:**

```text
MUST read instructions at <skill_dir>/implementer-prompt.md FIRST. Do not
act until you have read it. Then apply:
  task_summary  = <one-line summary of the task>
  plan_path     = <abs path>
  task_id       = <task number / heading>
  working_dir   = <abs path>
  commit_policy = <One commit per task | One commit at the end | No commits>
  context       = <scene-setting only: where this task fits, prior task
                   outputs, dependencies, architectural notes not in the plan>
```

**Spec compliance reviewer:**

```text
MUST read instructions at <skill_dir>/spec-reviewer-prompt.md FIRST. Do not
act until you have read it. Then apply:
  task_summary  = <one-line summary of the task>
  plan_path     = <abs path>
  task_id       = <task number / heading>
  base_ref      = <SHA at task start, or merge-base for final review>
  changed_files = <space-separated paths>
```

**Code quality reviewer:**

```text
MUST read instructions at <skill_dir>/code-quality-reviewer-prompt.md FIRST.
Do not act until you have read it. Then apply:
  task_summary         = <one-line summary of the task>
  description          = <one-line task summary>
  plan_or_requirements = "Task <task_id> from <plan_path>"
  base_ref             = <SHA>
  changed_files        = <space-separated paths>
```

## Red flags

**Never:**

- Start implementation on main/master branch without explicit user consent
- Skip reviews (spec compliance OR code quality)
- Proceed with unfixed issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Paste full task text into the prompt (pass `plan_path` + `task_id` only)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance (spec reviewer found issues = not
  done)
- Skip review loops (reviewer found issues = implementer fixes = review again)
- Let implementer self-review replace actual review (both are needed)
- **Start code quality review before spec compliance is ✅** (wrong order)
- Move to next task while either review has open issues

**If subagent asks questions:**

- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

**If reviewer finds issues:**

- Implementer (same subagent) fixes them
- Reviewer reviews again
- Repeat until approved
- Don't skip the re-review

**If subagent fails task:**

- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

## Integration

**Related workflow skills:**

- **./code-quality-reviewer-prompt.md** - Code review template (wraps
  `requesting-code-review`)
- **verification-before-completion** - Verifies before claiming completion
