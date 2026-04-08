#!/usr/bin/env python3
"""
sync-apps.py — Scan repos and update apps-data.json + app.js INLINE_APPS
Generates trilingual descriptions (EN/FR/AR) from README content.
Usage: cd ~/Desktop/00_work/apps && python3 sync-apps.py
"""

import json, os, re, sys, subprocess

REPOS_DIR = None
for candidate in [
    os.path.join(os.path.dirname(__file__), "repos"),
    "/Users/besma/Desktop/00_work/repos",
    "/Users/besma/Desktop/00_work/apps/repos",
]:
    if os.path.isdir(candidate):
        REPOS_DIR = candidate
        break

if not REPOS_DIR:
    print("ERROR: Cannot find repos directory"); sys.exit(1)

APPS_DATA = os.path.join(os.path.dirname(__file__), "apps-data.json")
APP_JS = os.path.join(os.path.dirname(__file__), "app.js")

# ─── Category detection ───
BOOK_PREFIXES = [
    "al-", "aqidat-", "fiqh-", "dustur-", "haqiqat-", "hasad-", "humum-",
    "huquq-", "iyadat-", "jaddid-", "jihad-", "kayfa-", "khuluq-", "khutab-",
    "kunuz-", "maa-", "marakah-", "miat-", "min-huna-", "mushkilat-", "nahwa-",
    "nazarat-", "qadhaaif-", "rakaiz-", "rihlati-", "sayhah-", "shahid-",
    "taamulat-", "tarbiyat-", "zalam-", "fan-al-", "fi-mawkib-", "difaa-",
    "qadaya-", "ayqidh-", "ramadan-wal-",
]

CATEGORY_MAP = {
    # micro:bit
    "bit-bot": "microbit", "talking-robot": "microbit", "teachable-machine": "microbit",
    "face-tracking": "microbit", "bitmoji-lab": "microbit", "bit-playground": "microbit",
    "rxy": "microbit", "usb-logger": "microbit", "ble-logger": "microbit",
    "ble-dashboard": "microbit",
    # camera
    "magic-hands": "camera", "face-quest": "camera",
    # classroom
    "classroom": "classroom", "mission-control": "classroom",
    # arabic & islamic
    "arabic-translator": "arabic", "arabic-speaker": "arabic", "piper-arabic-tts": "arabic",
    "arabic-keyboard": "arabic", "elarabya": "arabic", "ierab": "arabic", "amthal": "arabic",
    "tethkir": "arabic", "kalami": "arabic", "jisr": "arabic", "al-maqlub": "arabic",
    "salat-times": "arabic", "tesbih": "arabic", "adhkari": "arabic",
    "luminaries-of-islam": "arabic", "golden-age": "arabic", "builders-of-light": "arabic",
    "hajj-guide": "arabic", "eid": "arabic", "nusuk": "arabic", "halqa": "arabic",
    "sada": "arabic", "arabic-tts": "arabic", "cowsay": "arabic",
    # education / learning
    "wled-kids-lab": "learning", "esp32-c3-kids-lab": "learning",
    "crypto-academy": "learning", "pentest-lab": "learning", "linux-kids-lab": "learning",
    "production-chain": "learning", "circuit-lab": "learning", "3d-lab": "learning",
    "git-lab": "learning", "save-our-planet": "learning", "makecode-adventures": "learning",
    "bit-54-activities": "learning", "crypto-vault": "learning", "web-kids": "learning",
    "AI-hacker-lab": "learning", "hacktivist-kids": "learning", "bonjour": "learning",
    # network / hardware
    "mqtt-lab": "hardware", "dhcp-lab": "hardware", "docker-lab": "hardware",
    "nodered-lab": "hardware", "avahi": "hardware", "tshark": "hardware",
    "pyshark": "hardware", "mdns": "hardware", "scapy": "hardware",
    "wifi-dashboard": "hardware", "sniffers-sallae": "hardware", "hackrf-one": "hardware",
    # ai
    "ollama-bot": "ai", "prompt-hero": "ai", "claude-toolkit": "ai",
    # infra → tools
    "ocpp": "tools", "sdr-lab": "tools", "reddis": "tools", "firebase": "tools",
    "ota": "tools", "firmware-update": "tools", "evic-toolkit": "tools",
    # fun → learning
    "time-machine": "learning", "morse-code": "learning", "satellites": "learning",
    "flight-tracker": "learning",
    # meta → tools
    "workshop-diy": "tools", "apps": "tools", "fihris": "tools",
    "flyers": "tools", "posts": "tools", "presentation": "tools",
    "warsha": "tools", "PlanPilot": "tools",
    # standalone
    "callgraph": "tools", "linkedin": "tools", "gmail-lab": "tools",
    "dir-pulse": "tools", "git-pulse": "tools",
}

