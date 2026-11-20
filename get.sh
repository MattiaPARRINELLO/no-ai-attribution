#!/usr/bin/env bash
# get.sh - one-line installer for no-ai-attribution.
#
# Linux and macOS:
#   curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.sh | bash
#
# Non-interactive:
#   curl -fsSL .../get.sh | bash -s -- --yes
#   curl -fsSL .../get.sh | bash -s -- --uninstall
set -euo pipefail

REPO_URL="${NO_AI_ATTRIBUTION_REPO:-https://github.com/MattiaPARRINELLO/no-ai-attribution}"
REF="${NO_AI_ATTRIBUTION_REF:-main}"

say() { printf '%s\n' "$*"; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: get.sh [--yes | --uninstall | --help]

Download no-ai-attribution and run its installer.

Options:
  -y, --yes       Install without the interactive menu.
      --uninstall Remove the hook, the pattern list and the helper.
  -h, --help      Show this help.

Without an option, a terminal opens the interactive menu (TUI).
If no terminal is available, the standard installer runs.

Environment:
  NO_AI_ATTRIBUTION_REPO  override the repository URL
  NO_AI_ATTRIBUTION_REF   override the branch (default: main)
EOF
}

ACTION=auto
while [ $# -gt 0 ]; do
  case "$1" in
    -y | --yes) ACTION=install ;;
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
command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar >/dev/null 2>&1 || die "tar is required"

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/no-ai-attribution.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

say "Téléchargement de $REPO_URL ($REF)..."
curl -fsSL "$REPO_URL/archive/refs/heads/$REF.tar.gz" | tar -xz -C "$TMP_DIR" ||
  die "download failed, check your network or the repository URL"

SRC_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
[ -n "$SRC_DIR" ] || die "unexpected archive layout"
[ -f "$SRC_DIR/install.sh" ] || die "install.sh not found in the archive"

case "$ACTION" in
  install)
    bash "$SRC_DIR/install.sh"
    exit 0
    ;;
  uninstall)
    bash "$SRC_DIR/install.sh" --uninstall
    exit 0
    ;;
esac

# Open the TUI when a terminal is available, even if stdin is the pipe itself.
if [ -t 1 ] && (exec 3</dev/tty) 2>/dev/null; then
  bash "$SRC_DIR/tui.sh"
  exit 0
fi

say "Aucun terminal interactif détecté, installation standard."
bash "$SRC_DIR/install.sh"
