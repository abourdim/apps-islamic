#!/usr/bin/env bash
# ============================================================
# Workshop-Diy — script.sh
# Clone all repos for the given GitHub user
# ============================================================

set -euo pipefail

GITHUB_USER="abourdim"
DEST_DIR="./repos"

echo "🔄 Cloning all repos for $GITHUB_USER..."
mkdir -p "$DEST_DIR"
cd "$DEST_DIR" || exit 1

page=1
total=0

while :; do
  repos=$(curl -sf "https://api.github.com/users/$GITHUB_USER/repos?per_page=100&page=$page" \
    | grep -o '"clone_url": *"[^"]*"' \
    | sed 's/"clone_url": "//;s/"//')

  [ -z "$repos" ] && break

  for repo in $repos; do
    name=$(basename "$repo" .git)
    if [ -d "$name" ]; then
      echo "  ♻️  Updating $name"
      (cd "$name" && git pull --quiet 2>/dev/null) || true
    else
      echo "  📦 Cloning $name"
      git clone --quiet --depth 1 "$repo" 2>/dev/null || echo "  ⚠️  Failed: $name"
    fi
    total=$((total + 1))
  done

  page=$((page + 1))
done

echo ""
echo "✅ Done! $total repos in $DEST_DIR"
