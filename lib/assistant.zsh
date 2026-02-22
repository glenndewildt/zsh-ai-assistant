# lib/assistant.zsh — Natural language → shell command (Ctrl-G)

ai_assistant() {
  # Tell ZLE we're taking over the terminal
  zle -I

  # Move to a clean line — the cursor may be right after the prompt text
  printf '\n' >/dev/tty

  _ai_print "%F{39}  ┌─────────────────────────────────────────┐%f"
  _ai_print "%F{39}  │  🤖 AI Shell Assistant                  │%f"
  _ai_print "%F{39}  └─────────────────────────────────────────┘%f"
  _ai_print "%F{245}  Describe your task in plain English.%f"
  _ai_print "%F{245}  e.g. 'kill all node processes' · 'find .env files recursively'%f"
  _ai_printf '  ❯ '

  local user_request
  read -r user_request </dev/tty
  [[ -z "$user_request" ]] && { zle reset-prompt; return; }

  ai_ensure_ollama || { zle reset-prompt; return; }

  # Show spinner inline (stays on same line, erased when done)
  _ai_printf '  \033[38;5;245m⟳ Generating...\033[0m'

  local command
  command=$(ai_call "$user_request" \
    "You are a Linux shell expert. The user describes a task. Output ONLY the exact shell command. No explanation. No markdown. No backticks. No commentary. Just the raw command on one line." \
    "$ZSH_AI_TIMEOUT_COMMAND" "$ZSH_AI_TOKENS_COMMAND" | ai_clean_output | head -1)

  _ai_erase_line

  if [[ -z "$command" ]]; then
    _ai_print "  %F{red}✗ No command generated. Try rephrasing.%f"
    _ai_print "  %F{245}  Tip: be specific — e.g. 'compress folder myapp to tar.gz excluding node_modules'%f"
    sleep 2
    zle reset-prompt
    return
  fi

  _ai_print ""
  _ai_print "  %F{39}Task   %f %F{yellow}${user_request}%f"
  _ai_print "  %F{39}Result %f %F{75}${command}%f"
  _ai_print ""
  _ai_print "  %F{green}[e]%f Edit   %F{green}[r]%f Run   %F{green}[c]%f Copy   %F{green}[s]%f Save script   %F{green}[x]%f Explain"
  _ai_printf '  ❯ '

  local action
  read -r action </dev/tty

  case "${action:l}" in
    e)
      BUFFER="$command"
      CURSOR=$#BUFFER
      ;;

    r)
      if [[ "${ZSH_AI_SAFE_RUN:-1}" == "1" ]]; then
        _ai_print ""
        _ai_print "  %F{red}⚠  AI-generated command — review before running:%f"
        _ai_print "  %F{red}   ${command}%f"
        _ai_printf '  Type '\''yes'\'' to confirm: '
        local confirm
        read -r confirm </dev/tty
        if [[ "$confirm" != "yes" ]]; then
          _ai_print "  %F{245}Cancelled.%f"
          sleep 0.3
          zle reset-prompt
          return
        fi
      fi
      _ai_print ""
      # Run command with terminal properly connected
      eval "$command" </dev/tty
      local exit_code=$?
      _ai_print ""
      (( exit_code == 0 )) && \
        _ai_print "  %F{green}✓ Done (exit 0)%f" || \
        _ai_print "  %F{red}✗ Exited with code ${exit_code}%f"
      sleep 1
      ;;

    c)
      local copied=false
      for clip_cmd in "wl-copy" "xclip -sel clip" "xsel -b" "pbcopy" "clip"; do
        if printf '%s' "$command" | eval "$clip_cmd" 2>/dev/null; then
          copied=true; break
        fi
      done
      $copied && _ai_print "  %F{green}✓ Copied to clipboard%f" || \
                 _ai_print "  %F{red}✗ No clipboard tool found (install wl-copy or xclip)%f"
      sleep 1
      ;;

    s)
      local fname="ai_script_$(date +%s).sh"
      {
        printf '#!/usr/bin/env bash\n'
        printf '# AI-generated script\n'
        printf '# Task: %s\n' "$user_request"
        printf '# Date: %s\n' "$(date)"
        printf 'set -euo pipefail\n\n'
        printf '%s\n' "$command"
      } > "$fname"
      chmod +x "$fname"
      _ai_print "  %F{green}✓ Saved: ${fname}%f"
      sleep 1.5
      ;;

    x)
      _ai_show_explanation "$command"
      _ai_printf '  Press Enter to continue...'
      read -r </dev/tty
      ;;

    *)
      _ai_print "  %F{245}Cancelled.%f"
      sleep 0.3
      ;;
  esac

  # Full ZLE redraw — repositions cursor correctly after all our output
  zle reset-prompt
}
