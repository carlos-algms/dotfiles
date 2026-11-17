<!--
Copyright 2026 Google LLC.
SPDX-License-Identifier: Apache-2.0
Port-specific guide (not upstream): written for the dotfiles vendored port.
-->

# Pi integration

This is a port-specific guide, written for the vendored EGM skills port in this
repository. It is not an upstream document.

## Invocation

Pi discovers EGM skills through `~/.agents/skills` (linked to
`AI-configs/skills/`). EGM skills set `disable-model-invocation: true`, so they
never trigger automatically. Invoke explicitly:

```text
/skill:egm-brainstorm <request>
/skill:egm-draft <request>
/skill:egm-review <path-to-design-doc>
```

Pi appends everything after `/skill:name` to the loaded skill instructions as
the user request.

## Delegation (Goldfish reviewers)

Use the `subagent` tool from pi-subagents.

- Personas live at `~/.agents/agents/egm-<name>.md`; Pi scans that directory
  natively, so `egm-zoom-out`, `egm-comprehension`, `egm-design`,
  `egm-implementation-readiness`, `egm-inventive-catalyst`, `egm-structural`,
  `egm-style`, `egm-synthesizer`, `egm-codebase-details`, and
  `egm-bootstrap-orchestrator` are requestable agent names
- Spawn one child per reviewer: `{agent: "egm-<name>", task: "<prompt>"}`. For
  concurrent reviewers within one stage, use one
  `{workflow: "parallel", args: {tasks: [...]}}` call
- If a named agent is unavailable, spawn the default child and instruct it to
  read the persona file at `~/.agents/agents/egm-<name>.md` first
- Persona frontmatter has no `tools` or `model` fields, so children inherit the
  parent's tools and model. Personas are strictly read-only by their own text;
  do not widen their permissions
- Reviewers must run in fresh contexts. A review executed in the main
  conversation is not a Goldfish review. If subagents are unavailable, stop and
  say so
- Keep review stages sequential; parallelize only reviewers within the current
  stage

## Artifacts

Write briefs, drafts, and reports to the working directory. If the session's
`AGENTS.md` (global: `~/.claude/CLAUDE.md` symlink target, or a project
`.pi/APPEND_SYSTEM.md`) contains `EGM artifact directory: <path>`, write there
instead.

## Resources

- Skills: `AI-configs/skills/egm-*/SKILL.md`
- Document standards:
  `AI-configs/google-elephant-goldfish/resources/document_standards/`
- Execution instructions:
  `AI-configs/google-elephant-goldfish/resources/execution_instructions.md`
- Harness guides: `claude.md`, `codex.md`, `harnesses.md` (siblings of this
  file)
