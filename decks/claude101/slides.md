---
title: Claude Code 101
description: Agentic coding from your terminal — install, configure, extend, ship
theme: default
colorSchema: dark
highlighter: shiki
lineNumbers: false
fonts:
  sans: Inter
  mono: JetBrains Mono
transition: fade
mdc: true
---

<div class="flex flex-col justify-center items-start h-full pl-2">
  <div class="text-xs font-mono text-indigo-400 uppercase tracking-widest mb-4">Developer Onboarding</div>
  <h1 class="text-6xl font-bold text-white mb-3 leading-tight">Claude Code 101</h1>
  <div class="text-2xl text-slate-300 mb-8">Agentic coding from your terminal</div>
  <div class="flex gap-6 text-sm text-slate-400">
    <span>Install</span>
    <span>&middot;</span>
    <span>Configure</span>
    <span>&middot;</span>
    <span>Extend</span>
    <span>&middot;</span>
    <span>Ship</span>
  </div>
</div>

<div class="absolute bottom-8 right-12 text-xs text-slate-600 font-mono">2026</div>

---
layout: default
---

# Agenda

<div class="grid grid-cols-2 gap-x-12 gap-y-3 mt-6 text-sm">
<div>

**Getting Started**
Install, first run, the agentic loop

**Core Tools**
Files, search, bash, web

**Permissions**
Modes, allowlists, auto mode

**CLAUDE.md**
Persistent instructions, hierarchy

</div>
<div>

**Context & Memory**
Context window, compaction, auto memory

**Git Integration**
Commits, PRs, code review

**Extending Claude**
MCP, hooks, skills, subagents

**Tips & Tricks**
Shortcuts, best practices, gotchas

</div>
</div>

---
layout: default
---

# What is Claude Code?

An **agentic coding assistant** that lives in your terminal.

<div class="grid grid-cols-2 gap-8 mt-6">
<div>

### It can...

- Read & edit files across your codebase
- Run shell commands, tests, builds
- Search code with regex / glob
- Search the web & fetch docs
- Create commits & pull requests
- Connect to external tools (MCP)

</div>
<div>

### Available on...

- **Terminal** &mdash; `claude` CLI
- **VS Code** &mdash; extension
- **JetBrains** &mdash; plugin
- **Desktop app** &mdash; macOS / Windows
- **Web** &mdash; claude.ai/code

</div>
</div>

---
layout: default
---

# Installation

<div class="mt-4">

### Native install (recommended, auto-updates)

```bash
# macOS / Linux / WSL
curl -fsSL https://claude.ai/install.sh | bash

# Windows PowerShell
irm https://claude.ai/install.ps1 | iex
```

### Alternatives

```bash
brew install --cask claude-code        # Homebrew
winget install Anthropic.ClaudeCode    # Windows
npm install -g @anthropic-ai/claude-code  # npm (deprecated)
```

### First run

```bash
cd your-project
claude          # logs in on first use, then you're ready
```

</div>

---
layout: default
---

# The Agentic Loop

Claude works in a **continuous cycle** you can interrupt at any time.

<div class="flex justify-center mt-8">
<div class="grid grid-cols-4 gap-4 text-center text-sm">

<div class="bg-blue-900/40 rounded-xl p-4">
<div class="text-2xl mb-2">1</div>
<div class="font-bold mb-1">Gather</div>
Read files, search code, ask clarifying questions
</div>

<div class="bg-indigo-900/40 rounded-xl p-4">
<div class="text-2xl mb-2">2</div>
<div class="font-bold mb-1">Act</div>
Edit files, run commands, make changes
</div>

<div class="bg-violet-900/40 rounded-xl p-4">
<div class="text-2xl mb-2">3</div>
<div class="font-bold mb-1">Verify</div>
Run tests, check output, compare results
</div>

<div class="bg-purple-900/40 rounded-xl p-4">
<div class="text-2xl mb-2">4</div>
<div class="font-bold mb-1">Iterate</div>
Adjust approach based on feedback
</div>

</div>
</div>

<div class="text-center text-sm text-slate-400 mt-6">
You're always in the loop &mdash; press <kbd>Esc</kbd> to stop, type to redirect.
</div>

---
layout: default
---

# Core Tools

<div class="grid grid-cols-2 gap-6 mt-4 text-sm">

<div>

