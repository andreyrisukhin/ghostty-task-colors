# ghostty_task.zsh
#
# `task` command: tag a Ghostty terminal window with a background color and
# title so visually-similar one-off windows can be distinguished at a glance.
# Coexists with the dir-based `ghostty-path-color` setup -- when TASK is set
# it wins over the dir color (re-applied via chpwd hook).
#
# Colors are drawn from the Flexoki palette by Steph Ango
# (https://stephango.com/flexoki). Accent names default to `-900`; every
# Flexoki accent suffix is also accepted (for example `yellow-850`).
#
# Source from ~/.zshrc:
#   source ~/repos/scripts/shell_utils/zshrc_extend/ghostty_task.zsh
#
# Usage:
#   task                # print current task + swatch
#   task -p             # preview every color with a visible swatch
#   task shade 400      # snap this pane to Flexoki suffix 400
#   task shade global 850 # snap every opted-in pane to Flexoki suffix 850
#   task rgb            # background accent-gradient transition at -400
#   task --help         # full usage
#   task red            # accent, default -900 intensity
#   task red-950        # explicit Flexoki suffix
#   task yellow-850     # any accent + suffix
#   task '#2a1a3a'      # exact hex
#   task pr-1234        # hashed -> one of the 8 Flexoki accents
#   task clear          # drop tag, restore dir color

[[ "$TERM_PROGRAM" == "ghostty" || -n "$GHOSTTY_RESOURCES_DIR" ]] || return 0

autoload -Uz add-zsh-hook

# These helpers are also defined by the dir-color block in .zshrc; redefine
# defensively so this file works standalone if that block is ever removed.
_ghostty_path_color() { command ghostty-path-color "$PWD" 2>/dev/null; }
_ghostty_reset_colors() { printf '\033]112\007\033]111\007'; }

# Flexoki palette. `<accent>` is an alias for `<accent>-900`.
typeset -gA _flexoki_task_colors=(
  [red]="#3E1715"      [red-50]="#FFE1D5"      [red-100]="#FFCABB"     [red-150]="#FDB2A2"
  [red-200]="#F89A8A"  [red-300]="#E8705F"     [red-400]="#D14D41"     [red-500]="#C03E35"
  [red-600]="#AF3029"  [red-700]="#942822"     [red-800]="#6C201C"     [red-850]="#551B18"
  [red-900]="#3E1715"  [red-950]="#261312"

  [orange]="#40200D"      [orange-50]="#FFE7CE"      [orange-100]="#FED3AF"     [orange-150]="#FCC192"
  [orange-200]="#F9AE77"  [orange-300]="#EC8B49"     [orange-400]="#DA702C"     [orange-500]="#CB6120"
  [orange-600]="#BC5215"  [orange-700]="#9D4310"     [orange-800]="#71320D"     [orange-850]="#59290D"
  [orange-900]="#40200D"  [orange-950]="#27180E"

  [yellow]="#3A2D04"      [yellow-50]="#FAEEC6"      [yellow-100]="#F6E2A0"     [yellow-150]="#F1D67E"
  [yellow-200]="#ECCB60"  [yellow-300]="#DFB431"     [yellow-400]="#D0A215"     [yellow-500]="#BE9207"
  [yellow-600]="#AD8301"  [yellow-700]="#8E6B01"     [yellow-800]="#664D01"     [yellow-850]="#503D02"
  [yellow-900]="#3A2D04"  [yellow-950]="#241E08"

  [green]="#252D09"      [green-50]="#EDEECF"      [green-100]="#DDE2B2"     [green-150]="#CDD597"
  [green-200]="#BEC97E"  [green-300]="#A0AF54"     [green-400]="#879A39"     [green-500]="#768D21"
  [green-600]="#66800B"  [green-700]="#536907"     [green-800]="#3D4C07"     [green-850]="#313D07"
  [green-900]="#252D09"  [green-950]="#1A1E0C"

  [cyan]="#122F2C"      [cyan-50]="#DDF1E4"      [cyan-100]="#BFE8D9"     [cyan-150]="#A2DECE"
  [cyan-200]="#87D3C3"  [cyan-300]="#5ABDAC"     [cyan-400]="#3AA99F"     [cyan-500]="#2F968D"
  [cyan-600]="#24837B"  [cyan-700]="#1C6C66"     [cyan-800]="#164F4A"     [cyan-850]="#143F3C"
  [cyan-900]="#122F2C"  [cyan-950]="#101F1D"

  [blue]="#12253B"      [blue-50]="#E1ECEB"      [blue-100]="#C6DDE8"     [blue-150]="#ABCFE2"
  [blue-200]="#92BFDB"  [blue-300]="#66A0C8"     [blue-400]="#4385BE"     [blue-500]="#3171B2"
  [blue-600]="#205EA6"  [blue-700]="#1A4F8C"     [blue-800]="#163B66"     [blue-850]="#133051"
  [blue-900]="#12253B"  [blue-950]="#101A24"

  [purple]="#261C39"      [purple-50]="#F0EAEC"      [purple-100]="#E2D9E9"     [purple-150]="#D3CAE6"
  [purple-200]="#C4B9E0"  [purple-300]="#A699D0"     [purple-400]="#8B7EC8"     [purple-500]="#735EB5"
  [purple-600]="#5E409D"  [purple-700]="#4F3685"     [purple-800]="#3C2A62"     [purple-850]="#31234E"
  [purple-900]="#261C39"  [purple-950]="#1A1623"

  [magenta]="#39172B"      [magenta-50]="#FEE4E5"      [magenta-100]="#FCCFDA"     [magenta-150]="#F9B9CF"
  [magenta-200]="#F4A4C2"  [magenta-300]="#E47DA8"     [magenta-400]="#CE5D97"     [magenta-500]="#B74583"
  [magenta-600]="#A02F6F"  [magenta-700]="#87285E"     [magenta-800]="#641F46"     [magenta-850]="#4F1B39"
  [magenta-900]="#39172B"  [magenta-950]="#24131D"

  [paper]="#FFFCF0"  [black]="#100F0F"  [gray]="#1C1B1A"  [grey]="#1C1B1A"
  [base-50]="#F2F0E5"   [base-100]="#E6E4D9"  [base-150]="#DAD8CE"  [base-200]="#CECDC3"
  [base-300]="#B7B5AC"  [base-400]="#9F9D96"  [base-500]="#878580"  [base-600]="#6F6E69"
  [base-700]="#575653"  [base-800]="#403E3C"  [base-850]="#343331"  [base-900]="#282726"
  [base-950]="#1C1B1A"
)

