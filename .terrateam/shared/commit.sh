#!/bin/bash

set -euo pipefail

# mark workspace as safe
git config --global safe.directory /github/workspace

echo "GitHub actor: ${GITHUB_ACTOR:-unknown}"
echo "Repository: ${GITHUB_REPOSITORY:-unknown}"
echo "Head ref: ${GITHUB_HEAD_REF:-}"
echo "Ref name: ${GITHUB_REF_NAME:-}"

# 1) Get token: prefer SECRETS_CONTEXT.github_token; fallback to GITHUB_TOKEN.
REQUIRE_APP_TOKEN="${REQUIRE_APP_TOKEN:-true}"
TOKEN=""
_src="none"

if [ -n "${SECRETS_CONTEXT:-}" ]; then
  if command -v jq >/dev/null 2>&1; then
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | jq -r '.github_token // empty')"
  else
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | sed -n 's/.*"github_token":[[:space:]]*"\([^"]*\)".*/\1/p')"
  fi
  if [ -n "$TOKEN" ]; then _src="terrateam_app_token"; fi
fi

if [ -z "$TOKEN" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  TOKEN="${GITHUB_TOKEN}"
  _src="github_actions_token"
fi

if [ "$REQUIRE_APP_TOKEN" = "true" ] && [ "$_src" = "github_actions_token" ]; then
  echo "Refusing to push with github-actions[bot] token."
  echo "Tip: enable 'contents: write' in workflow permissions or ensure Terrateam app token is exposed."
  exit 1
fi

[ -n "$TOKEN" ] || { echo "No GitHub token available (SECRETS_CONTEXT.github_token or GITHUB_TOKEN)"; exit 1; }


echo "Using token source: ${_src}"

# Force our credentials (avoid cached helpers using github-actions[bot])
git config --global credential.helper ""
git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
echo "Remote (sanitized): https://x-access-token:***@github.com/${GITHUB_REPOSITORY}.git"

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
  echo "Preparing commit for branch ${BRANCH}"
  git commit -m "Add generated file"
  if ! git push origin "HEAD:${BRANCH}"; then
    git pull --rebase origin "${BRANCH}"
    git push origin "HEAD:${BRANCH}"
  fi
else
  echo "No changes to commit."
fi