# lib/api.zsh — Ollama REST API wrapper

# Main API call — uses REST directly (faster than `ollama run` CLI)
ai_call() {
  local prompt="$1"
  local system="${2:-You are a Linux shell expert. Output only the requested content. No markdown, no backticks, no explanation.}"
  local timeout_s="${3:-$ZSH_AI_TIMEOUT_COMMAND}"
  local max_tokens="${4:-$ZSH_AI_TOKENS_COMMAND}"

  local escaped_prompt escaped_system
  escaped_prompt=$(printf '%s' "$prompt" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')
  escaped_system=$(printf '%s' "$system" | sed 's/\\/\\\\/g; s/"/\\"/g')

  local payload="{\"model\":\"${ZSH_AI_MODEL}\",\"prompt\":\"${escaped_prompt}\",\"system\":\"${escaped_system}\",\"stream\":false,\"options\":{\"temperature\":0.1,\"num_predict\":${max_tokens}}}"

  local response
  response=$(curl -sf \
    --max-time "$timeout_s" \
    -X POST "${ZSH_AI_OLLAMA_URL}/api/generate" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null) || return 1

  # Extract "response" field — no jq dependency
  printf '%s' "$response" | \
    grep -o '"response":"[^"]*"' | \
    sed 's/^"response":"//; s/"$//' | \
    sed 's/\\n/\n/g; s/\\t/\t/g; s/\\\\/\\/g' | \
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# Strip code fences, prompt chars, comment lines, blank lines from AI output
ai_clean_output() {
  sed -e 's/^```[a-zA-Z]*[[:space:]]*//' \
      -e 's/```[[:space:]]*//' \
      -e 's/^[[:space:]]*\$[[:space:]]*//' \
      -e 's/^[[:space:]]*#[[:space:]].*$//' \
      -e '/^[[:space:]]*$/d' \
      -e 's/[[:space:]]*$//'
}