typeset -ga _flexoki_task_accents=(red orange yellow green cyan blue purple magenta)
typeset -ga _flexoki_task_suffixes=(50 100 150 200 300 400 500 600 700 800 850 900 950)
_ghostty_task_state_dir() {
  print -r -- "${XDG_STATE_HOME:-$HOME/.local/state}/ghostty-task"
}

_ghostty_task_brightness_file() {
  print -r -- "$(_ghostty_task_state_dir)/brightness"
}

_ghostty_task_registry_file() {
  print -r -- "$(_ghostty_task_state_dir)/panes.tsv"
}

_ghostty_task_panes_dir() {
  print -r -- "$(_ghostty_task_state_dir)/panes"
}

_ghostty_task_pane_file() {
  local tty="$1"
  print -r -- "$(_ghostty_task_panes_dir)/${tty}.tsv"
}

_ghostty_task_tty_name() {
  local tty="${GHOSTTY_TASK_TTY:-${TTY:-$(tty 2>/dev/null)}}"
  tty="${tty#/dev/}"
  [[ -n "$tty" && "$tty" != 'not a tty' && "$tty" != '??' ]] || return 1
  print -r -- "$tty"
}

_ghostty_task_rgb_pid_file() {
  local tty="$1"
  print -r -- "$(_ghostty_task_state_dir)/rgb-${tty}.pid"
}

_ghostty_task_pane_suffix_file() {
  local tty="$1"
  print -r -- "$(_ghostty_task_state_dir)/shade-${tty}"
}

_ghostty_task_is_suffix() {
  local suffix="$1" known
  for known in "${_flexoki_task_suffixes[@]}"; do
    [[ "$suffix" == "$known" ]] && return 0
  done
  return 1
}

_ghostty_task_global_suffix() {
  local file suffix
  file=$(_ghostty_task_brightness_file)
  [[ -r "$file" ]] || return 1
  suffix="$(<"$file")"
  _ghostty_task_is_suffix "$suffix" || return 1
  print -r -- "$suffix"
}

_ghostty_task_local_suffix() {
  local tty file suffix
  tty=$(_ghostty_task_tty_name 2>/dev/null) || return 1
  file=$(_ghostty_task_pane_suffix_file "$tty")
  [[ -r "$file" ]] || return 1
  suffix="$(<"$file")"
  _ghostty_task_is_suffix "$suffix" || return 1
  print -r -- "$suffix"
}

_ghostty_task_active_suffix() {
  _ghostty_task_local_suffix 2>/dev/null || _ghostty_task_global_suffix 2>/dev/null
}

_ghostty_task_suffix_for_tty() {
  local tty="$1" file suffix
  file=$(_ghostty_task_pane_suffix_file "$tty")
  [[ -r "$file" ]] || return 1
  suffix="$(<"$file")"
  _ghostty_task_is_suffix "$suffix" || return 1
  print -r -- "$suffix"
}

