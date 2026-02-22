#!/usr/bin/env bash
# install.sh — zsh-ai-assistant installer
# Usage:  bash <(curl -fsSL https://raw.githubusercontent.com/glenndewildt/zsh-ai-assistant/main/install.sh)
# Or:     ./install.sh [--dir /custom/path] [--no-banner] [--model qwen2.5:0.5b]

set -euo pipefail

# ─── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { printf "  ${CYAN}→${RESET} %s\n" "$*"; }
success() { printf "  ${GREEN}✓${RESET} %s\n" "$*"; }
warn()    { printf "  ${YELLOW}⚠${RESET}  %s\n" "$*"; }
error()   { printf "  ${RED}✗${RESET} %s\n" "$*" >&2; }
header()  { printf "\n${BOLD}%s${RESET}\n" "$*"; }

# ─── Defaults ──────────────────────────────────────────────────────────────────
INSTALL_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-ai-assistant"
MODEL="phi4-mini:latest"
BANNER=1

# ─── Parse args ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)     INSTALL_DIR="$2"; shift 2 ;;
    --model)   MODEL="$2";       shift 2 ;;
    --no-banner) BANNER=0;       shift   ;;
    -h|--help)
      echo "Usage: install.sh [--dir PATH] [--model MODEL] [--no-banner]"
      echo ""
      echo "  --dir PATH     Install to PATH (default: \$ZSH_CUSTOM/plugins/zsh-ai-assistant)"
      echo "  --model MODEL  Default Ollama model (default: phi4-mini:latest)"
      echo "  --no-banner    Don't show welcome banner on shell start"
      exit 0 ;;
    *) error "Unknown argument: $1"; exit 1 ;;
  esac
done

# ─── Banner ───────────────────────────────────────────────────────────────────
printf "\n${BOLD}${CYAN}"
cat << 'EOF'
  ╔══════════════════════════════════════════╗
  ║   🤖  zsh-ai-assistant  installer       ║
  ╚══════════════════════════════════════════╝
EOF
printf "${RESET}\n"

# ─── Check prerequisites ───────────────────────────────────────────────────────
header "Checking prerequisites..."

if ! command -v zsh > /dev/null 2>&1; then
  error "zsh is not installed."; exit 1
fi
success "zsh $(zsh --version | awk '{print $2}')"

if ! command -v curl > /dev/null 2>&1; then
  error "curl is required but not installed. Install it with: sudo apt install curl"
  exit 1
fi
success "curl"

if ! command -v git > /dev/null 2>&1; then
  error "git is required but not installed. Install it with: sudo apt install git"
  exit 1
fi
success "git"

if command -v ollama > /dev/null 2>&1; then
  success "ollama $(ollama --version 2>/dev/null | head -1)"
else
  warn "Ollama not found. Install from https://ollama.ai"
  warn "The plugin will prompt you when you first use it."
fi

if command -v fzf > /dev/null 2>&1; then
  success "fzf (fuzzy finder — enables interactive completion picker)"
else
  warn "fzf not found. Install for best experience: sudo apt install fzf"
  warn "Falling back to numbered menu without fzf."
fi

# ─── Install / Update ─────────────────────────────────────────────────────────
header "Installing plugin..."

REPO_URL="https://github.com/glenndewildt/zsh-ai-assistant.git"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  info "Updating existing installation at $INSTALL_DIR"
  git -C "$INSTALL_DIR" pull --ff-only
  success "Updated to latest version"
else
  info "Cloning into $INSTALL_DIR"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
  success "Cloned successfully"
fi

# ─── User config ──────────────────────────────────────────────────────────────
header "Writing user config..."

CONFIG_DIR="$HOME/.config/zsh-ai-assistant"
CONFIG_FILE="$CONFIG_DIR/config.zsh"
mkdir -p "$CONFIG_DIR"

if [[ ! -f "$CONFIG_FILE" ]]; then
  cat > "$CONFIG_FILE" << 'EOF'
# zsh-ai-assistant user config
# This file is loaded by the plugin and overrides defaults.
# Re-run install.sh to regenerate, or edit manually.
#
# Model to use (run 'ai_model' to switch at runtime, or 'ollama list' to see installed):
ZSH_AI_MODEL="${MODEL}"

