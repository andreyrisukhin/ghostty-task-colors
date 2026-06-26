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
task bright
task dim
task global dim
task rainbow
task rainbow stop
task clear
```

## Commands

- `task <name>`: set a task label and deterministic Flexoki accent color.
- `task red`, `task red-400`, `task '#2a1a3a'`: set explicit colors.
- `task bright [suffix]`: brighten this pane, default suffix `400`.
- `task dim [suffix]`: dim this pane, default suffix `850`.
- `task normal`: clear this pane's brightness override.
- `task global bright|dim|normal`: control brightness for all registered panes.
- `task rainbow`: start a background RGB accent cycle for this pane.
- `task rainbow stop`: stop the background RGB cycle.
- `task shade <suffix>`: low-level suffix control for this pane.
- `task -p`: preview the Flexoki palette.

## Uninstall

```bash
./uninstall.sh
```
