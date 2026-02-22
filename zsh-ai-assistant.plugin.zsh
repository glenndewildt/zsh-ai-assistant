# zsh-ai-assistant.plugin.zsh
# AI-powered terminal assistant for Zsh
# https://github.com/YOUR_USERNAME/zsh-ai-assistant
#
# Compatible with: oh-my-zsh, zinit, zplug, antigen, manual source

# ─────────────────────────────────────────────
# GUARD: prevent double-loading
# ─────────────────────────────────────────────
[[ -n "$_ZSH_AI_ASSISTANT_LOADED" ]] && return
_ZSH_AI_ASSISTANT_LOADED=1

# ─────────────────────────────────────────────
# PLUGIN ROOT — resolves correctly regardless of how sourced
# ─────────────────────────────────────────────
_AI_PLUGIN_DIR="${${(%):-%x}:A:h}"

# ─────────────────────────────────────────────
# LOAD MODULES (order matters: ui first so helpers exist for all others)
# ─────────────────────────────────────────────
source "${_AI_PLUGIN_DIR}/lib/config.zsh"
source "${_AI_PLUGIN_DIR}/lib/ui.zsh"          # _ai_print helpers — must be first
source "${_AI_PLUGIN_DIR}/lib/lifecycle.zsh"
source "${_AI_PLUGIN_DIR}/lib/api.zsh"
source "${_AI_PLUGIN_DIR}/lib/completions.zsh"
source "${_AI_PLUGIN_DIR}/lib/assistant.zsh"
source "${_AI_PLUGIN_DIR}/lib/explain.zsh"

# ─────────────────────────────────────────────
# REGISTER ZLE WIDGETS
# ─────────────────────────────────────────────
zle -N ai_assistant
zle -N ai_suggest_command
zle -N ai_explain_last
zle -N ai_fix_last
zle -N ai_explain_buffer

# ─────────────────────────────────────────────
# KEYBINDINGS
# Each binding is skipped if the key is set to empty string ""
# ─────────────────────────────────────────────
_ai_bind() {
  local key="$1" widget="$2"
  [[ -n "$key" ]] && bindkey "$key" "$widget"
}
_ai_bind "${ZSH_AI_KEY_ASSISTANT:-^G}"   ai_assistant
_ai_bind "${ZSH_AI_KEY_COMPLETE:-^S}"    ai_suggest_command
_ai_bind "${ZSH_AI_KEY_EXPLAIN:-^L}"     ai_explain_last
_ai_bind "${ZSH_AI_KEY_FIX:-^K}"         ai_fix_last
_ai_bind "${ZSH_AI_KEY_EXPLAIN_BUF:-^J}" ai_explain_buffer

# ─────────────────────────────────────────────
# RPROMPT — cached Ollama status, refreshed every 15s
#
# IMPORTANT: _ai_rprompt must use printf, NOT print -P.
# print -P adds a trailing newline which breaks RPROMPT rendering
# and causes the cursor to drop to the next line.
# ─────────────────────────────────────────────
typeset -g _AI_STATUS_CACHE=""
typeset -g _AI_STATUS_TIME=0

_ai_rprompt() {
  local now=$EPOCHSECONDS
  if (( now - _AI_STATUS_TIME > 15 )); then
    if curl -sf --max-time 0.5 "${ZSH_AI_OLLAMA_URL}/api/tags" >/dev/null 2>&1; then
      # Use raw escape codes — no print -P, no trailing newline
      _AI_STATUS_CACHE=$'%F{32}\u29a1 '"${ZSH_AI_MODEL}"$'%f'
    else
      _AI_STATUS_CACHE=$'%F{237}\u29a1 offline%f'
    fi
    _AI_STATUS_TIME=$now
  fi
  # printf with no newline — RPROMPT must not have a trailing newline
  printf '%s' "$_AI_STATUS_CACHE"
}

if [[ "${ZSH_AI_RPROMPT:-1}" == "1" ]]; then
  RPROMPT='$(_ai_rprompt)'
fi

# ─────────────────────────────────────────────
# WELCOME BANNER
# Registered as a one-shot precmd hook so it fires AFTER the first
# prompt is drawn — avoids conflicts with zsh-autosuggestions and
# other plugins that also use precmd.
# ─────────────────────────────────────────────
if [[ "${ZSH_AI_BANNER:-1}" == "1" ]]; then
  _ai_print_welcome
fi