# Ollama endpoint (change if running Ollama on a remote machine):
# ZSH_AI_OLLAMA_URL="http://remote-host:11434"

# Show welcome banner on shell start (0 to hide):
ZSH_AI_BANNER=${BANNER}

# Require 'yes' confirmation before running AI-generated commands (recommended):
ZSH_AI_SAFE_RUN=1

# Show model status in right-side prompt (0 to disable):
ZSH_AI_RPROMPT=1

# Keybindings — change to any key sequence, or "" to disable:
# ZSH_AI_KEY_ASSISTANT="^G"    # Ctrl-G  → Ask AI for command
# ZSH_AI_KEY_COMPLETE="^S"     # Ctrl-S  → Smart autocomplete
# ZSH_AI_KEY_EXPLAIN="^L"      # Ctrl-L  → Explain last command
# ZSH_AI_KEY_FIX="^K"          # Ctrl-K  → Fix last failed command
# ZSH_AI_KEY_EXPLAIN_BUF="^J"  # Ctrl-J  → Explain buffer
EOF
  success "Config written to $CONFIG_FILE"
else
  info "Config already exists at $CONFIG_FILE — skipping (edit manually to change settings)"
fi

# ─── Pull recommended Ollama model ────────────────────────────────────────────
if command -v ollama > /dev/null 2>&1; then
  header "Pulling Ollama model..."
  if ollama list 2>/dev/null | grep -q "${MODEL%%:*}"; then
    success "Model '${MODEL}' already installed"
  else
    info "Pulling '${MODEL}' — this may take a moment..."
    if ollama pull "$MODEL"; then
      success "Model '${MODEL}' ready"
    else
      warn "Could not pull model. Run manually: ollama pull ${MODEL}"
    fi
  fi
fi

# ─── Configure .zshrc ─────────────────────────────────────────────────────────
header "Configuring .zshrc..."

ZSHRC="$HOME/.zshrc"

# Detect oh-my-zsh plugin array vs manual source
if grep -q 'ZSH_CUSTOM\|oh-my-zsh' "$ZSHRC" 2>/dev/null; then
  # oh-my-zsh user: add to plugins array
  if grep -q 'zsh-ai-assistant' "$ZSHRC" 2>/dev/null; then
    info "Plugin already present in .zshrc"
  else
    # Insert into plugins=(...) array
    if grep -q '^plugins=(' "$ZSHRC"; then
      sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-ai-assistant)/' "$ZSHRC"
      success "Added 'zsh-ai-assistant' to plugins array in .zshrc"
    else
      echo "" >> "$ZSHRC"
      echo "# zsh-ai-assistant" >> "$ZSHRC"
      echo "source \"${INSTALL_DIR}/zsh-ai-assistant.plugin.zsh\"" >> "$ZSHRC"
      success "Added source line to .zshrc (oh-my-zsh plugins array not found)"
    fi
  fi
else
  # Manual / zinit / zplug user: add a source line
  if grep -q 'zsh-ai-assistant' "$ZSHRC" 2>/dev/null; then
    info "Plugin already present in .zshrc"
  else
    echo "" >> "$ZSHRC"
    echo "# zsh-ai-assistant — https://github.com/glenndewildt/zsh-ai-assistant" >> "$ZSHRC"
    echo "source \"${INSTALL_DIR}/zsh-ai-assistant.plugin.zsh\"" >> "$ZSHRC"
    success "Added source line to .zshrc"
  fi
fi

# ─── Done ────────────────────────────────────────────────────────────────────
printf "\n${BOLD}${GREEN}  ✓ Installation complete!${RESET}\n\n"
printf "  Reload your shell:  ${CYAN}exec zsh${RESET}\n"
printf "  Or source manually: ${CYAN}source ~/.zshrc${RESET}\n\n"
printf "  Quick start:\n"
printf "    ${YELLOW}Ctrl-G${RESET}  → Ask AI for a command\n"
printf "    ${YELLOW}Ctrl-S${RESET}  → Smart autocomplete\n"
printf "    ${YELLOW}Ctrl-L${RESET}  → Explain last command\n"
printf "    ${YELLOW}Ctrl-K${RESET}  → Fix last failed command\n"
printf "    ${YELLOW}ai_model${RESET} → Switch AI model\n\n"
printf "  Docs: https://github.com/glenndewildt/zsh-ai-assistant\n\n"
