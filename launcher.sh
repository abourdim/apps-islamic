#!/usr/bin/env bash
# ============================================================
# Workshop-DIY — Launcher
# Unified menu for all project operations
# ============================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_DIR="$SCRIPT_DIR/repos"
DATA_FILE="$SCRIPT_DIR/apps-data.json"
JS_FILE="$SCRIPT_DIR/app.js"
FLYERS_DIR="$REPOS_DIR/flyers"
GITHUB_USER="abourdim"

# ── Colors ──
RED='\033[0;31m'    GREEN='\033[0;32m'  YELLOW='\033[1;33m'
BLUE='\033[0;34m'   CYAN='\033[0;36m'   MAGENTA='\033[0;35m'
BOLD='\033[1m'      DIM='\033[2m'       NC='\033[0m'

log()  { echo -e "${BLUE}[wdi]${NC} $1"; }
ok()   { echo -e "${GREEN}  ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠️  $1${NC}"; }
err()  { echo -e "${RED}  ❌ $1${NC}"; }

pause() { echo ""; read -p "  Press Enter to continue..." < /dev/tty; }

# ============================================================
#  MENU
# ============================================================
show_menu() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}  ║        🛠️  Workshop-DIY Launcher         ║${NC}"
  echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${DIM}── Repos ──────────────────────────────────${NC}"
  echo -e "   ${BOLD}1${NC})  Clone all repos"
  echo -e "   ${BOLD}2${NC})  Pull all repos"
  echo -e "   ${BOLD}3${NC})  Repo health check"
  echo -e "   ${BOLD}4${NC})  Fix READMEs"
  echo ""
  echo -e "  ${DIM}── Data ───────────────────────────────────${NC}"
  echo -e "   ${BOLD}5${NC})  Sync app data"
  echo -e "   ${BOLD}6${NC})  Validate data"
  echo -e "   ${BOLD}7${NC})  Export report"
  echo ""
  echo -e "  ${DIM}── Build & Deploy ─────────────────────────${NC}"
  echo -e "   ${BOLD}8${NC})  Build"
  echo -e "   ${BOLD}9${NC})  Generate thumbnails"
  echo -e "  ${BOLD}10${NC})  Deploy"
  echo ""
  echo -e "  ${DIM}── Apps ───────────────────────────────────${NC}"
  echo -e "  ${BOLD}11${NC})  List apps"
  echo -e "  ${BOLD}12${NC})  Edit app"
  echo -e "  ${BOLD}13${NC})  Bulk edit"
  echo -e "  ${BOLD}14${NC})  Dashboard"
  echo ""
  echo -e "  ${DIM}── Flyers ─────────────────────────────────${NC}"
  echo -e "  ${BOLD}15${NC})  Event flyer"
  echo -e "  ${BOLD}16${NC})  App catalog"
  echo -e "  ${BOLD}17${NC})  Batch flyers"
  echo ""
  echo -e "  ${DIM}── Quality ────────────────────────────────${NC}"
  echo -e "  ${BOLD}18${NC})  Broken links check"
  echo -e "  ${BOLD}19${NC})  i18n coverage"
  echo -e "  ${BOLD}20${NC})  Consistency check"
  echo -e "  ${BOLD}21${NC})  Auto-tagger"
  echo -e "  ${BOLD}22${NC})  Run all quality checks"
  echo ""
  echo -e "  ${DIM}── Web ────────────────────────────────────${NC}"
  echo -e "  ${BOLD}23${NC})  Web launcher"
  echo ""
  echo -e "   ${BOLD}0${NC})  Quit"
  echo ""
}

# ============================================================
#  HELPERS
# ============================================================

# Count apps in data file
app_count() { python3 -c "import json; print(len(json.load(open('$DATA_FILE')).get('apps',[])))" 2>/dev/null || echo 0; }

# Get app field by name
app_field() {
  local name="$1" field="$2"
  python3 -c "
import json
data = json.load(open('$DATA_FILE'))
for a in data.get('apps',[]):
    if a['name'] == '$name':
        v = a.get('$field','')
        print(v if not isinstance(v, list) else ','.join(v))
        break
" 2>/dev/null
}

# List app names
app_names() {
  python3 -c "
import json
data = json.load(open('$DATA_FILE'))
for a in data.get('apps',[]):
    print(a['name'])
" 2>/dev/null
}

# ============================================================
#  1. CLONE ALL REPOS
# ============================================================
do_clone() {
  log "Cloning all repos for ${CYAN}${GITHUB_USER}${NC}..."
  if [ -f "$SCRIPT_DIR/02_clone_all.sh" ]; then
    bash "$SCRIPT_DIR/02_clone_all.sh"
  else
    mkdir -p "$REPOS_DIR"
    local page=1 total=0
    while :; do
      local repos
      repos=$(curl -sf "https://api.github.com/users/$GITHUB_USER/repos?per_page=100&page=$page" \
        | grep -o '"clone_url": *"[^"]*"' | sed 's/"clone_url": "//;s/"//') || break
      [ -z "$repos" ] && break
      for url in $repos; do
        local name=$(basename "$url" .git)
        if [ -d "$REPOS_DIR/$name" ]; then
          echo -e "  ♻️  ${DIM}$name${NC}"
          (cd "$REPOS_DIR/$name" && git pull --quiet 2>/dev/null) || true
        else
          echo -e "  📦 ${BOLD}$name${NC}"
          git clone --quiet --depth 1 "$url" "$REPOS_DIR/$name" 2>/dev/null || warn "Failed: $name"
        fi
        total=$((total + 1))
      done
      page=$((page + 1))
    done
    ok "Done! $total repos"
  fi
}

