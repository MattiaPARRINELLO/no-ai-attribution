#!/usr/bin/env bash
# tui.sh - interactive installer for no-ai-attribution.
# Pure bash, no dependency beyond Git.
set -euo pipefail

SRC_DIR=$(cd "$(dirname "$0")" && pwd)
HOOKS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git/hooks"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
OS=$(uname -s 2>/dev/null || echo unknown)
VERSION="1.0.0"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'EOF'
Usage: tui.sh

Interactive installer for no-ai-attribution. Use the arrow keys and Enter,
or press the number of an entry. Press q to quit.

Environment:
  XDG_CONFIG_HOME  where hooks are installed (default ~/.config)
  XDG_BIN_HOME     where the helper is installed (default ~/.local/bin)
EOF
  exit 0
fi

# Read keys from the terminal even when this script was piped to bash.
if ! exec 3</dev/tty; then
  printf 'No terminal available, running the standard installer.\n'
  exec bash "$SRC_DIR/install.sh"
fi

if [ -t 1 ]; then
  B=$'\033[1m'
  D=$'\033[2m'
  R=$'\033[0m'
  INV=$'\033[7m'
  GREEN=$'\033[32m'
  RED=$'\033[31m'
  YELLOW=$'\033[33m'
  CYAN=$'\033[36m'
else
  B="" D="" R="" INV="" GREEN="" RED="" YELLOW="" CYAN=""
fi

pause() {
  printf '\n%sAppuie sur une touche pour revenir au menu.%s' "$D" "$R"
  read -rsn1 -u 3 || true
}

confirm() {
  printf '%s [o/N] ' "$1"
  read -rn1 -u 3 answer || answer="n"
  printf '\n'
  case "$answer" in
    o | O | y | Y) return 0 ;;
    *) return 1 ;;
  esac
}

installed_hook() { [ -x "$HOOKS_DIR/commit-msg" ]; }

do_install() {
  clear
  printf '%sInstallation%s\n\n' "$B" "$R"
  bash "$SRC_DIR/install.sh"
  printf '\n'
  pause
}

do_verify() {
  clear
  printf '%sVérification%s\n\n' "$B" "$R"
  local ok=0

  if installed_hook; then
    printf '  %sOK%s   hook installé: %s\n' "$GREEN" "$R" "$HOOKS_DIR/commit-msg"
  else
    printf '  %sFAIL%s hook absent: %s\n' "$RED" "$R" "$HOOKS_DIR/commit-msg"
    ok=1
  fi

  if [ -f "$HOOKS_DIR/ai-agents.regex" ]; then
    printf '  %sOK%s   liste des IA: %s\n' "$GREEN" "$R" "$HOOKS_DIR/ai-agents.regex"
  else
    printf '  %sFAIL%s liste absente: %s\n' "$RED" "$R" "$HOOKS_DIR/ai-agents.regex"
    ok=1
  fi

  if [ -x "$BIN_DIR/git-purge-ai-attribution" ]; then
    printf '  %sOK%s   outil de nettoyage: %s\n' "$GREEN" "$R" "$BIN_DIR/git-purge-ai-attribution"
  else
    printf '  %sFAIL%s outil absent: %s\n' "$RED" "$R" "$BIN_DIR/git-purge-ai-attribution"
    ok=1
  fi

  hooks_path=$(git config --global --get core.hooksPath 2>/dev/null || true)
  if [ "${hooks_path%/}" = "${HOOKS_DIR%/}" ]; then
    printf '  %sOK%s   core.hooksPath: %s\n' "$GREEN" "$R" "$hooks_path"
  else
    printf '  %sFAIL%s core.hooksPath: %s (attendu: %s)\n' "$RED" "$R" "${hooks_path:-vide}" "$HOOKS_DIR"
    ok=1
  fi

  if command -v git-filter-repo >/dev/null 2>&1; then
    printf '  %sOK%s   git-filter-repo: %s\n' "$GREEN" "$R" "$(git filter-repo --version 2>/dev/null || echo présent)"
  else
    printf '  %sWARN%s git-filter-repo absent, le nettoyage d historique ne marchera pas\n' "$YELLOW" "$R"
  fi

  printf '\n%sTest du hook%s\n' "$B" "$R"
  local tmp
  tmp=$(mktemp)
  printf 'sujet de test\n\nCo-Authored-By: Claude <noreply@anthropic.com>\nCo-Authored-By: Jane Doe <jane@example.com>\n' >"$tmp"
  if installed_hook; then
    bash "$HOOKS_DIR/commit-msg" "$tmp"
    if grep -qi "claude" "$tmp"; then
      printf '  %sFAIL%s le trailer IA n a pas été supprimé\n' "$RED" "$R"
      ok=1
    else
      printf '  %sOK%s   trailer IA supprimé\n' "$GREEN" "$R"
    fi
    if grep -q "Jane Doe" "$tmp"; then
      printf '  %sOK%s   co-auteur humain conservé\n' "$GREEN" "$R"
    else
      printf '  %sFAIL%s le co-auteur humain a été supprimé\n' "$RED" "$R"
      ok=1
    fi
  else
    printf '  %sSKIP%s hook non installé\n' "$YELLOW" "$R"
  fi
  rm -f "$tmp"

  printf '\n'
  if [ "$ok" -eq 0 ]; then
    printf '%sTout est en ordre.%s\n' "$GREEN" "$R"
  else
    printf '%sIl reste des problèmes, choisis Installer.%s\n' "$RED" "$R"
  fi
  pause
}

