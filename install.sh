#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty-task-colors"
source_line="source \"$target_dir/shells/zsh/ghostty-task.zsh\""
zshrc="${ZDOTDIR:-$HOME}/.zshrc"

mkdir -p "$target_dir/shells/zsh"
cp "$repo_dir/shells/zsh/ghostty-task.zsh" "$target_dir/shells/zsh/ghostty-task.zsh"

if [[ -f "$zshrc" ]] && grep -Fqx "$source_line" "$zshrc"; then
  echo "ghostty-task-colors is already installed in $zshrc"
else
  {
    echo
    echo "# ghostty-task-colors"
    echo "$source_line"
  } >> "$zshrc"
  echo "Added ghostty-task-colors to $zshrc"
fi

echo "Restart your shell, or run:"
echo "  $source_line"