# ============================================================
#  2. PULL ALL REPOS
# ============================================================
do_pull() {
  log "Pulling all repos..."
  if [ ! -d "$REPOS_DIR" ]; then err "repos/ not found. Clone first."; return; fi

  local updated=0 failed=0 total=0
  for repo in "$REPOS_DIR"/*/; do
    [ ! -d "$repo/.git" ] && continue
    local name=$(basename "$repo")
    total=$((total + 1))
    if (cd "$repo" && git pull --quiet 2>/dev/null); then
      updated=$((updated + 1))
    else
      warn "$name — pull failed"
      failed=$((failed + 1))
    fi
  done
  ok "Pulled $updated/$total repos ($failed failed)"
}

# ============================================================
#  3. REPO HEALTH CHECK
# ============================================================
do_health() {
  log "Repo health check..."
  if [ ! -d "$REPOS_DIR" ]; then err "repos/ not found."; return; fi

  local dirty=0 no_index=0 unpushed=0 total=0
  echo ""
  echo -e "  ${BOLD}${DIM}Repo                          Issues${NC}"
  echo -e "  ${DIM}─────────────────────────────────────────────${NC}"

  for repo in "$REPOS_DIR"/*/; do
    [ ! -d "$repo/.git" ] && continue
    local name=$(basename "$repo")
    total=$((total + 1))
    local issues=""

    # Dirty?
    local status=$(cd "$repo" && git status --porcelain 2>/dev/null | head -1)
    [ -n "$status" ] && { issues+=" ${YELLOW}dirty${NC}"; dirty=$((dirty + 1)); }

    # No index.html?
    [ ! -f "$repo/index.html" ] && { issues+=" ${RED}no index.html${NC}"; no_index=$((no_index + 1)); }

    # No README?
    [ ! -f "$repo/README.md" ] && issues+=" ${MAGENTA}no README${NC}"

    # Unpushed commits?
    local ahead=$(cd "$repo" && git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    [ "$ahead" -gt 0 ] && { issues+=" ${CYAN}${ahead} unpushed${NC}"; unpushed=$((unpushed + 1)); }

    [ -n "$issues" ] && printf "  %-30s%b\n" "$name" "$issues"
  done

  echo -e "  ${DIM}─────────────────────────────────────────────${NC}"
  echo -e "  Total: $total | ${YELLOW}Dirty: $dirty${NC} | ${RED}No index: $no_index${NC} | ${CYAN}Unpushed: $unpushed${NC}"

  # Offer to push unpushed
  if [ "$unpushed" -gt 0 ]; then
    echo ""
    read -p "  Push all $unpushed unpushed repos? (y/n): " do_push < /dev/tty
    if [ "$do_push" = "y" ]; then
      for repo in "$REPOS_DIR"/*/; do
        [ ! -d "$repo/.git" ] && continue
        local name=$(basename "$repo")
        local ahead=$(cd "$repo" && git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
        if [ "$ahead" -gt 0 ]; then
          (cd "$repo" && git push --quiet 2>/dev/null) && ok "Pushed $name" || warn "Push failed: $name"
        fi
      done
    fi
  fi

  # Private repos check
  echo ""
  log "Checking for private repos..."
  if [ -f "$SCRIPT_DIR/05_list-private.sh" ]; then
    bash "$SCRIPT_DIR/05_list-private.sh"
  fi
}

# ============================================================
#  4. FIX READMES
# ============================================================
do_fix_readmes() {
  log "Scanning READMEs..."
  if [ ! -d "$REPOS_DIR" ]; then err "repos/ not found."; return; fi

  local missing=0 short=0 total=0
  echo ""
  echo -e "  ${BOLD}${DIM}Repo                          README Status${NC}"
  echo -e "  ${DIM}─────────────────────────────────────────────${NC}"

  for repo in "$REPOS_DIR"/*/; do
    [ ! -d "$repo/.git" ] && continue
    local name=$(basename "$repo")
    total=$((total + 1))

    if [ ! -f "$repo/README.md" ]; then
      printf "  %-30s ${RED}MISSING${NC}\n" "$name"
      missing=$((missing + 1))
    else
      local lines=$(wc -l < "$repo/README.md" | tr -d ' ')
      if [ "$lines" -lt 5 ]; then
        printf "  %-30s ${YELLOW}TOO SHORT ($lines lines)${NC}\n" "$name"
        short=$((short + 1))
      fi
    fi
  done

  echo -e "  ${DIM}─────────────────────────────────────────────${NC}"
  echo -e "  Total: $total | ${RED}Missing: $missing${NC} | ${YELLOW}Short: $short${NC}"

  if [ $((missing + short)) -eq 0 ]; then
    ok "All READMEs look good!"
    return
  fi

  echo ""
  read -p "  Generate missing/short READMEs? (y/n): " confirm < /dev/tty
  [ "$confirm" != "y" ] && return

  for repo in "$REPOS_DIR"/*/; do
    [ ! -d "$repo/.git" ] && continue
    local name=$(basename "$repo")
    local generate=0

    [ ! -f "$repo/README.md" ] && generate=1
    [ -f "$repo/README.md" ] && [ "$(wc -l < "$repo/README.md" | tr -d ' ')" -lt 5 ] && generate=1

    if [ "$generate" -eq 1 ]; then
      local emoji=$(app_field "$name" "emoji")
      local desc=$(app_field "$name" "desc")
      local tags=$(app_field "$name" "tags")
      local cats=$(app_field "$name" "categories")
      [ -z "$emoji" ] && emoji="🔧"

      # Get English description
      local desc_en
      desc_en=$(python3 -c "
import json
data = json.load(open('$DATA_FILE'))
for a in data.get('apps',[]):
    if a['name'] == '$name':
        print(a.get('desc',{}).get('en',''))
        break
" 2>/dev/null)
      [ -z "$desc_en" ] && desc_en="$name — Workshop DIY app"

      cat > "$repo/README.md" << READMEEOF
# $emoji $name

$desc_en

## Live Demo

[Open in browser](https://abourdim.github.io/$name/)

## Tech Stack

$([ -n "$tags" ] && echo "$tags" | tr ',' '\n' | sed 's/^/- /' || echo "- HTML/CSS/JavaScript")

## Category

$([ -n "$cats" ] && echo "$cats" | tr ',' '\n' | sed 's/^/- /' || echo "- tools")

---

Part of [Workshop-DIY](https://abourdim.github.io/all/) — Educational mini-apps hub.
READMEEOF
      ok "Generated README for $name"
    fi
  done

  # Offer to commit
  echo ""
  read -p "  Commit changes in each repo? (y/n): " do_commit < /dev/tty
  if [ "$do_commit" = "y" ]; then
    for repo in "$REPOS_DIR"/*/; do
      [ ! -d "$repo/.git" ] && continue
      local name=$(basename "$repo")
      local changed=$(cd "$repo" && git status --porcelain README.md 2>/dev/null)
      if [ -n "$changed" ]; then
        (cd "$repo" && git add README.md && git commit -m "docs: add/update README" --quiet 2>/dev/null)
        ok "Committed in $name"
      fi
    done

    echo ""
    read -p "  Push all committed repos? (y/n): " do_push < /dev/tty
    if [ "$do_push" = "y" ]; then
      for repo in "$REPOS_DIR"/*/; do
        [ ! -d "$repo/.git" ] && continue
        local name=$(basename "$repo")
        local ahead=$(cd "$repo" && git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
        if [ "$ahead" -gt 0 ]; then
          (cd "$repo" && git push --quiet 2>/dev/null) && ok "Pushed $name" || warn "Push failed: $name"
        fi
      done
    fi
  fi
}

# ============================================================
#  5. SYNC APP DATA
# ============================================================
do_sync() {
  log "Syncing app data..."
  if [ -f "$SCRIPT_DIR/03_sync.sh" ]; then
    bash "$SCRIPT_DIR/03_sync.sh" "$@"
  else
    err "03_sync.sh not found"
  fi
}

# ============================================================
#  6. VALIDATE DATA
# ============================================================
do_validate() {
  log "Validating apps-data.json..."
  python3 << 'PYEOF'
import json, sys

with open("apps-data.json") as f:
    data = json.load(f)

apps = data.get("apps", [])
issues = []

for a in apps:
    name = a.get("name", "???")
    # Missing description
    desc = a.get("desc", {})
    if not desc.get("en"): issues.append(f"  {name:30s} ❌ missing EN description")
    if not desc.get("fr"): issues.append(f"  {name:30s} ⚠️  missing FR description")
    if not desc.get("ar"): issues.append(f"  {name:30s} ⚠️  missing AR description")
    # Missing emoji
    if not a.get("emoji"): issues.append(f"  {name:30s} ❌ missing emoji")
    # No tags
    if not a.get("tags"): issues.append(f"  {name:30s} ⚠️  no tags")
    # No categories
    if not a.get("categories"): issues.append(f"  {name:30s} ❌ no categories")
    # Badge check
    badge = a.get("badge", "")
    if badge not in ("popular", "stable", "hub", "dev", "new", ""):
        issues.append(f"  {name:30s} ⚠️  unknown badge: {badge}")
    # Status check
    status = a.get("status", "")
    if status not in ("stable", "beta", "dev", "offline"):
        issues.append(f"  {name:30s} ⚠️  unknown status: {status}")
    # Badge/status coherence
    if badge == "new" and status == "stable":
        issues.append(f"  {name:30s} ⚠️  badge=new but status=stable (remove badge?)")
    if badge == "stable" and status != "stable":
        issues.append(f"  {name:30s} ⚠️  badge=stable but status={status}")
    if badge == "popular" and status == "offline":
        issues.append(f"  {name:30s} ⚠️  badge=popular but status=offline")
    if badge == "dev" and status == "stable":
        issues.append(f"  {name:30s} ⚠️  badge=dev but status=stable")

# Check duplicates
names = [a["name"] for a in apps]
dupes = set(n for n in names if names.count(n) > 1)
for d in dupes:
    issues.append(f"  {d:30s} ❌ DUPLICATE entry")

# Check orphans (in data but no repo)
import os
repos_dir = "repos"
if os.path.isdir(repos_dir):
    repo_names = set(os.listdir(repos_dir))
    for a in apps:
        if a["name"] not in repo_names:
            issues.append(f"  {a['name']:30s} ⚠️  no repo folder")

print(f"\n  📊 Validation: {len(apps)} apps\n")
if issues:
    for i in sorted(issues):
        print(i)
    print(f"\n  Found {len(issues)} issue(s)")
else:
    print("  ✅ All clean!")
print()
PYEOF
}

# ============================================================
#  7. EXPORT REPORT
# ============================================================
do_export() {
  log "Exporting report..."
  python3 << 'PYEOF'
import json

with open("apps-data.json") as f:
    data = json.load(f)

apps = data.get("apps", [])
print(f"\n  {'#':>3s}  {'Name':<25s} {'Emoji':>5s} {'Status':<8s} {'Badge':<10s} {'Categories':<20s} {'Tags'}")
print(f"  {'─'*110}")

for i, a in enumerate(apps, 1):
    cats = ",".join(a.get("categories", []))
    tags = ",".join(a.get("tags", [])[:4])
    print(f"  {i:3d}  {a['name']:<25s} {a.get('emoji',''):>5s} {a.get('status',''):<8s} {a.get('badge',''):<10s} {cats:<20s} {tags}")

print(f"\n  Total: {len(apps)} apps\n")

# Also export CSV
with open("apps-report.csv", "w") as f:
    f.write("name,emoji,status,badge,categories,tags,desc_en\n")
    for a in apps:
        cats = ";".join(a.get("categories", []))
        tags = ";".join(a.get("tags", []))
        desc = a.get("desc", {}).get("en", "").replace('"', '""')
        f.write(f'"{a["name"]}","{a.get("emoji","")}","{a.get("status","")}","{a.get("badge","")}","{cats}","{tags}","{desc}"\n')

print("  📄 Exported to apps-report.csv")
print()
PYEOF
}

# ============================================================
#  8. BUILD
# ============================================================
do_build() {
  log "Building..."
  if [ -f "$SCRIPT_DIR/01_build.sh" ]; then
    bash "$SCRIPT_DIR/01_build.sh"
  else
    err "01_build.sh not found"
  fi
}

# ============================================================
#  9. GENERATE THUMBNAILS
# ============================================================
do_thumbs() {
  log "Generating thumbnails..."
  if [ -f "$SCRIPT_DIR/01_build.sh" ]; then
    bash "$SCRIPT_DIR/01_build.sh" --thumbs-only
  else
    err "01_build.sh not found"
  fi
}

# ============================================================
# 10. DEPLOY
# ============================================================
do_deploy() {
  log "Deploying..."
  if [ -f "$SCRIPT_DIR/01_build.sh" ]; then
    bash "$SCRIPT_DIR/01_build.sh" --deploy
  else
    err "01_build.sh not found"
  fi
}

# ============================================================
# 11. LIST APPS
# ============================================================
do_list() {
  python3 << 'PYEOF'
import json

with open("apps-data.json") as f:
    data = json.load(f)

apps = data.get("apps", [])

# Filter menu
print("\n  Filter by:")
print("    1) All")
print("    2) Status")
print("    3) Badge")
print("    4) Category")
choice = input("  Choose [1-4]: ").strip()

filtered = apps
label = "all"

if choice == "2":
    statuses = sorted(set(a.get("status","") for a in apps))
    for i, s in enumerate(statuses, 1):
        count = sum(1 for a in apps if a.get("status") == s)
        print(f"    {i}) {s} ({count})")
    si = input("  Choose: ").strip()
    try:
        st = statuses[int(si) - 1]
        filtered = [a for a in apps if a.get("status") == st]
        label = f"status={st}"
    except: pass
elif choice == "3":
    badges = sorted(set(a.get("badge","") for a in apps))
    for i, b in enumerate(badges, 1):
        count = sum(1 for a in apps if a.get("badge") == b)
        print(f"    {i}) {b} ({count})")
    bi = input("  Choose: ").strip()
    try:
        bd = badges[int(bi) - 1]
        filtered = [a for a in apps if a.get("badge") == bd]
        label = f"badge={bd}"
    except: pass
elif choice == "4":
    all_cats = set()
    for a in apps:
        for c in a.get("categories", []):
            all_cats.add(c)
    all_cats = sorted(all_cats)
    for i, c in enumerate(all_cats, 1):
        count = sum(1 for a in apps if c in a.get("categories", []))
        print(f"    {i}) {c} ({count})")
    ci = input("  Choose: ").strip()
    try:
        ct = all_cats[int(ci) - 1]
        filtered = [a for a in apps if ct in a.get("categories", [])]
        label = f"category={ct}"
    except: pass

COLORS = {"stable": "\033[0;32m", "beta": "\033[1;33m", "dev": "\033[0;35m", "offline": "\033[0;31m"}
NC = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"

print(f"\n  Showing {len(filtered)} apps ({label}):\n")
print(f"  {'#':>3s}  {'':>3s} {'Name':<25s} {'Status':<10s} {'Badge':<10s} {'Categories'}")
print(f"  {'─'*80}")
for i, a in enumerate(filtered, 1):
    color = COLORS.get(a.get("status",""), "")
    cats = ",".join(a.get("categories", []))
    print(f"  {i:3d}  {a.get('emoji',''):>3s} {a['name']:<25s} {color}{a.get('status',''):<10s}{NC} {a.get('badge',''):<10s} {DIM}{cats}{NC}")
print()
PYEOF
}

# ============================================================
# 12. EDIT APP
# ============================================================
do_edit() {
  if [ -f "$SCRIPT_DIR/04_manage-apps.sh" ]; then
    bash "$SCRIPT_DIR/04_manage-apps.sh"
  else
    err "04_manage-apps.sh not found"
  fi
}

# ============================================================
# 13. BULK EDIT
# ============================================================
do_bulk() {
  if [ -f "$SCRIPT_DIR/04_manage-apps.sh" ]; then
    bash "$SCRIPT_DIR/04_manage-apps.sh"
  else
    err "04_manage-apps.sh not found"
  fi
}

# ============================================================
# 14. DASHBOARD
# ============================================================
do_dashboard() {
  python3 << 'PYEOF'
import json

with open("apps-data.json") as f:
    data = json.load(f)

apps = data.get("apps", [])
G = "\033[0;32m"; Y = "\033[1;33m"; P = "\033[0;35m"; R = "\033[0;31m"
C = "\033[0;36m"; B = "\033[1m"; D = "\033[2m"; N = "\033[0m"

stable = sum(1 for a in apps if a.get("status") == "stable")
beta   = sum(1 for a in apps if a.get("status") == "beta")
dev    = sum(1 for a in apps if a.get("status") == "dev")
offline= sum(1 for a in apps if a.get("status") == "offline")

print(f"\n  {B}{C}╔══════════════════════════════════════╗{N}")
print(f"  {B}{C}║       📊 Dashboard                   ║{N}")
print(f"  {B}{C}╚══════════════════════════════════════╝{N}")

print(f"\n  {B}Total apps: {len(apps)}{N}\n")
print(f"  {B}By Status:{N}")
print(f"    {G}● Stable:  {stable:3d}{N}  {'█' * stable}")
print(f"    {Y}● Beta:    {beta:3d}{N}  {'█' * beta}")
print(f"    {P}● Dev:     {dev:3d}{N}  {'█' * dev}")
print(f"    {R}● Offline: {offline:3d}{N}  {'█' * offline}")

print(f"\n  {B}By Badge:{N}")
badges = {}
for a in apps:
    b = a.get("badge", "none")
    badges[b] = badges.get(b, 0) + 1
for b in sorted(badges):
    print(f"    {b:<12s} {badges[b]:3d}  {'█' * badges[b]}")

print(f"\n  {B}By Category:{N}")
cats = {}
for a in apps:
    for c in a.get("categories", []):
        cats[c] = cats.get(c, 0) + 1
for c in sorted(cats, key=cats.get, reverse=True):
    print(f"    {c:<14s} {cats[c]:3d}  {'█' * cats[c]}")

# i18n coverage
en = sum(1 for a in apps if a.get("desc",{}).get("en"))
fr = sum(1 for a in apps if a.get("desc",{}).get("fr"))
ar = sum(1 for a in apps if a.get("desc",{}).get("ar"))
print(f"\n  {B}i18n Coverage:{N}")
print(f"    EN: {en}/{len(apps)}  {'✅' if en == len(apps) else '⚠️'}")
print(f"    FR: {fr}/{len(apps)}  {'✅' if fr == len(apps) else '⚠️'}")
print(f"    AR: {ar}/{len(apps)}  {'✅' if ar == len(apps) else '⚠️'}")
print()
PYEOF
}

# ============================================================
# 15. EVENT FLYER
# ============================================================
do_event_flyer() {
  log "Event flyer generator"
  mkdir -p "$FLYERS_DIR"

  # Pick app with search/filter
  echo ""
  local names
  mapfile -t names < <(app_names)
  echo -e "  ${BOLD}Select app${NC} (type name to filter, or number):"
  for i in "${!names[@]}"; do
    printf "  %3d) %s\n" "$((i+1))" "${names[$i]}"
  done | column
  echo ""
  read -p "  App (number or search): " input < /dev/tty

  local app_name=""
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    app_name="${names[$((input-1))]}"
  else
    # Search by name
    local matches=()
    for n in "${names[@]}"; do
      [[ "$n" == *"$input"* ]] && matches+=("$n")
    done
    if [ ${#matches[@]} -eq 1 ]; then
      app_name="${matches[0]}"
    elif [ ${#matches[@]} -gt 1 ]; then
      echo -e "  ${BOLD}Multiple matches:${NC}"
      for i in "${!matches[@]}"; do
        printf "  %3d) %s\n" "$((i+1))" "${matches[$i]}"
      done
      read -p "  Pick: " mi < /dev/tty
      app_name="${matches[$((mi-1))]}"
    fi
  fi
  [ -z "$app_name" ] && { err "Invalid selection"; return; }

  log "Selected: ${BOLD}$app_name${NC}"

  # Get app data
  local emoji=$(app_field "$app_name" "emoji")
  local cats=$(app_field "$app_name" "categories")
  local desc_fr
  desc_fr=$(python3 -c "
import json
data = json.load(open('$DATA_FILE'))
for a in data.get('apps',[]):
    if a['name'] == '$app_name':
        print(a.get('desc',{}).get('fr',''))
        break
" 2>/dev/null)

  # Auto theme by category
  local accent="#d4820a" bg="#fdf6e3" theme="Gold"
  case "$cats" in
    *ai*|*camera*)   accent="#0a9e72"; bg="#e8f8f2"; theme="Teal" ;;
    *learning*|*classroom*|*tools*) accent="#3a7bd5"; bg="#e8f0fe"; theme="Blue" ;;
    *arabic*)        accent="#7c3aed"; bg="#f3e8ff"; theme="Violet" ;;
  esac
  echo -e "  🎨 Theme: ${BOLD}$theme${NC} (from category: $cats)"

  # Theme override
  read -p "  Override theme? (g=Gold, t=Teal, b=Blue, v=Violet, Enter=keep): " tov < /dev/tty
  case "$tov" in
    g|G) accent="#d4820a"; bg="#fdf6e3"; theme="Gold" ;;
    t|T) accent="#0a9e72"; bg="#e8f8f2"; theme="Teal" ;;
    b|B) accent="#3a7bd5"; bg="#e8f0fe"; theme="Blue" ;;
    v|V) accent="#7c3aed"; bg="#f3e8ff"; theme="Violet" ;;
  esac
  [ -n "$tov" ] && echo -e "  🎨 Theme overridden to: ${BOLD}$theme${NC}"

  # Prompt for event details
  echo ""
  read -p "  📅 Date (ex: Dimanche 8 mars 2026): " ev_date < /dev/tty
  read -p "  🕘 Horaire (ex: 9h – 11h30): " ev_time < /dev/tty
  read -p "  📍 Lieu (ex: Parc du Souvenir — Chelles): " ev_lieu < /dev/tty
  [ -z "$ev_date" ] && ev_date="JJ mois AAAA"
  [ -z "$ev_time" ] && ev_time="HHh – HHh"
  [ -z "$ev_lieu" ] && ev_lieu="Lieu à définir"

  # Auto-suggest features from README
  local readme_feats=""
  if [ -f "$REPOS_DIR/$app_name/README.md" ]; then
    readme_feats=$(grep -E '^\s*[-*] ' "$REPOS_DIR/$app_name/README.md" 2>/dev/null | head -6 | sed 's/^[[:space:]]*[-*] //')
    if [ -n "$readme_feats" ]; then
      echo ""
      echo -e "  ${DIM}Features found in README:${NC}"
      echo "$readme_feats" | head -4 | nl -ba -w3 -s') '
    fi
  fi

  # Prompt for 4 features
  echo ""
  echo -e "  ${BOLD}4 features (with emoji):${NC} ${DIM}(Enter=defaults)${NC}"
  local feat1 feat2 feat3 feat4
  read -p "  1) " feat1 < /dev/tty
  read -p "  2) " feat2 < /dev/tty
  read -p "  3) " feat3 < /dev/tty
  read -p "  4) " feat4 < /dev/tty
  [ -z "$feat1" ] && feat1="🔧 Découvre l'application"
  [ -z "$feat2" ] && feat2="📡 Connecte-toi en Bluetooth"
  [ -z "$feat3" ] && feat3="🎮 Teste les fonctionnalités"
  [ -z "$feat4" ] && feat4="🚀 Partage tes résultats"

  # Numbering
  local next_num
  next_num=$(printf "%03d" $(( $(ls "$FLYERS_DIR"/*.html 2>/dev/null | wc -l) + 1 )))
  local out_html="$FLYERS_DIR/${next_num}_${app_name}.html"
  local out_txt="$FLYERS_DIR/${next_num}_${app_name}.txt"
  local app_url="https://abourdim.github.io/${app_name}/"

  # Generate QR
  local qr_b64
  qr_b64=$(python3 -c "
import qrcode, base64, io
qr = qrcode.QRCode(version=2, error_correction=qrcode.constants.ERROR_CORRECT_H, box_size=8, border=2)
qr.add_data('$app_url')
qr.make(fit=True)
img = qr.make_image(fill_color='$accent', back_color='$bg').convert('RGBA')
buf = io.BytesIO()
img.save(buf, 'PNG')
print(base64.b64encode(buf.getvalue()).decode())
" 2>/dev/null)

  if [ -z "$qr_b64" ]; then
    warn "QR generation failed (pip install qrcode pillow)"
    qr_b64=""
  fi

  # Title split: accent first word
  local title_acc title_rest
  title_acc=$(echo "$app_name" | cut -d'-' -f1 | sed 's/.*/\u&/')
  title_rest="-$(echo "$app_name" | cut -d'-' -f2- | sed 's/.*/\u&/')"
  [ "$title_rest" = "-" ] && title_rest=""

  # Generate HTML
  python3 - "$out_html" "$app_name" "$emoji" "$title_acc" "$title_rest" \
    "$desc_fr" "$feat1" "$feat2" "$feat3" "$feat4" \
    "$ev_date" "$ev_time" "$ev_lieu" "$app_url" \
    "$accent" "$bg" "$qr_b64" "$cats" << 'PYEOF'
import sys

out_html, app_name, emoji, title_acc, title_rest = sys.argv[1:6]
desc_fr = sys.argv[6]
feat1, feat2, feat3, feat4 = sys.argv[7:11]
ev_date, ev_time, ev_lieu, app_url = sys.argv[11:15]
accent, bg, qr_b64, cats = sys.argv[15:19]

# Parse features: split emoji from text
def parse_feat(f):
    if len(f) > 2 and f[0] not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789":
        # First char(s) are emoji
        parts = f.split(" ", 1)
        return parts[0], parts[1] if len(parts) > 1 else ""
    return "🔧", f

f1e, f1t = parse_feat(feat1)
f2e, f2t = parse_feat(feat2)
f3e, f3t = parse_feat(feat3)
f4e, f4t = parse_feat(feat4)

# Compute wash color from accent
def hex_to_rgba(h, a):
    r, g, b = int(h[1:3],16), int(h[3:5],16), int(h[5:7],16)
    return f"rgba({r},{g},{b},{a})"

wash1 = hex_to_rgba(accent, 0.08)
wash2 = hex_to_rgba(accent, 0.02)
bismillah_color = hex_to_rgba(accent, 0.38)

# Islamic SVG pattern
islamic_b64 = "PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHdpZHRoPScxMDAnIGhlaWdodD0nMTAwJz4KICA8ZGVmcz48cGF0dGVybiBpZD0nZycgd2lkdGg9JzEwMCcgaGVpZ2h0PScxMDAnIHBhdHRlcm5Vbml0cz0ndXNlclNwYWNlT25Vc2UnPgogICAgPGcgZmlsbD0nbm9uZScgc3Ryb2tlPSdyZ2JhKDIwMCwxNjAsNjAsMC4wOSknIHN0cm9rZS13aWR0aD0nMC43Jz4KICAgICAgPHBvbHlnb24gcG9pbnRzPSc1MCw2IDU4LDMwIDgyLDIyIDcwLDQ0IDg0LDYyIDYwLDU2IDU4LDgwIDUwLDYyIDQyLDgwIDQwLDU2IDE2LDYyIDMwLDQ0IDE4LDIyIDQyLDMwJy8+CiAgICAgIDxwb2x5Z29uIHBvaW50cz0nNTAsMjQgNTUsMzYgNjgsMzIgNjIsNDIgNzAsNTIgNTcsNTAgNTYsNjIgNTAsNTQgNDQsNjIgNDMsNTAgMzAsNTIgMzgsNDIgMzIsMzIgNDUsMzYnLz4KICAgICAgPGNpcmNsZSBjeD0nNTAnIGN5PSc1MCcgcj0nMTEnIHN0cm9rZS13aWR0aD0nMC41Jy8+CiAgICA8L2c+CiAgPC9wYXR0ZXJuPjwvZGVmcz4KICA8cmVjdCB3aWR0aD0nMTAwJyBoZWlnaHQ9JzEwMCcgZmlsbD0ndXJsKCNnKScvPgo8L3N2Zz4="

qr_img = f'<img src="data:image/png;base64,{qr_b64}" alt="QR" style="border-color:{accent};"/>' if qr_b64 else '<div style="width:130px;height:130px;border:3px solid {accent};border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:11px;color:#999;">QR</div>'

html = f'''<!DOCTYPE html>
<html lang="fr"><head><meta charset="UTF-8">
<title>Atelier {app_name} — Workshop DIY</title>
<link href="https://fonts.googleapis.com/css2?family=Fredoka+One&family=Nunito:wght@400;600;700;800;900&display=swap" rel="stylesheet">
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ background:#fff; font-family:'Nunito',sans-serif; }}
.flyer {{ width:1080px; position:relative; overflow:hidden; padding-bottom:48px; background:{bg}; }}
.bg-pattern {{
  position:absolute; inset:0; pointer-events:none; z-index:1;
  background-image:url("data:image/svg+xml;base64,{islamic_b64}");
  background-size:100px 100px;
}}
.bg-wash {{ position:absolute; inset:0; pointer-events:none; z-index:2;
  background:linear-gradient(160deg, {wash1} 0%, rgba(255,248,220,0.5) 50%, {wash2} 100%); }}
.bismillah {{
  position:absolute; top:10px; left:50%; transform:translateX(-50%);
  font-size:15px; letter-spacing:3px; z-index:20; white-space:nowrap;
  font-family:'Scheherazade New','Arial Unicode MS',serif;
  color:{bismillah_color};
}}
.topbar {{
  position:relative; z-index:20;
  display:flex; align-items:center; justify-content:space-between;
  padding:48px 56px 24px;
}}
.logo-box {{
  background:rgba(255,255,255,0.9); border:2px solid rgba(0,0,0,0.12);
  border-radius:18px; padding:10px 18px;
}}
.logo-text {{ font-family:'Fredoka One',cursive; font-size:20px; color:#1a1a2e; }}
.hero {{ position:relative; z-index:20; padding:0 56px 18px; }}
.sub-tag {{
  font-size:12px; font-weight:800; letter-spacing:3px; text-transform:uppercase;
  display:flex; align-items:center; gap:8px; margin-bottom:8px;
  color:{accent}; opacity:0.7;
}}
.atelier-label {{
  font-family:'Fredoka One',cursive; font-size:24px; letter-spacing:3px;
  text-transform:uppercase; margin-bottom:0px; opacity:0.65; color:{accent};
}}
.title {{
  font-family:'Fredoka One',cursive; font-size:82px; line-height:1;
  margin-bottom:16px; display:flex; align-items:center; gap:12px; color:#1a1a2e;
}}
.title .acc {{ color:{accent}; }}
.desc {{ font-size:17px; line-height:1.65; max-width:840px; margin-bottom:18px; color:#2c2c3e; font-weight:600; }}
.features {{ display:flex; flex-direction:column; gap:10px; margin-bottom:24px; }}
.feat-item {{
  display:flex; align-items:center; gap:14px; font-size:16px; font-weight:700;
  padding:12px 18px; border-radius:14px; color:#1a1a2e;
  background:rgba(255,255,255,0.75); border-left:4px solid {accent};
  box-shadow:0 2px 8px rgba(0,0,0,0.06);
}}
.feat-item .fi {{ font-size:22px; flex-shrink:0; }}
.audience-row {{
  position:relative; z-index:20;
  display:flex; gap:12px; padding:0 56px 22px; flex-wrap:wrap;
}}
.aud-pill {{
  display:flex; align-items:center; gap:9px; padding:10px 22px; border-radius:50px;
  font-size:15px; font-weight:800; color:#1a1a2e;
  background:rgba(255,255,255,0.8); box-shadow:0 2px 8px rgba(0,0,0,0.1);
  border:2px solid rgba(0,0,0,0.08);
}}
.price-banner {{
  position:relative; z-index:20; margin:0 56px 22px; border-radius:20px;
  padding:22px 28px; display:flex; align-items:center; gap:20px;
  background:rgba(255,255,255,0.85); box-shadow:0 4px 16px rgba(0,0,0,0.1);
  border:2px solid rgba(0,0,0,0.07);
}}
.price-item {{ display:flex; align-items:center; gap:14px; flex:1; }}
.price-icon {{ font-size:32px; }}
.price-lbl {{ font-size:11px; font-weight:800; letter-spacing:2px; text-transform:uppercase; color:#666; margin-bottom:3px; }}
.price-val {{ font-size:22px; font-weight:900; color:#1a1a2e; }}
.price-divider {{ width:2px; height:50px; background:rgba(0,0,0,0.08); border-radius:2px; }}
.atelier-banner {{
  position:relative; z-index:20; margin:0 56px 22px;
  border-radius:20px; padding:22px 28px;
  display:flex; align-items:center; justify-content:space-between; gap:24px;
  background:rgba(255,255,255,0.85); box-shadow:0 4px 16px rgba(0,0,0,0.1);
  border:2px solid {accent}55;
}}
.atelier-left {{ flex:1; }}
.atelier-title {{
  font-family:'Fredoka One',cursive; font-size:22px; color:#1a1a2e;
  margin-bottom:8px; display:flex; align-items:center; gap:10px;
}}
.atelier-title .badge {{
  font-size:10px; font-weight:900; letter-spacing:2px; text-transform:uppercase;
  padding:4px 12px; border-radius:20px; background:{accent}22; color:{accent};
}}
.atelier-desc {{ font-size:14px; font-weight:700; color:#444; line-height:1.5; margin-bottom:8px; }}
.atelier-url {{ font-size:12px; font-weight:700; word-break:break-all; font-family:monospace; color:#555; }}
.atelier-cta {{ font-size:14px; font-weight:900; margin-top:10px; color:{accent}; }}
.qr-wrap {{ display:flex; flex-direction:column; align-items:center; gap:8px; }}
.qr-wrap img {{ width:130px; height:130px; border-radius:12px; padding:6px; border:3px solid; }}
.qr-label {{ font-size:10px; font-weight:900; letter-spacing:1.5px; text-transform:uppercase; color:#666; }}
.info-row {{
  position:relative; z-index:20; display:flex; gap:14px; padding:0 56px 18px;
}}
.info-card {{
  flex:1; border-radius:16px; padding:16px 20px;
  display:flex; align-items:center; gap:12px;
  background:rgba(255,255,255,0.85); box-shadow:0 2px 10px rgba(0,0,0,0.08);
  border:2px solid rgba(0,0,0,0.07);
}}
.info-icon {{ font-size:26px; flex-shrink:0; }}
.lbl {{ font-size:10px; letter-spacing:2px; text-transform:uppercase; color:#888; font-weight:800; margin-bottom:3px; }}
.val {{ font-size:16px; font-weight:900; color:#1a1a2e; line-height:1.3; }}
.contact-bar {{
  position:relative; z-index:20;
  display:flex; align-items:center; gap:14px; padding:0 56px 22px; flex-wrap:wrap;
}}
.ci-item {{ font-size:14px; font-weight:700; color:#444; display:flex; align-items:center; gap:6px; }}
.dot-sep {{ color:#bbb; font-size:18px; }}
.footer {{
  position:relative; z-index:20; margin:0 56px;
  border-top:2px solid rgba(0,0,0,0.08); padding-top:18px;
  display:flex; align-items:center; justify-content:space-between;
}}
.fnote {{ font-size:13px; color:#888; font-style:italic; font-weight:600; }}
.htags {{ display:flex; gap:8px; }}
.ht {{
  font-size:12px; font-weight:800; padding:5px 12px; border-radius:20px;
  border:2px solid rgba(0,0,0,0.1); color:#555; background:rgba(255,255,255,0.6);
}}
</style>
</head><body>
<div class="flyer">
  <div class="bg-pattern"></div>
  <div class="bg-wash"></div>
  <div class="bismillah">\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064e\u0647\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0652\u0645\u064e\u0640\u0646\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0650\u064a\u0645\u0650</div>

  <div class="topbar">
    <div class="logo-box"><span class="logo-text">Workshop-DIY</span></div>
  </div>

  <div class="hero">
    <div class="sub-tag">\u25c6 Workshop-DIY \u00b7 {cats}</div>
    <div class="atelier-label">Atelier</div>
    <div class="title">{emoji} <span class="acc">{title_acc}</span>{title_rest}</div>
    <div class="desc">{desc_fr}</div>
    <div class="features">
      <div class="feat-item"><span class="fi">{f1e}</span><span>{f1t}</span></div>
      <div class="feat-item"><span class="fi">{f2e}</span><span>{f2t}</span></div>
      <div class="feat-item"><span class="fi">{f3e}</span><span>{f3t}</span></div>
      <div class="feat-item"><span class="fi">{f4e}</span><span>{f4t}</span></div>
    </div>
  </div>

  <div class="audience-row">
    <div class="aud-pill">\U0001f466 \u00c0 partir de 10 ans</div>
    <div class="aud-pill">\U0001f4bb PC portable recommand\u00e9</div>
    <div class="aud-pill">\U0001f393 Aucun pr\u00e9requis</div>
  </div>

  <div class="price-banner">
    <div class="price-item">
      <div class="price-icon">\U0001fa99</div>
      <div class="price-text">
        <div class="price-lbl">Adh\u00e9rents Workshop-DIY</div>
        <div class="price-val" style="color:#2e7d32;">Gratuit \u2705</div>
      </div>
    </div>
    <div class="price-divider"></div>
    <div class="price-item">
      <div class="price-icon">\U0001f39f\ufe0f</div>
      <div class="price-text">
        <div class="price-lbl">Non-adh\u00e9rents</div>
        <div class="price-val">7 \u20ac / personne</div>
      </div>
    </div>
    <div class="price-divider"></div>
    <div class="price-item" style="flex:0.7;">
      <div class="price-icon">\u2139\ufe0f</div>
      <div class="price-text">
        <div class="price-lbl">Devenir adh\u00e9rent</div>
        <div class="price-val" style="font-size:15px;">workshop-diy.org</div>
      </div>
    </div>
  </div>

  <div class="atelier-banner">
    <div class="atelier-left">
      <div class="atelier-title">
        \U0001f680 Lancer l\u2019atelier
        <span class="badge">EN LIGNE</span>
      </div>
      <div class="atelier-desc">Ouvre l\u2019application dans ton navigateur \u2014 aucune installation requise !</div>
      <div class="atelier-url">{app_url}</div>
      <div class="atelier-cta">\u2191 Scanne le QR code ou tape l\u2019URL \u25b6</div>
    </div>
    <div class="qr-wrap">
      {qr_img}
      <div class="qr-label">Scanner pour lancer</div>
    </div>
  </div>

  <div class="info-row">
    <div class="info-card">
      <div class="info-icon">\U0001f4c5</div>
      <div class="info-text"><div class="lbl">Date</div><div class="val"><em>{ev_date}</em></div></div>
    </div>
    <div class="info-card">
      <div class="info-icon">\U0001f558</div>
      <div class="info-text"><div class="lbl">Horaire</div><div class="val"><em>{ev_time}</em></div></div>
    </div>
    <div class="info-card">
      <div class="info-icon">\U0001f4cd</div>
      <div class="info-text"><div class="lbl">Lieu</div><div class="val"><em>{ev_lieu}</em></div></div>
    </div>
  </div>

  <div class="contact-bar">
    <div class="ci-item">\U0001f310 workshop-diy.org</div>
    <span class="dot-sep">\u00b7</span>
    <div class="ci-item">\u2709\ufe0f contact@workshop-diy.org</div>
    <span class="dot-sep">\u00b7</span>
    <div class="ci-item">\U0001f4de 06 19 51 51 73</div>
  </div>

  <div class="footer">
    <div class="fnote">\u2728 Curiosit\u00e9 et sourire bienvenus !</div>
    <div class="htags">
      <span class="ht">#Atelier{title_acc}{title_rest.lstrip("-")}</span>
      <span class="ht">#WorkshopDIY</span>
    </div>
  </div>
</div></body></html>'''

with open(out_html, "w") as f:
    f.write(html)
print(f"  ✅ {out_html}")
PYEOF

  # Generate Facebook post
  cat > "$out_txt" << FBEOF
$emoji Atelier ${title_acc}${title_rest} — Workshop DIY

$desc_fr

Lors de cet atelier tu vas :
$feat1
$feat2
$feat3
$feat4

👦 À partir de 10 ans | 💻 PC portable recommandé | 🎓 Aucun prérequis

💰 Tarifs :
🪙 Adhérents Workshop-DIY → Gratuit ✅
🎟️ Non-adhérents → 7 € / personne
ℹ️ Devenir adhérent : workshop-diy.org

🔗 Lancer l'atelier : $app_url

📅 $ev_date | 🕘 $ev_time
📍 $ev_lieu

🌐 workshop-diy.org | ✉️ contact@workshop-diy.org | 📞 06 19 51 51 73

#Atelier${title_acc}${title_rest//-/} #WorkshopDIY
FBEOF
  ok "Facebook post: $out_txt"
}

# ============================================================
# 16. APP CATALOG
# ============================================================
do_catalog() {
  log "Generating app catalog..."
  mkdir -p "$FLYERS_DIR"

  python3 << 'PYEOF'
import json, os

try:
    import qrcode, base64, io
    HAS_QR = True
except ImportError:
    HAS_QR = False

with open("apps-data.json") as f:
    data = json.load(f)

apps = sorted(data.get("apps", []), key=lambda a: a["name"])

def gen_qr_b64(url):
    if not HAS_QR:
        return ""
    qr = qrcode.QRCode(version=1, error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=4, border=1)
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="#333", back_color="#fff").convert("RGBA")
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return base64.b64encode(buf.getvalue()).decode()

rows = ""
for a in apps:
    if a.get("status") == "offline":
        continue
    name = a["name"]
    emoji = a.get("emoji", "\U0001f527")
    desc = a.get("desc", {}).get("fr", a.get("desc", {}).get("en", ""))
    cats = ", ".join(a.get("categories", []))
    url = f"https://abourdim.github.io/{name}/"
    badge = a.get("badge", "")
    badge_html = f'<span style="font-size:10px;background:#d4820a22;color:#d4820a;padding:2px 8px;border-radius:10px;font-weight:800;">{badge}</span>' if badge in ("popular","hub") else ""

    qr_b64 = gen_qr_b64(url)
    qr_html = f'<img src="data:image/png;base64,{qr_b64}" width="48" height="48" style="border-radius:4px;"/>' if qr_b64 else '<span style="font-size:10px;color:#ccc;">—</span>'

    rows += f"""<tr>
      <td style="font-size:28px;text-align:center;width:50px;">{emoji}</td>
      <td><strong>{name}</strong> {badge_html}<br><span style="font-size:13px;color:#555;">{desc}</span></td>
      <td style="font-size:11px;color:#888;">{cats}</td>
      <td style="font-size:11px;"><a href="{url}" style="color:#3a7bd5;">{url}</a></td>
      <td style="text-align:center;width:60px;">{qr_html}</td>
    </tr>"""

html = f"""<!DOCTYPE html>
<html lang="fr"><head><meta charset="UTF-8">
<title>Workshop-DIY — Catalogue Apps</title>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
body {{ font-family:'Nunito',sans-serif; background:#fafafa; padding:40px; }}
h1 {{ font-size:28px; margin-bottom:8px; }}
.sub {{ font-size:14px; color:#888; margin-bottom:24px; }}
table {{ width:100%; border-collapse:collapse; }}
th {{ text-align:left; font-size:11px; text-transform:uppercase; letter-spacing:2px; color:#888; padding:8px 12px; border-bottom:2px solid #eee; }}
td {{ padding:10px 12px; border-bottom:1px solid #f0f0f0; vertical-align:middle; }}
tr:hover {{ background:#f5f5f5; }}
@media print {{ body {{ padding:20px; }} }}
</style>
</head><body>
<h1>\U0001f6e0\ufe0f Workshop-DIY — Catalogue</h1>
<p class="sub">{len([a for a in apps if a.get('status') != 'offline'])} applications éducatives</p>
<table>
<tr><th style="width:50px;"></th><th>Application</th><th>Catégorie</th><th>Lien</th><th style="width:60px;">QR</th></tr>
{rows}
</table>
</body></html>"""

out = "repos/flyers/catalog.html"
with open(out, "w") as f:
    f.write(html)
count = len([a for a in apps if a.get("status") != "offline"])
print(f"  \u2705 {out} ({count} apps)")
if not HAS_QR:
    print("  \u26a0\ufe0f  QR codes skipped (pip install qrcode pillow)")
PYEOF
}

