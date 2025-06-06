alias dr="docker run --rm -it "

drw() {
    docker run --rm -it -v "$(pwd):/workspace" -w '/workspace' "$@"
}

alias dps="docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}'"
alias dcps="docker compose ps --format 'table {{.ID}}\t{{.Name}}\t{{.Image}}\t{{.Status}}'"
alias dcls="dps"
alias dclsa="dps -a"
