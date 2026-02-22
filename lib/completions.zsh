# lib/completions.zsh — Smart autocomplete widget (Ctrl-S)

# ─────────────────────────────────────────────
# STATIC COMPLETIONS TABLE
# Values are pipe-separated SUFFIXES (what follows "cmd ").
# ─────────────────────────────────────────────
declare -A _AI_STATIC
_AI_STATIC=(
  [git]="status|add .|commit -m ''|push|push --force-with-lease|pull --rebase|fetch --all|log --oneline --graph --decorate|branch -a|checkout -b|diff HEAD|stash|stash pop|rebase -i HEAD~3|cherry-pick|tag|remote -v"
  [git\ log]="--oneline|--oneline --graph --decorate --all|--author='Name'|--since='1 week ago'|--stat|-p --follow --all"
  [git\ diff]="HEAD|--staged|HEAD~1|main...feature|--name-only|--word-diff"
  [git\ checkout]="main|develop|-b feature/|-b fix/|-- ."
  [git\ stash]="pop|list|drop|apply|show -p"
  [docker]="ps|ps -a|images|run -it --rm|build -t .|compose up -d|compose down|compose logs -f|logs -f|exec -it|system prune -f|volume ls|network ls|inspect|stats"
  [docker\ compose]="up -d|down|logs -f|ps|restart|build --no-cache|pull|exec"
  [kubectl]="get pods|get svc|get nodes|get all|describe pod|apply -f|delete -f|logs -f|exec -it|rollout status|rollout restart deploy|get all -n kube-system|port-forward|scale deploy"
  [apt]="install|update|upgrade|remove|purge|autoremove|search|list --installed|show|policy"
  [apt-get]="install|update|upgrade|remove|purge|autoremove|dist-upgrade"
  [ls]="-la|-lh|-ltr|-la --color|-la --group-directories-first|--sort=size -lh"
  [find]=". -name '*.py'|. -type f -size +100M|. -mtime -7|. -name '*.log'|. -empty -delete|. -type f -newer /tmp/ref|. -name '*.py' -exec grep -l 'TODO' {} +"
  [grep]="-r|-rn|--include='*.py'|--color=always|-v|-E|-l|-ri|-rn --include='*.js'"
  [systemctl]="status|start|stop|restart|enable|disable|list-units --failed|daemon-reload|is-active|is-enabled|list-timers"
  [ssh]="-i ~/.ssh/id_rsa|-L 8080:localhost:8080|-R|-N -f|-o StrictHostKeyChecking=no|-v"
  [rsync]="-avz --progress|--delete|-avz --exclude '.git'|--dry-run -avz|--checksum"
  [tar]="czf archive.tar.gz|xzf archive.tar.gz|xjf archive.tar.bz2|tzf archive.tar.gz"
  [curl]="-s|-X POST -H 'Content-Type: application/json' -d|-o output.file|-L --progress-bar|--retry 3 -sf|-I|-u user:pass"
  [python3]="-m http.server 8080|-m venv .venv|-m pip install|-m pip install -r requirements.txt|-c|-u"
  [npm]="install|install --save-dev|run dev|run build|run test|update|audit fix|list -g --depth=0|ci"
  [cargo]="build|build --release|run|test|clippy|fmt|add|update|doc --open"
  [make]="install|clean|test|all|--dry-run|-B"
  [sed]="-i 's/old/new/g'|-n '/pattern/p'|-E 's/(a|b)/c/'|-i.bak 's/foo/bar/g'"
  [awk]="'{print \$1}'|'{print NF}'|'{sum+=\$1} END{print sum}'|-F, '{print \$2}'|'NR>1 {print}'|'!seen[\$0]++'"
  [jq]=".|.[]|.key|keys|length|select(.key==\"val\")|map(select(.))|to_entries|from_entries"
  [ps]="aux|aux | grep|-eo pid,comm,pcpu,pmem --sort=-%cpu|--forest"
  [df]="-h|-hT|--total -h"
  [du]="-sh *|-h --max-depth=1|-sh --exclude=.git"
  [ss]="-tulpn|-an|-s|--tcp state established"
  [ip]="addr show|route show|link show|neigh show"
  [journalctl]="-f|-u nginx|-xe|--since '1 hour ago'|--no-pager -p err|-b -p warning"
  [chmod]="755|644|+x|-R 755|u+x,go-wx|a-x"
  [pip]="install|install -r requirements.txt|freeze > requirements.txt|list --outdated|show|uninstall -y"
  [go]="build .|run .|test ./...|mod tidy|get -u|install|generate"
  [terraform]="init|plan|apply -auto-approve|destroy|fmt -recursive|validate|output -json"
  [ffmpeg]="-i input.mp4 -c:v libx264 -c:a aac output.mp4|-i input.mp4 -vf scale=1280:720|-ss 00:00:30 -t 60|-i input.mp4 -an"
  [vim]="+/pattern|+'%s/old/new/g'|-u NONE|-p file1 file2|+'set paste'"
)

