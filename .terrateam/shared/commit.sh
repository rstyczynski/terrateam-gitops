#!/bin/bash
set -euo pipefail

# Make workspace safe for git inside containers
git config --global safe.directory /github/workspace

# --- Token selection (simple & robust) ---
# Prefer Terrateam app token from SECRETS_CONTEXT; fall back to GITHUB_TOKEN unless REQUIRE_APP_TOKEN=true
REQUIRE_APP_TOKEN="${REQUIRE_APP_TOKEN:-false}"
TOKEN=""
if [ -n "${SECRETS_CONTEXT:-}" ]; then
  if command -v jq >/dev/null 2>&1; then
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | jq -r '.github_token // empty')"
  else
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | sed -n 's/.*"github_token":[[:space:]]*"\([^"]*\)".*/\1/p')"
  fi
fi
if [ -z "$TOKEN" ] && [ -n "${GITHUB_TOKEN:-}" ] && [ "$REQUIRE_APP_TOKEN" != "true" ]; then
  TOKEN="${GITHUB_TOKEN}"
fi
[ -n "$TOKEN" ] || { echo "No GitHub token available (SECRETS_CONTEXT.github_token or GITHUB_TOKEN)"; exit 1; }

# --- Repo / branch ---
REPO="${GITHUB_REPOSITORY:?}"
BRANCH="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}"
[ -n "$BRANCH" ] || { echo "Cannot determine branch"; exit 1; }

# --- Identity ---
git config user.name  "${GITHUB_ACTOR:-ci-bot}"
git config user.email "${GITHUB_ACTOR_ID:-0}+${GITHUB_ACTOR:-ci-bot}@users.noreply.github.com"

# --- Remote with token ---
git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${REPO}.git"

# --- Stage & commit only when needed ---
git add -A
if git diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

COMMIT_MSG="${COMMIT_MSG:-Automated update by Terrateam}"
git commit -m "$COMMIT_MSG"

# --- Push with one rebase-retry ---
if ! git -c http.extraheader= -c http.https://github.com/.extraheader= push origin "HEAD:${BRANCH}"; then
  git -c http.extraheader= -c http.https://github.com/.extraheader= pull --rebase origin "${BRANCH}"
  git -c http.extraheader= -c http.https://github.com/.extraheader= push origin "HEAD:${BRANCH}"
fi

echo "Pushed ${REPO}@${BRANCH}"