_ghostty_task_project_key_for_path() {
  local start="$1" out home="$HOME"
  out=$(command git -C "$start" rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$out" ]]; then
    print -r -- "$out"
    return
  fi
  if [[ "$start" == "$home" ]]; then
    print -r -- "__HOME__"
    return
  fi
  if [[ "$start" == "$home"/* ]]; then
    print -r -- "$home/${${start#$home/}%%/*}"
    return
  fi
  print -r -- "$start"
}

_ghostty_task_project_key() {
  _ghostty_task_project_key_for_path "$PWD"
}

_ghostty_task_hash_accent() {
  local name="$1" hash_hex idx
  hash_hex=$(printf '%s' "$name" | /usr/bin/shasum | /usr/bin/cut -c1-2)
  idx=$((16#$hash_hex % 8))
  print -r -- "${_flexoki_task_accents[$((idx + 1))]}"
}

_ghostty_task_color_key() {
  local name="$1" suffix accent
  if [[ -z "$name" ]]; then
    accent=$(_ghostty_task_hash_accent "$(_ghostty_task_project_key)")
    print -r -- "${accent}-900"
    return
  fi
  if [[ "$name" == base-<-> ]]; then
    suffix="${name#base-}"
    _ghostty_task_is_suffix "$suffix" && print -r -- "$name" && return
  fi
  for accent in "${_flexoki_task_accents[@]}"; do
    if [[ "$name" == "$accent" ]]; then
      print -r -- "${accent}-900"
      return
    fi
    if [[ "$name" == "$accent"-<-> ]]; then
      suffix="${name#${accent}-}"
      _ghostty_task_is_suffix "$suffix" && print -r -- "$name" && return
    fi
  done
  accent=$(_ghostty_task_hash_accent "$name")
  print -r -- "${accent}-900"
}

_ghostty_task_color_key_for_path() {
  local path="$1" accent
  accent=$(_ghostty_task_hash_accent "$(_ghostty_task_project_key_for_path "$path")")
  print -r -- "${accent}-900"
}

_ghostty_task_snap_key() {
  local key="$1" suffix="$2" accent
  [[ -z "$suffix" ]] && { print -r -- "$key"; return; }
  if [[ "$key" == base-<-> ]]; then
    print -r -- "base-${suffix}"
    return
  fi
  for accent in "${_flexoki_task_accents[@]}"; do
    if [[ "$key" == "$accent"-<-> ]]; then
      print -r -- "${accent}-${suffix}"
      return
    fi
  done
  print -r -- "$key"
}

_ghostty_task_swatch() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
  printf '\033[48;2;%d;%d;%dm      \033[0m' $r $g $b
}

_ghostty_task_chip() {
  local label="$1" hex="${2#\#}"
  local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
  local yiq=$(((r * 299 + g * 587 + b * 114) / 1000))
  local fg_r=255 fg_g=252 fg_b=240
  if (( yiq >= 140 )); then
    fg_r=16
    fg_g=15
    fg_b=15
  fi
  printf '\033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm %-11s\033[0m ' $r $g $b $fg_r $fg_g $fg_b "$label"
}

_ghostty_task_hex_rgb() {
  local hex="${1#\#}"
  print -r -- "$((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))"
}

_ghostty_task_mix_hex() {
  local from="$1" to="$2" step="$3" steps="$4"
  local fr fg fb tr tg tb r g b
  read -r fr fg fb <<< "$(_ghostty_task_hex_rgb "$from")"
  read -r tr tg tb <<< "$(_ghostty_task_hex_rgb "$to")"
  r=$((fr + ((tr - fr) * step / steps)))
  g=$((fg + ((tg - fg) * step / steps)))
  b=$((fb + ((tb - fb) * step / steps)))
  printf '#%02X%02X%02X\n' "$r" "$g" "$b"
}

_ghostty_task_resolve() {
  local name="$1"
  if [[ "$name" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    print -r -- "$name"
    return
  fi
  local key suffix
  key=$(_ghostty_task_color_key "$name")
  suffix=$(_ghostty_task_active_suffix 2>/dev/null)
  key=$(_ghostty_task_snap_key "$key" "$suffix")
  if [[ -n "${_flexoki_task_colors[$key]:-}" ]]; then
    print -r -- "${_flexoki_task_colors[$key]}"
    return
  fi
  local bg="${_flexoki_task_colors[$name]:-}"
  if [[ -n "$bg" ]]; then
    print -r -- "$bg"
    return
  fi
  if [[ "$name" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    print -r -- "$name"
    return
  fi
  local hash_hex idx accent
  hash_hex=$(printf '%s' "$name" | /usr/bin/shasum | /usr/bin/cut -c1-2)
  idx=$((16#$hash_hex % 8))
  accent="${_flexoki_task_accents[$((idx + 1))]}"
  print -r -- "${_flexoki_task_colors[$accent]}"
}

_ghostty_task_suggested_color() {
  local name="$1" suffix="$2"
  if [[ "$name" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    print -r -- "$name"
    return
  fi
  local key
  key=$(_ghostty_task_snap_key "$(_ghostty_task_color_key "$name")" "$suffix")
  print -r -- "${_flexoki_task_colors[$key]}"
}

_ghostty_task_suggested_color_for_path() {
  local path="$1" suffix="$2" key
  key=$(_ghostty_task_snap_key "$(_ghostty_task_color_key_for_path "$path")" "$suffix")
  print -r -- "${_flexoki_task_colors[$key]}"
}

_ghostty_task_path_bg() {
  local path="$1" osc bg
  osc=$(command ghostty-path-color "$path" 2>/dev/null)
  bg="${osc#*$'\033]11;'}"
  if [[ "$bg" != "$osc" ]]; then
    bg="${bg%%$'\a'*}"
    [[ "$bg" =~ ^#[0-9a-fA-F]{6}$ ]] && { print -r -- "$bg"; return; }
  fi
  print -r -- '#100F0F'
}

_ghostty_task_current_bg() {
  if [[ -n "$TASK" ]]; then
    _ghostty_task_resolve "${TASK:-}"
    return
  fi
  _ghostty_task_path_bg "$PWD"
}

_ghostty_task_terminal_cols() {
  local cols="${COLUMNS:-}"
  if [[ ! "$cols" =~ ^[0-9]+$ ]]; then
    cols=$(command tput cols 2>/dev/null)
  fi
  if [[ ! "$cols" =~ ^[0-9]+$ ]]; then
    cols=80
  fi
  print -r -- "$cols"
}

_ghostty_task_palette_row() {
  local suffix="$1" start="$2" end="$3"
  local idx name key hex
  printf '  %-5s ' "$suffix"
  idx="$start"
  while (( idx <= end )); do
    name="${_flexoki_task_accents[$idx]}"
    key="${name}-${suffix}"
    hex="${_flexoki_task_colors[$key]}"
    _ghostty_task_chip "$key" "$hex"
    idx=$((idx + 1))
  done
  printf '\n'
}

_ghostty_task_wrapped_chips() {
  local -a keys
  keys=("$@")
  local cols=$(_ghostty_task_terminal_cols)
  local chips_per_line=$((cols / 13))
  (( chips_per_line < 1 )) && chips_per_line=1
  local count=0 key hex
  printf '  '
  for key in "${keys[@]}"; do
    if (( count > 0 && count % chips_per_line == 0 )); then
      printf '\n  '
    fi
    hex="${_flexoki_task_colors[$key]}"
    _ghostty_task_chip "$key" "$hex"
    count=$((count + 1))
  done
  printf '\n'
}

_ghostty_task_palette() {
  local name hex key suffix
  local cols=$(_ghostty_task_terminal_cols)
  local chip_width=13 prefix_width=8
  local colors_per_grid=$(((cols - prefix_width) / chip_width))
  (( colors_per_grid < 1 )) && colors_per_grid=1
  (( colors_per_grid > ${#_flexoki_task_accents[@]} )) && colors_per_grid=${#_flexoki_task_accents[@]}

  echo 'Flexoki accent palette (rows are suffixes; cells are task color strings):'
  echo
  local start=1 end idx total=${#_flexoki_task_accents[@]}
  while (( start <= total )); do
    end=$((start + colors_per_grid - 1))
    (( end > total )) && end="$total"
    printf '  %-5s ' 'sfx'
    idx="$start"
    while (( idx <= end )); do
      name="${_flexoki_task_accents[$idx]}"
      printf '%-12s ' "$name"
      idx=$((idx + 1))
    done
    printf '\n'
    for suffix in "${_flexoki_task_suffixes[@]}"; do
      _ghostty_task_palette_row "$suffix" "$start" "$end"
    done
    start=$((end + 1))
    (( start <= total )) && printf '\n'
  done
  echo
  echo 'Base palette:'
  local -a base_keys
  base_keys=()
  for suffix in "${_flexoki_task_suffixes[@]}"; do
    base_keys+=("base-${suffix}")
  done
  base_keys+=(paper black gray)
  _ghostty_task_wrapped_chips "${base_keys[@]}"
  echo
  echo 'Other forms:'
  echo '  #rrggbb        exact hex'
  echo '  <anything>     hashed -> one of the 8 accents'
}

_ghostty_task_rgb() {
  local suffix steps delay key from to i hex tty target pid_file pid
  case "${1:-}" in
    --help|-h)
      cat <<'EOF'
Usage: task rgb [<suffix>] [<steps>] [<delay-seconds>]
       task rgb stop
       task rgb status

Starts a background Flexoki accent-gradient shift in the current Ghostty pane,
then returns shell control immediately.
The suffix defaults to 400 so the RGB cycle is visible without going too dark.

Examples:
  task rgb             shift at the default -400 shade
  task rgb 850         shift through darker accent colors
  task rgb 100 6 .02   shift through light colors, faster
  task rgb stop        stop shifting this pane
EOF
      return
      ;;
    stop|off|clear)
      _ghostty_task_rgb_stop
      return
      ;;
    status)
      _ghostty_task_rgb_status
      return
      ;;
  esac
  suffix="${1:-400}"
  if ! _ghostty_task_is_suffix "$suffix"; then
    echo "task rgb: expected Flexoki suffix: ${_flexoki_task_suffixes[*]}" >&2
    return 2
  fi
  steps="${2:-8}"
  delay="${3:-0.025}"
  if [[ ! "$steps" == <-> || "$steps" -lt 1 ]]; then
    echo 'task rgb: steps must be a positive integer' >&2
    return 2
  fi

  local -a keys
  keys=()
  for key in "${_flexoki_task_accents[@]}"; do
    keys+=("${key}-${suffix}")
  done
  keys+=("${_flexoki_task_accents[1]}-${suffix}")

  tty=$(_ghostty_task_tty_name) || { echo 'task rgb: no tty found for this pane' >&2; return 2; }
  target="/dev/$tty"
  [[ -w "$target" ]] || { echo "task rgb: cannot write to $target" >&2; return 2; }
  _ghostty_task_rgb_stop quiet
  mkdir -p "$(_ghostty_task_state_dir)" || return
  pid_file=$(_ghostty_task_rgb_pid_file "$tty")
  printf '\033]0;[rgb-%s] %s\033\\' "$suffix" "${PWD/#$HOME/~}"
  (
    trap 'exit 0' INT TERM HUP
    local idx=1 next_idx
    while (( 1 )); do
      idx=1
      while (( idx < ${#keys[@]} )); do
        next_idx=$((idx + 1))
        from="${_flexoki_task_colors[${keys[$idx]}]}"
        to="${_flexoki_task_colors[${keys[$next_idx]}]}"
        for (( i = 0; i <= steps; i++ )); do
          hex=$(_ghostty_task_mix_hex "$from" "$to" "$i" "$steps")
          printf '\033]11;%s\033\\' "$hex" > "$target"
          sleep "$delay"
        done
        idx=$next_idx
      done
    done
  ) >/dev/null 2>&1 &
  pid=$!
  print -r -- "$pid" > "$pid_file"
  disown "$pid" 2>/dev/null || :
  _ghostty_task_register_pane
  echo "started rgb shift for $tty (pid $pid); run \`task rgb stop\` to stop"
  return 0
}

_ghostty_task_rgb_stop() {
  local quiet="${1:-}" tty pid_file pid
  tty=$(_ghostty_task_tty_name 2>/dev/null) || return 0
  pid_file=$(_ghostty_task_rgb_pid_file "$tty")
  [[ -r "$pid_file" ]] || return 0
  pid="$(<"$pid_file")"
  if [[ "$pid" == <-> ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || :
    [[ "$quiet" == quiet ]] || echo "stopped rgb shift for $tty"
  fi
  rm -f "$pid_file"
}

_ghostty_task_rgb_status() {
  local tty pid_file pid
  tty=$(_ghostty_task_tty_name) || { echo 'rgb shift: no tty found for this pane'; return 2; }
  pid_file=$(_ghostty_task_rgb_pid_file "$tty")
  if [[ -r "$pid_file" ]]; then
    pid="$(<"$pid_file")"
    if [[ "$pid" == <-> ]] && kill -0 "$pid" 2>/dev/null; then
      echo "rgb shift: running for $tty (pid $pid)"
      return
    fi
    rm -f "$pid_file"
  fi
  echo "rgb shift: stopped for $tty"
}

_ghostty_task_register_pane() {
  local dir file tmp task_name bg ts tty
  dir=$(_ghostty_task_state_dir)
  mkdir -p "$dir" 2>/dev/null || return
  mkdir -p "$(_ghostty_task_panes_dir)" 2>/dev/null || return
  task_name="${TASK:-<dir>}"
  bg=$(_ghostty_task_current_bg)
  ts="${EPOCHSECONDS:-$(date +%s)}"
  tty=$(_ghostty_task_tty_name 2>/dev/null) || return
  file=$(_ghostty_task_pane_file "$tty")
  tmp="${file}.$$"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$$" "$task_name" "$PWD" "$bg" "$ts" "$tty" > "$tmp" && mv "$tmp" "$file"
}

_ghostty_task_apply_current_color() {
  if [[ -n "$TASK" ]]; then
    task "$TASK" >/dev/null
  elif _ghostty_task_active_suffix >/dev/null 2>&1; then
    printf '\033]11;%s\033\\' "$(_ghostty_task_resolve "")"
  else
    _ghostty_path_color
  fi
  _ghostty_task_register_pane
}

_ghostty_task_next_for_pane() {
  local task_name="$1" cwd="$2" suffix="$3"
  if [[ "$task_name" == '<dir>' || "$task_name" == '<unregistered>' || -z "$task_name" ]]; then
    _ghostty_task_suggested_color_for_path "$cwd" "$suffix"
  else
    _ghostty_task_suggested_color "$task_name" "$suffix"
  fi
}

_ghostty_task_migrate_legacy_registry() {
  local reg pid task_name cwd current ts tty live_tty file tmp old_pid old_task old_cwd old_current old_ts old_tty
  reg=$(_ghostty_task_registry_file)
  [[ -r "$reg" ]] || return
  mkdir -p "$(_ghostty_task_panes_dir)" 2>/dev/null || return
  while IFS=$'\t' read -r pid task_name cwd current ts tty; do
    [[ "$pid" == <-> ]] || continue
    [[ "$current" =~ ^#[0-9a-fA-F]{6}$ ]] || continue
    live_tty=$(command ps -p "$pid" -o tty= 2>/dev/null | /usr/bin/tr -d ' ')
    [[ -n "$live_tty" && "$live_tty" != '??' ]] || continue
    tty="${tty:-$live_tty}"
    [[ "$tty" == "$live_tty" ]] || continue
    file=$(_ghostty_task_pane_file "$tty")
    if [[ -r "$file" ]]; then
      IFS=$'\t' read -r old_pid old_task old_cwd old_current old_ts old_tty < "$file"
      [[ "$old_ts" == <-> && "$ts" == <-> && "$old_ts" -gt "$ts" ]] && continue
    fi
    tmp="${file}.$$"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$pid" "$task_name" "$cwd" "$current" "$ts" "$tty" > "$tmp" && mv "$tmp" "$file"
  done < "$reg"
}

_ghostty_task_admin_registered_panes() {
  local file pid task_name cwd current ts tty live_tty
  _ghostty_task_migrate_legacy_registry
  for file in "$(_ghostty_task_panes_dir)"/*.tsv(N); do
    IFS=$'\t' read -r pid task_name cwd current ts tty < "$file" || continue
    [[ "$pid" == <-> ]] || continue
    [[ "$current" =~ ^#[0-9a-fA-F]{6}$ ]] || continue
    tty="${tty:-${file:t:r}}"
    [[ -n "$tty" && "$tty" != 'not a tty' && "$tty" != '??' ]] || continue
    live_tty=$(command ps -p "$pid" -o tty= 2>/dev/null | /usr/bin/tr -d ' ')
    if [[ "$live_tty" != "$tty" ]]; then
      rm -f "$file"
      continue
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$pid" "$task_name" "$cwd" "$current" "$ts" "$tty"
  done
}

_ghostty_task_admin_discovered_panes() {
  local suffix="$1" now pid ppid tty comm args cwd current ts
  local -A ghostty_pids login_pids registered_pids
  now="${EPOCHSECONDS:-$(date +%s)}"
  while IFS=$'\t' read -r pid _task _cwd _current _ts _tty; do
    registered_pids[$pid]=1
  done < <(_ghostty_task_admin_registered_panes)
  while read -r pid ppid tty comm args; do
    [[ "$args" == *Ghostty.app* || "$comm" == *Ghostty* ]] && ghostty_pids[$pid]=1
  done < <(command ps -axo pid=,ppid=,tty=,comm=,args= 2>/dev/null)
  while read -r pid ppid tty comm args; do
    [[ -n "${ghostty_pids[$ppid]:-}" && "$comm" == */login ]] && login_pids[$pid]=1
  done < <(command ps -axo pid=,ppid=,tty=,comm=,args= 2>/dev/null)
  while read -r pid ppid tty comm args; do
    [[ -n "${registered_pids[$pid]:-}" ]] && continue
    [[ -n "${login_pids[$ppid]:-}" ]] || continue
    [[ "$tty" != '??' ]] || continue
    [[ "$comm" == */zsh || "$comm" == */bash || "$comm" == */fish || "$comm" == -* ]] || continue
    cwd=$(/usr/sbin/lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | /usr/bin/sed -n 's/^n//p' | /usr/bin/head -1)
    [[ -n "$cwd" ]] || cwd="$HOME"
    current=$(_ghostty_task_path_bg "$cwd")
    ts="$now"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$pid" '<unregistered>' "$cwd" "$current" "$ts" "$tty"
  done < <(command ps -axo pid=,ppid=,tty=,comm=,args= 2>/dev/null)
}

_ghostty_task_admin_panes() {
  local suffix="$1"
  _ghostty_task_admin_registered_panes
  _ghostty_task_admin_discovered_panes "$suffix"
}

_ghostty_task_tab_category() {
  local task_name="$1" category
  if [[ "$task_name" == '<dir>' || "$task_name" == '<unregistered>' || -z "$task_name" ]]; then
    print -r -- 'other'
    return
  fi
  if [[ "$task_name" == */* ]]; then
    category="${task_name%%/*}"
  elif [[ "$task_name" == *:* ]]; then
    category="${task_name%%:*}"
  else
    case "${task_name:l}" in
      pr*|review*|diff*) category='pr' ;;
      draft*|writing*|write*) category='drafting' ;;
      *) category='other' ;;
    esac
  fi
  print -r -- "${category:l}"
}

_ghostty_task_tab_label() {
  local task_name="$1"
  if [[ "$task_name" == '<dir>' || "$task_name" == '<unregistered>' || -z "$task_name" ]]; then
    print -r -- "$task_name"
  elif [[ "$task_name" == */* ]]; then
    print -r -- "${task_name#*/}"
  elif [[ "$task_name" == *:* ]]; then
    print -r -- "${task_name#*:}"
  else
    print -r -- "$task_name"
  fi
}

_ghostty_task_tabs() {
  local mode="${1:-}" interval pid task_name cwd current ts tty category label active_tty mark age row
  case "$mode" in
    --help|-h)
      cat <<'EOF'
Usage: task tabs [watch [seconds]]

Shows a vertical, categorized list of Ghostty panes registered by `task`.
Use category prefixes in task names to define groups:
  task pr/fix-login
  task drafting/release-notes
  task other/scratch

Run `task tabs watch` in a narrow split to use it as a live side panel.
EOF
      return
      ;;
    watch)
      shift
      interval="${1:-2}"
      while true; do
        printf '\033[H\033[2J'
        _ghostty_task_tabs
        sleep "$interval"
      done
      ;;
  esac

  active_tty=$(_ghostty_task_tty_name 2>/dev/null || :)
  local -a categories
  local -A seen rows counts
  categories=()
  printf 'Ghostty panes by task\n'
  printf 'Use `task <category>/<name>` to categorize; `task tabs watch` for a side panel.\n\n'
  while IFS=$'\t' read -r pid task_name cwd current ts tty; do
    category=$(_ghostty_task_tab_category "$task_name")
    label=$(_ghostty_task_tab_label "$task_name")
    if [[ -z "${seen[$category]:-}" ]]; then
      seen[$category]=1
      categories+=("$category")
    fi
    counts[$category]=$(( ${counts[$category]:-0} + 1 ))
    mark=' '
    [[ -n "$active_tty" && "$tty" == "$active_tty" ]] && mark='*'
    age="$(( ${EPOCHSECONDS:-$(date +%s)} - ${ts:-0} ))s"
    row=$(printf '  %s %-8s %-24s %-7s %s' "$mark" "$tty" "$label" "$age" "${cwd/#$HOME/~}")
    rows[$category]+="${row}"$'\n'
  done < <(_ghostty_task_admin_panes 900)

  if (( ${#categories[@]} == 0 )); then
    echo 'No Ghostty panes found.'
    return
  fi
  for category in "${categories[@]}"; do
    printf '[%s] %s\n' "$category" "${counts[$category]}"
    printf '%s' "${rows[$category]}"
    printf '\n'
  done
}

_ghostty_task_admin_preview() {
  local suffix="$1" pid task_name cwd current ts tty next label saw_unregistered=0
  printf 'Global Ghostty task brightness preview: suffix %s\n\n' "$suffix"
  printf '%-7s %-8s %-18s %-19s %-19s %-10s %s\n' 'pid' 'tty' 'task' 'current' 'next' 'age' 'cwd'
  while IFS=$'\t' read -r pid task_name cwd current ts tty; do
    [[ "$task_name" == '<unregistered>' ]] && saw_unregistered=1
    next=$(_ghostty_task_next_for_pane "$task_name" "$cwd" "$suffix")
    label="$task_name"
    printf '%-7s %-8s %-18s %-8s ' "$pid" "$tty" "$label" "$current"
    _ghostty_task_swatch "$current"
    printf ' %-8s ' "$next"
    _ghostty_task_swatch "$next"
    printf ' %-10s %s\n' "$(( ${EPOCHSECONDS:-$(date +%s)} - ${ts:-0} ))s" "${cwd/#$HOME/~}"
  done < <(_ghostty_task_admin_panes "$suffix")
  if (( saw_unregistered )); then
    echo
    echo 'note: <unregistered> means an existing pane has not loaded this helper yet; new Ghostty panes auto-register via ~/.zshrc.'
  fi
}

_ghostty_task_admin_signal_panes() {
  local suffix="$1" mode="${2:-apply}" pid task_name cwd current ts tty next target file tmp now applied=0 skipped=0 failed=0 local_suffix
  while IFS=$'\t' read -r pid task_name cwd current ts tty; do
    next=''
    if [[ -n "$tty" && "$tty" != '??' ]]; then
      target="/dev/$tty"
      if [[ -w "$target" ]]; then
        if [[ "$mode" == clear ]]; then
          local_suffix=$(_ghostty_task_suffix_for_tty "$tty" 2>/dev/null || :)
          if [[ -n "$local_suffix" ]]; then
            next=$(_ghostty_task_next_for_pane "$task_name" "$cwd" "$local_suffix")
            if ! printf '\033]11;%s\007' "$next" > "$target"; then
              failed=$((failed + 1))
              continue
            fi
          elif [[ "$task_name" == '<dir>' || "$task_name" == '<unregistered>' || -z "$task_name" ]]; then
            next=$(_ghostty_task_path_bg "$cwd")
            if ! printf '%s' "$(command ghostty-path-color "$cwd" 2>/dev/null)" > "$target"; then
              failed=$((failed + 1))
              continue
            fi
          else
            next=$(_ghostty_task_suggested_color "$task_name" "")
            if ! printf '\033]11;%s\007' "$next" > "$target"; then
              failed=$((failed + 1))
              continue
            fi
          fi
          if [[ -n "$next" ]]; then
            now="${EPOCHSECONDS:-$(date +%s)}"
            file=$(_ghostty_task_pane_file "$tty")
            tmp="${file}.$$"
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$pid" "$task_name" "$cwd" "$next" "$now" "$tty" > "$tmp" && mv "$tmp" "$file"
            applied=$((applied + 1))
          fi
        else
          next=$(_ghostty_task_next_for_pane "$task_name" "$cwd" "$suffix")
          if printf '\033]11;%s\007' "$next" > "$target"; then
            now="${EPOCHSECONDS:-$(date +%s)}"
            file=$(_ghostty_task_pane_file "$tty")
            tmp="${file}.$$"
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$pid" "$task_name" "$cwd" "$next" "$now" "$tty" > "$tmp" && mv "$tmp" "$file"
            applied=$((applied + 1))
          else
            failed=$((failed + 1))
          fi
        fi
      else
        failed=$((failed + 1))
      fi
    else
      skipped=$((skipped + 1))
    fi
  done < <(_ghostty_task_admin_registered_panes)
  print -r -- "$applied $skipped $failed"
}

_ghostty_task_shade() {
  local preview=0 suffix file dir tty current_global current_local result
  case "${1:-}" in
    --help|-h)
      cat <<'EOF'
Usage: task shade [<suffix> | -p [<suffix>] | clear | status | --help]
       task shade global [<suffix> | -p [<suffix>] | clear | status]

Sets this pane's Flexoki brightness suffix while preserving its task hue.
Use `task shade global` for the all-pane brightness default.

Examples:
  task shade 400           set this pane to suffix 400
  task shade clear         clear this pane's shade override
  task shade global 850    set all registered panes, and future panes, to suffix 850
  task shade global clear  clear the global brightness default
EOF
      return
      ;;
    global|all)
      shift
      _ghostty_task_global_shade "$@"
      return
      ;;
    -p|--preview)
      preview=1
      shift
      ;;
    clear|off)
      tty=$(_ghostty_task_tty_name) || { echo 'task shade: no tty found for this pane' >&2; return 2; }
      rm -f "$(_ghostty_task_pane_suffix_file "$tty")"
      _ghostty_task_apply_current_color
      echo "cleared shade override for $tty"
      return
      ;;
    status|'')
      current_local=$(_ghostty_task_local_suffix 2>/dev/null || :)
      current_global=$(_ghostty_task_global_suffix 2>/dev/null || :)
      echo "pane shade: ${current_local:-<none>}"
      echo "global shade: ${current_global:-<none>}"
      return
      ;;
  esac
  suffix="$1"
  if [[ -z "$suffix" && "$preview" == 1 ]]; then
    suffix=$(_ghostty_task_active_suffix 2>/dev/null || :)
    [[ -n "$suffix" ]] || suffix=900
  fi
  if ! _ghostty_task_is_suffix "$suffix"; then
    echo "task shade: expected Flexoki suffix: ${_flexoki_task_suffixes[*]}" >&2
    return 2
  fi
  if (( preview )); then
    printf 'Pane shade preview: suffix %s\n' "$suffix"
    _ghostty_task_swatch "$(_ghostty_task_resolve "${TASK:-}")"
    printf ' -> '
    _ghostty_task_swatch "$(_ghostty_task_next_for_pane "${TASK:-<dir>}" "$PWD" "$suffix")"
    printf '\n'
    return
  fi
  tty=$(_ghostty_task_tty_name) || { echo 'task shade: no tty found for this pane' >&2; return 2; }
  dir=$(_ghostty_task_state_dir)
  file=$(_ghostty_task_pane_suffix_file "$tty")
  mkdir -p "$dir" || return
  print -r -- "$suffix" > "$file"
  _ghostty_task_apply_current_color
  echo "applied pane shade suffix $suffix to $tty"
}

