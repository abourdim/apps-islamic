#!/usr/bin/env bash
# ============================================================
# Workshop-Diy — list-private.sh
# List private repos by comparing cloned repos against GitHub API
# Uses gh CLI if authenticated, falls back to curl
# ============================================================

set -euo pipefail

GITHUB_USER="abourdim"
REPOS_DIR="$(cd "$(dirname "$0")" && pwd)/repos"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

if [ ! -d "$REPOS_DIR" ]; then
  echo -e "${RED}Error: repos/ not found. Run 02_clone_all.sh first.${NC}"
  exit 1
fi

# ──────── Fetch public repo names ────────
fetch_public() {
  if gh auth status &>/dev/null; then
    gh repo list "$GITHUB_USER" --limit 200 --public --json name -q '.[].name' 2>/dev/null | sort
  else
    local page=1
    local all=""
    while :; do
      local batch
      batch=$(curl -sf "https://api.github.com/users/$GITHUB_USER/repos?per_page=100&page=$page" 2>/dev/null || echo "[]")
      local names
      names=$(echo "$batch" | python3 -c "
import json, sys
try:
    for r in json.load(sys.stdin):
        print(r.get('name',''))
except: pass
" 2>/dev/null)
      [ -z "$names" ] && break
      all="$all
$names"
      page=$((page + 1))
    done
    echo "$all" | grep -v '^$' | sort
  fi
}

echo -e "\n${CYAN}${BOLD}  Fetching public repos for ${GITHUB_USER}...${NC}\n"
public_repos=$(fetch_public)

if [ -z "$public_repos" ]; then
  echo -e "${RED}  Error: Could not fetch public repos (API rate limit or network issue).${NC}"
  echo -e "${YELLOW}  Tip: run 'gh auth login' to avoid rate limits.${NC}"
  exit 1
fi

public_count=$(echo "$public_repos" | wc -l | tr -d ' ')

# ──────── Compare with cloned repos ────────
private_count=0
total=0

echo -e "${BOLD}  ${DIM}#   Repo                        Status${NC}"
echo -e "${DIM}  ─────────────────────────────────────────${NC}"

for repo in "$REPOS_DIR"/*/; do
  name=$(basename "$repo")
  total=$((total + 1))
  if echo "$public_repos" | grep -qx "$name"; then
    : # public — skip
  else
    private_count=$((private_count + 1))
    printf "  ${BOLD}%-3s${NC} %-30s ${RED}🔒 private${NC}\n" "$private_count" "$name"
  fi
done

echo -e "${DIM}  ─────────────────────────────────────────${NC}"
echo -e "  ${GREEN}Public:${NC}  $((total - private_count))"
echo -e "  ${RED}Private:${NC} ${BOLD}${private_count}${NC}"
echo -e "  Total:   ${total}\n"
