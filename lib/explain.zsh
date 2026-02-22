# lib/explain.zsh — Explain and fix command widgets

# ─── Shared explanation renderer ─────────────────────────────────────────────
# Called from within a ZLE widget — all output goes to /dev/tty
_ai_show_explanation() {
  local cmd="$1"
  local prompt="${2:-Explain what this shell command does, step by step, including each flag and argument: ${cmd}}"

  _ai_printf '  \033[38;5;245m⟳ Explaining...\033[0m'

  local raw_explanation
  raw_explanation=$(ai_call "$prompt" \
    "You are a Linux expert. Explain shell commands clearly and concisely. Use markup: **bold** for important terms, \`code\` for commands/flags. Plain text paragraphs. Max 300 words." \
    "$ZSH_AI_TIMEOUT_EXPLAIN" "$ZSH_AI_TOKENS_EXPLAIN")

  _ai_erase_line

  if [[ -z "$raw_explanation" ]]; then
    _ai_print "  %F{red}✗ Failed to generate explanation%f"
    return 1
  fi

  local formatted
  formatted=$(_ai_format_text "$raw_explanation")

  _ai_print ""
  _ai_print "  %F{75}${cmd}%f"
  _ai_print "  %F{39}───────────────────────────────────────%f"
  _ai_print ""
  # Print each line via _ai_print so % escapes are handled correctly
  while IFS= read -r line; do
    _ai_print "  ${line}"
  done <<< "$formatted"
  _ai_print ""
}

# ─── Explain LAST command (Ctrl-L) ───────────────────────────────────────────
ai_explain_last() {
  zle -I

  local last_cmd
  last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')

  if [[ -z "$last_cmd" ]]; then
    zle -M "No previous command found"
    sleep 0.8
    zle -M ""
    return
  fi

  ai_ensure_ollama || { zle reset-prompt; return; }

  printf '\n' >/dev/tty
  _ai_print "  %F{39}Last command:%f %F{yellow}${last_cmd}%f"
  _ai_print ""

  _ai_show_explanation "$last_cmd"

  _ai_printf '  Press Enter to continue...'
  read -r </dev/tty

  zle reset-prompt
}

# ─── Fix LAST failed command (Ctrl-K) ────────────────────────────────────────
ai_fix_last() {
  zle -I

  local last_cmd
  last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')

  if [[ -z "$last_cmd" ]]; then
    zle -M "No previous command found"
    sleep 0.8
    zle -M ""
    return
  fi

  ai_ensure_ollama || { zle reset-prompt; return; }

  printf '\n' >/dev/tty
  _ai_print "  %F{red}✗ Last command:%f %F{yellow}${last_cmd}%f"
  _ai_printf '  \033[38;5;245m⟳ Generating fix...\033[0m'

  local fixed
  fixed=$(ai_call \
    "This shell command failed or has an error: '${last_cmd}'. Output the corrected command only. Nothing else." \
    "You are a Linux shell expert. Fix broken shell commands. Output only the corrected command, no explanation." \
    "$ZSH_AI_TIMEOUT_COMMAND" 150 | ai_clean_output | head -1)

  _ai_erase_line

  if [[ -z "$fixed" || "$fixed" == "$last_cmd" ]]; then
    _ai_print "  %F{red}✗ Could not generate a fix.%f"
    _ai_print "  %F{245}  Try Ctrl-G to describe the problem in plain English.%f"
    sleep 2
    zle reset-prompt
    return
  fi

  _ai_print "  %F{green}Fix:%f %F{75}${fixed}%f"
  _ai_print ""
  _ai_print "  %F{green}[e]%f Edit in prompt   %F{green}[r]%f Run now   %F{green}[other]%f Cancel"
  _ai_printf '  ❯ '

  local action
  read -r action </dev/tty

  case "${action:l}" in
    e)
      BUFFER="$fixed"
      CURSOR=$#BUFFER
      ;;
    r)
      _ai_print ""
      eval "$fixed" </dev/tty
      local exit_code=$?
      _ai_print ""
      (( exit_code == 0 )) && \
        _ai_print "  %F{green}✓ Done%f" || \
        _ai_print "  %F{red}✗ Exited with code ${exit_code}%f"
      sleep 1
      ;;
    *)
      _ai_print "  %F{245}Cancelled.%f"
      sleep 0.3
      ;;
  esac

  zle reset-prompt
}

# ─── Explain current BUFFER command (Ctrl-J) ─────────────────────────────────
ai_explain_buffer() {
  zle -I

  local cmd="$BUFFER"

  if [[ -z "$cmd" ]]; then
    zle -M "Buffer is empty — type a command first"
    sleep 0.8
    zle -M ""
    return
  fi

  ai_ensure_ollama || { zle reset-prompt; return; }

  printf '\n' >/dev/tty
  _ai_print "  %F{39}Explaining buffer:%f %F{yellow}${cmd}%f"
  _ai_print ""

  _ai_show_explanation "$cmd" "Explain what this shell command does in 2-4 sentences: ${cmd}"

  _ai_printf '  Press Enter to continue (buffer unchanged)...'
  read -r </dev/tty

  # Buffer is unchanged — restore it exactly as it was
  BUFFER="$cmd"
  CURSOR=$#BUFFER
  zle reset-prompt
}
