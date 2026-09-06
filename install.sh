#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_CONFIG_DIR="$REPO_DIR/claude"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { printf "${GREEN}[info]${RESET}  %s\n" "$*"; }
warn()    { printf "${YELLOW}[warn]${RESET}  %s\n" "$*"; }
error()   { printf "${RED}[error]${RESET} %s\n" "$*"; }
section() { printf "\n${BOLD}%s${RESET}\n" "$*"; }

# ── check prereqs ─────────────────────────────────────────────────────────────
section "Checking prerequisites"

if [ ! -d "$CLAUDE_DIR" ]; then
    error "~/.claude/ directory not found."
    error "Claude Code must be installed before running this script."
    error "Install it with:  npm install -g @anthropic-ai/claude-code"
    error "Then run 'claude' once to initialise the config directory."
    exit 1
fi

info "Found ~/.claude/ — proceeding."

# ── symlink helper ────────────────────────────────────────────────────────────
link_item() {
    local target="$1" source="$2" label="$3"

    if [ ! -e "$source" ]; then
        return 0
    fi

    section "Symlinking $label"

    if [ -L "$target" ]; then
        warn "$label is already a symlink — relinking."
        rm "$target"
    elif [ -e "$target" ]; then
        local backup="${target}.backup.$(date +%s)"
        warn "Existing $label found. Backing up to: $backup"
        mv "$target" "$backup"
    fi

    ln -s "$source" "$target"
    info "Linked $target -> $source"
}

LINKS=(
    "settings.json:settings.json"
    "CLAUDE.md:CLAUDE.md"
    "skills:skills"
    "agents:agents"
    "commands:commands"
    "keybindings.json:keybindings.json"
    "statusline-command.sh:statusline/statusline-command.sh"
)

for entry in "${LINKS[@]}"; do
    name="${entry%%:*}"
    rel="${entry#*:}"
    link_item "$CLAUDE_DIR/$name" "$CLAUDE_CONFIG_DIR/$rel" "$name"
done

# ── settings.local.json (machine-specific) ────────────────────────────────────
section "settings.local.json (machine-specific permissions)"

LOCAL_TARGET="$CLAUDE_DIR/settings.local.json"
LOCAL_EXAMPLE="$CLAUDE_CONFIG_DIR/settings.local.json.example"

if [ -f "$LOCAL_TARGET" ] || [ -L "$LOCAL_TARGET" ]; then
    warn "settings.local.json already exists — skipping (keeping your existing one)."
    warn "Reference template: $LOCAL_EXAMPLE"
else
    printf "\n%s" "No settings.local.json found. Copy the example template? [y/N] "
    read -r REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        cp "$LOCAL_EXAMPLE" "$LOCAL_TARGET"
        info "Copied settings.local.json.example to $LOCAL_TARGET"
        info "Edit $LOCAL_TARGET to add your machine-specific Bash allowlists."
    else
        info "Skipped. You can copy it manually later:"
        info "  cp \"$LOCAL_EXAMPLE\" \"$LOCAL_TARGET\""
    fi
fi

# ── bash statusline prompt integration ───────────────────────────────────────
section "Bash statusline"

BASHRC_D="$HOME/.bashrc.d"
PROMPT_SOURCE="$CLAUDE_CONFIG_DIR/statusline/prompt.bash"
PROMPT_LINK="$BASHRC_D/claude-statusline.bash"

if [ ! -d "$BASHRC_D" ]; then
    mkdir -p "$BASHRC_D"
    info "Created $BASHRC_D"
fi

if true; then
    if [ -L "$PROMPT_LINK" ]; then
        warn "claude-statusline.bash symlink already exists — relinking."
        rm "$PROMPT_LINK"
    elif [ -f "$PROMPT_LINK" ]; then
        warn "claude-statusline.bash already exists as a file — backing up."
        mv "$PROMPT_LINK" "${PROMPT_LINK}.backup.$(date +%s)"
    fi
    ln -s "$PROMPT_SOURCE" "$PROMPT_LINK"
    info "Linked $PROMPT_LINK -> $PROMPT_SOURCE"
fi

# ── manual steps ──────────────────────────────────────────────────────────────
section "Manual steps required inside Claude Code"

printf "\n"
printf "${BOLD}Step 1: Register the karpathy-skills marketplace${RESET}\n"
printf "  The official Anthropic marketplace is auto-registered.\n"
printf "  The karpathy-skills marketplace is third-party and must be added manually.\n"
printf "\n"
printf "  In Claude Code, run:\n"
printf "\n"
printf "    /plugins add-marketplace forrestchang/andrej-karpathy-skills\n"
printf "\n"
printf "  When prompted for a marketplace ID, enter:  karpathy-skills\n"
printf "\n"
printf "${BOLD}Step 2: Install the three plugins${RESET}\n"
printf "\n"
printf "  In Claude Code, run each of these:\n"
printf "\n"
printf "    /plugins install skill-creator@claude-plugins-official\n"
printf "    /plugins install claude-code-setup@claude-plugins-official\n"
printf "    /plugins install andrej-karpathy-skills@karpathy-skills\n"
printf "\n"

section "Done"
info "settings.json is symlinked from the repo. Complete the manual steps above and you're set."
