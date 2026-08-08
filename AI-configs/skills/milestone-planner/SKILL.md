---
name: milestone-planner
description: >
  Create or update a terse milestone file composed of delegated implementation
  plans. Use only when the user directly invokes milestone-planner or explicitly
  asks to create or update a milestone plan. Do not infer use from large
  features, multiple plans, parallel work, sequential work, or PR decomposition.
---

# Milestone planner

**Announce at start:** "I'm using the milestone-planner skill to compose the
implementation plans."

Create a dependency graph of implementation plans. Keep the milestone file as a
small index, not a specification. Delegate every plan to a fresh subagent that
uses `writing-plans`. Never write or revise plan files in the main agent.

## Files

- Milestone: `docs/milestones/<name>.md`
- Plans: the main agent selects each exact path. Pass it to the plan writer as
  an authoritative override of the `writing-plans` default
- Default plan path override:
  `docs/plans/YYYY-MM-DD-<milestone-name>-<plan-name>.md`

Honor user-selected paths. Resolve every milestone link relative to the
milestone file.

## Document commit gate

Default `Plan file policy` to `Exclude`. This policy covers the plan file and
the milestone file listed under `Additional plan state files`.

Treat both files as local execution state. Exclude them from staging, commits,
PR diffs, and external-commit handoffs. A request to commit implementation, push
a branch, or create a PR does not include planning documents.

`Exclude` preserves tracking state only in the current workspace. A fresh clone
cannot recover excluded milestone or plan state. Never claim otherwise.

Do not ask about inclusion during normal milestone creation. If a later action
would include either document type, stop and ask this exact gate with the
resolved paths:

```text
Include <milestone path> and its linked plan files in implementation commits and PRs? (y/n)
```

Only `y`, `yes`, or an equally explicit instruction to include both document
types closes the gate. Any other response keeps the policy `Exclude`. Record the
resolved policy in every generated plan. When the policy changes after plans
exist, re-dispatch each owning writer, or a fresh replacement, to update the
header, policy-dependent checkpoints, and guards, then re-run plan review. The
main agent never edits plan content.

## Workflow

1. Capture the milestone goal and source requirements
2. Read the repository rules, relevant code, tests, and existing plans
3. Map the required changes to plan-sized outcomes
4. Define the plan dependency graph
5. Assign stable IDs in topological order: `P1`, `P2`, and so on
6. Resolve the execution mode and commit policy required by `writing-plans`
7. Present the milestone path, plan paths, dependency graph, shared plan
   choices, and document policy
8. Ask one exact gate naming every target:
   `Apply: create <milestone path> and plan files <exact path list>? (y/n)`
9. Write the milestone file with the planned paths and unchecked boxes
10. Dispatch plan-writer subagents with the mandatory input below
11. Collect each reviewed plan without drafting or fixing plan content inline
12. Format the milestone file with the repository formatter
13. Verify the graph, links, policies, and injected completion steps

## Plan-writer delegation

- Launch one fresh plan-writer subagent for each plan
- Dispatch one writer at a time in topological order
- Give one subagent ownership of one plan file only
- Require each subagent to load and follow `writing-plans`
- Give each subagent the repository root, plan path, milestone path, expected
  milestone link target, plan-specific source requirements, dependencies,
  execution mode, commit policy, and document policy
- Pass `review_source_requirements` captured before drafting: original user
  requirements, the plan-specific outcome, and every mandatory milestone rule
- Require each subagent to format its plan file with the repository formatter
- Require each subagent to return the plan path, final plan-review result,
  milestone path, matched plan-link target, resolved document policy, and exact
  implementation file set
- Do not paste one writer's full plan into another writer's prompt
- Let a dependent writer read completed prerequisite plan files from disk
- Do not let plan writers edit the milestone file
- Validate returned headers and final checkpoints with targeted reads
- Never load complete plan bodies into the main-agent context
- Never edit returned plan content in the main agent
- Send defects back to the owning subagent for revision and re-review
- Use a fresh replacement subagent when the original writer is unavailable

The main agent owns decomposition, the dependency graph, the milestone file,
dispatch, and final cross-plan validation. Plan-writer subagents own all plan
text and revisions.

## Parallel execution coordinator

The agent that dispatches more than one plan execution is the root milestone
execution coordinator. It owns this handshake for one milestone file:

1. Dispatch each plan with `milestone_execution_mode = coordinated`
2. Receive `READY <plan ID>` from a plan executor after implementation review
   and validation pass
3. Grant `FINALIZE <plan ID>` to one ready executor
4. Grant no other finalization turn for that milestone file
5. Receive `FINALIZED <plan ID>` after the checkbox update completes
6. Grant the next ready executor

