---
title: Linux 101
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
  <h1 class="text-6xl font-bold text-white mb-3 leading-tight">Linux 101</h1>
  <div class="text-2xl text-slate-300 mb-8">SSH, core commands, pipes, text processing, CLI tools</div>
</div>

<div class="absolute bottom-8 right-12 text-xs text-slate-600 font-mono">2026</div>

---
layout: default
---

# Agenda

<div class="grid grid-cols-2 gap-x-12 gap-y-3 mt-6 text-sm">
<div>

**1. SSH & Keys**
How key auth works, setting up keys and config

**2. Navigating & Files**
Moving around, permissions, reading files

**3. Environment**
Variables, PATH, getting help

</div>
<div>

**4. Pipes & Redirection**
Connecting commands together

**5. Text Processing & Search**
grep, find, awk, sed

**6. CLI Tools**
jq, csvlens, fzf, rg, bat, and more

</div>
</div>

<div class="mt-8 text-xs text-slate-500">

Demo files: `~/tmp/demo/` — logs, CSV, JSON, source code

</div>

---
layout: section
---

# 1. SSH & Keys

---
layout: default
---

# SSH — Public & Private Keys

<div class="mt-6 text-sm">

You generate a **key pair**: two files that are mathematically linked.

```
~/.ssh/id_ed25519       ← private key (stays on your machine, never share)
~/.ssh/id_ed25519.pub   ← public key  (you give this to servers)
```

</div>

<v-click>

<div class="mt-4 text-sm">

Think of it like a padlock:
- The **public key** is an open padlock you hand out — anyone can lock something with it
- The **private key** is the only key that can open it

When you connect, the server locks a challenge with your public key.
Only your private key can unlock it — that proves you are who you say you are.
No password ever crosses the network.

</div>

</v-click>

---
layout: default
---

# Generating a key

```bash
ssh-keygen -t ed25519
```

<div class="mt-4 text-sm">

Accept the default path, optionally set a passphrase.

Then copy the public key to the server:

```bash
ssh-copy-id user@host
```

This appends your public key to `~/.ssh/authorized_keys` on the server. From now on, `ssh user@host` authenticates with your key automatically.

</div>

---
layout: default
---

# SSH config

<div class="mt-4 text-sm">

`~/.ssh/config` lets you define host aliases:

```
Host devbox
    HostName 192.168.1.50
    User cagdas
    Port 2222
    IdentityFile ~/.ssh/work_key

Host prod
    HostName prod.example.com
    User deploy
```

Then just:
```bash
ssh devbox
ssh prod
```

This also works with `scp`, `rsync`, `git` — anything that uses SSH.

</div>

---
layout: section
---

# 2. Navigating & Files

---
layout: default
---

# Moving around

```bash
pwd                   # where am I?
ls                    # what's here?
ls -la                # show hidden files, details, permissions
cd /var/log           # go to absolute path
cd ..                 # go up one level
cd ~                  # go home
cd -                  # go to previous directory
```

<v-click>

# Creating, copying, moving, deleting

```bash
mkdir -p app/src/lib  # create nested dirs
touch app/readme.md   # create empty file

cp file.txt backup/   # copy
cp -r src/ src_bak/   # copy directory

mv old.txt new.txt    # rename / move
rm file.txt           # delete (no trash, gone forever)
rm -r directory/      # delete directory
```

</v-click>

---
layout: default
---

# Permissions

```bash
$ ls -l
-rw-r--r-- 1 cagdas devs 4096 Apr  1 10:00 config.yaml
drwxr-xr-x 3 cagdas devs 4096 Apr  1 10:00 src/
```

<div class="mt-2 text-sm">

```
 type   owner  group  others
  d     rwx    r-x    r-x        ← directory, owner can write, others can read+enter
  -     rw-    r--    r--        ← file, owner can write, others can only read
```

</div>

<v-click>

```bash
chmod +x script.sh          # make executable
chmod 755 script.sh         # rwx r-x r-x (common for scripts)
chmod 600 ~/.ssh/id_ed25519 # rw- --- --- (required for SSH keys)
chown user:group file       # change owner
```

</v-click>

<v-click>

<div class="mt-4 text-xs text-slate-400">

`r=4  w=2  x=1` — add them up per group: `755 = rwx r-x r-x`

</div>

</v-click>

---
layout: default
---

# Reading files

```bash
cat file.txt              # dump entire file
less file.txt             # scroll through (q to quit, / to search)
head -20 file.txt         # first 20 lines
tail -20 file.txt         # last 20 lines
tail -f logs/app.log      # follow live output — see new lines as they come
wc -l file.txt            # count lines
```

<v-click>

# Useful extras

