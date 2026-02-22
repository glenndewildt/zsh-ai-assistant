# lib/assistant.zsh — Natural language → shell command (Ctrl-G)

ai_assistant() {
  zle -I

  print -P ""
  print -P "%F{39}  ┌─────────────────────────────────────────┐%f"
  print -P "%F{39}  │  🤖 AI Shell Assistant                  │%f"
  print -P "%F{39}  └─────────────────────────────────────────┘%f"
  print -P "%F{245}  Describe your task in plain English.%f"
  print -P "%F{245}  e.g. 'kill all node processes' · 'find .env files recursively'%f"
  echo -n "  ❯ "

  local user_request
  read -r user_request < /dev/tty
  [[ -z "$user_request" ]] && { zle reset-prompt; return; }

  ai_ensure_ollama || { zle reset-prompt; return; }

  printf "  %s" "$(print -P '%F{245}⟳ Generating...%f')"

  local command
  command=$(ai_call "$user_request" \
    "You are a Linux shell expert. The user describes a task. Output ONLY the exact shell command. No explanation. No markdown. No backticks. No commentary. Just the raw command on one line." \
    "$ZSH_AI_TIMEOUT_COMMAND" "$ZSH_AI_TOKENS_COMMAND" | ai_clean_output | head -1)

  printf "\r\033[K"

  if [[ -z "$command" ]]; then
    print -P "  %F{red}✗ No command generated. Try rephrasing.%f"
    print -P "  %F{245}  Tip: be specific — e.g. 'compress folder myapp to tar.gz excluding node_modules'%f"
    sleep 2; zle reset-prompt; return
  fi

  print -P ""
  print -P "  %F{39}Task   %f %F{yellow}${user_request}%f"
  print -P "  %F{39}Result %f %F{75}${command}%f"
  print -P ""
  print -P "  %F{green}[e]%f Edit   %F{green}[r]%f Run   %F{green}[c]%f Copy   %F{green}[s]%f Save script   %F{green}[x]%f Explain"
  echo -n "  ❯ "

  local action
  read -r action < /dev/tty

  case "${action:l}" in
    e)
      BUFFER="$command"
      CURSOR=$#BUFFER
      ;;
    r)
      if [[ "${ZSH_AI_SAFE_RUN}" == "1" ]]; then
        print -P ""
        print -P "  %F{red}⚠  AI-generated command — review before running:%f"
        print -P "  %F{red}   ${command}%f"
        echo -n "  Type 'yes' to confirm: "
        local confirm; read -r confirm < /dev/tty
        [[ "$confirm" != "yes" ]] && { print -P "  %F{245}Cancelled.%f"; sleep 0.3; zle reset-prompt; return; }
      fi
      print -P ""
      eval "$command"
      local exit_code=$?
      (( exit_code == 0 )) && \
        print -P "  %F{green}✓ Done (exit 0)%f" || \
        print -P "  %F{red}✗ Exited with code ${exit_code}%f"
      sleep 1
      ;;
    c)
      local copied=false
      for clip_cmd in "wl-copy" "xclip -sel clip" "xsel -b" "pbcopy" "clip"; do
        if echo "$command" | eval "$clip_cmd" 2>/dev/null; then
          copied=true; break
        fi
      done
      $copied && print -P "  %F{green}✓ Copied%f" || \
                 print -P "  %F{red}✗ No clipboard tool found (install wl-copy or xclip)%f"
      sleep 1
      ;;
    s)
      local fname="ai_script_$(date +%s).sh"
      { echo "#!/usr/bin/env bash"
        echo "# AI-generated script"
        echo "# Task: $user_request"
        echo "# Date: $(date)"
        echo "set -euo pipefail"
        echo ""
        echo "$command"
      } > "$fname"
      chmod +x "$fname"
      print -P "  %F{green}✓ Saved: ${fname}%f"
      sleep 1.5
      ;;
    x)
      _ai_show_explanation "$command"
      ;;
    *)
      print -P "  %F{245}Cancelled.%f"; sleep 0.3
      ;;
  esac

  zle reset-prompt
}
