---
name: sync-dotfiles
description: Sync the local claude-dotfiles git repo (~/github/claude-dotfiles, Fedora WSL2) with its GitHub origin — commit any uncommitted local changes, then push, pull, or rebase-and-push as needed to reconcile with origin, fully autonomously with no permission prompts for the git commands involved. Use this whenever the user asks to sync, push, pull, or reconcile their dotfiles repo, or wants this run on a recurring schedule/loop (e.g. "sync my dotfiles", "push my claude-dotfiles changes", "keep claude-dotfiles in sync with origin"). Only the rebase-conflict case needs a human — everything else should be handled without asking.
---

# Sync claude-dotfiles with origin

This repo (`~/github/claude-dotfiles`) is meant to stay in sync with GitHub
automatically, including when this skill is invoked unattended in a loop. The
git operations below (fetch, add, commit, push, pull, rebase) are routine and
safe to run without asking for confirmation — the only situation that needs a
human is a genuine rebase conflict, since force-resolving that risks silently
discarding someone's work.

The repo holds `claude/skills/`, which `~/.claude/skills` is symlinked to —
so every global skill (including this one) lives inside the repo and is
covered by the same fetch/add/commit/push/pull/rebase cycle below. Adding,
editing, or removing a skill under `~/.claude/skills/` is just editing a file
in the repo; no extra sync steps are needed beyond the ones already listed.

Run every step with `-C ~/github/claude-dotfiles` (or `cd` there first) so it
works regardless of the current shell directory.

## Steps

1. **Fetch.**
   ```
   git -C ~/github/claude-dotfiles fetch origin
   ```
   This updates the remote-tracking refs without touching local work.

2. **Check for uncommitted local changes.**
   ```
   git -C ~/github/claude-dotfiles status --porcelain
   ```
   If this prints anything, there are uncommitted changes. Stage and commit
   them so they aren't lost or left dangling:
   ```
   git -C ~/github/claude-dotfiles add -A
   git -C ~/github/claude-dotfiles commit -m "<descriptive message>"
   ```
   Write the commit message from what actually changed (`git -C
   ~/github/claude-dotfiles diff --cached --stat` is useful here) — summarize
   the substance of the change, not just "update files". After this, local
   has at least one commit origin doesn't have yet, which the next step will
   pick up.

3. **Compare local and remote, then reconcile.**
   Find the current branch and the ahead/behind counts:
   ```
   branch=$(git -C ~/github/claude-dotfiles branch --show-current)
   git -C ~/github/claude-dotfiles rev-list --left-right --count HEAD...origin/$branch
   ```
   This prints two numbers: `<ahead>\t<behind>`.

   - **Ahead only** (ahead > 0, behind = 0) — local has commits origin lacks
     (including any just made in step 2):
     ```
     git -C ~/github/claude-dotfiles push
     ```
   - **Behind only** (ahead = 0, behind > 0) — origin has commits local
     lacks, no local work to protect:
     ```
     git -C ~/github/claude-dotfiles pull
     ```
     This is a plain fast-forward since local has nothing of its own.
   - **Diverged** (ahead > 0 and behind > 0) — both sides moved:
     ```
     git -C ~/github/claude-dotfiles pull --rebase
     ```
     If that succeeds cleanly, follow with:
     ```
     git -C ~/github/claude-dotfiles push
     ```
     If the rebase reports a conflict, stop reconciling automatically — this
     is the one case that genuinely needs a human, because guessing at a
     conflict resolution could silently drop someone's change. Abort cleanly
     instead of leaving the repo mid-rebase:
     ```
     git -C ~/github/claude-dotfiles rebase --abort
     ```
     Then report the conflict (which files, which commits) so it can be
     resolved by hand. Do not force-push, do not discard changes, do not try
     to pick a "winning" side yourself.
   - **Neither ahead nor behind** — already in sync, nothing to do.

4. **Report the outcome.** State plainly which of these happened, since the
   caller (often an unattended loop) needs to know at a glance:
   - `synced clean` — nothing to do, already in sync
   - `committed+pushed` — include the commit message(s)
   - `pulled` — include the commit range pulled in
   - `rebased+pushed` — include the commit range involved
   - `stopped on conflict` — include which files conflicted and that the
     rebase was aborted, so the repo is left in a clean (pre-rebase) state
     for manual resolution