### File Operations
| Tool | Purpose |
|------|---------|
| **Read** | View file contents |
| **Edit** | Modify existing files |
| **Write** | Create new files |
| **Glob** | Find files by pattern |
| **Grep** | Search content with regex |

</div>
<div>

### Execution & Web
| Tool | Purpose |
|------|---------|
| **Bash** | Run any shell command |
| **WebSearch** | Search the internet |
| **WebFetch** | Fetch & parse URLs |
| **Agent** | Spawn subagents |
| **TaskCreate** | Track multi-step work |

</div>
</div>

<div class="mt-6 text-sm">

### Quick bash from the prompt
```
! npm test              # prefix with ! to run a command inline
```

</div>

---
layout: default
---

# Permission System

Control how much Claude can do without asking.

<div class="mt-4 text-sm">

| Mode | Reads | Edits | Commands | Best For |
|------|-------|-------|----------|----------|
| **default** | Free | Ask | Ask | Getting started |
| **acceptEdits** | Free | Free | Ask | Trust edits, review commands |
| **plan** | Free | No | Ask | Explore before implementing |
| **auto** | Free | Free | Free* | Long tasks, less interruption |
| **bypassPermissions** | Free | Free | Free | Isolated containers only |

</div>

<div class="mt-4 text-sm">

**Cycle modes:** <kbd>Shift+Tab</kbd> during a session

**Allowlist trusted commands** in `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["Bash(npm test)", "Bash(git commit *)", "Read", "Edit"]
  }
}
```

</div>

---
layout: default
---

# CLAUDE.md &mdash; Persistent Instructions

A markdown file Claude reads **at the start of every session**.

<div class="grid grid-cols-2 gap-8 mt-4 text-sm">
<div>

### What to put in it
- Build & test commands
- Code style rules
- Architectural patterns
- Branch / PR conventions
- Environment setup
- Non-obvious gotchas

### Generate one automatically
```
/init
```

</div>
<div>

### File hierarchy

| Level | Path | Shared? |
|-------|------|---------|
| Project | `./CLAUDE.md` | Yes (git) |
| User | `~/.claude/CLAUDE.md` | No |
| Local | `./CLAUDE.local.md` | No |
| Rules | `.claude/rules/*.md` | Yes |

Rules support **path globs** for scoped instructions:

```yaml
---
paths: ["src/api/**/*.ts"]
---
Always use standard error format.
```

</div>
</div>

<div class="text-sm text-slate-400 mt-4">

Tip: keep it under **200 lines**. Longer files reduce adherence.

</div>

---
layout: default
---

# Slash Commands

<div class="grid grid-cols-2 gap-6 mt-2 text-sm">
<div>

### Essentials
| Command | Purpose |
|---------|---------|
| `/help` | Show all commands |
| `/clear` | Reset conversation |
| `/compact` | Compress context |
| `/context` | Visualize context usage |
| `/init` | Generate CLAUDE.md |
| `/commit` | Stage & commit changes |
| `/diff` | Interactive diff viewer |

### Session
| Command | Purpose |
|---------|---------|
| `/resume` | Resume previous session |
| `/rename` | Name current session |
| `/fork` | Branch conversation |

</div>
<div>

### Mode & Model
| Command | Purpose |
|---------|---------|
| `/fast` | Toggle fast output mode |
| `/effort` | Set reasoning level |
| `/model` | Switch models |
| `/plan` | Enter plan mode |

### Management
| Command | Purpose |
|---------|---------|
| `/memory` | Browse auto memory |
| `/permissions` | Manage allow/deny |
| `/mcp` | Configure MCP servers |
| `/hooks` | View hook events |
| `/cost` | Token usage stats |
| `/status` | Version & account info |

</div>
</div>

---
layout: default
---

# Context Management

Claude's context holds your conversation, file reads, command outputs, and config.

<div class="grid grid-cols-2 gap-8 mt-4 text-sm">
<div>

### Watching context usage

```
/context          # colored grid visualization
```

Status line shows real-time percentage.

### When context fills up

- **Auto-compaction** kicks in
- Or run `/compact` manually
- CLAUDE.md is **re-read fresh** after compaction

</div>
<div>

### Staying lean

- `/clear` between unrelated tasks
- Use **subagents** for large investigations
- Scope searches narrowly
- <kbd>Ctrl+O</kbd> &mdash; toggle verbose output
- Keep CLAUDE.md under 200 lines
- Use `.claude/rules/` for path-specific rules

