---
tags: [cyber, module1, git]
jqr: "Module 1 — create a GitHub account and keep your Bash/Python work in PUBLIC repos for instructors to review"
---

# Git and GitHub

Version control + the place instructors watch your progress. The JQR requires your study/project repos to be **public** so Troop members can see your work — this whole vault is that repo, synced with the Obsidian Git plugin.

> **The mental model:** git keeps a *timeline of snapshots*, not a pile of files. Every `commit` is a full labeled photo of your project at a moment, and the history is those photos in order — so you can always jump back to any one. GitHub isn't git; it's just a shared server you *push* that timeline to, so other people (here, instructors) can watch it grow. Local git = your save-points; GitHub = the cloud copy everyone can see.

## TL;DR — the daily loop
```bash
git status                 # what changed
git add -A                 # stage everything
git commit -m "add nmap notes"   # save a snapshot with a message
git pull --rebase          # get others' changes first (avoid conflicts)
git push                   # publish to GitHub
```
In Obsidian you can do all of this from the **Obsidian Git** plugin ("commit-and-sync" / gitpush) instead of the terminal.

> **Why two steps (`add` then `commit`)?** Git has a middle zone called the *staging area* — a loading dock where you assemble exactly what goes into the next snapshot. `add` puts changes on the dock; `commit` seals them into a photo. It feels like a chore when you just want "commit everything," but it's what lets you commit *some* changes and hold others back when you need to.

## My original notes (kept)
- I set up the repo **initially private**, then flipped it to **Public** so instructors can view my notes and progress.
- Public repo: **`Study-Prep`** under user **`grizzysammy-dev`** → https://github.com/grizzysammy-dev/Study-Prep

## Core concepts (fast)
| Term | Meaning |
|---|---|
| **repo** | a project folder tracked by git |
| **commit** | a saved snapshot + message |
| **branch** | a parallel line of work (`main` is default) |
| **remote** (`origin`) | the GitHub copy you push/pull |
| **clone** | download a repo | **fork** | your own copy of someone's repo |

## First-time setup
```bash
git config --global user.name  "Sam"
git config --global user.email "you@example.com"

# start a repo from an existing folder
cd Study-prep-repo
git init
git add -A && git commit -m "initial"
git branch -M main
git remote add origin https://github.com/grizzysammy-dev/Study-Prep.git
git push -u origin main
```

## Obsidian Git workflow (how you actually push this vault)
1. Edit notes in Obsidian.
2. Command palette → **Obsidian Git: Commit-and-sync** (or your hotkey / the sidebar button) — it stages, commits, pulls, and pushes in one step.
3. Set **auto-commit interval** in the plugin if you want hands-off backups.
→ If a push is rejected, someone/another device changed the remote — run **pull** first, then push. In the terminal that's `git pull --rebase` then `git push`.

## .gitignore (keep junk and secrets out of the repo)
```
# .gitignore
.obsidian/workspace.json
.trash/
*_loot/
*.key
*.ovpn
```
→ Anything matching `.gitignore` is never committed. Put scratch, VPN keys, and any credential files here so they can't be pushed to a **public** repo by accident.

> **Why `.gitignore` *before* you commit, not after:** git history is permanent. If a key gets committed even once, deleting the file later doesn't remove it — it's still sitting in an earlier snapshot for anyone to dig out. That's why leaked credentials in public repos are a top real-world breach source, and why the only real fix after a leak is to *rotate the secret*, not just delete the file. `.gitignore` keeps the secret out of the timeline in the first place.

> [!warning] Security heads-up — your push token
> Your `origin` URL currently has a **Personal Access Token embedded in it** (`https://<token>@github.com/...`). That's fine *functionally* and it lives only in `.git/config`, which git never pushes — so it is **not** exposed on the public repo. Two hardening tips anyway: (1) prefer a **Git credential helper** or a **fine-grained token scoped to just this one repo** instead of a broad classic token; (2) if that token ever lands in a file that *does* get committed, GitHub will auto-revoke it — rotate it in **GitHub → Settings → Developer settings → Tokens** and never paste it into a note. (I did not copy the token anywhere.)

## Exam tips & gotchas
- **Repo must be PUBLIC** for the JQR — check **Settings → Danger Zone → Change visibility**.
- On GitHub, `[[wikilinks]]` and Obsidian dataview **don't render** — navigate via the [README](../README.md) index links and the folder tree. That's why the index uses normal Markdown links.
- Commit small and often with real messages ("add iptables NAT section") — it's your visible progress trail.
- Never commit VPN keys, tokens, or `_loot/` — that's what `.gitignore` is for.

## References
- GitHub getting started (JQR-named) — https://docs.github.com/en/get-started/start-your-journey
- Git book (free) — https://git-scm.com/book/en/v2
- Obsidian Git plugin — https://github.com/Vinzent03/obsidian-git

## Related
- [VM Lab Setup](../VM%20Set%20Up/VM%20Lab%20Setup.md)
- [How This Vault Is Organized](../Study%20Aids/How%20This%20Vault%20Is%20Organized.md)
- [Bash - JQR Projects](../Bash%20Scripting/Bash%20-%20JQR%20Projects.md)