def detect_category(name, readme_text=""):
    """Detect category from name pattern."""
    # Explicit map first
    if name in CATEGORY_MAP:
        return CATEGORY_MAP[name]
    # Islamic books
    for prefix in BOOK_PREFIXES:
        if name.startswith(prefix):
            return "arabic"
    # ops-catalog variants
    if name.startswith("ops-catalog"):
        return "tools"
    # Fallback heuristics
    nl = name.lower()
    if any(k in nl for k in ["bit-", "micro"]): return "microbit"
    if any(k in nl for k in ["camera", "face-"]): return "camera"
    if any(k in nl for k in ["arabic", "islam", "quran", "dua", "salat"]): return "arabic"
    if any(k in nl for k in ["lab", "kids", "learn"]): return "learning"
    if any(k in nl for k in ["ai", "claude", "ollama", "prompt"]): return "ai"
    return "tools"


# ─── Description extraction ───
def extract_descriptions(repo_dir, name):
    """Extract trilingual descriptions from README and other sources."""
    en, fr, ar = "", "", ""
    readme_lines = []

    readme_path = os.path.join(repo_dir, "README.md")
    if os.path.isfile(readme_path):
        try:
            with open(readme_path, "r", encoding="utf-8", errors="replace") as f:
                readme_lines = f.readlines()[:30]
        except:
            pass

    # --- English description ---
    for line in readme_lines:
        stripped = line.strip()
        # Skip empty, badges, bismillah, headings that are just the name, short lines
        if not stripped: continue
        cleaned = re.sub(r'^[#>*\s]+', '', stripped).strip()
        cleaned = re.sub(r'\*\*', '', cleaned).strip()
        if not cleaned or len(cleaned) < 8: continue
        if cleaned.startswith("بِسْمِ") or cleaned.startswith("بسم"): continue
        if cleaned.startswith("!["): continue  # badge
        if cleaned.startswith("<img") or cleaned.startswith("<div"): continue
        if cleaned.startswith("---"): continue
        if cleaned.startswith("Live site"): continue
        if cleaned.startswith("[!["): continue
        if cleaned.lower().replace("-", " ").replace("_", " ") == name.lower().replace("-", " ").replace("_", " "): continue
        # Check if it's Arabic text
        if re.search(r'[\u0600-\u06FF]', cleaned) and not re.search(r'[a-zA-Z]', cleaned):
            if not ar: ar = cleaned[:120]
            continue
        # Check if French
        if re.search(r"[éèêëàâçùûôîïæœ]", cleaned.lower()):
            if not fr: fr = cleaned[:120]
            continue
        # English
        if not en:
            en = cleaned[:120]

    # --- Try to get Arabic from title lines ---
    if not ar:
        for line in readme_lines[:5]:
            # Look for Arabic text in title line
            match = re.search(r'([\u0600-\u06FF][\u0600-\u06FF\s\u0640\u064B-\u065F]{4,})', line)
            if match:
                ar = match.group(1).strip()[:120]
                break

    # --- Try <title> fallback for EN ---
    if not en:
        index_path = os.path.join(repo_dir, "index.html")
        if os.path.isfile(index_path):
            try:
                with open(index_path, "r", encoding="utf-8", errors="replace") as f:
                    content = f.read(5000)
                m = re.search(r'<title>([^<]+)</title>', content)
                if m:
                    title = m.group(1).strip()
                    if len(title) > 5:
                        en = title[:120]
            except:
                pass

    # --- Generate missing languages ---
    # Prettify name for fallback
    pretty = name.replace("-", " ").replace("_", " ").title()

    if not en:
        en = f"{pretty} — Workshop-DIY app"

    if not fr:
        fr = generate_french(en, name, pretty)

    if not ar:
        ar = generate_arabic(en, name, pretty)

    return en, fr, ar


def generate_french(en_desc, name, pretty):
    """Generate a French description from the English one."""
    # Common translation patterns
    translations = {
        "Interactive": "Interactif", "interactive": "interactif",
        "educational": "éducatif", "Educational": "Éducatif",
        "trilingual": "trilingue", "web app": "application web",
        "based on": "basé sur", "the books of": "les livres de",
        "for kids": "pour enfants", "for children": "pour enfants",
        "Real-time": "En temps réel", "real-time": "en temps réel",
        "browser": "navigateur", "dashboard": "tableau de bord",
        "toolkit": "boîte à outils", "generator": "générateur",
        "tracker": "suivi", "learning": "apprentissage",
        "hands-on": "pratique", "step by step": "pas à pas",
    }

    # Check for Islamic book patterns
    if name.startswith("al-") or any(name.startswith(p) for p in BOOK_PREFIXES):
        if "Sheikh Mohammed al-Ghazali" in en_desc or "al-Ghazali" in en_desc:
            return en_desc.replace(
                "Interactive trilingual web app based on",
                "Application web trilingue interactive basée sur"
            ).replace(
                "by Sheikh Mohammed al-Ghazali",
                "du Cheikh Mohammed al-Ghazali"
            ).replace("books of", "livres de")

        # Generic Islamic book
        return f"{pretty} — application éducative islamique trilingue."

    # Simple pattern replacement
    fr = en_desc
    for eng, fre in translations.items():
        fr = fr.replace(eng, fre)

    # If no changes were made, use a generic description
    if fr == en_desc:
        fr = f"{pretty} — application Workshop-DIY."

    return fr[:120]


