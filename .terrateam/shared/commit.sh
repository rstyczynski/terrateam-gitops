#!/bin/bash

set -euo pipefail

# 1) Get token: prefer $GITHUB_TOKEN if present, else parse from $SECRETS_CONTEXT
TOKEN="${GITHUB_TOKEN:-}"
if [ -z "${TOKEN}" ] && [ -n "${SECRETS_CONTEXT:-}" ]; then
  # jq path (preferred)
  if command -v jq >/dev/null 2>&1; then
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | jq -r '.github_token')"
  else
    # Fallback parser (no jq)
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | sed -n 's/.*"github_token":[[:space:]]*"\([^"]*\)".*/\1/p')"
  fi
fi
[ -n "$TOKEN" ] || { echo "No GitHub token available"; exit 1; }

# 2) Figure out the branch name (PR vs direct branch runs)
BRANCH="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME}}"
[ -n "$BRANCH" ] || { echo "Cannot determine branch"; exit 1; }

# 3) Configure git identity
git config user.name  "${GITHUB_ACTOR:-terrateam-action[bot]}"
git config user.email "${GITHUB_ACTOR_ID:-0}+bot@users.noreply.github.com"

# 4) Make your changes…
# (example) terraform fmt -recursive || true

# 5) Commit only if there are changes
if ! git diff --quiet; then
  git add -A
  git commit -m "Automated update from Terrateam job"

  # 6) Push back to the same repo/branch using the token
  REPO="${GITHUB_REPOSITORY:?}"  # e.g., rstyczynski/terrateam-gitops
  git push "https://x-access-token:${TOKEN}@github.com/${REPO}.git" "HEAD:${BRANCH}"
else
  echo "No changes to commit."
fi