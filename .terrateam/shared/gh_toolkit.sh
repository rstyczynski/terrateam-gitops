#!/bin/bash
set -Eeuo pipefail
# Optional: TRACE=1 enables xtrace
if [ "${TRACE:-}" = "1" ]; then set -x; fi

# Uniform error handler
__on_err() {
  local rc=$?
  echo "❌ Error (exit $rc) at line ${BASH_LINENO[0]:-?} in ${BASH_SOURCE[1]:-main}" 1>&2
  echo "   Last API URL: ${API_LAST_URL:-n/a}" 1>&2
  echo "   Hint: try DRY_RUN=1 to simulate, or set GITHUB_REPOSITORY and GITHUB_TOKEN" 1>&2
  exit $rc
}
trap __on_err ERR

#
# terrateam helper: commit, create PR, and check PR status
#
# Usage examples:
#   commit current repo (existing behavior):
#     ./commit.sh commit
#
#   create a PR from current branch to default base:
#     PR_TITLE="Update locks" PR_BODY="…" ./commit.sh create-pr
#   create a PR with explicit base/head and as draft:
#     BASE_BRANCH=main HEAD_BRANCH=my/feature DRAFT=true PR_TITLE="Feat" ./commit.sh create-pr
#
#   check PR status by number:
#     PR_NUMBER=123 ./commit.sh pr-status
#   or by head branch (and optional base):
#     HEAD_BRANCH=my/feature BASE_BRANCH=main ./commit.sh pr-status
#
# Required auth (same precedence as before):
#   1) SECRETS_CONTEXT.github_token (Terrateam app token)
#   2) GITHUB_TOKEN (if REQUIRE_APP_TOKEN!=true)
#

echo "🚀 START: terrateam git helpers ($*)" 1>&2

API_STATE_DIR="${TMPDIR:-/tmp}/gh_toolkit"
mkdir -p "$API_STATE_DIR" || true

# --- Token selection (simple & robust) ---
REQUIRE_APP_TOKEN="${REQUIRE_APP_TOKEN:-false}"
TOKEN=""
if [ -n "${SECRETS_CONTEXT:-}" ]; then
  if command -v jq >/dev/null 2>&1; then
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | jq -r '.github_token // empty')"
  else
    TOKEN="$(printf '%s' "$SECRETS_CONTEXT" | sed -n 's/.*"github_token":[[:space:]]*"\([^"[:space:]]*\)".*/\1/p')"
  fi
fi
if [ -z "$TOKEN" ] && [ -n "${GITHUB_TOKEN:-}" ] && [ "$REQUIRE_APP_TOKEN" != "true" ]; then
  TOKEN="${GITHUB_TOKEN}"
fi
if [ -z "$TOKEN" ] && [ "${DRY_RUN:-}" != "1" ]; then
  echo "No GitHub token available (SECRETS_CONTEXT.github_token or GITHUB_TOKEN)"
  exit 1
fi

# --- Repo / branch helpers ---
REPO="${GITHUB_REPOSITORY:-$(git config --get remote.origin.url | sed -E 's#.*github.com[:/]|\.git$##g') }"
[ -n "$REPO" ] || { echo "Cannot determine repository (GITHUB_REPOSITORY unset and unable to parse origin)"; exit 1; }

current_branch() {
  if [ -n "${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}" ]; then
    printf '%s' "${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}"
  else
    git rev-parse --abbrev-ref HEAD
  fi
}

# Determine remote default branch (e.g., main or master)
remote_default_branch() {
  git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p'
}

# Git identity
setup_git_identity() {
  git config --global safe.directory /github/workspace || true
  git config user.name  "${GITHUB_ACTOR:-ci-bot}"
  git config user.email "${GITHUB_ACTOR_ID:-0}+${GITHUB_ACTOR:-ci-bot}@users.noreply.github.com"
  if [ "${DRY_RUN:-}" = "1" ]; then
    echo "[DRY_RUN] Skipping remote set-url for origin" 1>&2
  else
    git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${REPO}.git"
  fi
}

# Minimal GitHub API wrapper
api() {
  local method="$1"; shift
  local path="$1"; shift
  local BASE URL out rc http_code body
  BASE="${GITHUB_API_BASE:-https://api.github.com}"
  URL="${BASE}/repos/${REPO}${path}"

  # DRY-RUN short-circuit with canned JSON
  if [ "${DRY_RUN:-}" = "1" ]; then
    echo "[DRY_RUN] ${method} ${URL}" 1>&2
    case "${path}" in
      "/pulls")
        cat <<'JSON'
{"number":123,"html_url":"https://example.local/pr/123","state":"open","draft":false,"title":"DRY RUN PR","head":{"sha":"deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"}}
JSON
        ;;
      /pulls/*)
        cat <<'JSON'
{"number":123,"state":"open","draft":false,"mergeable_state":"clean","title":"DRY RUN PR","html_url":"https://example.local/pr/123","head":{"sha":"deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"}}
JSON
        ;;
      /commits/*/status)
        cat <<'JSON'
{"state":"success","statuses":[{"context":"ci/build","state":"success"},{"context":"lint","state":"success"}]}
JSON
        ;;
      *)
        echo '{}' ;;
    esac
    API_LAST_STATUS=200
    API_LAST_URL="$URL"
    printf '%s' "$API_LAST_STATUS" > "$API_STATE_DIR/status"
    printf '%s' "$API_LAST_URL"    > "$API_STATE_DIR/url"
    return 0
  fi

  # Run curl but keep control even on HTTP errors so we can print useful messages
  set +e
  out=$(curl -sS -w '\n%{http_code}' -X "$method" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$URL" "$@")
  rc=$?
  set -e

  http_code="${out##*$'\n'}"
  body="${out%$'\n'${http_code}}"
  API_LAST_STATUS="$http_code"
  API_LAST_URL="$URL"
  printf '%s' "$API_LAST_STATUS" > "$API_STATE_DIR/status"
  printf '%s' "$API_LAST_URL"    > "$API_STATE_DIR/url"

  if [ $rc -ne 0 ]; then
    echo "❌ Network error (curl exit $rc) calling ${method} ${URL}" 1>&2
    echo "$body"
    return 1
  fi

  # Always echo the body; caller can inspect API_LAST_STATUS
  echo "$body"
}