def generate_arabic(en_desc, name, pretty):
    """Generate an Arabic description from the English one."""
    # Islamic book with Ghazali
    if "al-Ghazali" in en_desc or "الغزالي" in en_desc:
        return f"تطبيق ويب تفاعلي ثلاثي اللغات مبني على كتب الشيخ محمد الغزالي."

    # Generic Islamic book pattern
    if name.startswith("al-") or any(name.startswith(p) for p in BOOK_PREFIXES):
        return f"{pretty} — تطبيق تعليمي إسلامي تفاعلي ثلاثي اللغات."

    # Category-based Arabic descriptions
    categories_ar = {
        "microbit": "تطبيق مايكرو:بت تفاعلي من Workshop-DIY.",
        "camera": "تطبيق كاميرا تفاعلي من Workshop-DIY.",
        "arabic": "تطبيق عربي وإسلامي تفاعلي من Workshop-DIY.",
        "classroom": "تطبيق فصل دراسي تفاعلي من Workshop-DIY.",
        "learning": "تطبيق تعليمي تفاعلي من Workshop-DIY.",
        "hardware": "تطبيق شبكات وأجهزة من Workshop-DIY.",
        "ai": "تطبيق ذكاء اصطناعي من Workshop-DIY.",
        "tools": "أداة من Workshop-DIY.",
    }

    cat = detect_category(name)
    return categories_ar.get(cat, f"{pretty} — تطبيق من Workshop-DIY.")


def detect_status(repo_dir):
    """Detect app status from README content."""
    readme_path = os.path.join(repo_dir, "README.md")
    if os.path.isfile(readme_path):
        try:
            with open(readme_path, "r", encoding="utf-8", errors="replace") as f:
                content = f.read(3000).lower()
            if any(w in content for w in ["planned", "coming soon", "roadmap"]):
                return "dev"
            if any(w in content for w in ["v1.", "v2.", "v3.", "stable", "release"]):
                return "stable"
            if any(w in content for w in ["beta", "wip", "work in progress", "alpha"]):
                return "beta"
        except:
            pass

    # Check file count as heuristic
    try:
        files = [f for f in os.listdir(repo_dir) if not f.startswith(".")]
        if len(files) > 3:
            return "stable"
    except:
        pass

    return "dev"


def has_github(repo_dir):
    """Check if repo has a GitHub remote."""
    config = os.path.join(repo_dir, ".git", "config")
    if os.path.isfile(config):
        try:
            with open(config, "r") as f:
                return "github.com" in f.read()
        except:
            pass
    return False


def detect_emoji(repo_dir, name):
    """Extract emoji from README title or use default."""
    readme_path = os.path.join(repo_dir, "README.md")
    if os.path.isfile(readme_path):
        try:
            with open(readme_path, "r", encoding="utf-8", errors="replace") as f:
                for line in f.readlines()[:5]:
                    if line.startswith("#"):
                        # Find first emoji
                        emoji_pattern = re.compile(
                            "["
                            "\U0001F300-\U0001F9FF"  # symbols & pictographs
                            "\U00002600-\U000027BF"  # misc symbols
                            "\U0001FA00-\U0001FA6F"  # chess symbols
                            "\U0001FA70-\U0001FAFF"  # symbols extended
                            "\U00002702-\U000027B0"  # dingbats
                            "]"
                        )
                        m = emoji_pattern.search(line)
                        if m:
                            return m.group()
                        break
        except:
            pass

    # Defaults by category
    defaults = {
        "microbit": "🤖", "camera": "📸", "arabic": "🕌",
        "classroom": "🏫", "learning": "📚", "hardware": "🔩",
        "ai": "🧠", "tools": "🛠️",
    }
    cat = detect_category(name)
    return defaults.get(cat, "📁")