```bash
file mystery.bin        # what type of file is this?
du -sh *                # disk usage per item
df -h                   # disk space on system
which python            # where is this binary?
```

</v-click>

---
layout: section
---

# 3. Environment

---
layout: default
---

# Variables & PATH

```bash
echo $HOME                    # /home/cagdas
echo $USER                    # cagdas
echo $PATH                    # where the shell looks for commands
env                           # list all environment variables
```

<v-click>

<div class="mt-4 text-sm">

`$PATH` is a colon-separated list of directories. When you type a command, the shell searches these directories in order.

```bash
which python                  # shows which python it found in PATH
export MY_VAR="hello"         # set a variable for this session + child processes
echo $MY_VAR                  # hello
```

</div>

</v-click>

<v-click>

# Getting help

```bash
man ls                        # full manual page (q to quit, / to search)
ls --help                     # shorter usage info
```

`man` pages can be dense — we'll see a friendlier alternative later (`tldr`).

</v-click>

---
layout: section
---

# 4. Pipes & Redirection

---
layout: default
---

# A simple example first

<div class="mt-4 text-sm">

The pipe `|` sends the output of one command as input to the next.

</div>

```bash
# list all processes, find the ones matching "python"
ps aux | grep python

# list files, sort by size
ls -la | sort -k5 -rn
```

<v-click>

<div class="mt-4 text-sm">

You can chain as many as you want:

</div>

```bash
# "who logged in the most?" from our app log
cat logs/app.log | grep "login successful" | awk '{print $5}' | sort | uniq -c | sort -rn
```

</v-click>

<v-click>

<div class="mt-4 text-sm">

Each command does one thing. The pipe connects them.

</div>

</v-click>

---
layout: default
---

# Why this works — stdout, stdin, stderr

<div class="text-sm mt-4">

Every process has three streams:

```
              ┌─────────┐
  stdin  ──→  │ process │  ──→  stdout  (normal output)
              └─────────┘  ──→  stderr  (errors)
```

The pipe connects **stdout** of the left command to **stdin** of the right.

</div>

<v-click>

# Redirection

```bash
ls > files.txt                # stdout to file (overwrites)
echo "more" >> files.txt      # stdout to file (appends)
make 2> errors.txt            # stderr to file
make > output.txt 2>&1        # both to same file
make > /dev/null 2>&1         # discard everything
```

</v-click>

---
layout: default
---

# Demo — build a pipeline step by step

<div class="text-sm mt-2">

Using `~/tmp/demo/logs/app.log`:

</div>

```bash
# 1. look at the file
cat logs/app.log

# 2. filter to errors only
cat logs/app.log | grep ERROR

# 3. extract the component in brackets
cat logs/app.log | grep ERROR | awk -F'[][]' '{print $2}'

# 4. count occurrences of each component
cat logs/app.log | grep ERROR | awk -F'[][]' '{print $2}' | sort | uniq -c | sort -rn
```

<v-click>

<div class="mt-4 text-sm">

Result: which parts of the system have the most errors.

</div>

```bash
# same idea with the access log — most active IPs
awk '{print $1}' logs/access.log | sort | uniq -c | sort -rn
```

</v-click>

---
layout: section
---

# 5. Text Processing & Search

---
layout: default
---

# grep — search for patterns

```bash
grep "ERROR" logs/app.log             # lines containing "ERROR"
grep -i "error" logs/app.log          # case insensitive
grep -v "DEBUG" logs/app.log          # lines NOT matching
grep -c "ERROR" logs/app.log          # count matches
grep -E "ERROR|WARN" logs/app.log     # multiple patterns
```

<v-click>

```bash
# search recursively in a directory
grep -rn "TODO" src/

# list only filenames that match
grep -rl "import" src/
```

</v-click>

---
layout: default
---

# find — locate files

```bash
find . -name "*.py"                      # by name pattern
find . -name "*.log" -mtime -1           # modified in last 24h
find . -type f -size +100M               # files over 100MB
find . -name "*.sh" -exec chmod +x {} \; # find and execute on each
```

<v-click>

# awk & sed — the essentials

```bash
# awk: extract columns (space-separated by default)
ps aux | awk '{print $1, $11}'
cat /etc/passwd | cut -d':' -f1          # cut: simpler column extraction

# sed: search and replace
sed 's/localhost/prod-db/' src/config.yaml       # replace first per line
sed 's/localhost/prod-db/g' src/config.yaml      # replace all
sed -i 's/localhost/prod-db/g' src/config.yaml   # in-place edit
```

</v-click>

---
layout: default
---

# xargs — pipe output as arguments

<div class="text-sm mt-2">

Some commands don't read from stdin — they need arguments. `xargs` bridges that gap.

</div>