# ============================================================
# 17. BATCH FLYERS
# ============================================================
do_batch_flyers() {
  log "Batch flyer generation"
  echo ""
  echo -e "  ${YELLOW}This will generate one flyer per app (with placeholders).${NC}"
  echo -e "  ${DIM}Skip: offline apps and already-existing flyers.${NC}"
  read -p "  Continue? (y/n): " confirm < /dev/tty
  [ "$confirm" != "y" ] && return

  mkdir -p "$FLYERS_DIR"

  python3 << 'PYEOF'
import json, os, sys

try:
    import qrcode, base64, io
    HAS_QR = True
except ImportError:
    HAS_QR = False

FLYERS_DIR = "repos/flyers"
with open("apps-data.json") as f:
    data = json.load(f)

apps = data.get("apps", [])

THEMES = {
    "microbit": ("#d4820a", "#fdf6e3"),
    "hardware": ("#d4820a", "#fdf6e3"),
    "ai":       ("#0a9e72", "#e8f8f2"),
    "camera":   ("#0a9e72", "#e8f8f2"),
    "learning": ("#3a7bd5", "#e8f0fe"),
    "classroom":("#3a7bd5", "#e8f0fe"),
    "tools":    ("#3a7bd5", "#e8f0fe"),
    "arabic":   ("#7c3aed", "#f3e8ff"),
}

islamic_b64 = "PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHdpZHRoPScxMDAnIGhlaWdodD0nMTAwJz4KICA8ZGVmcz48cGF0dGVybiBpZD0nZycgd2lkdGg9JzEwMCcgaGVpZ2h0PScxMDAnIHBhdHRlcm5Vbml0cz0ndXNlclNwYWNlT25Vc2UnPgogICAgPGcgZmlsbD0nbm9uZScgc3Ryb2tlPSdyZ2JhKDIwMCwxNjAsNjAsMC4wOSknIHN0cm9rZS13aWR0aD0nMC43Jz4KICAgICAgPHBvbHlnb24gcG9pbnRzPSc1MCw2IDU4LDMwIDgyLDIyIDcwLDQ0IDg0LDYyIDYwLDU2IDU4LDgwIDUwLDYyIDQyLDgwIDQwLDU2IDE2LDYyIDMwLDQ0IDE4LDIyIDQyLDMwJy8+CiAgICAgIDxwb2x5Z29uIHBvaW50cz0nNTAsMjQgNTUsMzYgNjgsMzIgNjIsNDIgNzAsNTIgNTcsNTAgNTYsNjIgNTAsNTQgNDQsNjIgNDMsNTAgMzAsNTIgMzgsNDIgMzIsMzIgNDUsMzYnLz4KICAgICAgPGNpcmNsZSBjeD0nNTAnIGN5PSc1MCcgcj0nMTEnIHN0cm9rZS13aWR0aD0nMC41Jy8+CiAgICA8L2c+CiAgPC9wYXR0ZXJuPjwvZGVmcz4KICA8cmVjdCB3aWR0aD0nMTAwJyBoZWlnaHQ9JzEwMCcgZmlsbD0ndXJsKCNnKScvPgo8L3N2Zz4="

def get_theme(cats_str):
    for cat in cats_str.split(","):
        cat = cat.strip()
        if cat in THEMES:
            return THEMES[cat]
    return ("#3a7bd5", "#e8f0fe")

def hex_to_rgba(h, a):
    r, g, b = int(h[1:3],16), int(h[3:5],16), int(h[5:7],16)
    return f"rgba({r},{g},{b},{a})"

def gen_qr_b64(url, accent, bg):
    if not HAS_QR:
        return ""
    qr = qrcode.QRCode(version=2, error_correction=qrcode.constants.ERROR_CORRECT_H, box_size=8, border=2)
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color=accent, back_color=bg).convert("RGBA")
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return base64.b64encode(buf.getvalue()).decode()

