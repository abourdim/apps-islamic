#!/usr/bin/env bash
# ============================================================
# Workshop-Diy — sync.sh  (v2 — README-aware)
# Auto-detect new/removed GitHub repos, read README.md files,
# and auto-categorize apps based on content analysis.
#
# Usage:
#   ./sync.sh              # dry-run: show what changed
#   ./sync.sh --apply      # apply changes to files
#   ./sync.sh --full       # apply + thumbs + git push
#   ./sync.sh --audit      # re-scan ALL READMEs & update categories
# ============================================================

set -euo pipefail

GITHUB_USER="abourdim"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_FILE="$SCRIPT_DIR/apps-data.json"
JS_FILE="$SCRIPT_DIR/app.js"
README_CACHE="$SCRIPT_DIR/.readme-cache"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

MODE="${1:-}"

log()  { echo -e "${BLUE}[sync]${NC} $1"; }
ok()   { echo -e "${GREEN}  ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠️  $1${NC}"; }

# ──────── Fetch all repos from GitHub ────────
fetch_github_repos() {
  local page=1
  local all=""
  while :; do
    local batch
    batch=$(curl -sf "https://api.github.com/users/$GITHUB_USER/repos?per_page=100&page=$page" 2>/dev/null || echo "[]")
    local names
    names=$(echo "$batch" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if isinstance(data, list):
        for r in data:
            name = r.get('name','')
            desc = r.get('description','') or ''
            if name and name != 'MIT License':
                print(f'{name}|||{desc}')
except: pass
" 2>/dev/null)
    [ -z "$names" ] && break
    all="$all
$names"
    page=$((page + 1))
  done
  echo "$all" | grep -v '^$' | sort
}

# ──────── Fetch README.md for a repo (cached 24h) ────────
fetch_readme() {
  local repo="$1"
  mkdir -p "$README_CACHE"
  local cache_file="$README_CACHE/$repo.md"

  # Use cache if < 24h old
  if [ -f "$cache_file" ]; then
    local now age mtime
    now=$(date +%s)
    # macOS vs Linux stat
    mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)
    age=$(( now - mtime ))
    if [ "$age" -lt 86400 ]; then
      cat "$cache_file"
      return 0
    fi
  fi

  # Fetch from GitHub (try main, then master)
  local content=""
  for branch in main master; do
    content=$(curl -sf "https://raw.githubusercontent.com/$GITHUB_USER/$repo/$branch/README.md" 2>/dev/null || true)
    [ -n "$content" ] && break
  done

  if [ -n "$content" ]; then
    echo "$content" > "$cache_file"
    echo "$content"
  fi
}

# ──────── Fetch all READMEs and cache them ────────
fetch_all_readmes() {
  local repos="$1"
  mkdir -p "$README_CACHE"
  local count=0 total=0
  total=$(echo "$repos" | wc -w)
  for repo in $repos; do
    fetch_readme "$repo" > /dev/null 2>&1
    count=$((count + 1))
    printf "\r  📖 Fetching READMEs... %d/%d" "$count" "$total" >&2
  done
  echo "" >&2
}

