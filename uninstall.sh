#!/usr/bin/env bash
set -euo pipefail

target_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty-task-colors"
source_line="source \"$target_dir/shells/zsh/ghostty-task.zsh\""
zshrc="${ZDOTDIR:-$HOME}/.zshrc"

if [[ -f "$zshrc" ]]; then
  tmp="$(mktemp)"
  grep -Fvx "$source_line" "$zshrc" > "$tmp" || true
  mv "$tmp" "$zshrc"
  echo "Removed ghostty-task-colors source line from $zshrc"
fi

rm -rf "$target_dir"
echo "Removed $target_dir"
