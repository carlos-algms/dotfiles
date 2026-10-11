# Easy extract
extract() {
  local file="$1" name="${1##*/}" target

  if [ ! -f "$file" ]; then
    echo "'$file' is not a valid file!"
    return 1
  fi

  # a.tar.gz -> a, b.zip -> b
  name="${name%.tar.*}"
  if [[ "$name" == "${file##*/}" ]]; then
    name="${name%.*}"
  fi
  target="${2:-./$name}"

  case "$file" in
  # tar detects gz, bz2 and xz by itself. unzip and 7z create the target
  *.tar.* | *.tgz | *.tbz2 | *.tar)
    mkdir -p "$target"
    tar xvf "$file" -C "$target"
    ;;
  *.bz2) bunzip2 "$file" ;;
  *.rar)
    mkdir -p "$target"
    rar x "$file" "$target/"
    ;;
  *.gz) gunzip "$file" ;;
  *.zip) unzip "$file" -d "$target" ;;
  *.Z) uncompress "$file" ;;
  *.7z) 7z x "$file" -o"$target" ;;
  *) echo "don't know how to extract '$file'..." ;;
  esac
}

if command -v yazi >/dev/null 2>&1; then
  function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
  }
fi
