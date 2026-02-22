# lib/lifecycle.zsh — Ollama process lifecycle management

_AI_OLLAMA_PID=""
_AI_OLLAMA_STARTED_BY_US=false
_AI_TEMP_FILE="$(mktemp /tmp/.zsh_ai_XXXXXX 2>/dev/null || echo /tmp/.zsh_ai_$$)"

_ai_cleanup() {
  rm -f "$_AI_TEMP_FILE"
  if [[ "$_AI_OLLAMA_STARTED_BY_US" == true ]] &&
     [[ -n "$_AI_OLLAMA_PID" ]] &&
     kill -0 "$_AI_OLLAMA_PID" 2>/dev/null; then
    kill "$_AI_OLLAMA_PID" 2>/dev/null
  fi
}
trap _ai_cleanup EXIT

ai_ensure_ollama() {
  curl -sf --max-time 1 "${ZSH_AI_OLLAMA_URL}/api/tags" > /dev/null 2>&1 && return 0

  if ! command -v ollama > /dev/null 2>&1; then
    print -P "%F{red}  ✗ Ollama not installed.%f"
    print -P "%F{245}    Install from: https://ollama.ai%f"
    return 1
  fi

  print -P "  %F{245}⟳ Starting Ollama...%f"
  ollama serve > /dev/null 2>&1 &
  _AI_OLLAMA_PID=$!
  _AI_OLLAMA_STARTED_BY_US=true

  local retries=0
  until curl -sf "${ZSH_AI_OLLAMA_URL}/api/tags" > /dev/null 2>&1; do
    sleep 0.3
    (( retries++ ))
    if (( retries > 30 )); then
      print -P "%F{red}  ✗ Ollama failed to start after 9s%f"
      return 1
    fi
  done
  print -P "  %F{green}  ✓ Ollama ready%f"
}

# Convenience function: switch model at runtime
ai_model() {
  if [[ -z "$1" ]]; then
    print -P "%F{cyan}Current model:%f $ZSH_AI_MODEL"
    print -P "%F{245}Installed models:%f"
    ollama list 2>/dev/null | awk 'NR>1 {printf "  %s\n", $1}' || \
      print -P "  %F{245}(ollama not running)%f"
    return
  fi
  export ZSH_AI_MODEL="$1"
  _AI_STATUS_TIME=0   # force RPROMPT cache refresh
  print -P "%F{green}✓ Switched to: $ZSH_AI_MODEL%f"
}