_ghostty_task_global_shade() {
  local preview=0 suffix file dir result
  case "${1:-}" in
    -p|--preview)
      preview=1
      shift
      ;;
    clear|off)
      rm -f "$(_ghostty_task_brightness_file)"
      result=$(_ghostty_task_admin_signal_panes 900 clear)
      echo 'cleared global Ghostty task brightness'
      echo "touched panes: ${result:-0 0 0} (applied skipped failed)"
      return
      ;;
    status|'')
      suffix=$(_ghostty_task_global_suffix 2>/dev/null || :)
      if [[ -n "$suffix" ]]; then
        _ghostty_task_admin_preview "$suffix"
      else
        echo 'global Ghostty task brightness: <none>'
        _ghostty_task_admin_preview 900
      fi
      return
      ;;
  esac
  suffix="$1"
  if [[ -z "$suffix" && "$preview" == 1 ]]; then
    suffix=$(_ghostty_task_global_suffix 2>/dev/null || :)
    [[ -n "$suffix" ]] || suffix=900
  fi
  if ! _ghostty_task_is_suffix "$suffix"; then
    echo "task shade global: expected Flexoki suffix: ${_flexoki_task_suffixes[*]}" >&2
    return 2
  fi
  _ghostty_task_admin_preview "$suffix"
  (( preview )) && return
  dir=$(_ghostty_task_state_dir)
  file=$(_ghostty_task_brightness_file)
  mkdir -p "$dir" || return
  print -r -- "$suffix" > "$file"
  result=$(_ghostty_task_admin_signal_panes "$suffix")
  printf '\napplied global Ghostty task brightness suffix %s\n' "$suffix"
  echo "touched panes: ${result:-0 0 0} (applied skipped failed)"
  echo 'note: apply only changes registered panes; preview-only <unregistered> panes are intentionally skipped'
}

