# claude-dotfiles

Dotfiles for [Claude Code](https://claude.ai/code) — restore your global plugin setup on a new machine in minutes.

## What's included

| File | Purpose |
|------|---------|
| `settings.json` | Global Claude Code settings: enabled plugins |
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
- Copies `settings.json` to `~/.claude/settings.json`
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

## What settings.json does NOT control

These things are managed separately and are not restored by this repo:

- **Credentials** — Re-authenticate with `claude login` on the new machine
- **Per-project CLAUDE.md** — Lives in each project repo
- **MCP servers** — Configured per-project in `.claude/settings.json` inside each repo
- **Keybindings** — If you customize `~/.claude/keybindings.json`, add it to this repo manually (it contains no secrets)
- **Hooks** — If you configure global hooks in `~/.claude/settings.json`, they will be included automatically once you add them there
