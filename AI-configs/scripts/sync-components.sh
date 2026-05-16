#!/usr/bin/env bash
# Sync vendored AI components (skills, agents, commands, hooks) declared
# in components.json. See AI-configs/COMPONENTS-sync.md for usage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$SCRIPT_DIR/components.json"
LOCK="$SCRIPT_DIR/components.lock"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../shell/common/01_logging.sh"

target_dir() {
  case "$1" in
    skills|agents|commands) printf '%s/%s' "$ROOT_DIR" "$1" ;;
    hooks)                  printf '%s/claude/hooks' "$ROOT_DIR" ;;
    *) e_error "unknown target: $1"; return 1 ;;
  esac
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--update [name]] [--list]

Default: sync every component in components.json to its pinned SHA.
--update            fetch HEAD for every unique repo, rewrite lock, sync.
--update <name>     update only the named component (and any sibling
                    component sharing its repo, since they share a SHA).
--list              print the manifest entries.
EOF
}

command -v git >/dev/null || { e_error "git required"; exit 1; }
command -v jq  >/dev/null || { e_error "jq required";  exit 1; }
[[ -f "$MANIFEST" ]] || { e_error "missing $MANIFEST"; exit 1; }

MODE="apply"
TARGET=""
case "${1:-}" in
  "")        ;;
  --list)    MODE="list" ;;
  --update)  MODE="update"; TARGET="${2:-}" ;;
  -h|--help) usage; exit 0 ;;
  *)         usage; exit 2 ;;
esac

manifest_tsv() {
  jq -r '.components[] | [.name, (.target // "skills"), .repo, .subpath] | @tsv' "$MANIFEST"
}

lock_lookup_sha() {
  local repo="$1"
  [[ -f "$LOCK" ]] || return 1
  jq -r --arg r "$repo" '.components[] | select(.repo == $r) | .sha' "$LOCK" \
    | head -n1
}

lock_entries() {
  [[ -f "$LOCK" ]] || return 0
  jq -r '.components[] | [.name, .target, .subpath] | @tsv' "$LOCK"
}

declare -A LOCK_KEYS=()
load_lock_keys() {
  [[ -f "$LOCK" ]] || return 0
  local name target _sub
  while IFS=$'\t' read -r name target _sub; do
    [[ -z "$name" ]] && continue
    LOCK_KEYS["$target/$name"]=1
  done < <(lock_entries)
}
load_lock_keys

write_lock() {
  local tmp; tmp="$(mktemp)"
  printf '%s\n' "$1" | jq -R -s '
    split("\n") | map(select(length > 0) | split("\t") |
      {name: .[0], target: .[1], repo: .[2], subpath: .[3], sha: .[4]}) |
    {components: .}
  ' > "$tmp"
  mv "$tmp" "$LOCK"
}

dest_path() {
  local target="$1" name="$2" src="$3"
  local base; base="$(target_dir "$target")"
  if [[ -f "$src" ]]; then
    printf '%s/%s.%s' "$base" "$name" "${src##*.}"
  else
    printf '%s/%s' "$base" "$name"
  fi
}

if [[ "$MODE" == "list" ]]; then
  printf '%-22s %-8s %-46s %s\n' NAME TARGET REPO SUBPATH
  manifest_tsv | awk -F'\t' '{ printf "%-22s %-8s %-46s %s\n", $1, $2, $3, $4 }'
  exit 0
fi

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

declare -A REPO_DIR=()
declare -A WANT_SHA=()

resolve_want_sha() {
  local name="$1" repo="$2"
  local sha
  sha="$(lock_lookup_sha "$repo" || true)"
  [[ -n "$sha" ]] || {
    e_error "no lock entry for $repo (needed by $name)"
    [[ "$MODE" == "apply" ]] && e_error "run with --update to populate the lock"
    exit 1
  }
  WANT_SHA[$repo]="$sha"
}

while IFS=$'\t' read -r name target repo subpath; do
  [[ -z "$name" ]] && continue
  if [[ "$MODE" == "update" && ( -z "$TARGET" || "$TARGET" == "$name" ) ]]; then
    WANT_SHA[$repo]=""
  elif [[ -z "${WANT_SHA[$repo]+x}" ]]; then
    resolve_want_sha "$name" "$repo"
  fi
done < <(manifest_tsv)

prepare_repo() {
  local repo="$1" want_sha="$2"
  [[ -n "${REPO_DIR[$repo]:-}" ]] && return 0
  local dir="$TMP_ROOT/$(printf '%s' "$repo" | shasum -a 1 | cut -c1-12)"
  e_arrow "cloning $repo"
  git clone --quiet "$repo" "$dir"
  if [[ -n "$want_sha" ]]; then
    git -C "$dir" checkout --quiet "$want_sha"
  else
    WANT_SHA[$repo]="$(git -C "$dir" rev-parse HEAD)"
  fi
  REPO_DIR[$repo]="$dir"
}

for repo in "${!WANT_SHA[@]}"; do
  prepare_repo "$repo" "${WANT_SHA[$repo]}"
done

e_header "Syncing components"

new_lock_tsv=""
declare -A KEEP=()
while IFS=$'\t' read -r name target repo subpath; do
  [[ -z "$name" ]] && continue
  src="${REPO_DIR[$repo]}/$subpath"
  [[ -e "$src" ]] || { e_error "$name: not found at $repo:$subpath"; exit 1; }
  dst="$(dest_path "$target" "$name" "$src")"

  if [[ -e "$dst" && -z "${LOCK_KEYS["$target/$name"]:-}" ]]; then
    e_error "refusing to overwrite unmanaged path: $dst"
    e_error "delete it manually or remove the manifest entry"
    exit 1
  fi

  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -R "$src" "$dst"
  sha="${WANT_SHA[$repo]}"
  new_lock_tsv+="$name"$'\t'"$target"$'\t'"$repo"$'\t'"$subpath"$'\t'"$sha"$'\n'
  KEEP["$target/$name"]=1
  e_success "synced $target/$name <- $repo @ ${sha:0:7}"
done < <(manifest_tsv)

while IFS=$'\t' read -r old_name old_target _old_subpath; do
  [[ -z "$old_name" ]] && continue
  [[ -n "${KEEP["$old_target/$old_name"]:-}" ]] && continue
  base="$(target_dir "$old_target")" || continue
  stale_dir="$base/$old_name"
  if [[ -d "$stale_dir" ]]; then
    e_arrow "removing stale $old_target/$old_name (dir)"
    rm -rf "$stale_dir"
    continue
  fi
  shopt -s nullglob
  for f in "$base/$old_name".*; do
    e_arrow "removing stale $old_target/$old_name ($f)"
    rm -f "$f"
  done
  shopt -u nullglob
done < <(lock_entries)

write_lock "$new_lock_tsv"
e_success "lock written: $LOCK"

e_header "Done. Review with: git status"
