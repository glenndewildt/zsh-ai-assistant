# 🤖 zsh-ai-assistant

> An AI-powered Zsh plugin that turns your terminal into an intelligent assistant — generate commands from plain English, smart autocomplete, explain and fix commands, all powered by a local LLM via [Ollama](https://ollama.ai). **No API keys. No cloud. Runs entirely on your machine.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Zsh](https://img.shields.io/badge/shell-zsh-blue.svg)](https://www.zsh.org/)
[![Ollama](https://img.shields.io/badge/powered%20by-Ollama-green.svg)](https://ollama.ai)

---

## ✨ Features

| Shortcut | What it does |
|---|---|
| `Ctrl-G` | Describe a task in plain English → get the exact command |
| `Ctrl-S` | Smart autocomplete at your cursor — no double words, instant static lookup + AI fallback |
| `Ctrl-L` | Explain your last command in plain English |
| `Ctrl-K` | Auto-fix your last failed command |
| `Ctrl-J` | Explain whatever is currently typed in the prompt |
| `ai_model` | Switch the AI model on the fly |

All shortcuts are **fully configurable**. See [Configuration](#configuration).

---

## 📦 Requirements

| Requirement | Notes |
|---|---|
| `zsh` | Any recent version |
| [`Ollama`](https://ollama.ai) | Local LLM runtime |
| `curl` | For API calls |
| `git` | For installation |
| [`fzf`](https://github.com/junegunn/fzf) | Optional — enables interactive fuzzy picker for completions |

---

## 🚀 Installation

### One-liner (recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/glenndewildt/zsh-ai-assistant/refs/heads/master/install.sh)
```

The installer will:
1. Clone the plugin into `$ZSH_CUSTOM/plugins/`
2. Pull your chosen Ollama model
3. Write a config file to `~/.config/zsh-ai-assistant/config.zsh`
4. Add the plugin to your `.zshrc`

### Options

```bash
# Use a specific model
bash install.sh --model qwen2.5:0.5b

# Install to a custom directory
bash install.sh --dir ~/.zsh/plugins/zsh-ai-assistant

# No welcome banner
bash install.sh --no-banner
```

---

### Manual installation

**oh-my-zsh:**
```bash
git clone https://github.com/glenndewildt/zsh-ai-assistant \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-assistant

# Add to your .zshrc plugins array:
plugins=(... zsh-ai-assistant)
```

**zinit:**
```zsh
zinit light glenndewildt/zsh-ai-assistant
```

**zplug:**
```zsh
zplug "glenndewildt/zsh-ai-assistant"
```

**antigen:**
```zsh
antigen bundle glenndewildt/zsh-ai-assistant
```

**Manual source:**
```bash
git clone https://github.com/glenndewildt/zsh-ai-assistant ~/.zsh/zsh-ai-assistant
echo 'source ~/.zsh/zsh-ai-assistant/zsh-ai-assistant.plugin.zsh' >> ~/.zshrc
```

---

## ⚡ Model Selection

The default model is `phi4-mini:latest`. Pull it with:

```bash
ollama pull phi4-mini
```

| Model | Speed | Quality | Best for |
|---|---|---|---|
| `qwen2.5:0.5b` | ~150ms ⚡ | Good | Fastest completions |
| `qwen2.5:1.5b` | ~350ms | Better | Daily use |
| `llama3.2:1b` | ~500ms | Good | Balanced |
| `phi4-mini` | ~600ms | Great | Default — smart & fast |
| `phi3:mini` | ~800ms | Good | Reliable alternative |
| `mistral:7b` | ~2s | Best | Complex tasks |

Switch models at any time — no restart needed:
```bash
ai_model               # list installed models
ai_model qwen2.5:0.5b  # switch to a faster model
```

---

## ⚙️ Configuration

All settings live in `~/.config/zsh-ai-assistant/config.zsh`. This file is auto-created by the installer, or you can create it manually.

You can also set any variable in your `.zshrc` **before** the plugin loads.

```zsh
# ~/.config/zsh-ai-assistant/config.zsh

# ── Model & endpoint ──────────────────────────────────────────────
ZSH_AI_MODEL="phi4-mini:latest"
ZSH_AI_OLLAMA_URL="http://localhost:11434"       # Change for remote Ollama

# ── Features ─────────────────────────────────────────────────────
ZSH_AI_BANNER=1        # Show welcome banner on shell start (0 to hide)
ZSH_AI_RPROMPT=1       # Show model status in right-side prompt (0 to disable)
ZSH_AI_SAFE_RUN=1      # Require 'yes' before running AI-generated commands

# ── Keybindings ──────────────────────────────────────────────────
# Use any valid zsh bindkey sequence, or "" to disable a shortcut.
ZSH_AI_KEY_ASSISTANT="^G"    # Ctrl-G
ZSH_AI_KEY_COMPLETE="^S"     # Ctrl-S
ZSH_AI_KEY_EXPLAIN="^L"      # Ctrl-L
ZSH_AI_KEY_FIX="^K"          # Ctrl-K
ZSH_AI_KEY_EXPLAIN_BUF="^J"  # Ctrl-J

# ── Timeouts (seconds) ───────────────────────────────────────────
ZSH_AI_TIMEOUT_COMPLETE=6
ZSH_AI_TIMEOUT_COMMAND=15
ZSH_AI_TIMEOUT_EXPLAIN=30
```

### Using a remote Ollama instance

```zsh
# In ~/.config/zsh-ai-assistant/config.zsh
ZSH_AI_OLLAMA_URL="http://192.168.1.100:11434"
```

---

## 🎮 Usage Examples

### Ask for a command (`Ctrl-G`)
```
❯ What do you need?
  ❯ find all files larger than 500MB modified in the last week

  Task    find all files larger than 500MB modified in the last week
  Result  find / -type f -size +500M -mtime -7 2>/dev/null

  [e] Edit   [r] Run   [c] Copy   [s] Save script   [x] Explain
  ❯ e
```

### Smart autocomplete (`Ctrl-S`)
```bash
git sta          # Press Ctrl-S → shows: status, stash, stash pop (filtered)
docker           # Press Ctrl-S → shows: ps, images, run -it --rm, ...
kubectl get      # Press Ctrl-S → AI suggests: pods, svc, nodes, all, ...
```

Cursor placement matters — if your cursor is mid-word, the plugin replaces only that word:
```bash
git sta|tus      # Ctrl-S → offers completions, replaces "status" (not "statustus")
```

### Fix last command (`Ctrl-K`)
```bash
$ gti status     # typo — command fails
                 # Press Ctrl-K

  ✗ Last command: gti status
  Fix: git status

  [e] Edit in prompt   [r] Run now   [other] Cancel
  ❯ r
```

---

## 📁 Plugin structure

```
zsh-ai-assistant/
├── zsh-ai-assistant.plugin.zsh   # Entry point — sourced by plugin managers
├── lib/
│   ├── config.zsh                # Defaults + user config loader
│   ├── lifecycle.zsh             # Ollama start/stop, ai_model switcher
│   ├── api.zsh                   # REST API wrapper (ai_call, ai_clean_output)
│   ├── completions.zsh           # Ctrl-S autocomplete widget + static table
│   ├── assistant.zsh             # Ctrl-G natural language assistant
│   ├── explain.zsh               # Ctrl-L, Ctrl-K, Ctrl-J widgets
│   └── ui.zsh                    # Text formatting + welcome banner
├── install.sh                    # One-line installer
├── uninstall.sh                  # Clean uninstaller
└── README.md
```

---

## 🔄 Updating

```bash
# If installed via the installer or git clone:
git -C ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-assistant pull

# Or re-run the installer (it updates in place):
bash <(curl -fsSL https://raw.githubusercontent.com/glenndewildt/zsh-ai-assistant/refs/heads/master/install.sh)
```

---

## 🗑️ Uninstalling

```bash
bash ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-assistant/uninstall.sh
```

---

## 🤝 Contributing

PRs welcome! Ideas for contribution:
- Add more entries to the static completions table in `lib/completions.zsh`
- Add support for new package managers / tools
- Improve the AI prompts for better output quality

Please open an issue before starting large changes.

---

## 📄 License

MIT — see [LICENSE](LICENSE).