### Signs of overload

- Claude forgets instructions
- Repeats the same mistake
- Slower or lower-quality responses

Fix: `/clear` and start fresh with a better prompt.

</div>
</div>

---
layout: default
---

# Auto Memory

Claude **automatically saves learnings** about your project across sessions.

<div class="grid grid-cols-2 gap-8 mt-4 text-sm">
<div>

### What gets saved
- Build commands discovered
- Debugging insights
- Architecture patterns
- Code style preferences
- Project-specific knowledge

### Where it lives

```
~/.claude/projects/<project>/memory/
  MEMORY.md           # index (loaded every session)
  build-commands.md   # topic files
  api-conventions.md
  ...
```

</div>
<div>

### CLAUDE.md vs Auto Memory

| | CLAUDE.md | Auto Memory |
|-|-----------|-------------|
| **Author** | You | Claude |
| **Content** | Rules & instructions | Learnings |
| **Scope** | Project / user | Per directory |

### Managing

```
/memory             # browse, toggle, edit
```

Or edit the files directly &mdash; they're plain markdown.

</div>
</div>

---
layout: default
---

# Git Integration

<div class="grid grid-cols-2 gap-8 mt-4 text-sm">
<div>

### Commits

```
/commit
# or just ask:
"commit my changes with a descriptive message"
```

Claude reviews changes, writes message, stages & commits.

### Pull Requests

```
"create a PR for this feature"
```

Creates branch, pushes, opens PR with description.

### Code Review

```
/review               # interactive diff viewer
/security-review       # vulnerability analysis
```

</div>
<div>

### Worktrees &mdash; parallel sessions

```bash
claude -w feature-auth         # isolated worktree
claude -w feature-auth --tmux  # with visible pane
```

Each worktree gets its own files, branch, and session.

### Resume & continue

```bash
claude -c                  # resume last session
claude -r "auth-refactor"  # resume by name
claude -n "my-task"        # name current session
```

</div>
</div>

---
layout: default
---

# CLI Flags

<div class="text-sm mt-2">

### Most useful flags

| Flag | Purpose | Example |
|------|---------|---------|
| `-p` | Non-interactive (print mode) | `claude -p "fix typos"` |
| `-c` | Continue last session | `claude -c` |
| `-r` | Resume by name | `claude -r "auth"` |
| `-n` | Name session | `claude -n "my-task"` |
| `-w` | Git worktree isolation | `claude -w feature` |
| `--model` | Select model | `--model claude-sonnet-4-6` |
| `--effort` | Reasoning effort | `--effort high` |
| `--max-turns` | Limit agentic turns | `--max-turns 3` |
| `--permission-mode` | Start in mode | `--permission-mode plan` |
| `--add-dir` | Add working dirs | `--add-dir ../lib` |
| `--output-format` | Output as JSON | `--output-format json` |

### Piping

```bash
cat error.log | claude -p "what went wrong?"
git diff | claude -p "review this diff"
```

</div>

---
layout: default
---

# MCP &mdash; Model Context Protocol

Connect Claude to **external data sources and tools**.

<div class="grid grid-cols-2 gap-8 mt-4 text-sm">
<div>

### Adding servers

```bash
# Remote HTTP
claude mcp add --transport http \
  github https://api.anthropic.com/mcp/

# Local stdio
claude mcp add --transport stdio \
  postgres /usr/local/bin/mcp-postgres

# Manage
claude mcp list
claude mcp remove name
/mcp                  # in-session
```

### Popular servers

GitHub, Slack, Jira, Google Drive,
PostgreSQL, MySQL, Stripe, Sentry, ...

</div>
<div>

### Configuration

In `~/.claude/settings.json`:

```json
{
  "mcp": [
    {
      "name": "github",
      "transport": "http",
      "url": "https://api.anthropic.com/mcp/"
    },
    {
      "name": "postgres",
      "transport": "stdio",
      "command": "mcp-postgres",
      "args": ["--host", "localhost"]
    }
  ]
}
```

Tools load **on-demand** to save context.

</div>
</div>

---
layout: default
---

# Hooks

**Deterministic shell scripts** that fire at lifecycle points.

Unlike CLAUDE.md (advisory), hooks **guarantee execution**.

<div class="grid grid-cols-2 gap-8 mt-4 text-sm">
<div>

