#!/usr/bin/env bash
set -euo pipefail
[[ -n "${HOME:-}" && "${HOME#/}" != "$HOME" ]] || { echo "HOME must be an absolute user-home path" >&2; exit 2; }
HOME_REAL="$(cd -- "$HOME" && pwd -P)"
[[ "$HOME_REAL" != /usr && "$HOME_REAL" != /usr/* ]] || { echo "Refusing to write under /usr" >&2; exit 2; }
TOOL="${WOW_TOOL_NAME:-Proton-11-ARM64-WoW}"
[[ "$TOOL" =~ ^[A-Za-z0-9._-]+$ ]] || { echo 'WOW_TOOL_NAME may only contain letters, digits, dot, underscore and dash.' >&2; exit 2; }
DEST="$HOME/.local/share/Steam/compatibilitytools.d/$TOOL"
[[ -d "$DEST" ]] || { printf 'Nothing to remove: %s\n' "$DEST"; exit 0; }
read -r -p "Remove project-created directory $DEST? Type REMOVE: " answer
[[ "$answer" == REMOVE ]] || { echo 'Cancelled'; exit 1; }
chmod -R u+w "$DEST"
rm -rf -- "$DEST"
