#!/usr/bin/env bash
# ============================================================
# Workshop-Diy — 06_tag-visibility.sh
# Tags each app in apps-data.json with "visibility": "public"|"private"
# Run this from your apps/ repo directory.
#
# Usage:
#   ./06_tag-visibility.sh                  # probes github.com (no token)
#   GITHUB_TOKEN=ghp_xxx ./06_tag-visibility.sh  # uses API (sees private repos too)
# ============================================================

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/06_tag-visibility.py"

if [ ! -f "$SCRIPT" ]; then
  echo "❌ 06_tag-visibility.py not found next to this script."
  exit 1
fi

echo "🔍 Workshop-Diy — Visibility Tagger"
echo ""

if [ -n "${GITHUB_TOKEN:-}" ]; then
  echo "  🔑 Using GITHUB_TOKEN (will detect private repos too)"
else
  echo "  ⚠️  No GITHUB_TOKEN — probing github.com as anonymous user"
  echo "     Private repos = any repo returning 404"
fi

echo ""
python3 "$SCRIPT"
