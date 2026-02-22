# Changelog

All notable changes to zsh-ai-assistant will be documented here.
Format: [Semantic Versioning](https://semver.org/)

## [1.0.0] — Initial release

### Features
- `Ctrl-G` — Natural language to shell command via local Ollama LLM
- `Ctrl-S` — Smart autocomplete with static lookup table + AI fallback
  - Cursor-aware: replaces only the active token, never duplicates words
  - Mid-word cursor support (fixes "statustus" style bugs)
  - 30+ static entries for git, docker, kubectl, apt, systemctl, and more
- `Ctrl-L` — Explain last command with formatted output
- `Ctrl-K` — Auto-fix last failed command
- `Ctrl-J` — Explain current buffer command
- `ai_model` — Switch Ollama model at runtime without restarting shell
- RPROMPT indicator showing active model and Ollama status (cached, non-blocking)
- Fully configurable keybindings via `~/.config/zsh-ai-assistant/config.zsh`
- Compatible with oh-my-zsh, zinit, zplug, antigen, manual source
- One-line installer with auto model pull and `.zshrc` patching
- Clean uninstaller
