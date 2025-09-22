#!/bin/bash
set -Eeuo pipefail

# Creates a new branch from the default branch, applies current working changes,
# commits, pushes, and opens a PR. Outputs PR metadata as YAML to stdout and
# writes PR number to $PR_NUMBER_OUT if set (defaults to .terrateam/pr_number).
#
# Inputs (env):
#   COMMIT_MSG         Commit message (required if there are changes)
#   PR_TITLE           PR title (defaults to COMMIT_MSG)
#   PR_BODY            PR body (optional)
#   NEW_BRANCH_NAME    Exact new branch name (optional)
#   BRANCH_PREFIX      Prefix for generated branch (default: tt/auto)
#   REQUIRE_APP_TOKEN  If "true", require app token from SECRETS_CONTEXT
#   SECRETS_CONTEXT    JSON with {"github_token":"..."}
#   GITHUB_TOKEN       Fallback token when REQUIRE_APP_TOKEN!=true
#   GITHUB_REPOSITORY  owner/repo (auto-detected if missing)
#   PR_NUMBER_OUT      File path to save PR number (default: .terrateam/pr_number)
#   DRY_RUN            If "1", simulate network calls and git push
#
# Behavior:
#   - Detects changed/untracked and deleted files in current repo
#   - Clones the repo shallowly at default branch into a temp dir
#   - Creates a new branch from default, copies differences, commits and pushes
#   - Creates PR via GitHub API and prints YAML summary

if [ "${TRACE:-}" = "1" ]; then set -x; fi

__fail() { echo "❌ $*" 1>&2; exit 1; }

SRC_REPO_DIR=$(pwd)

# Token selection (prefer SECRETS_CONTEXT.github_token)
REQUIRE_APP_TOKEN="${REQUIRE_APP_TOKEN:-false}"
TOKEN=""
if [ -n "${SECRETS_CONTEXT:-}" ]; then
  if command -v jq >/dev/null 2>&1; then
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | jq -r '.github_token // empty')"
  else
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | sed -n 's/.*"github_token"\s*:\s*"\([^"]\+\)".*/\1/p')"
  fi
fi
if [ -z "$TOKEN" ] && [ -n "${GITHUB_TOKEN:-}" ] && [ "$REQUIRE_APP_TOKEN" != "true" ]; then
  TOKEN="${GITHUB_TOKEN}"
fi
if [ -z "$TOKEN" ] && [ "${DRY_RUN:-}" != "1" ]; then
  __fail "No GitHub token available (SECRETS_CONTEXT.github_token or GITHUB_TOKEN)"
fi

# Repo detection
REPO="${GITHUB_REPOSITORY:-}"
if [ -z "$REPO" ]; then
  if git -C "$SRC_REPO_DIR" config --get remote.origin.url >/dev/null 2>&1; then
    REPO=$(git -C "$SRC_REPO_DIR" config --get remote.origin.url | sed -E 's#.*github.com[:/]|\.git$##g')
  fi
fi
[ -n "$REPO" ] || __fail "Cannot determine repository (set GITHUB_REPOSITORY)"

# Determine default branch from remote
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
[ -n "$DEFAULT_BRANCH" ] || DEFAULT_BRANCH=main

# Gather changes in current working tree
mapfile -t CHANGED < <(git -C "$SRC_REPO_DIR" ls-files -m -o --exclude-standard)
mapfile -t DELETED < <(git -C "$SRC_REPO_DIR" ls-files -d || true)