_ghostty_task_help() {
  local active_suffix key suffix
  active_suffix=$(_ghostty_task_active_suffix 2>/dev/null || :)
  [[ -n "$active_suffix" ]] || active_suffix=900

  cat <<'EOF'
Usage: task [<name> | <color>[-suffix] | #rrggbb | clear | -p | rgb | shade | --help]

Tags the current Ghostty window with a Flexoki background color and title.
With no args, prints the current task and its swatch.
EOF

  printf '\nAccent names (Flexoki, current/default suffix -%s):\n' "$active_suffix"
  local -a accent_keys
  accent_keys=()
  for key in "${_flexoki_task_accents[@]}"; do
    accent_keys+=("${key}-${active_suffix}")
  done
  _ghostty_task_wrapped_chips "${accent_keys[@]}"

  printf '\nSuffixes (shown on red; append to any accent):\n'
  local -a suffix_keys
  suffix_keys=()
  for suffix in "${_flexoki_task_suffixes[@]}"; do
    suffix_keys+=("red-${suffix}")
  done
  _ghostty_task_wrapped_chips "${suffix_keys[@]}"

  printf '\nBase samples:\n'
  _ghostty_task_wrapped_chips paper black gray base-50 base-100 base-200 base-500 base-800 base-900 base-950

  cat <<'EOF'

Other:
  #rrggbb        use exact hex color
  <other>        hashed -> one of the 8 accents
  clear|off      drop tag, restore dir-based color
  -p, --palette  preview every Flexoki color in a rendered grid
  tabs --help    show vertical categorized pane list controls
  rgb --help     show accent-gradient transition controls
  shade --help   show pane/global brightness controls for light/dark mode switching

Flexoki palette by Steph Ango: https://stephango.com/flexoki
EOF
}

task() {
  if [[ -z "$1" ]]; then
    if [[ -n "$TASK" ]]; then
      local bg=$(_ghostty_task_resolve "$TASK")
      printf 'current task: %s  ' "$TASK"
      _ghostty_task_swatch "$bg"
      printf '\n'
    else
      echo 'current task: <none>'
    fi
    return
  fi
  case "$1" in
    --help|-h)
      _ghostty_task_help
      return
      ;;
    -p|--palette|--colors|list)
      _ghostty_task_palette
      return
      ;;
    shade)
      shift
      _ghostty_task_shade "$@"
      return
      ;;
    rgb)
      shift
      _ghostty_task_rgb "$@"
      return
      ;;
    tabs)
      shift
      _ghostty_task_tabs "$@"
      return
      ;;
    admin)
      shift
      echo 'task admin is now task shade global; run `task shade --help` for usage.' >&2
      _ghostty_task_global_shade "$@"
      return
      ;;
    clear|off)
      _ghostty_task_rgb_stop quiet
      unset TASK
      _ghostty_reset_colors
      _ghostty_task_apply_current_color
      return
      ;;
  esac

  export TASK="$1"
  _ghostty_task_rgb_stop quiet
  local bg
  bg=$(_ghostty_task_resolve "$1")
  printf '\033]11;%s\033\\' "$bg"
  printf '\033]0;[%s] %s\033\\' "$1" "${PWD/#$HOME/~}"
  _ghostty_task_register_pane
}

