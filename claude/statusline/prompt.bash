# Claude Code status indicator for bash prompt.
# Shows [claude] in yellow when Claude is actively using tools.
# Sourced from ~/.bashrc.d/ by the dotfiles install script.

_CLAUDE_STATUS_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code/status"

__claude_ps1() {
  [[ -f "$_CLAUDE_STATUS_FILE" ]] || return
  local s
  s=$(<"$_CLAUDE_STATUS_FILE")
  # \001 / \002 are readline's ignore-width markers (equivalent to \[ \] in PS1)
  [[ "$s" == "working" ]] && printf ' \001\e[33m\002[claude]\001\e[0m\002'
}

# Append once; guard against double-sourcing
[[ "${PS1-}" != *__claude_ps1* ]] && PS1="${PS1-}\$(__claude_ps1)"