do_status() {
  clear
  printf '%sÉtat%s\n\n' "$B" "$R"
  printf '  Système            : %s\n' "$OS"
  printf '  Git                : %s\n' "$(git --version 2>/dev/null || echo absent)"
  printf '  Hook               : %s\n' "$(installed_hook && echo installé || echo absent)"
  printf '  Dossier des hooks  : %s\n' "$HOOKS_DIR"
  printf '  Outil de nettoyage : %s\n' "$([ -x "$BIN_DIR/git-purge-ai-attribution" ] && echo installé || echo absent)"
  printf '  git-filter-repo    : %s\n' "$(command -v git-filter-repo >/dev/null 2>&1 && echo installé || echo absent)"
  printf '  core.hooksPath     : %s\n' "$(git config --global --get core.hooksPath 2>/dev/null || echo vide)"

  if [ -f "$HOOKS_DIR/ai-agents.regex" ]; then
    printf '  Motifs d IA        : %s\n' "$(tr '|' '\n' <"$HOOKS_DIR/ai-agents.regex" | wc -l | tr -d ' ')"
  fi

  printf '\n'
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf '  Dépôt courant      : %s\n' "$(git rev-parse --show-toplevel)"
    printf '  Branche            : %s\n' "$(git branch --show-current 2>/dev/null || echo détachée)"
    local tokens count
    if [ -f "$HOOKS_DIR/ai-agents.regex" ]; then
      tokens=$(tr -d '\n' <"$HOOKS_DIR/ai-agents.regex")
      count=$(git log --all --format=%B 2>/dev/null | grep -Eci "^[[:space:]]*co-authored-by:.*(${tokens})" || true)
      printf '  Trailers IA        : %s dans l historique local\n' "${count:-0}"
    fi
  else
    printf '  Dépôt courant      : aucun\n'
  fi
  pause
}

do_purge() {
  clear
  printf '%sNettoyer un historique%s\n\n' "$B" "$R"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'Tu n es pas dans un dépôt Git.\n'
    printf 'Chemin du dépôt (vide pour annuler): '
    read -r -u 3 repo_path || repo_path=""
    [ -n "$repo_path" ] || return 0
    cd "$repo_path" || {
      printf 'Chemin invalide.\n'
      pause
      return 0
    }
  fi

  printf 'Dépôt: %s\n\n' "$(git rev-parse --show-toplevel)"
  if ! command -v git-filter-repo >/dev/null 2>&1; then
    printf '%sgit-filter-repo est absent.%s\n' "$RED" "$R"
    printf 'Installe-le puis relance cette option.\n'
    pause
    return 0
  fi

  bash "$BIN_DIR/git-purge-ai-attribution"
  printf '\n'
  pause
}

do_uninstall() {
  clear
  printf '%sDésinstallation%s\n\n' "$B" "$R"
  printf 'Le hook, la liste et l outil seront supprimés de ton profil.\n'
  if confirm "Confirmer la désinstallation ?"; then
    bash "$SRC_DIR/install.sh" --uninstall
  else
    printf 'Annulé.\n'
  fi
  printf '\n'
  pause
}

draw_menu() {
  clear
  printf '%s' "$CYAN"
  cat <<'EOF'
   _   _         _    _    ___   _____         _   _   _
  | \ | | ___   / \  | |  / _ \ |_   _|_      / \ (_) |_| |_ _ __ __ _
  |  \| |/ _ \ / _ \ | | | | | |  | | | |    / _ \| | | | __| '__/ _` |
  | |\  | (_) / ___ \| | | |_| |  | | | |   / ___ \ | | | |_| | | (_| |
  |_| \_|\___/_/   \_\_|  \___/   |_| |_|  /_/   \_\|_|_|\__|_|  \__,_|
EOF
  printf '%s\n' "$R"
  printf '  %sRetire les co-auteurs IA de tes commits Git%s\n' "$D" "$R"
  printf '  %sVersion %s%s\n\n' "$D" "$VERSION" "$R"

  local labels=(
    "Installer / mettre à jour"
    "Vérifier l installation"
    "Voir l état"
    "Nettoyer l historique du dépôt courant"
    "Désinstaller"
    "Quitter"
  )
  local i
  for i in "${!labels[@]}"; do
    local n=$((i + 1))
    if [ "$i" -eq "$selected" ]; then
      printf '  %s> %d. %s %s\n' "$INV" "$n" "${labels[$i]}" "$R"
    else
      printf '    %s%d. %s%s\n' "$D" "$n" "${labels[$i]}" "$R"
    fi
  done
  printf '\n  %sFlèches ou chiffres, Entrée pour valider, q pour quitter.%s\n' "$D" "$R"
}

run_action() {
  case "$1" in
    0) do_install ;;
    1) do_verify ;;
    2) do_status ;;
    3) do_purge ;;
    4) do_uninstall ;;
    5) exit 0 ;;
  esac
}

selected=0
while true; do
  draw_menu
  key=""
  read -rsn1 -u 3 key || key="q"

  case "$key" in
    $'\033')
      read -rsn2 -u 3 rest || rest=""
      case "$rest" in
        "[A") selected=$(((selected - 1 + 6) % 6)) ;;
        "[B") selected=$(((selected + 1) % 6)) ;;
      esac
      ;;
    k | K) selected=$(((selected - 1 + 6) % 6)) ;;
    j | J) selected=$(((selected + 1) % 6)) ;;
    1) run_action 0 ;;
    2) run_action 1 ;;
    3) run_action 2 ;;
    4) run_action 3 ;;
    5) run_action 4 ;;
    6) run_action 5 ;;
    "") run_action "$selected" ;;
    q | Q) exit 0 ;;
  esac
done