### Key events

| Event | Fires |
|-------|-------|
| `PreToolUse` | Before a tool runs |
| `PostToolUse` | After tool succeeds |
| `Stop` | Claude finishes response |
| `Notification` | Claude needs input |

### Example: auto-format on edit

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "prettier --write $FILE"
      }]
    }]
  }
}
```

</div>
<div>

### Example: block protected files

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "echo $FILE | grep -q '.env' && exit 2"
      }]
    }]
  }
}
```

### Where to configure

- `~/.claude/settings.json` &mdash; global
- `.claude/settings.json` &mdash; project
- `.claude/settings.local.json` &mdash; local only

View with `/hooks`

</div>
</div>

---
layout: default
---

# Custom Skills & Slash Commands

Create reusable workflows as markdown files.

<div class="grid grid-cols-2 gap-8 mt-4 text-sm">
<div>

### Create a custom command

```
.claude/commands/fix-lint.md
```

```markdown
---
name: fix-lint
description: Fix all linting errors
---

1. Run `npm run lint --fix`
2. Verify all files pass
3. Commit with "chore: fix lint"
```

**Invoke:** `/fix-lint`

### With arguments

```markdown
---
name: migrate
argument-hint: [component] [from] [to]
---
Migrate $0 from $1 to $2.
```

**Invoke:** `/migrate SearchBar React Vue`

</div>
<div>

### Dynamic context injection

```markdown
---
name: pr-summary
---
Diff: !`gh pr diff`
Files: !`gh pr diff --name-only`

Summarize these PR changes.
```

Shell commands run first, output injected.

### Locations

| Path | Scope |
|------|-------|
| `.claude/commands/` | Project (shared) |
| `.claude/skills/` | Project (shared) |
| `~/.claude/commands/` | Personal (all projects) |
| `~/.claude/skills/` | Personal (all projects) |

</div>
</div>

---
layout: default
---

# Subagents

**Specialized AI assistants** running in isolated contexts.

<div class="grid grid-cols-2 gap-8 mt-4 text-sm">
<div>

### Why use them?

- Keep main context clean
- Focused, specialized behavior
- Parallel investigations
- Separate tool restrictions

### Built-in agents

| Agent | Purpose |
|-------|---------|
| **Explore** | Read-only codebase research |
| **Plan** | Analysis without implementation |
| **general-purpose** | Unrestricted complex tasks |

</div>
<div>

### Create your own

`.claude/agents/security-reviewer.md`:

```markdown
---
name: security-reviewer
description: Reviews code for vulnerabilities
tools: Read, Grep, Glob
model: opus
---

You are a security engineer. Review for:
- Injection vulnerabilities
- Auth flaws
- Secrets in code
Provide line references and fixes.
```

### Invoke

```
Use a subagent to review this for security
```

Or Claude auto-delegates based on description.

</div>
</div>

---
layout: default
---

# IDE Integration

<div class="grid grid-cols-2 gap-8 mt-4 text-sm">
<div>

### VS Code

Install: search **Claude Code** in Extensions

| Shortcut | Action |
|----------|--------|
| <kbd>Cmd+Esc</kbd> | Focus Claude input |
| <kbd>Cmd+Shift+Esc</kbd> | Open in new tab |
| <kbd>Cmd+N</kbd> | New conversation |
| <kbd>Alt+K</kbd> | Insert @-mention |

Features:
- Inline diff viewer
- @-mentions with line ranges
- Plan review before execution
- Multi-tab parallel conversations
- Permission mode selector

</div>
<div>

### JetBrains

Install: Settings &rarr; Plugins &rarr; search **Claude Code**

| Shortcut | Action |
|----------|--------|
| <kbd>Ctrl+Esc</kbd> | Open Claude |
| <kbd>Alt+Ctrl+K</kbd> | Insert file reference |

Features:
- Diff viewer integration
- Selection context sharing
- Diagnostic sharing (errors/warnings)
- Remote development support

### Both IDEs

- Share `~/.claude/settings.json` with CLI
- Same CLAUDE.md files apply
- Same permission system

</div>
</div>

---
layout: default
---

# Keyboard Shortcuts

<div class="grid grid-cols-2 gap-6 mt-2 text-sm">
<div>

