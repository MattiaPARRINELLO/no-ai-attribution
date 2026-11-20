#!/usr/bin/env bash
# install.sh - install the no-ai-attribution Git hooks and helper.
# Works on Linux, macOS and Windows (Git Bash).
set -euo pipefail

SRC_DIR=$(cd "$(dirname "$0")" && pwd)
HOOKS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git/hooks"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
STAMP=$(date +%Y%m%d-%H%M%S)
OS=$(uname -s 2>/dev/null || echo unknown)

say() { printf '%s\n' "$*"; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: install.sh [--uninstall] [--help]

Install the no-ai-attribution commit-msg hook, its AI pattern list and the
git-purge-ai-attribution helper.

Options:
  --uninstall   Remove the hook and helper, and unset core.hooksPath.
  --help        Show this help.
EOF
}

ACTION=install
while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) ACTION=uninstall ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

command -v git >/dev/null 2>&1 || die "git is required"

if [ "$ACTION" = uninstall ]; then
  rm -f "$HOOKS_DIR/commit-msg" "$HOOKS_DIR/ai-agents.regex" "$BIN_DIR/git-purge-ai-attribution"
  say "removed: $HOOKS_DIR/commit-msg"
  say "removed: $HOOKS_DIR/ai-agents.regex"
  say "removed: $BIN_DIR/git-purge-ai-attribution"
  current=$(git config --global --get core.hooksPath 2>/dev/null || true)
  if [ "${current%/}" = "${HOOKS_DIR%/}" ]; then
    git config --global --unset core.hooksPath
    say "git config: core.hooksPath unset"
  else
    say "git config: core.hooksPath left unchanged ($current)"
  fi
  say ""
  say "Done. AI co-author trailers will no longer be stripped automatically."
  exit 0
fi

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
  *)
    say ""
    say "note: $BIN_DIR is not in your PATH."
    case "$OS" in
      Darwin) say "      Add it in ~/.zshrc: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
      *) say "      Add it in ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
    esac
    ;;
esac

if ! command -v git-filter-repo >/dev/null 2>&1; then
  say ""
  say "note: git-filter-repo was not found. It is only needed to rewrite existing history."
  case "$OS" in
    Darwin) say "      Install it with: brew install git-filter-repo" ;;
    MINGW* | MSYS* | CYGWIN*) say "      Install it with: pip install --user git-filter-repo" ;;
    *) say "      Install it with: sudo apt install git-filter-repo  (or your package manager)" ;;
  esac
fi

if [ "$OS" = Darwin ]; then
  say ""
  if ! xcode-select -p >/dev/null 2>&1; then
    say "warning: Xcode Command Line Tools were not found. Install them with:"
    say "         xcode-select --install"
  fi
fi

say ""
say "Done. New commits will have AI Co-Authored-By trailers removed."
say "Test it:  git commit --allow-empty -m 'test' -m 'Co-Authored-By: Claude <noreply@anthropic.com>'"
say "Then:     git log -1 --format=%B"
