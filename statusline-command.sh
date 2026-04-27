#!/usr/bin/env bash
# Claude Code status line script
# Shows: git branch | model | context usage | token counts

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
output_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')

# Get git branch (skip optional locks to avoid conflicts)
branch=""
if [ -n "$cwd" ] && [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# Build output parts
parts=()

# Git branch
if [ -n "$branch" ]; then
  parts+=("$(printf '\033[36m\xef\x94\xa0 %s\033[0m' "$branch")")
fi

# Model
if [ -n "$model" ]; then
  parts+=("$(printf '\033[35m\xe2\xa7\xab %s\033[0m' "$model")")
fi

# Context usage
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -ge 80 ]; then
    color='\033[31m'  # red
  elif [ "$used_int" -ge 50 ]; then
    color='\033[33m'  # yellow
  else
    color='\033[32m'  # green
  fi
  parts+=("$(printf "${color}ctx: %s%% used\033[0m" "$used_int")")
fi

# Token counts (only when available)
if [ -n "$input_tokens" ] && [ -n "$output_tokens" ]; then
  parts+=("$(printf '\033[90min:%s out:%s\033[0m' "$input_tokens" "$output_tokens")")
fi

# Join with separator
(IFS='  '; printf '%s' "${parts[*]}")