# ──────── Main sync + README analysis in Python ────────
run_sync() {
  local github_data="$1"
  local apply_flag="$2"
  local audit_flag="${3:-0}"

  # Get list of repos to scan
  local repo_names
  repo_names=$(echo "$github_data" | grep '|||' | cut -d'|' -f1 | tr '\n' ' ')

  # Fetch all READMEs first
  if [ "$apply_flag" = "1" ] || [ "$audit_flag" = "1" ]; then
    local scan_list
    if [ "$audit_flag" = "1" ]; then
      # Audit: scan ALL known apps
      scan_list=$(python3 -c "
import json
try:
    data = json.load(open('$DATA_FILE'))
    names = set(a['name'] for a in data.get('apps', []))
except: names = set()
github = set('$repo_names'.split())
for n in sorted(names | github):
    print(n)
" 2>/dev/null)
    else
      # Normal: only scan new repos
      scan_list=$(python3 -c "
import json
try:
    data = json.load(open('$DATA_FILE'))
    current = set(a['name'] for a in data.get('apps', []))
except: current = set()
github = set('$repo_names'.split())
for n in sorted(github - current):
    print(n)
" 2>/dev/null)
    fi

    if [ -n "$scan_list" ]; then
      fetch_all_readmes "$scan_list"
    fi
  fi

  # Export everything for Python
  export GITHUB_DATA="$github_data"
  export APPLY="$apply_flag"
  export AUDIT="$audit_flag"
  export README_CACHE_DIR="$README_CACHE"

  python3 << 'PYEOF'
import json, os, re, sys, datetime

GITHUB_USER = os.environ.get("GITHUB_USER", "abourdim")
DATA_FILE = os.environ.get("DATA_FILE", "apps-data.json")
JS_FILE = os.environ.get("JS_FILE", "app.js")
README_CACHE_DIR = os.environ.get("README_CACHE_DIR", ".readme-cache")
apply = os.environ.get("APPLY", "0") == "1"
audit = os.environ.get("AUDIT", "0") == "1"

# ════════════════════════════════════════════════════
#  README ANALYSIS ENGINE
# ════════════════════════════════════════════════════

# Keywords → category (checked against README + name)
CAT_KEYWORDS = {
    "microbit": [
        "micro:bit", "microbit", "micro-bit", "makecode",
        "ble", "bluetooth", "web bluetooth", "web-bluetooth",
        "accelerometer", "magnetometer", "5x5 led", "led matrix",
        "uart service", "webusb", "microbit-dal",
    ],
    "camera": [
        "camera", "webcam", "video stream", "mediapipe",
        "face-api", "face detection", "face tracking", "hand tracking",
        "pose detection", "tensorflow.js", "teachable machine",
        "getusermedia", "canvas capture",
        "image classification", "object detection",
    ],
    "ai": [
        "machine learning", "tensorflow", "ml5", "neural network",
        "deep learning", "classifier", "inference",
        "chatgpt", "claude", "llm", "gpt-", "openai", "anthropic",
        "nlp", "natural language", "speech recognition",
        "text-to-speech", "piper", "mediapipe",
        "teachable machine", "artificial intelligence",
    ],
    "arabic": [
        "arabic", "عربي", "arabe", "rtl", "right-to-left",
        "quran", "piper-arabic", "tashkeel",
    ],
    "classroom": [
        "classroom", "student", "teacher",
        "peerjs", "video call", "screen share", "room code",
        "mission control", "webrtc",
    ],
    "hardware": [
        "esp32", "esp8266", "arduino", "raspberry",
        "wled", "neopixel", "ws2812", "led strip",
        "servo", "motor driver", "sensor", "gpio", "i2c", "spi",
        "circuit", "breadboard", "soldering", "pcb",
        "iot", "mqtt", "home assistant",
    ],
    "learning": [
        "tutorial", "lesson", "exercise", "quiz",
        "learn", "course", "beginner", "step-by-step",
        "activities", "education", "educational",
        "hands-on", "workshop activity", "challenge",
    ],
    "tools": [
        "tool", "utility", "dashboard", "catalog",
        "devops", "ci/cd", "docker", "kubernetes",
        "vpn", "proxy", "automation", "scraping",
        "pixel art", "generator",
    ],
}

# Also check app NAME for strong category hints
NAME_CAT_HINTS = {
    "microbit": ["bit-bot", "bit-playground", "bitmoji", "ble-logger",
                 "usb-logger", "rxy", "makecode", "bit-54",
                 "talking-robot", "mission-control"],
    "camera":   ["face-", "camera", "track", "magic-hands", "teachable"],
    "ai":       ["teachable", "claude", "prompt", "piper", "magic-hands"],
    "arabic":   ["arabic", "piper-arabic"],
    "classroom":["classroom", "mission-control"],
    "hardware": ["esp32", "wled", "circuit", "smart-home"],
    "learning": ["-lab", "academy", "adventure", "activit", "-kids",
                 "code-kids", "production-chain", "save-our-planet",
                 "crypto-vault", "crypto-academy"],
}

# Status detection
STATUS_KEYWORDS = {
    "dev":     ["wip", "work in progress", "coming soon", "under construction",
                "todo:", "not ready", "alpha version", "experimental", "prototype"],
    "offline": ["deprecated", "archived", "no longer maintained", "discontinued"],
    "beta":    ["beta", "preview version", "early access"],
}

# Tag extraction
TAG_KEYWORDS = {
    "BLE": ["ble", "bluetooth", "web bluetooth"],
    "WebSerial": ["webserial", "serial port", "usb serial"],
    "WebRTC": ["webrtc", "peerjs"],
    "camera": ["camera", "webcam", "getusermedia"],
    "TTS": ["text-to-speech", "tts", "speech synthesis"],
    "STT": ["speech-to-text", "stt", "speech recognition"],
    "mediapipe": ["mediapipe"],
    "tensorflow": ["tensorflow", "tf.js"],
    "micro:bit": ["micro:bit", "microbit"],
    "ESP32": ["esp32"],
    "WLED": ["wled"],
    "neopixel": ["neopixel", "ws2812"],
    "servo": ["servo"],
    "IoT": ["iot", "mqtt"],
    "piper": ["piper"],
    "WASM": ["wasm", "webassembly"],
    "game": ["game", "score", "level"],
    "no-code": ["no-code", "no code", "drag and drop"],
    "3D": ["three.js", "threejs", "webgl"],
    "git": ["git ", "version control"],
    "linux": ["linux", "terminal", "bash command"],
    "security": ["security", "pentest", "ctf"],
    "crypto": ["cryptography", "encryption", "blockchain"],
    "HTML": ["html", "css", "javascript"],
    "makecode": ["makecode", "block-based"],
    "robot": ["robot"],
    "pixel-art": ["pixel art", "pixel-art"],
    "LED": ["led"],
    "kids": ["kids", "children", "enfants"],
}

# Emoji from name
EMOJI_MAP = {
    "bit-bot": "🤖", "magic-hands": "🪄", "face-quest": "🕵️",
    "talking-robot": "💬", "teachable-machine": "🧠", "face-tracking": "😎",
    "bitmoji-lab": "😄", "mission-control": "🚀", "bit-playground": "🧩",
    "rxy": "🎛️", "pixel-gateway": "🎨", "wled-kids-lab": "💡",
    "esp32-c3-kids-lab": "⚡", "crypto-academy": "🪙", "pentest-lab": "🔐",
    "linux-kids-lab": "🐧", "production-chain": "🏭", "classroom": "🏫",
    "arabic-translator": "🌐", "arabic-speaker": "🗣️", "piper-arabic-tts": "🎙️",
    "usb-logger": "🔌", "ble-logger": "📡", "claude-toolkit": "🧰",
    "puppeteer-playground": "🎭", "workshop-diy": "🏗️", "all": "🏠",
    "circuit-lab": "🔋", "rocket-shield-vpn": "🛡️", "3d-lab": "🧊",
    "git-lab": "🔀", "prompt-hero": "✨", "save-our-planet": "🌍",
    "ops-catalog": "📋", "code-kids": "💻", "smart-home": "🏡",
    "makecode-adventures": "🧱", "bit-54-activities": "🤖", "crypto-vault": "💰",
}
CAT_EMOJI = {
    "microbit": "🤖", "camera": "📸", "arabic": "🗣️",
    "classroom": "🏫", "hardware": "⚡", "learning": "📚",
    "tools": "🛠️", "ai": "🧠",
}


def analyze_readme(readme_text, name):
    """Analyze README content → categories, status, tags, description."""
    text_lower = (readme_text or "").lower()
    name_lower = name.lower()

    # ─── Detect categories from README content ───
    cat_scores = {}
    for cat, keywords in CAT_KEYWORDS.items():
        score = 0
        for kw in keywords:
            count = text_lower.count(kw.lower())
            if count > 0:
                # Weight: exact multi-word matches score higher
                weight = 2 if ' ' in kw else 1
                score += count * weight
        cat_scores[cat] = score

    # ─── Detect categories from app name ───
    for cat, hints in NAME_CAT_HINTS.items():
        for hint in hints:
            if hint in name_lower:
                cat_scores[cat] = cat_scores.get(cat, 0) + 10  # strong boost

    # Qualify: need score >= 2
    categories = []
    for cat, score in sorted(cat_scores.items(), key=lambda x: -x[1]):
        if score >= 2:
            categories.append(cat)
    if not categories:
        categories = ["tools"]

    # ─── Detect status ───
    status = None  # None = don't override
    for st, keywords in STATUS_KEYWORDS.items():
        for kw in keywords:
            if kw in text_lower:
                status = st
                break
        if status:
            break

    # ─── Extract tags ───
    tags = []
    for tag, keywords in TAG_KEYWORDS.items():
        for kw in keywords:
            if kw in text_lower and tag not in tags:
                tags.append(tag)
                break

    # ─── Extract description (first real paragraph) ───
    desc_en = ""
    if readme_text:
        for line in readme_text.split("\n"):
            stripped = line.strip()
            if not stripped or stripped.startswith("#") or stripped.startswith("!["): continue
            if stripped.startswith("[![") or stripped.startswith("|") or stripped.startswith("---"): continue
            if len(stripped) < 20: continue
            desc_en = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', stripped)
            desc_en = re.sub(r'[*_`]', '', desc_en).strip()
            if len(desc_en) > 200:
                desc_en = desc_en[:197].rsplit(' ', 1)[0] + "..."
            break

    # ─── Emoji ───
    emoji = EMOJI_MAP.get(name, None)
    if not emoji:
        emoji = CAT_EMOJI.get(categories[0], "🔧") if categories else "🔧"

    return {
        "categories": categories,
        "status": status,
        "tags": tags,
        "desc_en": desc_en,
        "emoji": emoji,
    }


def load_readme(name):
    """Load README from cache."""
    path = os.path.join(README_CACHE_DIR, f"{name}.md")
    if os.path.isfile(path):
        with open(path) as f:
            return f.read()
    return ""


# ════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════

github_raw = os.environ.get("GITHUB_DATA", "")
github_repos = {}
for line in github_raw.strip().split('\n'):
    if '|||' in line:
        name, desc = line.split('|||', 1)
        name = name.strip()
        if name:
            github_repos[name] = desc.strip()

try:
    with open(DATA_FILE) as f:
        data = json.load(f)
except:
    data = {"generated": "", "user": GITHUB_USER, "apps": []}

current_names = {a['name'] for a in data.get('apps', [])}
github_names = set(github_repos.keys())

added = sorted(github_names - current_names)
removed = sorted(current_names - github_names)
unchanged = sorted(current_names & github_names)

print(f"\n{'='*60}")
print(f"  📊 SYNC REPORT {'(AUDIT MODE)' if audit else ''}")
print(f"{'='*60}")
print(f"  GitHub repos:  {len(github_names)}")
print(f"  Hub apps:      {len(current_names)}")
print(f"  ✅ Unchanged:   {len(unchanged)}")
print(f"  ➕ New:         {len(added)}")
print(f"  ➖ Removed:     {len(removed)}")
print(f"{'='*60}\n")

if added:
    print("  ➕ NEW repos:")
    for n in added:
        print(f"     {n}  →  {github_repos.get(n,'') or '(no desc)'}")
    print()

if removed:
    print("  ➖ REMOVED:")
    for n in removed:
        print(f"     {n}")
    print()

if not added and not removed and not audit:
    print("  🎯 Everything in sync!")
    print("  💡 Run with --audit to re-scan all READMEs.\n")
    sys.exit(0)

if not apply and not audit:
    print("  💡 Run with --apply, --full, or --audit.\n")
    sys.exit(0)

# ─── Analyze READMEs ───
scan_names = sorted(set(added) | (set(current_names | github_names) if audit else set()))
readme_results = {}

if scan_names:
    print(f"  📖 Analyzing {len(scan_names)} READMEs...\n")

for name in scan_names:
    readme = load_readme(name)
    if readme:
        analysis = analyze_readme(readme, name)
        readme_results[name] = analysis
        cats = ", ".join(analysis["categories"])
        tags = ", ".join(analysis["tags"][:5])
        st = analysis["status"] or "—"
        print(f"  📖 {name:25s} cats=[{cats:35s}] status={st:8s} tags=[{tags}]")
    else:
        # Still analyze by name alone
        analysis = analyze_readme("", name)
        readme_results[name] = analysis
        cats = ", ".join(analysis["categories"])
        print(f"  ⚠️  {name:25s} cats=[{cats:35s}] (no README)")

print()

if not apply:
    print("  💡 Run with --apply or --full to write changes.\n")
    sys.exit(0)

# ─── Add new apps ───
for name in added:
    analysis = readme_results.get(name, {})
    gh_desc = github_repos.get(name, '')
    categories = analysis.get("categories", ["tools"])
    status = analysis.get("status") or "stable"
    tags = analysis.get("tags", [t for t in name.split('-') if len(t) > 2][:3])
    emoji = analysis.get("emoji", "🔧")
    desc_en = analysis.get("desc_en") or gh_desc or f"{name.replace('-',' ').title()} — explore and experiment!"

    new_app = {
        "name": name, "emoji": emoji,
        "categories": categories,
        "badge": "new", "status": status,
        "tags": tags,
        "desc": {
            "en": desc_en,
            "fr": f"{name.replace('-',' ').title()} — explorez et expérimentez !",
            "ar": f"{name.replace('-',' ').title()} — استكشف وجرّب!",
        }
    }
    data['apps'].append(new_app)
    print(f"  ✅ Added: {name} [{emoji} {', '.join(categories)}]")

# ─── Remove deleted ───
if removed:
    data['apps'] = [a for a in data['apps'] if a['name'] not in removed]
    for n in removed:
        print(f"  🗑️  Removed: {n}")

# ─── Audit: merge README findings into existing apps ───
if audit:
    updated = 0
    for app in data['apps']:
        name = app['name']
        analysis = readme_results.get(name)
        if not analysis:
            continue

        old_cats = app.get("categories", [app.get("category", "tools")])
        if isinstance(old_cats, str): old_cats = [old_cats]
        new_cats = analysis["categories"]

        # Merge categories (keep existing + add detected)
        merged = list(old_cats)
        added_cats = [c for c in new_cats if c not in merged]
        for c in added_cats:
            merged.append(c)

        changes = []
        if added_cats:
            app["categories"] = merged
            changes.append(f"cats +{added_cats}")

        # Merge tags
        old_tags = app.get("tags", [])
        new_tags = [t for t in analysis.get("tags", []) if t not in old_tags]
        if new_tags:
            app["tags"] = (old_tags + new_tags)[:8]
            changes.append(f"tags +{len(new_tags)}")

        # Update generic descriptions
        cur_desc = app.get("desc", {}).get("en", "")
        if ("explore and experiment" in cur_desc.lower() or len(cur_desc) < 20):
            if analysis.get("desc_en"):
                app["desc"]["en"] = analysis["desc_en"]
                changes.append("desc ✏️")

        # Downgrade status only if README says dev/offline
        if analysis.get("status") in ["dev", "offline"] and app.get("status") not in ["dev", "offline"]:
            app["status"] = analysis["status"]
            changes.append(f"status → {analysis['status']}")

        if changes:
            updated += 1
            print(f"  🔄 {name:25s} → {', '.join(changes)}")

    print(f"\n  🔄 Audit updated {updated} apps")

# ─── Save JSON ───
data['generated'] = datetime.datetime.utcnow().isoformat() + 'Z'
with open(DATA_FILE, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print(f"\n  📄 {DATA_FILE} ({len(data['apps'])} apps)")

# ─── Rebuild INLINE_APPS in app.js ───
with open(JS_FILE) as f:
    js = f.read()

lines = ["const INLINE_APPS = ["]
for app in data['apps']:
    name = app['name']
    emoji = app['emoji']
    cats = app.get('categories', app.get('category', ['tools']))
    if isinstance(cats, str): cats = [cats]
    cats_str = json.dumps(cats)
    badge = app.get('badge', '')
    status = app.get('status', 'stable')
    tags = app.get('tags', [])
    desc = app.get('desc', {})
    en = desc.get('en', '').replace('"', '\\"')
    fr = desc.get('fr', '').replace('"', '\\"')
    ar = desc.get('ar', '').replace('"', '\\"')
    tags_str = ','.join([f'"{t}"' for t in tags[:8]])
    badge_str = f'"{badge}"' if badge else '"stable"'

    lines.append(f'  {{ name:"{name}", emoji:"{emoji}", categories:{cats_str}, badge:{badge_str}, status:"{status}", tags:[{tags_str}],')
    lines.append(f'    desc:{{ en:"{en}", fr:"{fr}", ar:"{ar}" }}}},')

lines.append("];")
new_block = "\n".join(lines)
js_new = re.sub(r'const INLINE_APPS = \[.*?\];', new_block, js, flags=re.DOTALL)

with open(JS_FILE, 'w') as f:
    f.write(js_new)
print(f"  📄 {JS_FILE} (INLINE_APPS: {len(data['apps'])})")

print(f"\n  🎉 Sync complete!\n")
PYEOF
}

# ============================================================
# MAIN
# ============================================================

echo ""
log "Fetching repos for ${CYAN}${GITHUB_USER}${NC}..."
github_data=$(fetch_github_repos)
repo_count=$(echo "$github_data" | grep -c '|||' || echo 0)
log "Found ${GREEN}${repo_count}${NC} repos on GitHub"

export GITHUB_USER DATA_FILE JS_FILE SCRIPT_DIR

case "$MODE" in
  --apply)
    log "Mode: ${YELLOW}Apply changes${NC}"
    run_sync "$github_data" "1" "0"
    echo ""
    ok "Files updated. Review then:"
    echo "    git add -A && git commit -m 'sync: update hub apps' && git push"
    echo ""
    ;;

  --audit)
    log "Mode: ${MAGENTA}Audit${NC} — re-scan ALL READMEs & update categories"
    run_sync "$github_data" "1" "1"
    echo ""
    ok "Audit complete. Review then:"
    echo "    git add -A && git commit -m 'audit: re-scan READMEs' && git push"
    echo ""
    ;;

  --full)
    log "Mode: ${YELLOW}Full rebuild${NC} (apply + thumbs + push)"
    run_sync "$github_data" "1" "0"

    if command -v node &>/dev/null && [ -f "$SCRIPT_DIR/screenshot.js" ]; then
      log "Generating thumbnails..."
      (cd "$SCRIPT_DIR" && node screenshot.js)
    fi

    if [ -f "$SCRIPT_DIR/build.sh" ]; then
      log "Updating manifest..."
      export THUMBS_DIR="$SCRIPT_DIR/thumbs" MANIFEST="$SCRIPT_DIR/manifest.json"
      python3 -c "
