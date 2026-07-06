#!/usr/bin/env bash
# Claude Code statusLine script
# Mirrors the look of the machine's shell PS1 (Fedora bash-color-prompt.sh:
# green "user@host:/cwd", PROMPT_COLOR=32), plus git branch and the usual
# Claude Code statusLine extras (model, context %, rate limit usage).
#
# Rendered as:
#   user@host:/current/working/dir (branch) | Model | ctx: NN% | 5h: NN% | 7d: NN%
#
# rate_limits.* is only populated for Claude.ai subscribers (Pro/Max) after
# the first API response of the session; absent for API-key users.

set -u

input="$(cat)"

model_cwd_pct="$(python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
model = (d.get("model") or {}).get("display_name") or (d.get("model") or {}).get("id") or "unknown"
cwd = (d.get("workspace") or {}).get("current_dir") or d.get("cwd") or ""
pct = (d.get("context_window") or {}).get("used_percentage")
rl = d.get("rate_limits") or {}
five_h = (rl.get("five_hour") or {}).get("used_percentage")
seven_d = (rl.get("seven_day") or {}).get("used_percentage")
print(model)
print(cwd)
print("" if pct is None else pct)
print("" if five_h is None else five_h)
print("" if seven_d is None else seven_d)
' <<<"$input")"

model="$(sed -n '1p' <<<"$model_cwd_pct")"
cwd="$(sed -n '2p' <<<"$model_cwd_pct")"
used_pct="$(sed -n '3p' <<<"$model_cwd_pct")"
five_hour_pct="$(sed -n '4p' <<<"$model_cwd_pct")"
seven_day_pct="$(sed -n '5p' <<<"$model_cwd_pct")"

[ -z "$model" ] && model="unknown"
[ -z "$cwd" ] && cwd="$(pwd)"

# Mirror PS1's \w: full path, with $HOME collapsed to ~
dir_display="$cwd"
case "$dir_display" in
    "$HOME") dir_display="~" ;;
    "$HOME"/*) dir_display="~${dir_display#$HOME}" ;;
esac

user="$(whoami)"
host="$(hostname -s 2>/dev/null || hostname)"

branch=""
if [ -d "$cwd" ]; then
    branch="$(cd "$cwd" 2>/dev/null && git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)"
fi

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# user@host:path segment, colored green like the shell PS1 (PROMPT_COLOR=32)
printf "${GREEN}%s@%s:%s${RESET}" "$user" "$host" "$dir_display"

# git branch, if any
[ -n "$branch" ] && printf " ${YELLOW}(%s)${RESET}" "$branch"

# model + context usage
printf " | %s" "$model"
if [ -n "$used_pct" ]; then
    ctx="$(printf '%.0f' "$used_pct" 2>/dev/null)"
    [ -n "$ctx" ] && printf " | ctx: %s%%" "$ctx"
fi

# rate limit usage (Claude.ai subscribers only; absent for API-key users)
if [ -n "$five_hour_pct" ]; then
    fh="$(printf '%.0f' "$five_hour_pct" 2>/dev/null)"
    [ -n "$fh" ] && printf " | 5h: %s%%" "$fh"
fi
if [ -n "$seven_day_pct" ]; then
    sd="$(printf '%.0f' "$seven_day_pct" 2>/dev/null)"
    [ -n "$sd" ] && printf " | 7d: %s%%" "$sd"
fi

printf '\n'
