# zsh-ai-assistant.plugin.zsh
# AI-powered terminal assistant for Zsh
# https://github.com/glenndewildt/zsh-ai-assistant
#
# Compatible with: oh-my-zsh, zinit, zplug, antigen, manual source

# ─────────────────────────────────────────────
# GUARD: prevent double-loading
# ─────────────────────────────────────────────
[[ -n "$_ZSH_AI_ASSISTANT_LOADED" ]] && return
_ZSH_AI_ASSISTANT_LOADED=1

# ─────────────────────────────────────────────
# PLUGIN ROOT — works regardless of how it was sourced
# ─────────────────────────────────────────────
_AI_PLUGIN_DIR="${${(%):-%x}:A:h}"

# ─────────────────────────────────────────────
# LOAD CONFIG (user's ~/.config/zsh-ai-assistant/config.zsh overrides defaults)
# ─────────────────────────────────────────────
source "${_AI_PLUGIN_DIR}/lib/config.zsh"

# ─────────────────────────────────────────────
# LOAD MODULES
# ─────────────────────────────────────────────
source "${_AI_PLUGIN_DIR}/lib/lifecycle.zsh"
source "${_AI_PLUGIN_DIR}/lib/api.zsh"
source "${_AI_PLUGIN_DIR}/lib/completions.zsh"
source "${_AI_PLUGIN_DIR}/lib/assistant.zsh"
source "${_AI_PLUGIN_DIR}/lib/explain.zsh"
source "${_AI_PLUGIN_DIR}/lib/ui.zsh"

# ─────────────────────────────────────────────
# REGISTER ZLE WIDGETS & KEYBINDINGS
# ─────────────────────────────────────────────
zle -N ai_assistant
zle -N ai_suggest_command
zle -N ai_explain_last
zle -N ai_fix_last
zle -N ai_explain_buffer

bindkey "${ZSH_AI_KEY_ASSISTANT:-^G}"    ai_assistant
bindkey "${ZSH_AI_KEY_COMPLETE:-^S}"     ai_suggest_command
bindkey "${ZSH_AI_KEY_EXPLAIN:-^L}"      ai_explain_last
bindkey "${ZSH_AI_KEY_FIX:-^K}"          ai_fix_last
bindkey "${ZSH_AI_KEY_EXPLAIN_BUF:-^J}"  ai_explain_buffer

# ─────────────────────────────────────────────
# RPROMPT — cached Ollama status
# ─────────────────────────────────────────────
typeset -g _AI_STATUS_CACHE=""
typeset -g _AI_STATUS_TIME=0

_ai_rprompt() {
  local now=$EPOCHSECONDS
  if (( now - _AI_STATUS_TIME > 15 )); then
    if curl -sf --max-time 0.5 "${ZSH_AI_OLLAMA_URL}/api/tags" > /dev/null 2>&1; then
      _AI_STATUS_CACHE="%F{32}⬡ ${ZSH_AI_MODEL}%f"
    else
      _AI_STATUS_CACHE="%F{237}⬡ offline%f"
    fi
    _AI_STATUS_TIME=$now
  fi
  print -P "$_AI_STATUS_CACHE"
}

# Only set RPROMPT if user hasn't disabled it
if [[ "${ZSH_AI_RPROMPT:-1}" == "1" ]]; then
  RPROMPT='$(_ai_rprompt)'
fi

# ─────────────────────────────────────────────
# WELCOME BANNER (disable with ZSH_AI_BANNER=0)
# ─────────────────────────────────────────────
if [[ "${ZSH_AI_BANNER:-1}" == "1" ]]; then
  _ai_print_welcome
fi
