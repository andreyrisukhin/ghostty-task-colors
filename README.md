# ghostty-task-colors

Opt-in Ghostty shell integration for coloring panes by task.

## Install

```bash
git clone https://github.com/andreyrisukhin/ghostty-task-colors.git
cd ghostty-task-colors
./install.sh
```

Restart your shell, then run:

```bash
task red
task shade 400
task shade global 850
task rgb
task rgb stop
task clear
```

## Commands

- `task <name>`: set a task label and deterministic Flexoki accent color.
- `task red`, `task red-400`, `task '#2a1a3a'`: set explicit colors.
- `task shade <suffix>`: change this pane's brightness suffix.
- `task shade global <suffix>`: change the global brightness suffix for registered panes.
- `task rgb`: start a background RGB accent cycle for this pane.
- `task rgb stop`: stop the background RGB cycle.
- `task -p`: preview the Flexoki palette.

## Uninstall

```bash
./uninstall.sh
```