generated = 0
skipped = 0

for i, a in enumerate(apps, 1):
    name = a["name"]
    if a.get("status") == "offline":
        continue
    num = f"{i:03d}"
    out = os.path.join(FLYERS_DIR, f"{num}_{name}.html")
    if os.path.isfile(out):
        skipped += 1
        continue

    emoji = a.get("emoji", "\U0001f527")
    cats = ",".join(a.get("categories", []))
    desc_fr = a.get("desc", {}).get("fr", a.get("desc", {}).get("en", f"{name} — Workshop DIY"))
    url = f"https://abourdim.github.io/{name}/"
    accent, bg = get_theme(cats)
    wash1 = hex_to_rgba(accent, 0.08)
    wash2 = hex_to_rgba(accent, 0.02)
    bis_color = hex_to_rgba(accent, 0.38)

    # Title: first word accented
    parts = name.split("-")
    title_acc = parts[0].capitalize()
    title_rest = "-" + "-".join(p.capitalize() for p in parts[1:]) if len(parts) > 1 else ""

    # QR code
    qr_b64 = gen_qr_b64(url, accent, bg)
    qr_img = f'<img src="data:image/png;base64,{qr_b64}" alt="QR" style="border-color:{accent};"/>' if qr_b64 else f'<div style="width:130px;height:130px;border:3px solid {accent};border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:11px;color:#999;">QR</div>'

    html = f'''<!DOCTYPE html>
<html lang="fr"><head><meta charset="UTF-8">
<title>Atelier {name} — Workshop DIY</title>
<link href="https://fonts.googleapis.com/css2?family=Fredoka+One&family=Nunito:wght@400;600;700;800;900&display=swap" rel="stylesheet">
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ background:#fff; font-family:'Nunito',sans-serif; }}
.flyer {{ width:1080px; position:relative; overflow:hidden; padding-bottom:48px; background:{bg}; }}
.bg-pattern {{ position:absolute; inset:0; pointer-events:none; z-index:1; background-image:url("data:image/svg+xml;base64,{islamic_b64}"); background-size:100px 100px; }}
.bg-wash {{ position:absolute; inset:0; pointer-events:none; z-index:2; background:linear-gradient(160deg, {wash1} 0%, rgba(255,248,220,0.5) 50%, {wash2} 100%); }}
.bismillah {{ position:absolute; top:10px; left:50%; transform:translateX(-50%); font-size:15px; letter-spacing:3px; z-index:20; white-space:nowrap; font-family:'Scheherazade New','Arial Unicode MS',serif; color:{bis_color}; }}
.topbar {{ position:relative; z-index:20; display:flex; align-items:center; justify-content:space-between; padding:48px 56px 24px; }}
.logo-box {{ background:rgba(255,255,255,0.9); border:2px solid rgba(0,0,0,0.12); border-radius:18px; padding:10px 18px; }}
.logo-text {{ font-family:'Fredoka One',cursive; font-size:20px; color:#1a1a2e; }}
.hero {{ position:relative; z-index:20; padding:0 56px 18px; }}
.sub-tag {{ font-size:12px; font-weight:800; letter-spacing:3px; text-transform:uppercase; display:flex; align-items:center; gap:8px; margin-bottom:8px; color:{accent}; opacity:0.7; }}
.atelier-label {{ font-family:'Fredoka One',cursive; font-size:24px; letter-spacing:3px; text-transform:uppercase; margin-bottom:0px; opacity:0.65; color:{accent}; }}
.title {{ font-family:'Fredoka One',cursive; font-size:82px; line-height:1; margin-bottom:16px; display:flex; align-items:center; gap:12px; color:#1a1a2e; }}
.title .acc {{ color:{accent}; }}
.desc {{ font-size:17px; line-height:1.65; max-width:840px; margin-bottom:18px; color:#2c2c3e; font-weight:600; }}
.features {{ display:flex; flex-direction:column; gap:10px; margin-bottom:24px; }}
.feat-item {{ display:flex; align-items:center; gap:14px; font-size:16px; font-weight:700; padding:12px 18px; border-radius:14px; color:#1a1a2e; background:rgba(255,255,255,0.75); border-left:4px solid {accent}; box-shadow:0 2px 8px rgba(0,0,0,0.06); }}
.feat-item .fi {{ font-size:22px; flex-shrink:0; }}
.audience-row {{ position:relative; z-index:20; display:flex; gap:12px; padding:0 56px 22px; flex-wrap:wrap; }}
.aud-pill {{ display:flex; align-items:center; gap:9px; padding:10px 22px; border-radius:50px; font-size:15px; font-weight:800; color:#1a1a2e; background:rgba(255,255,255,0.8); box-shadow:0 2px 8px rgba(0,0,0,0.1); border:2px solid rgba(0,0,0,0.08); }}
.price-banner {{ position:relative; z-index:20; margin:0 56px 22px; border-radius:20px; padding:22px 28px; display:flex; align-items:center; gap:20px; background:rgba(255,255,255,0.85); box-shadow:0 4px 16px rgba(0,0,0,0.1); border:2px solid rgba(0,0,0,0.07); }}
.price-item {{ display:flex; align-items:center; gap:14px; flex:1; }}
.price-icon {{ font-size:32px; }}
.price-lbl {{ font-size:11px; font-weight:800; letter-spacing:2px; text-transform:uppercase; color:#666; margin-bottom:3px; }}
.price-val {{ font-size:22px; font-weight:900; color:#1a1a2e; }}
.price-divider {{ width:2px; height:50px; background:rgba(0,0,0,0.08); border-radius:2px; }}
.atelier-banner {{ position:relative; z-index:20; margin:0 56px 22px; border-radius:20px; padding:22px 28px; display:flex; align-items:center; justify-content:space-between; gap:24px; background:rgba(255,255,255,0.85); box-shadow:0 4px 16px rgba(0,0,0,0.1); border:2px solid {accent}55; }}
.atelier-left {{ flex:1; }}
.atelier-title {{ font-family:'Fredoka One',cursive; font-size:22px; color:#1a1a2e; margin-bottom:8px; display:flex; align-items:center; gap:10px; }}
.atelier-title .badge {{ font-size:10px; font-weight:900; letter-spacing:2px; text-transform:uppercase; padding:4px 12px; border-radius:20px; background:{accent}22; color:{accent}; }}
.atelier-desc {{ font-size:14px; font-weight:700; color:#444; line-height:1.5; margin-bottom:8px; }}
.atelier-url {{ font-size:12px; font-weight:700; word-break:break-all; font-family:monospace; color:#555; }}
.atelier-cta {{ font-size:14px; font-weight:900; margin-top:10px; color:{accent}; }}
.qr-wrap {{ display:flex; flex-direction:column; align-items:center; gap:8px; }}
.qr-wrap img {{ width:130px; height:130px; border-radius:12px; padding:6px; border:3px solid; }}
.qr-label {{ font-size:10px; font-weight:900; letter-spacing:1.5px; text-transform:uppercase; color:#666; }}
.info-row {{ position:relative; z-index:20; display:flex; gap:14px; padding:0 56px 18px; }}
.info-card {{ flex:1; border-radius:16px; padding:16px 20px; display:flex; align-items:center; gap:12px; background:rgba(255,255,255,0.85); box-shadow:0 2px 10px rgba(0,0,0,0.08); border:2px solid rgba(0,0,0,0.07); }}
.info-icon {{ font-size:26px; flex-shrink:0; }}
.lbl {{ font-size:10px; letter-spacing:2px; text-transform:uppercase; color:#888; font-weight:800; margin-bottom:3px; }}
.val {{ font-size:16px; font-weight:900; color:#1a1a2e; line-height:1.3; }}
.contact-bar {{ position:relative; z-index:20; display:flex; align-items:center; gap:14px; padding:0 56px 22px; flex-wrap:wrap; }}
.ci-item {{ font-size:14px; font-weight:700; color:#444; display:flex; align-items:center; gap:6px; }}
.dot-sep {{ color:#bbb; font-size:18px; }}
.footer {{ position:relative; z-index:20; margin:0 56px; border-top:2px solid rgba(0,0,0,0.08); padding-top:18px; display:flex; align-items:center; justify-content:space-between; }}
.fnote {{ font-size:13px; color:#888; font-style:italic; font-weight:600; }}
.htags {{ display:flex; gap:8px; }}
.ht {{ font-size:12px; font-weight:800; padding:5px 12px; border-radius:20px; border:2px solid rgba(0,0,0,0.1); color:#555; background:rgba(255,255,255,0.6); }}
</style>
</head><body>
<div class="flyer">
  <div class="bg-pattern"></div>
  <div class="bg-wash"></div>
  <div class="bismillah">\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064e\u0647\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0652\u0645\u064e\u0640\u0646\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0650\u064a\u0645\u0650</div>
  <div class="topbar"><div class="logo-box"><span class="logo-text">Workshop-DIY</span></div></div>
  <div class="hero">
    <div class="sub-tag">\u25c6 Workshop-DIY \u00b7 {cats}</div>
    <div class="atelier-label">Atelier</div>
    <div class="title">{emoji} <span class="acc">{title_acc}</span>{title_rest}</div>
    <div class="desc">{desc_fr}</div>
    <div class="features">
      <div class="feat-item"><span class="fi">\U0001f527</span><span>D\u00e9couvre l\u2019application</span></div>
      <div class="feat-item"><span class="fi">\U0001f4e1</span><span>Connecte-toi et explore</span></div>
      <div class="feat-item"><span class="fi">\U0001f3ae</span><span>Teste les fonctionnalit\u00e9s</span></div>
      <div class="feat-item"><span class="fi">\U0001f680</span><span>Partage tes r\u00e9sultats</span></div>
    </div>
  </div>
  <div class="audience-row">
    <div class="aud-pill">\U0001f466 \u00c0 partir de 10 ans</div>
    <div class="aud-pill">\U0001f4bb PC portable recommand\u00e9</div>
    <div class="aud-pill">\U0001f393 Aucun pr\u00e9requis</div>
  </div>
  <div class="price-banner">
    <div class="price-item"><div class="price-icon">\U0001fa99</div><div class="price-text"><div class="price-lbl">Adh\u00e9rents Workshop-DIY</div><div class="price-val" style="color:#2e7d32;">Gratuit \u2705</div></div></div>
    <div class="price-divider"></div>
    <div class="price-item"><div class="price-icon">\U0001f39f\ufe0f</div><div class="price-text"><div class="price-lbl">Non-adh\u00e9rents</div><div class="price-val">7 \u20ac / personne</div></div></div>
    <div class="price-divider"></div>
    <div class="price-item" style="flex:0.7;"><div class="price-icon">\u2139\ufe0f</div><div class="price-text"><div class="price-lbl">Devenir adh\u00e9rent</div><div class="price-val" style="font-size:15px;">workshop-diy.org</div></div></div>
  </div>
  <div class="atelier-banner">
    <div class="atelier-left">
      <div class="atelier-title">\U0001f680 Lancer l\u2019atelier <span class="badge">EN LIGNE</span></div>
      <div class="atelier-desc">Ouvre l\u2019application dans ton navigateur \u2014 aucune installation requise !</div>
      <div class="atelier-url">{url}</div>
      <div class="atelier-cta">\u2191 Scanne le QR code ou tape l\u2019URL \u25b6</div>
    </div>
    <div class="qr-wrap">{qr_img}<div class="qr-label">Scanner pour lancer</div></div>
  </div>
  <div class="info-row">
    <div class="info-card"><div class="info-icon">\U0001f4c5</div><div class="info-text"><div class="lbl">Date</div><div class="val"><em>JJ mois AAAA</em></div></div></div>
    <div class="info-card"><div class="info-icon">\U0001f558</div><div class="info-text"><div class="lbl">Horaire</div><div class="val"><em>HHh \u2013 HHh</em></div></div></div>
    <div class="info-card"><div class="info-icon">\U0001f4cd</div><div class="info-text"><div class="lbl">Lieu</div><div class="val"><em>Lieu \u00e0 d\u00e9finir</em></div></div></div>
  </div>
  <div class="contact-bar">
    <div class="ci-item">\U0001f310 workshop-diy.org</div>
    <span class="dot-sep">\u00b7</span>
    <div class="ci-item">\u2709\ufe0f contact@workshop-diy.org</div>
    <span class="dot-sep">\u00b7</span>
    <div class="ci-item">\U0001f4de 06 19 51 51 73</div>
  </div>
  <div class="footer">
    <div class="fnote">\u2728 Curiosit\u00e9 et sourire bienvenus !</div>
    <div class="htags"><span class="ht">#Atelier{title_acc}{title_rest.lstrip("-")}</span><span class="ht">#WorkshopDIY</span></div>
  </div>
</div></body></html>'''

    with open(out, "w") as f:
        f.write(html)
    generated += 1
    print(f"  \033[1m{num}\033[0m {name} \033[0;32m✅\033[0m")

