# Components sync

How third-party AI components (skills, agents, hooks) are vendored into
`AI-configs/<target>/` so every agent CLI (Claude, Gemini, Codex, pi, opencode,
cursor, copilot) picks them up via the existing symlinks. No `npx`, no
`/plugin install`.

## Why vendor

- Content lives in this repo, reviewable in `git diff`.
- Updates are explicit: bump a SHA, re-run the sync script, review.
- One repo path per target covers every CLI, since each CLI symlinks the
  relevant dir directly (see `AI-Config-README.md`).

Note: not every CLI symlinks every target. As of today, `agents/` is only wired
into Claude and opencode. See `AI-Config-README.md`.

## Files

- `AI-configs/scripts/components.json` - manifest. Hand-edited. Each entry:
  `{ name, target, repo, subpath }`. `target` defaults to `skills` if omitted.
- `AI-configs/scripts/components.lock` - generated. Adds `sha` per entry. Commit
  it so syncs are reproducible.
- `AI-configs/scripts/sync-components.sh` - the only script. Reads the manifest,
  clones each repo once at its pinned SHA, copies `<repo>/<subpath>` into the
  target directory as `<name>` (dir) or `<name>.<ext>` (single file).

Component folder names stay flat (`obsidian-cli`, not `obsidian:obsidian-cli`)
because `:` is illegal in folder names on Windows NTFS.

## Supported targets

| Target   | Destination                      | Used for              |
| -------- | -------------------------------- | --------------------- |
| `skills` | `AI-configs/skills/<name>/`      | SKILL.md bundles      |
| `agents` | `AI-configs/agents/<name>.md`    | subagent definitions  |
| `hooks`  | `AI-configs/claude/hooks/<name>` | Claude-specific hooks |

`subpath` may point at a directory (copies the directory) or a single file
(copies the file under the target dir, preserving the extension).

## Run

```sh
# Apply pinned SHAs from components.lock. Fails if lock missing an entry.
AI-configs/scripts/sync-components.sh

# Fetch HEAD of every unique repo, rewrite the lock.
AI-configs/scripts/sync-components.sh --update

# Update one entry only (and any sibling entry sharing its repo).
AI-configs/scripts/sync-components.sh --update grill-with-docs

# Print the manifest.
AI-configs/scripts/sync-components.sh --list
```

After `--update`, review with `git status` and `git diff` before committing.

The script clones to a tempdir each run; nothing is left on disk. Components
sharing a repo are cloned once and synced together with the same SHA.

## Add an entry

1. Pick `name`, `target`, `repo`, and `subpath`. Confirm `<repo>/<subpath>`
   exists upstream.
1. Append an entry to `components.json`:

   ```json
   {
     "name": "<flat-name>",
     "target": "skills",
     "repo": "https://github.com/<owner>/<repo>",
     "subpath": "<path-inside-repo>"
   }
   ```

1. Run `sync-components.sh --update <name>` to fetch and pin.
1. Review `git status`, commit.

## Remove an entry

Delete the entry from `components.json` and run `sync-components.sh --update`.
The script wipes the destination and drops the entry from the lock.

## Safety guards

- The script refuses to overwrite a destination that is not listed in the
  current lock under the same `target/name` pair. Delete the conflicting path
  manually if you intend to let the manifest own it.
- Components hand-edited after a sync will be overwritten on the next sync. Fork
  upstream or write a standalone local component instead.

## Current sources

- <https://github.com/kepano/obsidian-skills>
- <https://github.com/mattpocock/skills>
- <https://github.com/anthropics/claude-plugins-official>
