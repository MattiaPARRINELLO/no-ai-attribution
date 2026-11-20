#!/usr/bin/env bash
# install.sh - install the no-ai-attribution Git hooks and helper.
set -euo pipefail

SRC_DIR=$(cd "$(dirname "$0")" && pwd)
HOOKS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git/hooks"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
STAMP=$(date +%Y%m%d-%H%M%S)

say() { printf '%s\n' "$*"; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || die "git is required"

mkdir -p "$HOOKS_DIR" "$BIN_DIR"

backup_if_needed() {
  target="$1"
  if [ -e "$target" ] && ! cmp -s "$target" "$2"; then
    cp -p "$target" "$target.bak-$STAMP"
    say "backup: $target.bak-$STAMP"
  fi
}

install_file() {
  src="$1"
  dst="$2"
  [ -f "$src" ] || die "missing source file: $src"
  backup_if_needed "$dst" "$src"
  install -m 0755 "$src" "$dst"
  say "installed: $dst"
}

install_file "$SRC_DIR/hooks/commit-msg" "$HOOKS_DIR/commit-msg"
install -m 0644 "$SRC_DIR/hooks/ai-agents.regex" "$HOOKS_DIR/ai-agents.regex"
install_file "$SRC_DIR/bin/git-purge-ai-attribution" "$BIN_DIR/git-purge-ai-attribution"

git config --global core.hooksPath "$HOOKS_DIR"
say "git config: core.hooksPath=$HOOKS_DIR"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) say "warning: $BIN_DIR is not in your PATH, add it to use git-purge-ai-attribution directly" ;;
esac

say ""
say "Done. New commits will have AI Co-Authored-By trailers removed."
say "Test it:  git commit --allow-empty -m 'test' -m 'Co-Authored-By: Claude <noreply@anthropic.com>'"
say "Then:     git log -1 --format=%B"