### Navigation & Control
| Shortcut | Action |
|----------|--------|
| <kbd>Ctrl+C</kbd> | Cancel current action |
| <kbd>Ctrl+D</kbd> | Exit Claude |
| <kbd>Esc</kbd> | Stop mid-action |
| <kbd>Esc Esc</kbd> | Open rewind menu |
| <kbd>Shift+Tab</kbd> | Cycle permission modes |
| <kbd>Ctrl+R</kbd> | Reverse search history |

### Mode Switching
| Shortcut | Action |
|----------|--------|
| <kbd>Alt+P</kbd> | Switch model |
| <kbd>Alt+T</kbd> | Toggle extended thinking |
| <kbd>Alt+O</kbd> | Toggle fast mode |

</div>
<div>

### Session & Tasks
| Shortcut | Action |
|----------|--------|
| <kbd>Ctrl+B</kbd> | Background running task |
| <kbd>Ctrl+T</kbd> | Toggle task list |
| <kbd>Ctrl+O</kbd> | Toggle verbose output |
| <kbd>Ctrl+V</kbd> | Paste image |

### Editing
| Shortcut | Action |
|----------|--------|
| <kbd>Shift+Enter</kbd> | New line in input |
| <kbd>Ctrl+K</kbd> | Delete to end of line |
| <kbd>Ctrl+U</kbd> | Delete to start of line |
| <kbd>Alt+B / Alt+F</kbd> | Move word back / forward |

</div>
</div>

---
layout: default
---

# Tips & Best Practices

<div class="grid grid-cols-2 gap-8 mt-2 text-sm">
<div>

### Write better prompts

```
Bad:  "add tests for foo.py"

Good: "Write pytest tests for foo.py covering
       the logged-out edge case. No mocks.
       Run them after."
```

- Be specific: which file, what scenario
- Include verification: "run tests after"
- Set constraints: libraries, patterns

### Explore before implementing

1. Start in **plan mode** &mdash; `/plan`
2. Read relevant files
3. Review the plan
4. Switch to normal mode
5. Implement & verify

</div>
<div>

### Manage context proactively

- `/clear` between unrelated tasks
- Use **subagents** for big investigations
- Scope searches: `"Read src/auth/"` not `"investigate backend"`
- `/compact` when things get slow

### When Claude makes mistakes

1. **First time:** simple redirect
2. **Second time:** something's wrong with context
3. **Third time:** `/clear`, restart with better prompt

### Onboarding a new project

```bash
cd my-project
claude
/init              # generates CLAUDE.md
```

Then ask: *"How does auth work in this project?"*

</div>
</div>

---
layout: default
---

# Quick Reference Card

<div class="grid grid-cols-3 gap-4 mt-2 text-xs">
<div>

### Install & Run
```bash
curl -fsSL https://claude.ai/install.sh | bash
cd project && claude
claude -p "query"    # non-interactive
claude -c            # continue last
claude -w feature    # worktree
```

### Config Files
```
./CLAUDE.md           # project
~/.claude/CLAUDE.md   # user
.claude/settings.json # permissions
.claude/rules/*.md    # scoped rules
.claude/commands/*.md # custom commands
.claude/agents/*.md   # subagents
```

</div>
<div>

### Essential Commands
```
/init       # generate CLAUDE.md
/clear      # reset conversation
/compact    # compress context
/commit     # stage & commit
/plan       # enter plan mode
/fast       # toggle fast mode
/context    # view context usage
/memory     # browse auto memory
/permissions# manage rules
/mcp        # manage MCP servers
```

</div>
<div>

### Key Shortcuts
```
Esc         stop mid-action
Esc Esc     rewind menu
Shift+Tab   cycle perm modes
Ctrl+B      background task
Ctrl+T      toggle task list
Ctrl+O      toggle verbose
Alt+P       switch model
Alt+O       toggle fast mode
! cmd       run shell inline
```

### Useful Flags
```
-p          print mode
-c          continue
-r          resume
-n          name session
-w          worktree
--model     select model
--effort    reasoning level
--add-dir   extra directories
```

</div>
</div>

---

<div class="flex flex-col justify-center items-center h-full">
  <h1 class="text-5xl font-bold text-white mb-6">Start Building</h1>
  <div class="text-xl text-slate-300 mb-8">

```bash
cd your-project && claude
```

  </div>
  <div class="text-sm text-slate-400 mt-4">
    Docs: docs.anthropic.com/claude-code
  </div>
</div>
