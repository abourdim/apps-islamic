#!/usr/bin/env bash
# ============================================================
# Workshop-Diy — build.sh
# Smart incremental rebuild pipeline
# Usage:
#   ./build.sh                 # smart incremental (only changed)
#   ./build.sh --force         # full rebuild everything
#   ./build.sh --thumbs-only   # just regenerate screenshots
#   ./build.sh --data-only     # just refresh app catalog
#   ./build.sh --deploy        # rebuild + push to gh-pages
#   ./build.sh --watch         # poll every 5min for changes
# ============================================================

set -euo pipefail

GITHUB_USER="abourdim"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_DIR="$SCRIPT_DIR/.repos"
DATA_FILE="$SCRIPT_DIR/apps-data.json"
LAST_BUILD="$SCRIPT_DIR/.last-build.json"
THUMBS_DIR="$SCRIPT_DIR/thumbs"
MANIFEST="$SCRIPT_DIR/manifest.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

MODE="${1:-}"

log()  { echo -e "${BLUE}[build]${NC} $1"; }
ok()   { echo -e "${GREEN}  ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠️  $1${NC}"; }
err()  { echo -e "${RED}  ❌ $1${NC}"; }

# ──────── Fetch repo list from GitHub API ────────
fetch_repos() {
  log "Fetching repos for ${CYAN}${GITHUB_USER}${NC}..."
  local page=1
  local all_repos=""

  while :; do
    local repos
    repos=$(curl -sf "https://api.github.com/users/$GITHUB_USER/repos?per_page=100&page=$page" 2>/dev/null || echo "[]")
    local names
    names=$(echo "$repos" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if isinstance(data, list):
        for r in data:
            print(r.get('name',''))
except: pass
" 2>/dev/null)

    [ -z "$names" ] && break
    all_repos="$all_repos
$names"
    page=$((page + 1))
  done

  echo "$all_repos" | grep -v '^$' | sort
}

# ──────── Get latest commit SHA for a repo ────────
get_sha() {
  local repo="$1"
  curl -sf "https://api.github.com/repos/$GITHUB_USER/$repo/commits?per_page=1" 2>/dev/null \
    | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['sha'])" 2>/dev/null || echo "unknown"
}

# ──────── Check if repo has index.html ────────
has_index() {
  local repo="$1"
  local status
  status=$(curl -sf -o /dev/null -w "%{http_code}" \
    "https://raw.githubusercontent.com/$GITHUB_USER/$repo/main/index.html" 2>/dev/null || echo "000")
  [ "$status" = "200" ]
}

# ──────── Clone or pull a repo ────────
clone_or_pull() {
  local repo="$1"
  mkdir -p "$REPOS_DIR"
  if [ -d "$REPOS_DIR/$repo" ]; then
    (cd "$REPOS_DIR/$repo" && git pull --quiet 2>/dev/null) || true
  else
    git clone --quiet --depth 1 "https://github.com/$GITHUB_USER/$repo.git" "$REPOS_DIR/$repo" 2>/dev/null || true
  fi
}