task-shade() { _ghostty_task_shade "$@"; }
task-admin() {
  echo 'task-admin is now task-shade global; run `task-shade --help` for usage.' >&2
  _ghostty_task_global_shade "$@"
}

# Re-apply task color after dir-based color hook runs on cd.
_ghostty_task_guard() { _ghostty_task_apply_current_color; }
add-zsh-hook chpwd _ghostty_task_guard
add-zsh-hook precmd _ghostty_task_register_pane

_task() {
  local -a colors intensities meta
  colors=(
    red orange yellow green cyan blue purple magenta
    paper gray grey black
  )
  intensities=()
  local color suffix
  for color in "${_flexoki_task_accents[@]}"; do
    for suffix in "${_flexoki_task_suffixes[@]}"; do
      intensities+=("${color}-${suffix}")
    done
  done
  for suffix in "${_flexoki_task_suffixes[@]}"; do
    intensities+=("base-${suffix}")
  done
  meta=(
    'clear:drop tag'
    'off:drop tag'
    '--help:show usage'
    '-p:preview all colors'
    '--palette:preview all colors'
    'rgb:run accent-gradient transition'
    'shade:preview/apply pane light/dark brightness'
    'tabs:show vertical categorized pane list'
    'global:apply shade to all panes'
    'status:show shade status'
  )
  _describe -t colors 'flexoki accent' colors
  _describe -t intensities 'flexoki intensity' intensities
  _describe -t meta 'meta' meta
}
if (( $+functions[compdef] )); then
  compdef _task task
  compdef _task task-shade
  compdef _task task-admin
else
  autoload -Uz compinit && compinit -u 2>/dev/null && compdef _task task && compdef _task task-shade && compdef _task task-admin
fi

_ghostty_task_register_pane
