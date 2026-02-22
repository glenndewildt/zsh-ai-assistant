# lib/ui.zsh — Text formatting and welcome banner

# Convert LLM markdown-style markup to zsh print -P terminal styles
_ai_format_text() {
  local text="$1"

  # Escape bare % signs (print -P treats them as format codes)
  text="${text//%/%%}"

  # **bold** → %Bbold%b
  text=$(printf '%s' "$text" | sed -E 's/\*\*([^*]+)\*\*/%B\1%b/g')

  # *italic* → cyan emphasis (terminals rarely support true italic)
  text=$(printf '%s' "$text" | sed -E 's/\*([^*]+)\*/%F{cyan}\1%f/g')

  # `code` → yellow
  text=$(printf '%s' "$text" | sed -E 's/`([^`]+)`/%F{yellow}\1%f/g')

  # ### Heading → bold + underline
  text=$(printf '%s' "$text" | sed -E 's/^### (.*)/%B%U\1%u%b/g')

  # - bullet → indented dot
  text=$(printf '%s' "$text" | sed -E 's/^[[:space:]]*[-*][[:space:]]+/  • /g')

  printf '%s' "$text"
}

# Welcome banner printed on shell start
_ai_print_welcome() {
  local model_len=${#ZSH_AI_MODEL}
  local pad=$(( 24 - model_len ))
  (( pad < 0 )) && pad=0
  local padding
  padding=$(printf '%*s' "$pad" '')

  print -P ""
  print -P "%F{39}  ┌──────────────────────────────────────────────────┐%f"
  print -P "%F{39}  │  🤖  AI Terminal Assistant                       │%f"
  print -P "%F{39}  ├──────────────────────────────────────────────────┤%f"
  print -P "%F{39}  │  %F{yellow}${ZSH_AI_KEY_ASSISTANT}%F{39}         Ask AI for a command           │%f"
  print -P "%F{39}  │  %F{yellow}${ZSH_AI_KEY_COMPLETE}%F{39}         Smart autocomplete at cursor   │%f"
  print -P "%F{39}  │  %F{yellow}${ZSH_AI_KEY_EXPLAIN}%F{39}         Explain last command           │%f"
  print -P "%F{39}  │  %F{yellow}${ZSH_AI_KEY_FIX}%F{39}         Fix last failed command        │%f"
  print -P "%F{39}  │  %F{yellow}${ZSH_AI_KEY_EXPLAIN_BUF}%F{39}         Explain buffer command         │%f"
  print -P "%F{39}  │  %F{245}ai_model%F{39}     Switch AI model                   │%f"
  print -P "%F{39}  │  %F{245}Model: %F{32}${ZSH_AI_MODEL}%F{39}${padding}│%f"
  print -P "%F{39}  └──────────────────────────────────────────────────┘%f"
  print -P ""
}