import json, os, datetime
THUMBS_DIR = os.environ.get('THUMBS_DIR', './thumbs')
manifest = {'generated': datetime.datetime.utcnow().isoformat() + 'Z', 'thumbs': {}}
if os.path.isdir(THUMBS_DIR):
    for f in sorted(os.listdir(THUMBS_DIR)):
        if f.endswith('.png'):
            path = os.path.join(THUMBS_DIR, f)
            manifest['thumbs'][f.replace('.png', '')] = {'file': f, 'size': os.path.getsize(path)}
with open(os.environ.get('MANIFEST', './manifest.json'), 'w') as f:
    json.dump(manifest, f, indent=2)
print(f'  Manifest: {len(manifest[\"thumbs\"])} thumbnails')
"
    fi

    log "Pushing to GitHub..."
    cd "$SCRIPT_DIR"
    git add -A
    git commit -m "🔄 sync: $(date -u '+%Y-%m-%d %H:%M') — auto-update" 2>/dev/null || log "Nothing to commit"
    git push origin main 2>/dev/null || warn "Push failed"
    echo ""
    ok "Full sync + deploy complete! 🚀"
    ;;

  *)
    log "Mode: ${CYAN}Dry run${NC} (preview only)"
    run_sync "$github_data" "0" "0"
    ;;
esac