# ------------------
# Subcommand: commit
# ------------------
cmd_commit() {
  echo "🚀 START: Current repository commit" 1>&2
  setup_git_identity

  local BRANCH
  BRANCH="$(current_branch)"
  [ -n "$BRANCH" ] || { echo "Cannot determine branch" 1>&2; exit 1; }

  git add -A
  if git diff --cached --quiet; then
    echo "No changes to commit." 1>&2
    echo "🚀 STOP: Current repository commit" 1>&2
    return 0
  fi

  local COMMIT_MSG
  COMMIT_MSG="${COMMIT_MSG:-Automated update by Terrateam}"
  git commit -m "$COMMIT_MSG"

  if [ "${DRY_RUN:-}" = "1" ]; then
    echo "[DRY_RUN] Would push HEAD:${BRANCH} to origin" 1>&2
  else
    # Push with one rebase-retry
    if ! git -c http.extraheader= -c http.https://github.com/.extraheader= push origin "HEAD:${BRANCH}"; then
      git -c http.extraheader= -c http.https://github.com/.extraheader= pull --rebase origin "${BRANCH}"
      git -c http.extraheader= -c http.https://github.com/.extraheader= push origin "HEAD:${BRANCH}"
    fi
  fi

  echo "Pushed ${REPO}@${BRANCH}" 1>&2
  echo "🚀 STOP: Current repository commit" 1>&2
}

