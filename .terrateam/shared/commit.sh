#!/bin/bash

set -euo pipefail

# mark workspace as safe
git config --global safe.directory /github/workspace

# 1) Get token: prefer SECRETS_CONTEXT.github_token; fallback to GITHUB_TOKEN.
TOKEN=""
if [ -n "${SECRETS_CONTEXT:-}" ]; then
  # Prefer Terrateam app token
  if command -v jq >/dev/null 2>&1; then
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | jq -r '.github_token // empty')"
  else
    # Fallback parser (no jq)
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | sed -n 's/.*"github_token":[[:space:]]*"\([^"]*\)".*/\1/p')"
  fi
fi
# Fallback to GITHUB_TOKEN only if not provided by SECRETS_CONTEXT
if [ -z "$TOKEN" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  TOKEN="${GITHUB_TOKEN}"
fi
[ -n "$TOKEN" ] || { echo "No GitHub token available (SECRETS_CONTEXT.github_token or GITHUB_TOKEN)"; exit 1; }

# 2) Figure out the branch name (PR vs direct branch runs)
BRANCH="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME}}"
[ -n "$BRANCH" ] || { echo "Cannot determine branch"; exit 1; }

# 3) Configure git identity
git config user.name  "${GITHUB_ACTOR:-terrateam-action[bot]}"
git config user.email "${GITHUB_ACTOR_ID:-0}+${GITHUB_ACTOR:-bot}@users.noreply.github.com"

# 4) Make your changes…
# (example) terraform fmt -recursive || true

# 5) Commit only if there are changes
git add -A
if ! git diff --cached --quiet; then
  git commit -m "Add generated file"
  if ! git push "https://x-access-token:${TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "HEAD:${BRANCH}"; then
    git pull --rebase origin "${BRANCH}"
    git push "https://x-access-token:${TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "HEAD:${BRANCH}"
  fi
else
  echo "No changes to commit."
fi