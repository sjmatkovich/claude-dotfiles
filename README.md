# claude-dotfiles

Dotfiles for [Claude Code](https://claude.ai/code) — restore your global plugin setup on a new machine in minutes.

## What's included

| File | Purpose |
|------|---------|
| `claude/CLAUDE.md` | Global behavioral instructions for Claude (applies to all sessions) |
| `settings.json` | Global Claude Code settings: enabled plugins |
| `claude/skills/` | Global skills, symlinked from `~/.claude/skills` — every skill you add there is version-controlled and synced automatically |
| `settings.local.json.example` | Template for machine-specific permission allowlists |
| `install.sh` | Automated setup script |

### Not included (intentionally)

- `.credentials.json` — OAuth tokens; machine-specific and secret
- `history.jsonl`, `sessions/`, `telemetry/`, `cache/`, `debug/` — ephemeral runtime data
- `projects/` — per-project config lives in each repo's `.claude/` directory

---

## Plugins

This setup installs three plugins across two marketplaces.

### Marketplace: `claude-plugins-official` (Anthropic official)

This marketplace is registered automatically when you first run Claude Code. No manual step needed.

#### `skill-creator`

**Source:** `anthropics/claude-plugins-official`

Create new skills, improve existing skills, and measure skill performance. Trigger it when you want to build a reusable Claude Code skill from scratch, improve an existing one with eval benchmarks, or run variance analysis on skill quality. The plugin manages the full skill authoring loop: draft, evaluate, compare, and iterate.

**When to invoke:** Say "create a new skill that..." or "improve my existing /foo skill" and Claude will invoke it automatically.

#### `claude-code-setup`

**Source:** `anthropics/claude-plugins-official`

Analyzes a codebase and recommends the top automations tailored to that project: MCP servers, skills, hooks, subagents, and slash commands. Read-only — it never modifies files.

**When to invoke:** Say "recommend automations for this project" or "help me set up Claude Code" in any project directory.

---

### Marketplace: `karpathy-skills` (third-party — requires manual registration)

**GitHub:** `forrestchang/andrej-karpathy-skills`

This is a third-party marketplace. Claude Code does not auto-register it. You must add it manually (see setup steps below).

#### `andrej-karpathy-skills`

Behavioral guidelines derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls. Installs four principles as a skill Claude invokes when writing or reviewing code:

| Principle | What it prevents |
|-----------|-----------------|
| **Think Before Coding** | Silent wrong assumptions, hidden confusion, missing tradeoffs |
| **Simplicity First** | Overengineering, bloated abstractions, speculative features |
| **Surgical Changes** | Drive-by refactoring, touching code orthogonal to the task |
| **Goal-Driven Execution** | Vague tasks with no verifiable success criteria |

**When to invoke:** Say "write/review/refactor code" — the skill triggers automatically to enforce these principles before and during implementation.

---

## Setup

### Prerequisites

Claude Code must already be installed. If it isn't, install it first:

```bash
npm install -g @anthropic-ai/claude-code
```

### Step 1: Run the install script

```bash
git clone https://github.com/sjmatkovich/claude-dotfiles.git
cd claude-dotfiles
chmod +x install.sh
./install.sh
```

The script:
- Checks that `~/.claude/` exists
- Backs up any existing `settings.json` before overwriting
- Symlinks `settings.json` to `~/.claude/settings.json`
- Symlinks `CLAUDE.md` to `~/.claude/CLAUDE.md`
- Backs up any existing `~/.claude/skills/` directory, then symlinks `claude/skills/` to `~/.claude/skills`
- Optionally copies `settings.local.json.example` as a starting point for `~/.claude/settings.local.json`

### Step 2: Register the karpathy-skills marketplace (in Claude Code)

The `claude-plugins-official` marketplace is registered automatically. The `karpathy-skills` marketplace is third-party and must be added manually. Open Claude Code and run:

```
/plugins add-marketplace forrestchang/andrej-karpathy-skills
```

When prompted for a marketplace ID, enter: `karpathy-skills`

### Step 3: Install the plugins (in Claude Code)

Install all three plugins:

```
/plugins install skill-creator@claude-plugins-official
/plugins install claude-code-setup@claude-plugins-official
/plugins install andrej-karpathy-skills@karpathy-skills
```

After installation, the plugins are active immediately — no restart needed.

### Step 4: Customize settings.local.json

Edit `~/.claude/settings.local.json` to add Bash command allowlists specific to your machine and workflow. For example:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git *)",
      "Bash(ls *)"
    ]
  }
}
```

See `settings.local.json.example` in this repo for the template.

---

## Keeping up to date

To update installed plugins to their latest versions from within Claude Code:

```
/plugins update
```

To pull new versions of these dotfiles onto an existing machine:

```bash
cd claude-dotfiles
git pull
./install.sh
```

The script will back up your existing `settings.json` before overwriting.

---

## Keeping this repo synced with GitHub

The `sync-dotfiles` skill (`claude/skills/sync-dotfiles/`) keeps this repo in sync with its GitHub origin: it commits any uncommitted local changes, then pushes, pulls, or rebase-and-pushes as needed to reconcile with `origin`, with no permission prompts for the git operations involved. Invoke it from within Claude Code with:

```
/sync-dotfiles
```

The only case that needs a human is a genuine rebase conflict — the skill aborts the rebase cleanly and reports which files/commits conflicted rather than guessing at a resolution.

### Scheduling an unattended daily sync (WSL2 + Windows Task Scheduler)

On Windows/WSL2, there's no reliable way to run a cron job from *inside* WSL2 alone, since the WSL2 VM shuts down when idle. Instead, use Windows Task Scheduler to start WSL2 and run the sync directly — this both wakes the VM (if needed) and executes the job in one step.

**Prerequisite:** the git commands `/sync-dotfiles` runs (`fetch`, `status`, `add`, `commit`, `push`, `pull`, `rebase`) must be pre-approved in `~/.claude/settings.json`, since a headless run has no TTY to answer a permission prompt. This repo's `settings.json` already includes:

```json
"Bash(git -C ~/github/claude-dotfiles *)"
```

**Set up the scheduled task** — run this from PowerShell or `cmd.exe` on Windows (not from inside WSL), adjusting the distro name (`-d Fedora`) and username (`-u sjm`) to match your setup:

```
schtasks /Create /TN "WSL Sync Dotfiles" /TR "wsl.exe -d Fedora -u sjm -- bash -lc \"claude -p '/sync-dotfiles' >> ~/.cache/sync-dotfiles-cron.log 2>&1\"" /SC DAILY /ST 08:00 /RL HIGHEST
```

This creates a task named `WSL Sync Dotfiles` that runs daily at 8:00 AM, launching WSL2 and invoking Claude Code non-interactively to run `/sync-dotfiles`, with output appended to `~/.cache/sync-dotfiles-cron.log` for later review. You'll be prompted for your Windows password so the task can run whether or not you're logged in.

To set it up via the Task Scheduler GUI instead:
1. **Create Task** (not "Basic Task") → name it, check **"Run whether user is logged on or not"**.
2. **Triggers** → New → **Daily**, start time **8:00 AM**.
3. **Actions** → New → Program: `wsl.exe`, Arguments: `-d Fedora -u sjm -- bash -lc "claude -p '/sync-dotfiles' >> ~/.cache/sync-dotfiles-cron.log 2>&1"`.
4. **Conditions** → uncheck "Start the task only if the computer is on AC power".
5. **Settings** → check "Run task as soon as possible after a scheduled start is missed".

Check `~/.cache/sync-dotfiles-cron.log` periodically — a `stopped on conflict` entry means a rebase conflict needs manual resolution.

---

## What settings.json does NOT control

These things are managed separately and are not restored by this repo:

- **Credentials** — Re-authenticate with `claude login` on the new machine
- **Global CLAUDE.md** — Managed by this repo at `claude/CLAUDE.md`, symlinked to `~/.claude/CLAUDE.md`
- **Per-project CLAUDE.md** — Lives in each project's own `.claude/CLAUDE.md`
- **MCP servers** — Configured per-project in `.claude/settings.json` inside each repo
- **Keybindings** — If you customize `~/.claude/keybindings.json`, add it to this repo manually (it contains no secrets)
- **Hooks** — If you configure global hooks in `~/.claude/settings.json`, they will be included automatically once you add them there