def detect_tags(repo_dir, name, category):
    """Generate relevant tags based on repo content."""
    tags = set()

    # Category-based tags
    cat_tags = {
        "microbit": ["micro:bit", "BLE"],
        "camera": ["camera", "face-detection"],
        "arabic": ["arabic", "Islamic"],
        "classroom": ["classroom", "collaboration"],
        "learning": ["education", "interactive"],
        "hardware": ["networking", "IoT"],
        "ai": ["AI", "machine-learning"],
        "tools": ["developer-tool"],
    }
    tags.update(cat_tags.get(category, []))

    # Name-based tags
    nl = name.lower()
    if "ble" in nl or "bluetooth" in nl: tags.add("BLE")
    if "tts" in nl or "speech" in nl: tags.add("TTS")
    if "lab" in nl: tags.add("lab")
    if "kids" in nl: tags.add("kids")
    if "web" in nl or os.path.isfile(os.path.join(repo_dir, "index.html")): tags.add("HTML")

    # Check for common files
    if os.path.isfile(os.path.join(repo_dir, "index.html")): tags.add("web-app")
    if os.path.isfile(os.path.join(repo_dir, "package.json")): tags.add("node")
    if os.path.isfile(os.path.join(repo_dir, "manifest.json")): tags.add("PWA")

    return sorted(list(tags))[:6]


def detect_badge(status, name):
    """Detect badge type."""
    if status == "stable": return "stable"
    if status == "beta": return "dev"
    return "new"


# ═══ MAIN ═══
print(f"Repos dir: {REPOS_DIR}")
print(f"Loading existing apps-data.json...")

with open(APPS_DATA, "r", encoding="utf-8") as f:
    data = json.load(f)
existing = {a["name"]: a for a in data["apps"]}
print(f"Existing: {len(existing)} apps")

# Scan repos
new_apps = []
updated = 0
for dirname in sorted(os.listdir(REPOS_DIR)):
    repo_dir = os.path.join(REPOS_DIR, dirname)
    if not os.path.isdir(repo_dir): continue
    if dirname.startswith("."): continue

    if dirname in existing:
        continue  # Keep existing entry unchanged

    # New app
    category = detect_category(dirname)
    en, fr, ar = extract_descriptions(repo_dir, dirname)
    status = detect_status(repo_dir)
    emoji = detect_emoji(repo_dir, dirname)
    github = has_github(repo_dir)
    tags = detect_tags(repo_dir, dirname, category)
    badge = detect_badge(status, dirname)
    visibility = "public" if github else "private"

    app = {
        "name": dirname,
        "emoji": emoji,
        "categories": [category],
        "badge": badge,
        "status": status,
        "tags": tags,
        "desc": {"en": en, "fr": fr, "ar": ar},
        "visibility": visibility,
    }
    new_apps.append(app)

print(f"New apps found: {len(new_apps)}")

# Merge
all_apps = data["apps"] + new_apps
# Sort by name
all_apps.sort(key=lambda a: a["name"].lower())

# Update data
data["apps"] = all_apps
data["generated"] = __import__("datetime").datetime.utcnow().isoformat() + "Z"

# Write apps-data.json
with open(APPS_DATA, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print(f"Written {len(all_apps)} apps to apps-data.json")

# ═══ Generate INLINE_APPS for app.js ═══
print("Generating INLINE_APPS for app.js...")

lines = []
for app in all_apps:
    cats = json.dumps(app.get("categories", []))
    tags = json.dumps(app.get("tags", []))
    desc_en = app["desc"]["en"].replace('"', '\\"')
    desc_fr = app["desc"]["fr"].replace('"', '\\"')
    desc_ar = app["desc"]["ar"].replace('"', '\\"')
    vis = app.get("visibility", "public")

    line = (
        f'  {{ name:"{app["name"]}", emoji:"{app["emoji"]}", '
        f'categories:{cats}, badge:"{app.get("badge","new")}", '
        f'status:"{app.get("status","dev")}", visibility:"{vis}", '
        f'tags:{tags},\n'
        f'    desc:{{ en:"{desc_en}", fr:"{desc_fr}", ar:"{desc_ar}" }}}},'
    )
    lines.append(line)

inline_block = "const INLINE_APPS = [\n" + "\n".join(lines) + "\n];"

# Patch app.js
with open(APP_JS, "r", encoding="utf-8") as f:
    js_content = f.read()

# Replace INLINE_APPS block
pattern = r'const INLINE_APPS\s*=\s*\[.*?\];'
if re.search(pattern, js_content, re.DOTALL):
    js_content = re.sub(pattern, inline_block, js_content, flags=re.DOTALL)
    with open(APP_JS, "w", encoding="utf-8") as f:
        f.write(js_content)
    print("INLINE_APPS replaced in app.js")
else:
    print("WARNING: Could not find INLINE_APPS in app.js")

# ═══ Summary ═══
print(f"\n=== Sync Complete ===")
print(f"Total apps: {len(all_apps)}")
cats = {}
for a in all_apps:
    for c in a.get("categories", []):
        cats[c] = cats.get(c, 0) + 1
print("Categories:")
for c in sorted(cats, key=cats.get, reverse=True):
    print(f"  {c}: {cats[c]}")
print(f"\nDone!")
