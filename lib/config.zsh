# lib/config.zsh — Default configuration
# Override any of these in ~/.config/zsh-ai-assistant/config.zsh
# or by setting them in your .zshrc BEFORE the plugin is loaded.

# ── Model & endpoint
: "${ZSH_AI_MODEL:=phi4-mini:latest}"
: "${ZSH_AI_OLLAMA_URL:=http://localhost:11434}"

# ── Behaviour toggles
: "${ZSH_AI_BANNER:=1}"          # Show welcome banner on shell start (0 to hide)
: "${ZSH_AI_RPROMPT:=1}"         # Show model status in RPROMPT (0 to disable)
: "${ZSH_AI_SAFE_RUN:=1}"        # Require 'yes' confirmation before running AI commands

# ── Keybindings (set to empty string "" to disable a binding)
: "${ZSH_AI_KEY_ASSISTANT:=^G}"   # Ctrl-G  → Ask AI for a command
: "${ZSH_AI_KEY_COMPLETE:=^S}"    # Ctrl-S  → Smart autocomplete
: "${ZSH_AI_KEY_EXPLAIN:=^L}"     # Ctrl-L  → Explain last command
: "${ZSH_AI_KEY_FIX:=^K}"         # Ctrl-K  → Fix last failed command
: "${ZSH_AI_KEY_EXPLAIN_BUF:=^J}" # Ctrl-J  → Explain buffer command

# ── Timeouts (seconds)
: "${ZSH_AI_TIMEOUT_COMPLETE:=6}"
: "${ZSH_AI_TIMEOUT_COMMAND:=15}"
: "${ZSH_AI_TIMEOUT_EXPLAIN:=30}"

# ── Token limits
: "${ZSH_AI_TOKENS_COMPLETE:=120}"
: "${ZSH_AI_TOKENS_COMMAND:=200}"
: "${ZSH_AI_TOKENS_EXPLAIN:=400}"

# ── Load user overrides if present
local _user_config="${HOME}/.config/zsh-ai-assistant/config.zsh"
[[ -f "$_user_config" ]] && source "$_user_config"