if [ ${#CHANGED[@]} -eq 0 ] && [ ${#DELETED[@]} -eq 0 ]; then
  echo "No local changes to propose; nothing to do." 1>&2
  exit 0
fi

COMMIT_MSG="${COMMIT_MSG:-}"
[ -n "$COMMIT_MSG" ] || __fail "COMMIT_MSG is required when changes exist"

PR_TITLE="${PR_TITLE:-$COMMIT_MSG}"
PR_BODY="${PR_BODY:-}"

# Branch naming
if [ -n "${NEW_BRANCH_NAME:-}" ]; then
  NEW_BRANCH="$NEW_BRANCH_NAME"
else
  BRANCH_PREFIX="${BRANCH_PREFIX:-tt/auto}"
  TS=$(date +%Y%m%d-%H%M%S)
  NEW_BRANCH="${BRANCH_PREFIX}/${TS}"
fi

# Temp clone
WORKDIR=$(mktemp -d 2>/dev/null || mktemp -d -t ttnew)
echo "➡️  Working directory: $WORKDIR" 1>&2

cd "$WORKDIR"

GIT_SSH_COMMAND="" # do not use ssh
if [ "${DRY_RUN:-}" = "1" ]; then
  echo "[DRY_RUN] Would clone https://github.com/${REPO}.git@${DEFAULT_BRANCH}" 1>&2
  mkdir -p repo && cd repo && git init -q && git remote add origin "https://github.com/${REPO}.git" && git checkout -q -b "$DEFAULT_BRANCH"
else
  git clone --depth=1 --branch "$DEFAULT_BRANCH" "https://x-access-token:${TOKEN}@github.com/${REPO}.git" repo 1>&2
  cd repo
fi

# Git identity and safety inside containers
git config --global safe.directory "$(pwd)" || true
git config user.name  "${GITHUB_ACTOR:-ci-bot}"
git config user.email "${GITHUB_ACTOR_ID:-0}+${GITHUB_ACTOR:-ci-bot}@users.noreply.github.com"

# Create new branch
git switch -c "$NEW_BRANCH" 1>&2

# Apply file changes: copy modified/untracked, remove deleted
for f in "${CHANGED[@]}"; do
  # ensure dir exists
  mkdir -p "$(dirname -- "$f")"
  # copy from source repo
  cp -p "$SRC_REPO_DIR/$f" "$f"
done

if [ ${#DELETED[@]} -gt 0 ]; then
  git rm -f -- "${DELETED[@]}" >/dev/null 2>&1 || true
fi

git add -A
if git diff --cached --quiet; then
  echo "No effective changes after applying diffs. Exiting." 1>&2
  exit 0
fi

git commit -m "$COMMIT_MSG" 1>&2

if [ "${DRY_RUN:-}" = "1" ]; then
  echo "[DRY_RUN] Would push branch $NEW_BRANCH to origin" 1>&2
else
  git -c http.extraheader= -c http.https://github.com/.extraheader= push -u origin "$NEW_BRANCH" 1>&2
fi

# Create PR via GitHub API
PR_JSON="{}"
API_URL="https://api.github.com/repos/${REPO}/pulls"
OWNER_HEAD="${REPO%%/*}:$NEW_BRANCH"

if command -v jq >/dev/null 2>&1; then
  PAYLOAD=$(jq -n --arg t "$PR_TITLE" --arg h "$OWNER_HEAD" --arg b "$DEFAULT_BRANCH" --arg body "$PR_BODY" '{title:$t, head:$h, base:$b, body:$body, draft:false}')
else
  BODY_CLEAN=$(printf '%s' "$PR_BODY" | tr '\n' ' ')
  PAYLOAD=$(printf '{"title":"%s","head":"%s","base":"%s","body":"%s","draft":false}' \
    "${PR_TITLE//\"/\\\"}" "${OWNER_HEAD//\"/\\\"}" "${DEFAULT_BRANCH//\"/\\\"}" "${BODY_CLEAN//\"/\\\"}")
fi

if [ "${DRY_RUN:-}" = "1" ]; then
  PR_JSON='{"number":123,"state":"open","html_url":"https://example.local/pr/123","title":"DRY RUN PR","base":{"ref":"'"$DEFAULT_BRANCH"'"},"head":{"ref":"'"$NEW_BRANCH"'"}}'
else
  PR_JSON=$(curl -sS -X POST \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Content-Type: application/json" \
    --data-raw "$PAYLOAD" "$API_URL")
fi

# Extract fields and output YAML
if command -v jq >/dev/null 2>&1; then
  NUMBER=$(printf '%s' "$PR_JSON" | jq -r '.number // empty')
  STATE=$(printf '%s' "$PR_JSON" | jq -r '.state // "open"')
  URL=$(printf '%s' "$PR_JSON" | jq -r '.html_url // empty')
  BASE_REF=$(printf '%s' "$PR_JSON" | jq -r '.base.ref // ""')
  HEAD_REF=$(printf '%s' "$PR_JSON" | jq -r '.head.ref // ""')
  TITLE_OUT=$(printf '%s' "$PR_JSON" | jq -r '.title // ""')
else
  NUMBER=$(printf '%s' "$PR_JSON" | sed -n 's/.*"number":\s*\([0-9]\+\).*/\1/p')
  STATE=$(printf '%s' "$PR_JSON" | sed -n 's/.*"state":"\([^"]\+\)".*/\1/p')
  URL=$(printf '%s' "$PR_JSON" | sed -n 's/.*"html_url":"\([^"]\+\)".*/\1/p')
  BASE_REF=$(printf '%s' "$PR_JSON" | sed -n 's/.*"base".*"ref":"\([^"]\+\)".*/\1/p')
  HEAD_REF=$(printf '%s' "$PR_JSON" | sed -n 's/.*"head".*"ref":"\([^"]\+\)".*/\1/p')
  TITLE_OUT=$(printf '%s' "$PR_JSON" | sed -n 's/.*"title":"\([^"]\+\)".*/\1/p')
fi

if [ -z "$NUMBER" ]; then
  echo "❌ Failed to create PR" 1>&2
  echo "$PR_JSON" 1>&2
  exit 1
fi

echo "---"
echo "number: $NUMBER"
echo "state: ${STATE:-open}"
TITLE_Q=$(printf '%s' "$TITLE_OUT" | sed 's/"/\\"/g')
URL_Q=$(printf '%s' "$URL" | sed 's/"/\\"/g')
echo "title: \"$TITLE_Q\""
echo "url: \"$URL_Q\""
echo "base: ${BASE_REF:-$DEFAULT_BRANCH}"
echo "head: ${HEAD_REF:-$NEW_BRANCH}"

# Save PR number if requested
PR_NUMBER_OUT="${PR_NUMBER_OUT:-$SRC_REPO_DIR/.terrateam/pr_number}"
mkdir -p "$(dirname "$PR_NUMBER_OUT")" 2>/dev/null || true
printf '%s' "$NUMBER" > "$PR_NUMBER_OUT"
echo "Saved PR number to $PR_NUMBER_OUT" 1>&2

echo "✅ Created PR #$NUMBER: $URL" 1>&2

