#!/usr/bin/env python3
"""
Workshop-Diy — 06_tag-visibility.py
Tags each app in apps-data.json with "visibility": "public"|"private"
by probing https://api.github.com/repos/abourdim/{name}
  - 200 → public
  - 404 → private (or doesn't exist on GitHub yet)
No token needed for public repos. With GITHUB_TOKEN env var → also sees private ones.
"""

import json, urllib.request, urllib.error, os, sys, time

GITHUB_USER = "abourdim"
JSON_FILE   = os.path.join(os.path.dirname(__file__), "apps-data.json")
TOKEN       = os.environ.get("GITHUB_TOKEN", "")

RESET  = "\033[0m"
GREEN  = "\033[32m"
YELLOW = "\033[33m"
RED    = "\033[31m"
CYAN   = "\033[36m"
BOLD   = "\033[1m"
DIM    = "\033[2m"

def check_visibility(name):
    url = f"https://api.github.com/repos/{GITHUB_USER}/{name}"
    headers = {"Accept": "application/vnd.github+json",
               "User-Agent": "workshop-diy-tagger/1.0"}
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=6) as r:
            data = json.loads(r.read())
            return "private" if data.get("private") else "public"
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return "private"
        if e.code == 403:
            return "unknown"   # rate-limited
        return "unknown"
    except Exception:
        return "unknown"

with open(JSON_FILE) as f:
    catalog = json.load(f)

apps = catalog["apps"]
total = len(apps)

print(f"\n{BOLD}Workshop-Diy — Visibility Tagger{RESET}")
print(f"{DIM}User: {GITHUB_USER}  |  {total} apps  |  Token: {'yes' if TOKEN else 'no (public only)'}{RESET}\n")

counts = {"public": 0, "private": 0, "unknown": 0}

for i, app in enumerate(apps, 1):
    name = app["name"]
    vis  = check_visibility(name)
    app["visibility"] = vis
    counts[vis] += 1

    icon = GREEN + "🌐" if vis == "public" else (YELLOW + "🔒" if vis == "private" else RED + "❓")
    print(f"  {icon}{RESET} {name:<30} {DIM}{vis}{RESET}")

    # Be polite to GitHub API — 30 req/s unauthenticated
    if i % 10 == 0:
        time.sleep(0.5)

# Save updated JSON
catalog["visibility_tagged"] = True
with open(JSON_FILE, "w", encoding="utf-8") as f:
    json.dump(catalog, f, indent=2, ensure_ascii=False)

print(f"\n{BOLD}Results:{RESET}")
print(f"  {GREEN}🌐 Public : {counts['public']}{RESET}")
print(f"  {YELLOW}🔒 Private: {counts['private']}{RESET}")
print(f"  {RED}❓ Unknown: {counts['unknown']}{RESET}")
print(f"\n{GREEN}✓ apps-data.json updated with visibility field.{RESET}\n")