print(f"\n  ✅ Generated: {generated} | Skipped: {skipped} (already exist)")
if not HAS_QR:
    print("  ⚠️  QR codes missing (pip install qrcode pillow)")
print()
PYEOF
}

# ============================================================
# 18. BROKEN LINKS CHECK
# ============================================================
do_broken_links() {
  log "Checking live URLs..."
  python3 << 'PYEOF'
import json, urllib.request, urllib.error, sys

with open("apps-data.json") as f:
    data = json.load(f)

apps = data.get("apps", [])
broken = 0
ok = 0

for a in apps:
    if a.get("status") == "offline":
        continue
    name = a["name"]
    url = f"https://abourdim.github.io/{name}/"
    try:
        req = urllib.request.Request(url, method="HEAD")
        resp = urllib.request.urlopen(req, timeout=10)
        code = resp.getcode()
        if code < 400:
            ok += 1
        else:
            print(f"  ❌ {name:<30s} HTTP {code}")
            broken += 1
    except urllib.error.HTTPError as e:
        print(f"  ❌ {name:<30s} HTTP {e.code}")
        broken += 1
    except Exception as e:
        print(f"  ❌ {name:<30s} {str(e)[:50]}")
        broken += 1

print(f"\n  ✅ OK: {ok} | ❌ Broken: {broken} | Total: {ok + broken}")
print()
PYEOF
}