Track at most one open grant. Keep the root coordinator active until each open
turn returns `FINALIZED` or a blocker. A blocker after `FINALIZE`, a terminated
executor, or lost message relay closes that routing turn as failed and halts new
grants. Re-read and validate the milestone file before resuming the same plan;
do not grant another plan until the blocker and any partial milestone edit are
resolved. When the harness cannot relay these messages at start, execute plans
sequentially.

## Plan boundaries

- Give each plan one independently testable, reviewable outcome
- Keep each plan suitable for one isolated PR
- Keep implementation file ownership disjoint between parallel plans
- Move shared foundations or contracts into an earlier prerequisite plan
- Add a dependency when a plan needs code, contracts, migrations, or generated
  artifacts from another plan
- Reject dependency cycles
- Order sequential plans by dependency
- Permit plans with no unmet dependency to run in parallel
- Treat parallel-ready as implementation and merge independence
- Run parallel plans only under one root milestone execution coordinator
- Let that root coordinator grant one `FINALIZE <plan ID>` turn at a time
- Never let two plan executors hold a finalization turn concurrently
- Execute plans sequentially when no root coordinator exists
- Treat the milestone file as the only expected shared file between parallel
  plans
- Do not make one plan depend on another plan's uncommitted state
- Preserve user changes and completed milestone boxes

## Mandatory input to `writing-plans`

Feed these requirements into every plan-writer prompt. Require the subagent to
pass them into `writing-plans`. Do not replace or relax that workflow.

1. Add these rules to the pre-draft `review_source_requirements`, then record
   them as explicit numbered `Source requirements`:
   1. After final implementation validation, mark the one milestone checkbox
      whose resolved link target is this plan path as complete
   2. Preserve every other milestone entry
   3. Apply `Plan file policy` to both the plan and milestone files
   4. Under parallel execution, request and receive `FINALIZE <plan ID>` from
      the root milestone execution coordinator before editing the milestone
2. Record `Plan file policy: Exclude` unless the document commit gate changed it
   to `Include`
3. List the milestone path under `Additional plan state files`
4. Exclude both files from every commit, PR, and external-commit handoff when
   `Plan file policy` is `Exclude`
5. Under `No commits` plus a requested PR, preserve the `writing-plans`
   external-commit scope and post-commit baseline audit; include plan state only
   when `Plan file policy` is `Include`
6. Add a final action to the plan's final-verification checkpoint, after review
   and implementation validation:
   1. Send `READY <plan ID>` to the root milestone execution coordinator
   2. Wait for the exact reply `FINALIZE <plan ID>`
      - No coordinator or messaging support: require sequential execution
   3. Re-read the milestone file
   4. Resolve every checkbox link target relative to the milestone file
   5. Require exactly one target to resolve to the executing plan path
      - Zero or multiple matches: edit no milestone state, report the blocker to
        the root coordinator, and fail the open finalization turn
   6. Change its `[ ]` to `[x]`; leave an existing `[x]` unchanged on resume
   7. Preserve every other milestone box and link
   8. Run the repository formatter on the milestone file
   9. Verify the link still resolves to the executing plan
   10. Send `FINALIZED <plan ID>` to the root coordinator
7. Do not check the box when review or implementation validation fails
8. Report excluded plan and milestone changes as local uncommitted execution
   state at completion

This embedded plan action owns milestone completion.

## Milestone format

Keep only the title, one-line goal, one execution rule, and plan checkboxes.
Omit architecture, acceptance criteria, implementation detail, and status
narration.

```markdown
# <Milestone name>

<One-line milestone goal>

Plans with no unmet dependency can run in parallel under one root coordinator.
Completion handshake: `READY` -> `FINALIZE` -> `FINALIZED`.

- [ ] [P1 <Plan title>](relative-path-to-plan)
- [ ] [P2 <Plan title>](relative-path-to-plan)
- [ ] [P3 <Plan title>](relative-path-to-plan) (after P1, P2)
```

Omit the dependency suffix when a plan has no prerequisites. Use only plan IDs
in the suffix. Do not add descriptions after links.

## Validation

- Every source requirement belongs to at least one plan
- Every plan link resolves to one saved plan
- Every plan appears once in the milestone
- Every dependency points to a lower plan ID
- Dependency graph is acyclic
- Parallel plans have disjoint implementation file sets
- Parallel plan finalization has one named root coordinator
- Each plan completes one `READY` -> `FINALIZE` -> `FINALIZED` handshake
- Every plan contains its exact milestone path and stable link target
- Every plan contains the mandatory checkbox completion action
- Every plan records the resolved `Plan file policy`
- Every plan lists the milestone under `Additional plan state files`
- Every excluded document has explicit commit, PR, and handoff guards
- Every writer attests to the path, link target, policy, implementation file
  set, and review result
- Checked boxes remain checked during milestone updates
