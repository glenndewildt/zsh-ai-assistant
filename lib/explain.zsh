# lib/explain.zsh — Explain and fix command widgets

# ─── Shared explanation renderer ─────────────────────────────────────────────
_ai_show_explanation() {
  local cmd="$1"
  local prompt="${2:-Explain what this shell command does, step by step, including each flag and argument: ${cmd}}"

  print -P ""
  print -P "  %F{245}⟳ Explaining...%f"

  local raw_explanation
  raw_explanation=$(ai_call "$prompt" \
    "You are a Linux expert. Explain shell commands clearly and concisely. Use markup: **bold** for important terms, \`code\` for commands/flags. Plain text paragraphs. Max 300 words." \
    "$ZSH_AI_TIMEOUT_EXPLAIN" "$ZSH_AI_TOKENS_EXPLAIN")

  printf "\r\033[K"

  if [[ -z "$raw_explanation" ]]; then
    print -P "  %F{red}✗ Failed to generate explanation%f"
    return
  fi

  local formatted
  formatted=$(_ai_format_text "$raw_explanation")

  print -P ""
  print -P "  %F{75}${cmd}%f"
  print -P "  %F{39}───────────────────────────────────────%f"
  print -P ""
  echo "$formatted" | while IFS= read -r line; do
    print -P "  $line"
  done
  print -P ""
}

# ─── Explain LAST command (Ctrl-L) ───────────────────────────────────────────
ai_explain_last() {
  zle -I
  local last_cmd
  last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
  [[ -z "$last_cmd" ]] && { zle reset-prompt; return; }

  ai_ensure_ollama || { zle reset-prompt; return; }

  print -P ""
  print -P "  %F{39}Last command:%f %F{yellow}${last_cmd}%f"

  _ai_show_explanation "$last_cmd"

  echo -n "  Press Enter to continue..."
  read -r < /dev/tty
  zle reset-prompt
}

# ─── Fix LAST failed command (Ctrl-K) ────────────────────────────────────────
ai_fix_last() {
  zle -I
  local last_cmd
  last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
  [[ -z "$last_cmd" ]] && { zle reset-prompt; return; }

  ai_ensure_ollama || { zle reset-prompt; return; }

  print -P ""
  print -P "  %F{red}✗ Last command:%f %F{yellow}${last_cmd}%f"
  print -P "  %F{245}⟳ Generating fix...%f"

  local fixed
  fixed=$(ai_call \
    "This shell command failed or has an error: '${last_cmd}'. Output the corrected command only. Nothing else." \
    "You are a Linux shell expert. Fix broken shell commands. Output only the corrected command, no explanation." \
    "$ZSH_AI_TIMEOUT_COMMAND" 150 | ai_clean_output | head -1)

  printf "\r\033[K"

  if [[ -z "$fixed" || "$fixed" == "$last_cmd" ]]; then
    print -P "  %F{red}✗ Could not generate a fix.%f"
    print -P "  %F{245}  Try Ctrl-G to describe the problem in plain English.%f"
    sleep 2; zle reset-prompt; return
  fi

  print -P "  %F{green}Fix:%f %F{75}${fixed}%f"
  print -P ""
  print -P "  %F{green}[e]%f Edit in prompt   %F{green}[r]%f Run now   %F{green}[other]%f Cancel"
  echo -n "  ❯ "

  local action; read -r action < /dev/tty

  case "${action:l}" in
    e)
      BUFFER="$fixed"; CURSOR=$#BUFFER
      ;;
    r)
      print -P ""; eval "$fixed"
      local exit_code=$?
      (( exit_code == 0 )) && \
        print -P "  %F{green}✓ Done%f" || \
        print -P "  %F{red}✗ Exited with code ${exit_code}%f"
      sleep 1
      ;;
    *)
      print -P "  %F{245}Cancelled.%f"; sleep 0.3
      ;;
  esac

  zle reset-prompt
}

# ─── Explain current BUFFER command (Ctrl-J) ─────────────────────────────────
ai_explain_buffer() {
  zle -I
  local cmd="$BUFFER"
  [[ -z "$cmd" ]] && { zle reset-prompt; return; }

  ai_ensure_ollama || { zle reset-prompt; return; }

  _ai_show_explanation "$cmd" "Explain what this shell command does in 2-4 sentences: ${cmd}"

  echo -n "  Press Enter to continue (buffer unchanged)..."
  read -r < /dev/tty
  zle reset-prompt
}