# ─────────────────────────────────────────────
# SMART AUTOCOMPLETE WIDGET
#
#  Buffer model:
#    [prefix_before_token][active_token][tail_of_token][after_word]
#    e.g. "git sta|tus" (cursor after 'a'):
#      prefix_before_token = "git "
#      active_token        = "sta"    ← typed before cursor
#      tail_of_token       = "tus"    ← rest of word after cursor
#      after_word          = ""       ← space + anything after the word
#
#  On selection, active_token + tail_of_token are BOTH replaced,
#  so "git sta|tus" + "status" → "git status", never "git statustus".
# ─────────────────────────────────────────────
ai_suggest_command() {
  local full_buffer="$BUFFER"
  local cursor_pos=$CURSOR

  if [[ -z "$full_buffer" ]]; then
    zle -M "⚡ Type a partial command first, then press ${ZSH_AI_KEY_COMPLETE}"
    sleep 1; zle -M ""; return
  fi

  # ── 1. Split buffer at cursor
  local before_cursor="${full_buffer:0:$cursor_pos}"
  local from_cursor="${full_buffer:$cursor_pos}"

  # ── 2. Active token = word fragment before cursor
  local active_token="" prefix_before_token=""
  if [[ "$before_cursor" =~ ^(.*[[:space:]])([^[:space:]]*)$ ]]; then
    prefix_before_token="${match[1]}"
    active_token="${match[2]}"
  else
    prefix_before_token=""
    active_token="$before_cursor"
  fi

  # ── 3. Tail = rest of the current word after cursor (must be consumed on replace)
  local tail_of_token="" after_word=""
  if [[ "$from_cursor" =~ ^([^[:space:]]*)(.*)$ ]]; then
    tail_of_token="${match[1]}"
    after_word="${match[2]}"
  fi

  local full_current_token="${active_token}${tail_of_token}"
  local cmd_base="${full_buffer%% *}"

  # ── 4. Two-word static key (e.g. "git log", "docker compose")
  local cmd_two_key=""
  if [[ "$full_buffer" == *" "* ]]; then
    local _first="${full_buffer%% *}"
    local _second="${${full_buffer#* }%% *}"
    if [[ "$prefix_before_token" == *" "* || -n "$active_token" ]]; then
      cmd_two_key="${_first}\\ ${_second}"
    fi
  fi

  local suggestions=""

  # ── 5. Static lookup (instant — no AI)
  if [[ -n "$cmd_two_key" && -n "${_AI_STATIC[$cmd_two_key]}" ]]; then
    suggestions=$(printf '%s' "${_AI_STATIC[$cmd_two_key]}" | tr '|' '\n')
  elif [[ -n "${_AI_STATIC[$cmd_base]}" ]]; then
    suggestions=$(printf '%s' "${_AI_STATIC[$cmd_base]}" | tr '|' '\n')
  fi

  # ── 6. Filter static by typed prefix (with glob-safe quoting)
  if [[ -n "$active_token" && "$active_token" != "$cmd_base" && -n "$suggestions" ]]; then
    local _escaped_token
    _escaped_token=$(printf '%s' "$active_token" | sed 's/[.[\*^$]/\\&/g')
    local filtered
    filtered=$(printf '%s\n' "$suggestions" | grep -i "^${_escaped_token}" 2>/dev/null)
    [[ -n "$filtered" ]] && suggestions="$filtered"
  fi

  # ── 7. AI fallback when static has no match
  if [[ -z "$suggestions" ]]; then
    ai_ensure_ollama || return
    zle -M "⟳ AI completing..."

    local ai_prompt
    if [[ -n "$active_token" && "$active_token" != "$cmd_base" ]]; then
      ai_prompt="Shell completion. Command so far: '${full_buffer}'. Completing token '${full_current_token}'. List 10 completions for that token only. One per line. No explanation. Do NOT repeat '${cmd_base}'."
    else
      ai_prompt="Shell completion. Command so far: '${before_cursor}'. List 10 useful arguments/flags/subcommands that follow. Output ONLY the suffixes, one per line, no explanation."
    fi

    suggestions=$(ai_call "$ai_prompt" \
      "You are a zsh completion engine. Output only raw completion strings, one per line. Never echo back the command name or full command. No markdown, no numbers, no explanation." \
      "$ZSH_AI_TIMEOUT_COMPLETE" "$ZSH_AI_TOKENS_COMPLETE" | ai_clean_output)

    zle -M ""
  fi

  [[ -z "$suggestions" ]] && {
    zle -M "✗ No completions found"; sleep 0.8; zle -M ""; return
  }

  # ── 8. Deduplicate & clean
  #   a) Remove blank lines
  #   b) Strip "cmd_base " prefix if AI echoed it back
  #   c) Remove entries identical to what's already typed
  #   d) Remove order-preserving duplicates
  local _safe_cmd
  _safe_cmd=$(printf '%s' "$cmd_base" | sed 's/[.[\*^$]/\\&/g')
  local cleaned
  cleaned=$(printf '%s\n' "$suggestions" \
    | grep -v '^[[:space:]]*$' \
    | sed "s|^${_safe_cmd}[[:space:]]\+||" \
    | grep -Fxv "$full_current_token" \
    | grep -Fxv "$before_cursor" \
    | awk '!seen[$0]++' \
    | grep -v '^[[:space:]]*$')

  [[ -z "$cleaned" ]] && {
    zle -M "✓ Already complete — no new suggestions"; sleep 0.8; zle -M ""; return
  }

  # ── 9. Present via fzf or numbered menu
  local selected=""

  if command -v fzf >/dev/null 2>&1; then
    # fzf takes over the terminal — tell ZLE we're doing that
    zle -I
    local fzf_preview
    if [[ -n "$full_current_token" ]]; then
      fzf_preview="printf '❯ %s\n' '${prefix_before_token}{}${after_word}'"
    else
      local _fsep=" "
      [[ "$before_cursor" == *" " ]] && _fsep=""
      fzf_preview="printf '❯ %s\n' '${before_cursor}${_fsep}{}${after_word}'"
    fi

    # Both stdin and stdout go through /dev/tty so fzf owns the terminal cleanly
    selected=$(printf '%s\n' "$cleaned" | fzf \
      --prompt="complete ❯ " \
      --height=14 --layout=reverse --border=rounded \
      --info=hidden \
      --preview="$fzf_preview" --preview-window="up:1:wrap" \
      --header="↵ select   ESC cancel" \
      </dev/tty 2>/dev/tty)
  else
    # Numbered menu fallback — all output to /dev/tty
    zle -I
    printf '\n' >/dev/tty
    local i=1 lines=()
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if [[ -n "$full_current_token" ]]; then
        print -P "  %F{green}${i})%f ${prefix_before_token}%F{yellow}${line}%f${after_word}" >/dev/tty
      else
        local _sep=" "; [[ "$before_cursor" == *" " ]] && _sep=""
        print -P "  %F{green}${i})%f ${before_cursor}${_sep}%F{yellow}${line}%f${after_word}" >/dev/tty
      fi
      lines+=("$line"); (( i++ ))
    done <<< "$cleaned"

    printf '  Choice [1-%d] (0 cancel): ' "${#lines[@]}" >/dev/tty
    local choice; read -r choice </dev/tty
    if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && (( choice >= 1 && choice <= ${#lines[@]} )); then
      selected="${lines[$choice]}"
    fi
  fi

  # ── 10. Reconstruct buffer — replace active+tail, keep rest
  if [[ -n "$selected" ]]; then
    if [[ -n "$full_current_token" && "$full_current_token" != "$cmd_base" ]]; then
      # REPLACE mode: swap out the full current word fragment
      BUFFER="${prefix_before_token}${selected}${after_word}"
      CURSOR=$(( ${#prefix_before_token} + ${#selected} ))
    else
      # APPEND mode: add after command
      local _sep=" "; [[ "$before_cursor" == *" " ]] && _sep=""
      BUFFER="${before_cursor}${_sep}${selected}${after_word}"
      CURSOR=$(( ${#before_cursor} + ${#_sep} + ${#selected} ))
    fi
    (( CURSOR > ${#BUFFER} )) && CURSOR=${#BUFFER}
    (( CURSOR < 0 ))          && CURSOR=0
  fi

  zle reset-prompt
}