# ---------------------
# Subcommand: create-pr
# ---------------------
# env: PR_TITLE (required), PR_BODY (optional), HEAD_BRANCH (default: current), BASE_BRANCH (default: remote default), DRAFT (true/false, default false)
cmd_create_pr() {
  setup_git_identity

  local HEAD BASE TITLE BODY DRAFT_FLAG
  HEAD="${HEAD_BRANCH:-$(current_branch)}"
  BASE="${BASE_BRANCH:-$(remote_default_branch)}"
  TITLE="${PR_TITLE:-}"; BODY="${PR_BODY:-}"; DRAFT_FLAG="${DRAFT:-false}"

  [ -n "$TITLE" ] || { echo "PR_TITLE is required" 1>&2; exit 1; }
  [ -n "$HEAD" ] || { echo "Cannot determine HEAD branch" 1>&2; exit 1; }
  [ -n "$BASE" ] || { echo "Cannot determine BASE branch (set BASE_BRANCH)" 1>&2; exit 1; }

  echo "➡️  Creating PR" 1>&2
  echo "    repo=${REPO} head=${HEAD} base=${BASE} draft=${DRAFT_FLAG}" 1>&2
  echo "    title=${TITLE}" 1>&2

  # Build JSON payload
  if command -v jq >/dev/null 2>&1; then
    PAYLOAD=$(jq -n --arg t "$TITLE" --arg h "$HEAD" --arg b "$BASE" --arg body "$BODY" --argjson draft "${DRAFT_FLAG}" '{title:$t, head:$h, base:$b, body:$body, draft:$draft}')
  else
    # fallback (no jq). Avoid $'\n' quoting; normalize BODY newlines via tr
    local BODY_CLEAN
    BODY_CLEAN=$(printf '%s' "$BODY" | tr '\n' ' ')
    PAYLOAD=$(printf '{"title":"%s","head":"%s","base":"%s","body":"%s","draft":%s}' \
      "${TITLE//\"/\\\"}" "${HEAD//\"/\\\"}" "${BASE//\"/\\\"}" "${BODY_CLEAN//\"/\\\"}" "${DRAFT_FLAG}")
  fi

  RESP=$(api POST "/pulls" -H "Content-Type: application/json" --data-raw "$PAYLOAD")
  API_LAST_STATUS=$(cat "$API_STATE_DIR/status" 2>/dev/null || echo "")
  API_LAST_URL=$(cat "$API_STATE_DIR/url" 2>/dev/null || echo "")

  if [ "${API_LAST_STATUS:-}" != "201" ]; then
    echo "❌ GitHub API returned ${API_LAST_STATUS:-unknown} for PR create at ${API_LAST_URL:-unknown}" 1>&2
    echo "Response body:" 1>&2
    echo "$RESP" 1>&2
    exit 1
  fi

  if command -v jq >/dev/null 2>&1; then
    NUMBER=$(printf '%s' "$RESP" | jq -r '.number // empty')
    HTML=$(printf '%s' "$RESP" | jq -r '.html_url // empty')
    ERR=$(printf '%s' "$RESP" | jq -r '.errors[0].message // .message // empty')
  else
    NUMBER=$(printf '%s' "$RESP" | sed -n 's/.*"number":\s*\([0-9]\+\).*/\1/p')
    HTML=$(printf '%s' "$RESP" | sed -n 's/.*"html_url":\s*"\([^"]\+\)".*/\1/p')
    ERR=$(printf '%s' "$RESP" | sed -n 's/.*"message":\s*"\([^"]\+\)".*/\1/p')
  fi

  if [ -n "$NUMBER" ]; then
    echo "✅ Created PR #$NUMBER" 1>&2
    echo "$HTML" 1>&2

    # Emit YAML to STDOUT
    echo "---"
    if command -v jq >/dev/null 2>&1; then
      STATE=$(printf '%s' "$RESP" | jq -r '.state // "open"')
      DRAFT=$(printf '%s' "$RESP" | jq -r '.draft // false')
      BASE_REF=$(printf '%s' "$RESP" | jq -r '.base.ref // ""')
      HEAD_REF=$(printf '%s' "$RESP" | jq -r '.head.ref // ""')
      TITLE_OUT=$(printf '%s' "$RESP" | jq -r '.title // ""')
      URL_OUT=$(printf '%s' "$RESP" | jq -r '.html_url // ""')

      TITLE_Q=$(printf '%s' "$TITLE_OUT" | sed 's/"/\\"/g')
      URL_Q=$(printf '%s' "$URL_OUT" | sed 's/"/\\"/g')
      printf 'number: %s\n' "$NUMBER"
      printf 'state: %s\n' "$STATE"
      printf 'draft: %s\n' "$DRAFT"
      printf 'title: "%s"\n' "$TITLE_Q"
      printf 'url: "%s"\n' "$URL_Q"
      printf 'base: %s\n' "$BASE_REF"
      printf 'head: %s\n' "$HEAD_REF"
    else
      # Minimal YAML without jq
      TITLE_OUT=$(echo "$RESP" | sed -n 's/.*"title":"\([^"]\+\)".*/\1/p')
      URL_OUT=$(echo "$RESP" | sed -n 's/.*"html_url":"\([^"]\+\)".*/\1/p')
      TITLE_Q=$(printf '%s' "$TITLE_OUT" | sed 's/"/\\"/g')
      URL_Q=$(printf '%s' "$URL_OUT" | sed 's/"/\\"/g')
      echo "number: $NUMBER"
      echo "state: open"
      echo "draft: false"
      echo "title: \"$TITLE_Q\""
      echo "url: \"$URL_Q\""
      echo "base: ${BASE:-}"  # may be empty
      echo "head: ${HEAD:-}"  # may be empty
    fi
  else
    echo "❌ Failed to create PR: $ERR" 1>&2
    echo "$RESP" | sed 's/.*/  &/' 1>&2
    exit 1
  fi
}