```bash
# find all Python files and search for "TODO" in them
find . -name "*.py" | xargs grep "TODO"

# delete all .pyc files
find . -name "*.pyc" | xargs rm

# safer with spaces in filenames
find . -name "*.pyc" -print0 | xargs -0 rm
```

---
layout: section
---

# 6. CLI Tools

---
layout: default
---

# jq — JSON processing

```bash
# pretty-print a JSON file
cat data/todos.json | jq .

# extract a field from each item
cat data/todos.json | jq '.[].title'

# filter: only incomplete, high priority
cat data/todos.json | jq '.[] | select(.completed == false and .priority == "high")'

# reshape into a new structure
cat data/todos.json | jq '.[] | {task: .title, who: .assignee}'
```

<v-click>

```bash
# works great with APIs
curl -s https://api.github.com/repos/jqlang/jq | jq '{stars: .stargazers_count, language: .language}'
```

</v-click>

---
layout: default
---

# csvlens — interactive CSV viewer

```bash
csvlens data/users.csv
```

<div class="mt-4 text-sm">

- Scroll horizontally and vertically through large CSVs
- Search and filter within columns
- Sort by column
- Tab-delimited: `csvlens -d '\t' data.tsv`

</div>

<v-click>

# bat — cat with syntax highlighting

```bash
bat src/config.yaml
bat src/app.py
bat --diff src/app.py         # show git changes inline
```

</v-click>

---
layout: default
---

# ripgrep (rg) — fast recursive search

```bash
rg "TODO" src/                 # search recursively
rg -i "error" logs/            # case-insensitive
rg "TODO" --type py            # only Python files
```

<div class="text-sm mt-2 text-slate-400">

Respects `.gitignore` by default, skips binary files.

</div>

<v-click>

# fd — simpler find

```bash
fd "\.py$"                     # find files matching regex
fd -e yaml                     # find by extension
fd --changed-within 1h         # recently modified
```

</v-click>

<v-click>

# man and tldr

```bash
man grep                       # full manual (dense)
tldr grep                      # community cheat sheet (practical examples)
tldr tar                       # never memorize tar flags again
```

</v-click>

---
layout: default
---

# fzf — fuzzy finder

```bash
# pick a file interactively
vim $(fzf)

# search command history
history | fzf

# pick a process to kill
ps aux | fzf | awk '{print $2}' | xargs kill

# git branch checkout
git branch | fzf | xargs git checkout
```

<v-click>

```bash
# combine with other tools — file picker with preview
fzf --preview 'bat --color=always {}'
```

</v-click>

<v-click>

<div class="mt-4 p-3 bg-slate-800 rounded text-sm">

fzf keybindings: `Ctrl+R` for history search, `Ctrl+T` for file picker, `Alt+C` for cd into directory

</div>

</v-click>

---
layout: default
---

# htop / btop — process monitoring

```bash
htop                           # interactive process viewer
btop                           # with CPU/memory/disk/network graphs
```

<div class="text-sm mt-2">

- Sort by CPU, memory, I/O
- Filter processes by name
- Kill processes with `k`
- Tree view with `t`

</div>

---
layout: default
---

# Other tools

| Tool | What it does |
|------|-------------|
| `delta` | Git diff with syntax highlighting |
| `duf` | Disk usage overview |
| `ncdu` | Interactive disk usage explorer |
| `httpie` | HTTP client — `http GET api.com/users` |
| `lazydocker` | TUI for Docker containers and logs |
| `lazygit` | TUI for git (staging, commits, branches) |
| `watch` | Re-run a command every N seconds |

---
layout: default
---

# Useful combos — putting it all together

```bash
# most common errors in the app log
grep ERROR logs/app.log | awk -F'[][]' '{print $2}' | sort | uniq -c | sort -rn

# most active IPs and their status codes
awk '{print $1, $9}' logs/access.log | sort | uniq -c | sort -rn

# who earns the most per department?
cat data/users.csv | awk -F',' 'NR>1 {print $4, $5, $2}' | sort -k1,1 -k2 -rn

# incomplete high-priority tasks
cat data/todos.json | jq -r '.[] | select(.completed==false) | "\(.priority)\t\(.assignee)\t\(.title)"'

# find all TODOs across the codebase
rg "TODO" src/
```

<div class="mt-4 text-center text-slate-400 text-xs">

Install: `bat fd-find ripgrep fzf jq csvlens htop tldr`

</div>

---
layout: center
---

<div class="text-center">
  <h1 class="text-4xl font-bold mb-4">End</h1>
  <div class="text-sm text-slate-400">Slides available as reference</div>
  <div class="text-xs text-slate-600 mt-2">Demo files: ~/tmp/demo/</div>
</div>
