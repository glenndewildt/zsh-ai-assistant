# lib/ui.zsh — Text formatting, output helpers, and welcome banner

# ─────────────────────────────────────────────
# OUTPUT HELPERS
# All output in ZLE widgets MUST go to /dev/tty, not stdout.
# Use these helpers everywhere instead of print/echo/printf directly.
# ─────────────────────────────────────────────

# Print a zsh %-formatted line to /dev/tty (safe inside ZLE widgets)
_ai_print() {
  print -P -- "$@" >/dev/tty
}

# Print a plain (no % expansion) line to /dev/tty
_ai_puts() {
  printf '%s\n' "$@" >/dev/tty
}

# Print without newline (for prompts/spinners)
_ai_printf() {
  printf "$@" >/dev/tty
}

# Erase the current line (used to clear spinner)
_ai_erase_line() {
  printf '\r\033[K' >/dev/tty
}

# Show a spinner message, run a command, erase the spinner
# Usage: _ai_spin "message" cmd [args...]
_ai_spin() {
  local msg="$1"; shift
  _ai_printf '  \033[38;5;245m⟳ %s\033[0m' "$msg" >/dev/tty
  "$@"
  local rc=$?
  _ai_erase_line
  return $rc
}

# ─────────────────────────────────────────────
# TEXT FORMATTER
# Converts LLM markdown-style markup → zsh terminal escapes
# ─────────────────────────────────────────────
_ai_format_text() {
  local text="$1"

  # Escape bare % (print -P treats % as format code)
  text="${text//%/%%}"

  # **bold** → %B...%b
  text=$(printf '%s' "$text" | sed -E 's/\*\*([^*]+)\*\*/%B\1%b/g')

  # *italic* → cyan (true italic rarely supported in terminals)
  text=$(printf '%s' "$text" | sed -E 's/\*([^*]+)\*/%F{cyan}\1%f/g')

  # `code` → yellow
  text=$(printf '%s' "$text" | sed -E 's/`([^`]+)`/%F{yellow}\1%f/g')

  # ### Heading → bold underline
  text=$(printf '%s' "$text" | sed -E 's/^### (.*)/%B%U\1%u%b/g')

  # - / * bullet → indented dot
  text=$(printf '%s' "$text" | sed -E 's/^[[:space:]]*[-*][[:space:]]+/  • /g')

  printf '%s' "$text"
}

# ─────────────────────────────────────────────
# WELCOME BANNER
# Printed via precmd hook on the FIRST prompt only, so it never
# interferes with ZLE state or zsh-autosuggestions ghost text.
# ─────────────────────────────────────────────
_AI_BANNER_SHOWN=0

_ai_precmd_banner() {
  # Only fire once, then remove ourselves from precmd
  if (( _AI_BANNER_SHOWN == 0 )); then
    _AI_BANNER_SHOWN=1
    # Remove this hook so it never runs again
    add-zsh-hook -d precmd _ai_precmd_banner 2>/dev/null

    local model_len=${#ZSH_AI_MODEL}
    local pad=$(( 26 - model_len ))
    (( pad < 0 )) && pad=0
    local padding
    padding=$(printf '%*s' "$pad" '')

    # Use regular print here — we're in precmd, NOT inside a ZLE widget,
    # so stdout is the terminal and this is safe.
    print -P ""
    print -P "%F{39}  ┌──────────────────────────────────────────────────┐%f"
    print -P "%F{39}  │  🤖  AI Terminal Assistant                       │%f"
    print -P "%F{39}  ├──────────────────────────────────────────────────┤%f"
    print -P "%F{39}  │  %F{yellow}${ZSH_AI_KEY_ASSISTANT:-^G}%F{39}         Ask AI for a command           │%f"
    print -P "%F{39}  │  %F{yellow}${ZSH_AI_KEY_COMPLETE:-^S}%F{39}         Smart autocomplete at cursor   │%f"
    print -P "%F{39}  │  %F{yellow}${ZSH_AI_KEY_EXPLAIN:-^L}%F{39}         Explain last command           │%f"
    print -P "%F{39}  │  %F{yellow}${ZSH_AI_KEY_FIX:-^K}%F{39}         Fix last failed command        │%f"
    print -P "%F{39}  │  %F{yellow}${ZSH_AI_KEY_EXPLAIN_BUF:-^J}%F{39}         Explain buffer command         │%f"
    print -P "%F{39}  │  %F{245}ai_model%F{39}     Switch AI model                   │%f"
    print -P "%F{39}  │  %F{245}Model: %F{32}${ZSH_AI_MODEL}%F{39}${padding}│%f"
    print -P "%F{39}  └──────────────────────────────────────────────────┘%f"
    print -P ""
  fi
}

# Register as a precmd hook (requires zsh/hooks, loaded by oh-my-zsh and most frameworks)
# Falls back to plain print if add-zsh-hook is unavailable
_ai_print_welcome() {
  if (( _AI_BANNER_SHOWN == 0 )); then
    if typeset -f add-zsh-hook > /dev/null 2>&1; then
      add-zsh-hook precmd _ai_precmd_banner
    else
      # No hook support — print immediately (slightly less safe but functional)
      _AI_BANNER_SHOWN=1
      print -P ""
      print -P "%F{39}  🤖  zsh-ai-assistant loaded%f"
      print -P "%F{245}     Ctrl-G: ask  Ctrl-S: complete  Ctrl-L: explain  Ctrl-K: fix%f"
      print -P ""
    fi
  fi
}
