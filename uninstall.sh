#!/usr/bin/env bash
# uninstall.sh — Remove zsh-ai-assistant

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'

INSTALL_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-ai-assistant"

echo ""
printf "${YELLOW}  Uninstalling zsh-ai-assistant...${RESET}\n\n"

# Remove plugin directory
if [[ -d "$INSTALL_DIR" ]]; then
  rm -rf "$INSTALL_DIR"
  printf "  ${GREEN}✓${RESET} Removed plugin directory: $INSTALL_DIR\n"
else
  printf "  ${YELLOW}⚠${RESET}  Plugin directory not found at $INSTALL_DIR\n"
fi

# Remove from .zshrc
ZSHRC="$HOME/.zshrc"
if grep -q 'zsh-ai-assistant' "$ZSHRC" 2>/dev/null; then
  # Remove source lines
  sed -i '/zsh-ai-assistant/d' "$ZSHRC"
  # Remove plugin from plugins array if it was added
  sed -i 's/ zsh-ai-assistant//' "$ZSHRC"
  printf "  ${GREEN}✓${RESET} Removed from .zshrc\n"
fi

# Ask about config
CONFIG_DIR="$HOME/.config/zsh-ai-assistant"
if [[ -d "$CONFIG_DIR" ]]; then
  printf "\n  Keep user config at ${CONFIG_DIR}? [Y/n] "
  read -r keep_config
  if [[ "${keep_config:l}" == "n" ]]; then
    rm -rf "$CONFIG_DIR"
    printf "  ${GREEN}✓${RESET} Removed config directory\n"
  else
    printf "  ${YELLOW}→${RESET} Config kept\n"
  fi
fi

printf "\n  ${GREEN}Done.${RESET} Reload your shell: exec zsh\n\n"
