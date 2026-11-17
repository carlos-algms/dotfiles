# Google Elephant-Goldfish Model (EGM) — vendored port

Vendored port of <https://github.com/google/elephant-goldfish-model> (EGM):
skills that draft designs with full context ("elephant") and review them with
fresh-context subagents ("goldfish"). Apache-2.0. Not an officially supported
Google product.

This file documents the port. Read it before editing any EGM file in this repo.

## Upstream pin

- Repo: `google/elephant-goldfish-model`
- SHA: `e4747323aab66157812cd3a71755f6447b2803a2` (2026-11-14)
- License: Apache-2.0 (kept: `LICENSE`)

## Layout (ported, not a single tree)

Upstream ships one plugin tree. Here it is split across the shared dirs so the
existing symlink set discovers everything:

| Content                                                                                                                       | Location                                                     |
| ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| 7 skills (`egm-brainstorm`, `egm-draft`, `egm-review`, `egm-review-loop`, `egm-resolve`, `egm-drift-report`, `egm-bootstrap`) | `AI-configs/skills/egm-*/`                                   |
| 10 reviewer personas                                                                                                          | `AI-configs/agents/egm-*.md` (renamed to frontmatter `name`) |
| `resources/` (document standards, execution instructions)                                                                     | this directory                                               |
| Runtime docs (`claude.md`, `codex.md`, `harnesses.md`, `pi.md`)                                                               | `docs/` here                                                 |
| `plugin.json` (version stamp), `README.md`                                                                                    | this directory                                               |
| Update patch                                                                                                                  | `port/port.patch`                                            |

Discovery needs no wiring: `~/.agents/skills`, `~/.claude/skills`,
`~/.agents/agents`, and `~/.claude/agents` already link to the shared dirs.

## Patches applied (vs upstream)

Every file-read reference inside a `SKILL.md` is absolute, because the skills
are reached through symlinks and lexical `../../` resolution would escape the
bundle:

1. 7 × `[Codex integration](../../docs/codex.md)` → absolute `docs/codex.md`
2. 7 × `${CLAUDE_PLUGIN_ROOT}/docs/claude.md` → absolute `docs/claude.md`
3. Pi branch line added to all 7 skills → absolute `docs/pi.md` (new file)
4. Persona refs `agents/<file>.md`, `agents/{name}.md`, `agents/zoom_out.md`,
   `agents/comprehension.md`, `agents/synthesizer.md`,
   `agents/bootstrap_orchestrator.md` → `~/.agents/agents/egm-<name>.md`
   (personas renamed to their frontmatter `name`)
5. Resource refs `resources/...` → absolute paths into this directory
6. `resources/README.md`: `../docs/index.md` link → upstream GitHub URL
   (`docs/index.md` was dropped)
7. `docs/claude.md`: "Ported install" note added (no plugin cache; `/egm-`
   invocation without the `/egm:` prefix; permission examples describe upstream
   cache paths)
8. `docs/codex.md`: "Ported install" note added (no bundle root; the persona
   mapping examples there use upstream filenames — translate to
   `~/.agents/agents/egm-<name>.md`; resources resolve to this directory)

Nothing else was changed. Personas are byte-identical to upstream (renamed files
only). `docs/harnesses.md` is upstream-verbatim.

Local-authored companion (not upstream, never overwritten by the update
procedure): `AI-configs/skills/egm-sequence/` — routing map for the skill set
(order, mandatory/optional, entry points).

## Dropped from upstream

- Per-skill `TEST.md` and `test_scenarios.yaml` (pytest fixtures; they link
  `../../TESTING.md`, which is not vendored)
- `docs/designs/`, `docs/verification/`, `docs/site/`, `docs/cursor.md`,
  `docs/faq.md`, `docs/privacy.md`, `docs/releases.md`,
  `docs/getting_started.md`, `docs/index.md`, `docs/directory.md` (no runtime
  reader reads them)
- Plugin manifests for other harnesses (`.claude-plugin/`, `.codex-plugin/`,
  `.gemini/`, `.windsurf/`, `.cursor-plugin/`, `adapters/`, `.agents/`,
  `.github/`, `tests/`, `scripts/`, `TESTING.md`, `pyproject.toml`)

