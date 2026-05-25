#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# ── install settings.json ─────────────────────────────────────────────────────
section "Installing settings.json"

TARGET="$CLAUDE_DIR/settings.json"
SOURCE="$REPO_DIR/settings.json"

if [ -f "$TARGET" ]; then
    BACKUP="${TARGET}.backup.$(date +%s)"
    warn "Existing settings.json found. Backing up to: $BACKUP"
    cp "$TARGET" "$BACKUP"
fi

cp "$SOURCE" "$TARGET"
info "Copied settings.json to $TARGET"

# ── optionally install settings.local.json ────────────────────────────────────
section "settings.local.json (machine-specific permissions)"

LOCAL_TARGET="$CLAUDE_DIR/settings.local.json"
LOCAL_SOURCE="$REPO_DIR/settings.local.json.example"

if [ -f "$LOCAL_TARGET" ]; then
    warn "settings.local.json already exists — skipping (keeping your existing one)."
    warn "Reference template: $LOCAL_SOURCE"
else
    printf "\n%s" "No settings.local.json found. Copy the example template? [y/N] "
    read -r REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        cp "$LOCAL_SOURCE" "$LOCAL_TARGET"
        info "Copied settings.local.json.example to $LOCAL_TARGET"
        info "Edit $LOCAL_TARGET to add your machine-specific Bash allowlists."
    else
        info "Skipped. You can copy it manually later:"
        info "  cp \"$LOCAL_SOURCE\" \"$LOCAL_TARGET\""
    fi
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
info "settings.json is in place. Complete the manual steps above and you're set."