# ──────── Detect changes since last build ────────
get_changed_repos() {
  local repos="$1"
  local changed=""

  if [ ! -f "$LAST_BUILD" ] || [ "$MODE" = "--force" ]; then
    echo "$repos"
    return
  fi

  while IFS= read -r repo; do
    [ -z "$repo" ] && continue
    local new_sha
    new_sha=$(get_sha "$repo")
    local old_sha
    old_sha=$(python3 -c "
import json
try:
    d = json.load(open('$LAST_BUILD'))
    print(d.get('repos',{}).get('$repo',{}).get('sha',''))
except: print('')
" 2>/dev/null)

    if [ "$new_sha" != "$old_sha" ]; then
      changed="$changed
$repo"
    fi
  done <<< "$repos"

  echo "$changed" | grep -v '^$'
}

# ──────── Save build state ────────
save_state() {
  local repos="$1"
  python3 -c "
import json, datetime

repos = '''$repos'''.strip().split('\n')
state = {'last_run': datetime.datetime.utcnow().isoformat() + 'Z', 'repos': {}}

# Load existing state
try:
    with open('$LAST_BUILD') as f:
        state = json.load(f)
    state['last_run'] = datetime.datetime.utcnow().isoformat() + 'Z'
except: pass

# We'll update SHAs in the main loop
with open('$LAST_BUILD', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null
}

# ──────── Generate thumbnails for specific repos ────────
generate_thumbs() {
  local repos="$1"
  log "Generating thumbnails..."

  if ! command -v node &>/dev/null; then
    warn "Node.js not found, skipping thumbnails"
    return
  fi

  if [ ! -d "$SCRIPT_DIR/node_modules/puppeteer" ]; then
    log "Installing Puppeteer..."
    (cd "$SCRIPT_DIR" && npm install puppeteer --save 2>/dev/null) || {
      warn "Could not install Puppeteer"
      return
    }
  fi

  # Pass changed repos to screenshot.js via env
  CHANGED_REPOS="$repos" node "$SCRIPT_DIR/screenshot.js"
}

# ──────── Update apps-data.json ────────
update_data() {
  local repos="$1"
  log "Updating apps-data.json..."

  python3 << 'PYEOF'
import json, os, datetime

DATA_FILE = os.environ.get("DATA_FILE", "./apps-data.json")
LAST_BUILD = os.environ.get("LAST_BUILD", "./.last-build.json")
THUMBS_DIR = os.environ.get("THUMBS_DIR", "./thumbs")

# Load existing data
try:
    with open(DATA_FILE) as f:
        data = json.load(f)
except:
    data = {"generated": "", "user": "abourdim", "apps": []}

existing = {a["name"]: a for a in data.get("apps", [])}

# Check which repos have thumbnails
thumbs = set()
if os.path.isdir(THUMBS_DIR):
    for f in os.listdir(THUMBS_DIR):
        if f.endswith(".png"):
            thumbs.add(f.replace(".png", ""))

# Update generated timestamp
data["generated"] = datetime.datetime.utcnow().isoformat() + "Z"

# Update has_thumb for each app
for app in data.get("apps", []):
    app["has_thumb"] = app["name"] in thumbs

with open(DATA_FILE, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"  Updated {len(data['apps'])} apps in apps-data.json")
PYEOF
}

# ──────── Generate manifest ────────
generate_manifest() {
  log "Generating manifest.json..."
  python3 << 'PYEOF'
import json, os, datetime

THUMBS_DIR = os.environ.get("THUMBS_DIR", "./thumbs")
manifest = {
    "generated": datetime.datetime.utcnow().isoformat() + "Z",
    "thumbs": {}
}

if os.path.isdir(THUMBS_DIR):
    for f in sorted(os.listdir(THUMBS_DIR)):
        if f.endswith(".png"):
            path = os.path.join(THUMBS_DIR, f)
            manifest["thumbs"][f.replace(".png", "")] = {
                "file": f,
                "size": os.path.getsize(path)
            }

MANIFEST = os.environ.get("MANIFEST", "./manifest.json")
with open(MANIFEST, "w") as f:
    json.dump(manifest, f, indent=2)

print(f"  Manifest: {len(manifest['thumbs'])} thumbnails tracked")
PYEOF
}

# ──────── Deploy to GitHub Pages ────────
deploy() {
  log "Deploying to GitHub Pages..."
  if ! command -v git &>/dev/null; then
    err "Git not found"
    return 1
  fi

  # Check if we're in a git repo
  if [ ! -d "$SCRIPT_DIR/.git" ]; then
    warn "Not a git repository, skipping deploy"
    return
  fi

  cd "$SCRIPT_DIR"
  git add -A
  git commit -m "🔄 Auto-rebuild: $(date -u '+%Y-%m-%d %H:%M UTC')" || {
    log "Nothing to commit"
    return
  }
  git push origin main
  ok "Deployed!"
}

# ──────── Print summary ────────
print_summary() {
  local total="$1"
  local changed="$2"
  local new_count="$3"
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}   🏗️  Build Summary                  ${CYAN}║${NC}"
  echo -e "${CYAN}╠══════════════════════════════════════╣${NC}"
  echo -e "${CYAN}║${NC}   Total repos:    ${GREEN}${total}${NC}"
  echo -e "${CYAN}║${NC}   Changed:        ${YELLOW}${changed}${NC}"
  echo -e "${CYAN}║${NC}   New:            ${BLUE}${new_count}${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
  echo ""
}

# ============================================================
# MAIN
# ============================================================

export DATA_FILE LAST_BUILD THUMBS_DIR MANIFEST

case "$MODE" in
  --thumbs-only)
    log "Mode: Thumbnails only"
    repos=$(fetch_repos)
    generate_thumbs "$repos"
    generate_manifest
    ok "Done!"
    ;;

  --data-only)
    log "Mode: Data only"
    update_data ""
    generate_manifest
    ok "Done!"
    ;;

  --watch)
    log "Mode: Watch (polling every 5 minutes)"
    while true; do
      log "Checking for changes at $(date '+%H:%M:%S')..."
      repos=$(fetch_repos)
      changed=$(get_changed_repos "$repos")
      if [ -n "$changed" ]; then
        count=$(echo "$changed" | wc -l | tr -d ' ')
        log "Found ${count} changed repos!"
        generate_thumbs "$changed"
        update_data "$changed"
        generate_manifest
        ok "Update complete!"
      else
        log "No changes detected."
      fi
      log "Sleeping 5 minutes..."
      sleep 300
    done
    ;;

  --deploy)
    log "Mode: Full rebuild + deploy"
    repos=$(fetch_repos)
    total=$(echo "$repos" | wc -l | tr -d ' ')
    changed=$(get_changed_repos "$repos")
    changed_count=$(echo "$changed" | grep -c . || echo 0)

    if [ -n "$changed" ]; then
      generate_thumbs "$changed"
    fi
    update_data "$changed"
    generate_manifest
    deploy
    print_summary "$total" "$changed_count" "0"
    ok "Build + Deploy complete! 🚀"
    ;;

  --force)
    log "Mode: Full force rebuild"
    repos=$(fetch_repos)
    total=$(echo "$repos" | wc -l | tr -d ' ')
    generate_thumbs "$repos"
    update_data "$repos"
    generate_manifest
    print_summary "$total" "$total" "0"
    ok "Force rebuild complete! 💪"
    ;;

  *)
    log "Mode: Smart incremental"
    repos=$(fetch_repos)
    total=$(echo "$repos" | wc -l | tr -d ' ')
    changed=$(get_changed_repos "$repos")
    changed_count=0

    if [ -n "$changed" ]; then
      changed_count=$(echo "$changed" | wc -l | tr -d ' ')
      log "Found ${YELLOW}${changed_count}${NC} changed repos"
      generate_thumbs "$changed"
    else
      log "No changes detected since last build"
    fi

    update_data "$changed"
    generate_manifest
    print_summary "$total" "$changed_count" "0"
    ok "Build complete! ✨"
    ;;
esac