## Update procedure

1. `git clone --depth 1 https://github.com/google/elephant-goldfish-model /tmp/egm-update`
   and note the new SHA
2. Copy the same subsets as the original port:
   - `skills/egm-*` → `AI-configs/skills/` minus `TEST.md`,
     `test_scenarios.yaml`
   - `agents/*.md` → `AI-configs/agents/egm-<frontmatter name>.md`
   - `plugin.json`, `LICENSE`, `README.md`, `docs/{claude,codex,harnesses}.md`,
     `resources/` → this directory
3. `git apply port/port.patch` from the repo root
4. Re-check with the verification greps below; new upstream files or changed
   reference patterns need a reviewed port.patch regeneration
5. Update the SHA line above in the same commit

If upstream changes a patch target (a branch line moves, a persona is renamed),
do not force the patch: re-apply the intent by hand, regenerate `port.patch`,
and note it here.

## Verification greps (repo root)

```sh
rg -n 'CLAUDE_PLUGIN_ROOT|CURSOR_PLUGIN_ROOT' AI-configs/skills/egm-*/SKILL.md
# expect: no output
rg -n '\.\./' AI-configs/skills/egm-*/SKILL.md
# expect: no output
rg -n '\$\{' AI-configs/google-elephant-goldfish/resources AI-configs/google-elephant-goldfish/docs/claude.md
# expect: only the explained prose mention in docs/claude.md
```

## Invocation per CLI

- Claude Code: `/egm-brainstorm`, `/egm-draft`, `/egm-review` (no plugin, so no
  `/egm:` prefix). Skills keep `disable-model-invocation: true`; the `Skill`
  tool refuses them — run chained skills (e.g. `egm-resolve` mid-review) by
  reading their `SKILL.md` and following it in-thread
- Pi: `/skill:egm-brainstorm`, `/skill:egm-draft`, `/skill:egm-review`.
  Reviewers: `subagent` tool with `egm-*` agent names (see `docs/pi.md`)
- Cursor (verified on local Agent): does NOT register the skills — its skill
  registry listed 77 entries from `~/.agents/skills` with zero `egm-*` (the
  vendored skills lack `.cursor-plugin` packaging, and Cursor filters non-plugin
  skills). Two upstream-sanctioned fallbacks work: tell the agent to read
  `AI-configs/skills/egm-<skill>/SKILL.md` and follow it in-thread, and spawn a
  generic `Task` subagent instructed to read `~/.agents/agents/egm-<name>.md`
  first (verified: persona loads and answers in character). Named `egm-*`
  reviewer types are not available; upstream's experimental Cursor adapter
  (dropped in this port) would register them
- Codex (verified on 0.167.1): discovers all 7 skills from `~/.agents/skills`.
  Its `spawn` tool has no agent-type selector, so named `egm-*` agents are not
  requestable; use the skills' designed fallback — spawn a generic subagent and
  instruct it to read `~/.agents/agents/egm-<name>.md` first (verified: persona
  loads and answers in character)

## Quirks and risks

- Reviews require fresh-context subagents; without them a skill must stop, not
  fake the review in-context
- Reviews are token-heavy; not worth it for small, clear bug fixes
- `egm-synthesizer` nests children (Claude Code caps nesting at 3 levels)
- Codex cannot select `egm-*` agent types; every Goldfish there runs through the
  persona-file fallback, which works but costs a persona read per reviewer
- Cursor: skills unregistered and reviewers unnamed; everything runs through the
  read-SKILL.md + persona-file fallbacks. Upstream's experimental
  `.cursor-plugin` adapter registers real Cursor reviewer types (read-only,
  `permissionMode: readonly`) if full support is ever wanted
- Patched `~` paths assume the dotfiles repo at `~/projects/dotfiles` and the
  standard link set (`~/.agents/*`, `~/.claude/*`) on the host
- The `EGM artifact directory: <path>` line in an instructions file redirects
  briefs/drafts/reports; without it they land in the working directory