# --------------------
# Subcommand: pr-status
# --------------------
# env: PR_NUMBER (preferred) or HEAD_BRANCH (+ optional BASE_BRANCH)
cmd_pr_status() {
  setup_git_identity

  local NUMBER HEAD BASE
  NUMBER="${PR_NUMBER:-}"
  HEAD="${HEAD_BRANCH:-}"; BASE="${BASE_BRANCH:-}"

  if [ -z "$NUMBER" ]; then
    # Try to resolve by head (and optionally base)
    local OWNER HEAD_Q RESP
    OWNER="${REPO%%/*}"
    HEAD_Q="${OWNER}:${HEAD:-$(current_branch)}"
    RESP=$(api GET "/pulls?head=${HEAD_Q}")
    if command -v jq >/dev/null 2>&1; then
      if [ -n "$BASE" ]; then
        NUMBER=$(printf '%s' "$RESP" | jq -r --arg base "$BASE" '.[] | select(.base.ref==$base) | .number' | head -n1)
      else
        NUMBER=$(printf '%s' "$RESP" | jq -r '.[0].number // empty')
      fi
    else
      NUMBER=$(printf '%s' "$RESP" | sed -n 's/.*"number":\s*\([0-9]\+\).*/\1/p' | head -n1)
    fi
  fi

  [ -n "$NUMBER" ] || { echo "Could not resolve PR number. Set PR_NUMBER or HEAD_BRANCH/BASE_BRANCH" 1>&2; exit 1; }

  echo "➡️  Reading PR status: repo=${REPO} number=${NUMBER}" 1>&2

  local PR_JSON SHA STATUS_JSON
  PR_JSON=$(api GET "/pulls/${NUMBER}")
  API_LAST_STATUS=$(cat "$API_STATE_DIR/status" 2>/dev/null || echo "")
  API_LAST_URL=$(cat "$API_STATE_DIR/url" 2>/dev/null || echo "")
  if [ "${API_LAST_STATUS:-}" != "200" ]; then
    echo "❌ GitHub API returned ${API_LAST_STATUS:-unknown} for PR read at ${API_LAST_URL:-unknown}" 1>&2
    echo "Response body:" 1>&2
    echo "$PR_JSON" 1>&2
    exit 1
  fi

  if command -v jq >/dev/null 2>&1; then
    NUMBER_VAL="$NUMBER"
    STATE=$(printf '%s' "$PR_JSON" | jq -r '.state')
    DRAFT=$(printf '%s' "$PR_JSON" | jq -r '.draft')
    TITLE=$(printf '%s' "$PR_JSON" | jq -r '.title')
    URL=$(printf '%s' "$PR_JSON" | jq -r '.html_url')
    BASE_REF=$(printf '%s' "$PR_JSON" | jq -r '.base.ref')
    HEAD_REF=$(printf '%s' "$PR_JSON" | jq -r '.head.ref')
    HEAD_SHA=$(printf '%s' "$PR_JSON" | jq -r '.head.sha')
    MERGEABLE_STATE=$(printf '%s' "$PR_JSON" | jq -r '.mergeable_state // "unknown"')

    STATUS_JSON=$(api GET "/commits/${HEAD_SHA}/status")
    API_LAST_STATUS=$(cat "$API_STATE_DIR/status" 2>/dev/null || echo "")
    API_LAST_URL=$(cat "$API_STATE_DIR/url" 2>/dev/null || echo "")
    if [ "${API_LAST_STATUS:-}" != "200" ]; then
      echo "❌ GitHub API returned ${API_LAST_STATUS:-unknown} for commit status at ${API_LAST_URL:-unknown}" 1>&2
      echo "Response body:" 1>&2
      echo "$STATUS_JSON" 1>&2
      exit 1
    fi
    CI_STATE=$(printf '%s' "$STATUS_JSON" | jq -r '.state')

    # --- Discussion: issue comments, review comments, and reviews ---
    ISSUE_COMMENTS=$(api GET "/issues/${NUMBER}/comments")
    API_LAST_STATUS=$(cat "$API_STATE_DIR/status" 2>/dev/null || echo "")
    API_LAST_URL=$(cat "$API_STATE_DIR/url" 2>/dev/null || echo "")
    if [ "${API_LAST_STATUS:-}" != "200" ]; then
      echo "❌ GitHub API returned ${API_LAST_STATUS:-unknown} for issue comments at ${API_LAST_URL:-unknown}" 1>&2
      echo "Response body:" 1>&2
      echo "$ISSUE_COMMENTS" 1>&2
      exit 1
    fi

    REVIEW_COMMENTS=$(api GET "/pulls/${NUMBER}/comments")
    API_LAST_STATUS=$(cat "$API_STATE_DIR/status" 2>/dev/null || echo "")
    API_LAST_URL=$(cat "$API_STATE_DIR/url" 2>/dev/null || echo "")
    if [ "${API_LAST_STATUS:-}" != "200" ]; then
      echo "❌ GitHub API returned ${API_LAST_STATUS:-unknown} for review comments at ${API_LAST_URL:-unknown}" 1>&2
      echo "Response body:" 1>&2
      echo "$REVIEW_COMMENTS" 1>&2
      exit 1
    fi

    REVIEWS=$(api GET "/pulls/${NUMBER}/reviews")
    API_LAST_STATUS=$(cat "$API_STATE_DIR/status" 2>/dev/null || echo "")
    API_LAST_URL=$(cat "$API_STATE_DIR/url" 2>/dev/null || echo "")
    if [ "${API_LAST_STATUS:-}" != "200" ]; then
      echo "❌ GitHub API returned ${API_LAST_STATUS:-unknown} for reviews at ${API_LAST_URL:-unknown}" 1>&2
      echo "Response body:" 1>&2
      echo "$REVIEWS" 1>&2
      exit 1
    fi

    COMMENTS_COUNT=$(printf '%s' "$ISSUE_COMMENTS" | jq -r 'length')
    REVIEW_COMMENTS_COUNT=$(printf '%s' "$REVIEW_COMMENTS" | jq -r 'length')
    REVIEWS_COUNT=$(printf '%s' "$REVIEWS" | jq -r 'length')

    # YAML to STDOUT
    echo "---"
    printf 'number: %s\n' "$NUMBER_VAL"
    printf 'state: %s\n' "$STATE"
    printf 'draft: %s\n' "$DRAFT"
    # Quote title and url safely
    TITLE_Q=$(printf '%s' "$TITLE" | sed 's/"/\\"/g')
    URL_Q=$(printf '%s' "$URL" | sed 's/"/\\"/g')
    printf 'title: "%s"\n' "$TITLE_Q"
    printf 'url: "%s"\n' "$URL_Q"
    printf 'base: %s\n' "$BASE_REF"
    printf 'head: %s\n' "$HEAD_REF"
    printf 'head_sha: %s\n' "$HEAD_SHA"
    printf 'mergeable_state: %s\n' "$MERGEABLE_STATE"
    printf 'checks:\n'
    printf '  state: %s\n' "$CI_STATE"
    if printf '%s' "$STATUS_JSON" | jq -e '.statuses | length>0' >/dev/null 2>&1; then
      printf '  statuses:\n'
      printf '%s' "$STATUS_JSON" \
        | jq -r '.statuses | map("    - context: \(.context|tojson)\n      state: \(.state)") | .[]'
    else
      printf '  statuses: []\n'
    fi

    # Discussion YAML
    printf 'discussion:\n'
    printf '  comments_count: %s\n' "$COMMENTS_COUNT"
    printf '  review_comments_count: %s\n' "$REVIEW_COMMENTS_COUNT"
    printf '  reviews_count: %s\n' "$REVIEWS_COUNT"

    # Issue comments list
    if [ "$COMMENTS_COUNT" -gt 0 ]; then
      printf '  comments:\n'
      printf '%s' "$ISSUE_COMMENTS" \
        | jq -r '.[] | "    - author: \(.user.login)\n      created_at: \(.created_at)\n      body: \(.body|tojson)"'
    else
      printf '  comments: []\n'
    fi

    # Review comments list (file comments)
    if [ "$REVIEW_COMMENTS_COUNT" -gt 0 ]; then
      printf '  review_comments:\n'
      printf '%s' "$REVIEW_COMMENTS" \
        | jq -r '.[] | "    - author: \(.user.login)\n      path: \(.path)\n      created_at: \(.created_at)\n      body: \(.body|tojson)"'
    else
      printf '  review_comments: []\n'
    fi

    # Reviews list (stateful reviews)
    if [ "$REVIEWS_COUNT" -gt 0 ]; then
      printf '  reviews:\n'
      printf '%s' "$REVIEWS" \
        | jq -r '.[] | "    - author: \(.user.login)\n      state: \(.state)\n      submitted_at: \(.submitted_at)\n      body: \(.body|tojson)"'
    else
      printf '  reviews: []\n'
    fi
  else
    # Fallback minimal YAML without jq
    NUMBER_VAL="$NUMBER"
    TITLE=$(echo "$PR_JSON" | sed -n 's/.*"title":"\([^"]\+\)".*/\1/p')
    URL=$(echo "$PR_JSON" | sed -n 's/.*"html_url":"\([^"]\+\)".*/\1/p')
    STATE=$(echo "$PR_JSON" | sed -n 's/.*"state":"\([^"]\+\)".*/\1/p' | head -n1)
    MERGEABLE_STATE=$(echo "$PR_JSON" | sed -n 's/.*"mergeable_state":"\([^"]\+\)".*/\1/p')
    echo "---"
    echo "number: $NUMBER_VAL"
    echo "state: ${STATE:-unknown}"
    echo "draft: unknown"
    TITLE_Q=$(printf '%s' "$TITLE" | sed 's/"/\\"/g')
    URL_Q=$(printf '%s' "$URL" | sed 's/"/\\"/g')
    echo "title: \"$TITLE_Q\""
    echo "url: \"$URL_Q\""
    echo "base: unknown"
    echo "head: unknown"
    echo "head_sha: unknown"
    echo "mergeable_state: ${MERGEABLE_STATE:-unknown}"
    echo "checks:"
    echo "  state: unknown"
    echo "  statuses: []"
    echo "discussion:"
    echo "  comments_count: unknown"
    echo "  review_comments_count: unknown"
    echo "  reviews_count: unknown"
    echo "  comments: []"
    echo "  review_comments: []"
    echo "  reviews: []"
  fi
}

# ---------
# Dispatcher
# ---------
SUBCMD="${1:-commit}"
case "$SUBCMD" in
  commit)    shift || true; cmd_commit "$@" ;;
  create-pr) shift || true; cmd_create_pr "$@" ;;
  pr-status) shift || true; cmd_pr_status "$@" ;;
  *) echo "Unknown subcommand: $SUBCMD" 1>&2; echo "Use one of: commit | create-pr | pr-status" 1>&2; exit 1 ;;

esac

echo "🚀 STOP: terrateam git helpers ($SUBCMD)" 1>&2