# ============================================================
# 19. I18N COVERAGE
# ============================================================
do_i18n() {
  log "i18n coverage check..."
  python3 << 'PYEOF'
import json

with open("apps-data.json") as f:
    data = json.load(f)

apps = data.get("apps", [])
missing = {"en": [], "fr": [], "ar": []}

for a in apps:
    desc = a.get("desc", {})
    for lang in ("en", "fr", "ar"):
        if not desc.get(lang) or len(desc.get(lang, "")) < 10:
            missing[lang].append(a["name"])

for lang in ("en", "fr", "ar"):
    count = len(apps) - len(missing[lang])
    pct = int(100 * count / len(apps)) if apps else 0
    bar = "█" * (pct // 2) + "░" * (50 - pct // 2)
    status = "✅" if pct == 100 else "⚠️"
    print(f"\n  {lang.upper()} {status} {count}/{len(apps)} ({pct}%)")
    print(f"  {bar}")
    if missing[lang]:
        for n in missing[lang][:10]:
            print(f"    - {n}")
        if len(missing[lang]) > 10:
            print(f"    ... and {len(missing[lang]) - 10} more")
print()
PYEOF
}

# ============================================================
# 20. CONSISTENCY CHECK
# ============================================================
do_consistency() {
  log "Consistency check..."
  if [ ! -d "$REPOS_DIR" ]; then err "repos/ not found."; return; fi

  echo ""
  echo -e "  ${BOLD}Checking all repos for:${NC} favicon, meta, lang, manifest, PWA, OG tags"
  echo -e "  ${DIM}─────────────────────────────────────────────${NC}"

  local total=0 issues=0
  for repo in "$REPOS_DIR"/*/; do
    [ ! -f "$repo/index.html" ] && continue
    local name=$(basename "$repo")
    total=$((total + 1))
    local problems=""

    # Check favicon
    grep -qi 'favicon\|icon' "$repo/index.html" 2>/dev/null || problems+=" no-favicon"

    # Check meta viewport
    grep -qi 'viewport' "$repo/index.html" 2>/dev/null || problems+=" no-viewport"

    # Check lang attribute
    grep -qi 'lang=' "$repo/index.html" 2>/dev/null || problems+=" no-lang"

    # Check title
    grep -qi '<title>' "$repo/index.html" 2>/dev/null || problems+=" no-title"

    # Check manifest.json
    [ ! -f "$repo/manifest.json" ] && problems+=" no-manifest"

    # Check service worker (PWA readiness)
    grep -qi 'serviceWorker\|service-worker' "$repo/index.html" 2>/dev/null || \
    [ -f "$repo/sw.js" ] || [ -f "$repo/service-worker.js" ] || problems+=" no-sw"

    # Check Open Graph meta tags
    grep -qi 'og:title\|og:description' "$repo/index.html" 2>/dev/null || problems+=" no-og"

    # Check meta description
    grep -qi 'name="description"' "$repo/index.html" 2>/dev/null || problems+=" no-meta-desc"

    if [ -n "$problems" ]; then
      printf "  %-30s ${YELLOW}%s${NC}\n" "$name" "$problems"
      issues=$((issues + 1))
    fi
  done

  echo -e "  ${DIM}─────────────────────────────────────────────${NC}"
  echo -e "  Checked: $total | ${YELLOW}Issues: $issues${NC}"
  echo ""
}

# ============================================================
# 21. AUTO-TAGGER
# ============================================================
do_autotag() {
  log "Auto-tagger: scanning repos..."
  if [ ! -d "$REPOS_DIR" ]; then err "repos/ not found."; return; fi

  python3 << 'PYEOF'
import json, os, re

REPOS_DIR = "repos"
with open("apps-data.json") as f:
    data = json.load(f)

TAG_DETECT = {
    "BLE":        [r"bluetooth", r"navigator\.bluetooth", r"web bluetooth"],
    "WebSerial":  [r"serial", r"navigator\.serial"],
    "WebRTC":     [r"webrtc", r"peerjs", r"RTCPeerConnection"],
    "camera":     [r"getUserMedia", r"webcam", r"<video"],
    "TTS":        [r"speechSynthesis", r"text-to-speech"],
    "STT":        [r"SpeechRecognition", r"webkitSpeechRecognition"],
    "mediapipe":  [r"mediapipe"],
    "tensorflow": [r"tensorflow", r"@tensorflow"],
    "canvas":     [r"<canvas", r"getContext\("],
    "PWA":        [r"serviceWorker", r"manifest\.json"],
    "micro:bit":  [r"micro.?bit", r"microbit"],
    "game":       [r"score", r"level", r"gameOver"],
}

suggestions = []

for a in data.get("apps", []):
    name = a["name"]
    repo_path = os.path.join(REPOS_DIR, name)
    if not os.path.isdir(repo_path):
        continue

    # Read index.html + all .js files + package.json
    code = ""
    index = os.path.join(repo_path, "index.html")
    if os.path.isfile(index):
        with open(index, errors="ignore") as f:
            code += f.read()
    # Scan .js files (top-level only, skip node_modules)
    for fname in os.listdir(repo_path):
        if fname.endswith(".js") and fname != "node_modules":
            fpath = os.path.join(repo_path, fname)
            if os.path.isfile(fpath):
                with open(fpath, errors="ignore") as f:
                    code += f.read()
    # Scan package.json for dependencies
    pkg = os.path.join(repo_path, "package.json")
    if os.path.isfile(pkg):
        with open(pkg, errors="ignore") as f:
            code += f.read()
    if not code:
        continue

    current_tags = set(a.get("tags", []))
    new_tags = []

    for tag, patterns in TAG_DETECT.items():
        if tag in current_tags:
            continue
        for p in patterns:
            if re.search(p, code, re.IGNORECASE):
                new_tags.append(tag)
                break

    if new_tags:
        suggestions.append((name, current_tags, new_tags))

if suggestions:
    print(f"\n  Found tag suggestions for {len(suggestions)} apps:\n")
    for name, current, new in suggestions:
        print(f"  {name:<30s} current: {','.join(current)}")
        print(f"  {'':30s} + suggest: \033[0;32m{','.join(new)}\033[0m")
        print()
else:
    print("\n  ✅ All tags look accurate!\n")
PYEOF
}

# ============================================================
# 22. RUN ALL QUALITY CHECKS
# ============================================================
do_all_quality() {
  log "Running all quality checks..."
  echo ""

  echo -e "  ${BOLD}${CYAN}[1/5] Validation${NC}"
  do_validate

  echo -e "  ${BOLD}${CYAN}[2/5] Broken links${NC}"
  do_broken_links

  echo -e "  ${BOLD}${CYAN}[3/5] i18n coverage${NC}"
  do_i18n

  echo -e "  ${BOLD}${CYAN}[4/5] Consistency check${NC}"
  do_consistency

  echo -e "  ${BOLD}${CYAN}[5/5] Auto-tagger${NC}"
  do_autotag

  ok "All quality checks complete!"
}

# ============================================================
# 23. WEB LAUNCHER
# ============================================================
do_web_launcher() {
  log "Starting web launcher..."
  if [ ! -f "$SCRIPT_DIR/launcher-web.py" ]; then
    err "launcher-web.py not found"
    return 1
  fi
  python3 "$SCRIPT_DIR/launcher-web.py"
}

# ============================================================
#  MAIN LOOP
# ============================================================
cd "$SCRIPT_DIR"

# ── Run a choice ──
run_choice() {
  case "$1" in
    1)  do_clone ;;
    2)  do_pull ;;
    3)  do_health ;;
    4)  do_fix_readmes ;;
    5)  do_sync ;;
    6)  do_validate ;;
    7)  do_export ;;
    8)  do_build ;;
    9)  do_thumbs ;;
    10) do_deploy ;;
    11) do_list ;;
    12) do_edit ;;
    13) do_bulk ;;
    14) do_dashboard ;;
    15) do_event_flyer ;;
    16) do_catalog ;;
    17) do_batch_flyers ;;
    18) do_broken_links ;;
    19) do_i18n ;;
    20) do_consistency ;;
    21) do_autotag ;;
    22) do_all_quality ;;
    23) do_web_launcher ;;
    *) return 1 ;;
  esac
}

# ── CLI argument: ./launcher.sh 14 ──
if [ -n "${1:-}" ]; then
  if run_choice "$1"; then
    exit 0
  else
    err "Invalid option: $1 (valid: 1-23)"
    exit 1
  fi
fi

# ── Interactive menu ──
while true; do
  show_menu
  read -p "  Choose [0-23]: " choice

  case "$choice" in
    0|q|Q) echo -e "\n  ${GREEN}Bye! 🚀${NC}\n"; exit 0 ;;
    *)
      if run_choice "$choice"; then
        pause
      else
        echo -e "  ${RED}Invalid choice${NC}"; sleep 1
      fi
      ;;
  esac
done
