#!/usr/bin/env python3
"""Workshop-DIY Web Launcher — tiny HTTP server for launcher.sh"""

import hashlib
import http.server
import json
import logging
import subprocess
import os
import re
import signal
import traceback
import webbrowser
import threading
from html import escape as html_escape
from pathlib import Path
from urllib.parse import urlparse
from datetime import datetime

SCRIPT_DIR = Path(__file__).parent.resolve()
DATA_FILE = SCRIPT_DIR / "apps-data.json"
FLYERS_DIR = SCRIPT_DIR / "repos" / "flyers"
LAUNCHER = SCRIPT_DIR / "launcher.sh"
PORT = int(os.environ.get("PORT", 8787))
ANSI_RE = re.compile(r'\x1b\[[0-9;]*[a-zA-Z]')
MAX_BODY = 1024 * 1024  # 1 MB max request body
MAX_OPTION = 22
PROC_TIMEOUT = 300  # 5 minutes max per subprocess

# Interactive options that need special handling
TERMINAL_ONLY = {12, 13}  # Edit/Bulk edit — fully interactive TUI
ALLOWED_ORIGINS = {f"http://127.0.0.1:{PORT}", f"http://localhost:{PORT}"}

log = logging.getLogger("launcher")
logging.basicConfig(format="  %(levelname)s %(message)s", level=logging.INFO)


def strip_ansi(text):
    return ANSI_RE.sub('', text)


def load_apps():
    try:
        with open(DATA_FILE, encoding='utf-8') as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        log.error("Failed to load %s: %s", DATA_FILE, e)
        return {"apps": []}


def get_status():
    apps = load_apps().get("apps", [])
    repo_count = sum(1 for d in (SCRIPT_DIR / "repos").iterdir()
                     if d.is_dir() and (d / ".git").is_dir()) if (SCRIPT_DIR / "repos").is_dir() else 0
    flyer_count = len(list(FLYERS_DIR.glob("*.html"))) if FLYERS_DIR.is_dir() else 0
    return {
        "apps": len(apps),
        "repos": repo_count,
        "flyers": flyer_count,
        "stable": sum(1 for a in apps if a.get("status") == "stable"),
        "beta": sum(1 for a in apps if a.get("status") == "beta"),
        "dev": sum(1 for a in apps if a.get("status") == "dev"),
        "offline": sum(1 for a in apps if a.get("status") == "offline"),
    }


def list_flyers():
    if not FLYERS_DIR.is_dir():
        return []
    flyers = []
    for f in sorted(FLYERS_DIR.glob("*.html")):
        stat = f.stat()
        flyers.append({
            "name": f.name,
            "size": stat.st_size,
            "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
        })
    return flyers


def generate_event_flyer(params):
    """Generate an event flyer from form data (Python-native)."""
    try:
        import qrcode
        import base64
        import io
        HAS_QR = True
    except ImportError:
        HAS_QR = False

    app_name = params.get("app_name", "")
    apps = load_apps().get("apps", [])
    app = next((a for a in apps if a["name"] == app_name), None)
    if not app:
        return {"error": f"App '{app_name}' not found"}

    emoji = html_escape(app.get("emoji", "\U0001f527"))
    cats = html_escape(",".join(app.get("categories", [])))
    desc_fr = html_escape(app.get("desc", {}).get("fr", app.get("desc", {}).get("en", app_name)))
    url = f"https://abourdim.github.io/{app_name}/"

    # Theme
    theme = params.get("theme", "auto")
    THEMES = {
        "Gold": ("#d4820a", "#fdf6e3"),
        "Teal": ("#0a9e72", "#e8f8f2"),
        "Blue": ("#3a7bd5", "#e8f0fe"),
        "Violet": ("#7c3aed", "#f3e8ff"),
    }
    if theme == "auto" or theme not in THEMES:
        accent, bg = "#3a7bd5", "#e8f0fe"
        for cat in app.get("categories", []):
            if cat in ("microbit", "hardware"):
                accent, bg = THEMES["Gold"]; break
            elif cat in ("ai", "camera"):
                accent, bg = THEMES["Teal"]; break
            elif cat in ("arabic",):
                accent, bg = THEMES["Violet"]; break
    else:
        accent, bg = THEMES[theme]

    ev_date = html_escape(params.get("date", "JJ mois AAAA"))
    ev_time = html_escape(params.get("time", "HHh \u2013 HHh"))
    ev_lieu = html_escape(params.get("lieu", "Lieu \u00e0 d\u00e9finir"))
    features = params.get("features", [
        "\U0001f527 D\u00e9couvre l\u2019application",
        "\U0001f4e1 Connecte-toi et explore",
        "\U0001f3ae Teste les fonctionnalit\u00e9s",
        "\U0001f680 Partage tes r\u00e9sultats"
    ])
    while len(features) < 4:
        features.append("")

    def hex_to_rgba(h, a):
        r, g, b = int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16)
        return f"rgba({r},{g},{b},{a})"

    wash1 = hex_to_rgba(accent, 0.08)
    wash2 = hex_to_rgba(accent, 0.02)
    bis_color = hex_to_rgba(accent, 0.38)

    # Parse features
    def parse_feat(f):
        if not f:
            return "\U0001f527", ""
        f = str(f)
        if f[0] not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789":
            parts = f.split(" ", 1)
            return html_escape(parts[0]), html_escape(parts[1]) if len(parts) > 1 else ""
        return "\U0001f527", html_escape(f)

    feats = [parse_feat(f) for f in features[:4]]

    # QR code
    qr_b64 = ""
    if HAS_QR:
        qr = qrcode.QRCode(version=2, error_correction=qrcode.constants.ERROR_CORRECT_H, box_size=8, border=2)
        qr.add_data(url)
        qr.make(fit=True)
        img = qr.make_image(fill_color=accent, back_color=bg).convert("RGBA")
        buf = io.BytesIO()
        img.save(buf, "PNG")
        qr_b64 = base64.b64encode(buf.getvalue()).decode()

    qr_img = f'<img src="data:image/png;base64,{qr_b64}" alt="QR" style="border-color:{accent};"/>' if qr_b64 else f'<div style="width:130px;height:130px;border:3px solid {accent};border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:11px;color:#999;">QR</div>'

    # Title split
    parts = app_name.split("-")
    title_acc = html_escape(parts[0].capitalize())
    title_rest = html_escape("-" + "-".join(p.capitalize() for p in parts[1:])) if len(parts) > 1 else ""

    islamic_b64 = "PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHdpZHRoPScxMDAnIGhlaWdodD0nMTAwJz4KICA8ZGVmcz48cGF0dGVybiBpZD0nZycgd2lkdGg9JzEwMCcgaGVpZ2h0PScxMDAnIHBhdHRlcm5Vbml0cz0ndXNlclNwYWNlT25Vc2UnPgogICAgPGcgZmlsbD0nbm9uZScgc3Ryb2tlPSdyZ2JhKDIwMCwxNjAsNjAsMC4wOSknIHN0cm9rZS13aWR0aD0nMC43Jz4KICAgICAgPHBvbHlnb24gcG9pbnRzPSc1MCw2IDU4LDMwIDgyLDIyIDcwLDQ0IDg0LDYyIDYwLDU2IDU4LDgwIDUwLDYyIDQyLDgwIDQwLDU2IDE2LDYyIDMwLDQ0IDE4LDIyIDQyLDMwJy8+CiAgICAgIDxwb2x5Z29uIHBvaW50cz0nNTAsMjQgNTUsMzYgNjgsMzIgNjIsNDIgNzAsNTIgNTcsNTAgNTYsNjIgNTAsNTQgNDQsNjIgNDMsNTAgMzAsNTIgMzgsNDIgMzIsMzIgNDUsMzYnLz4KICAgICAgPGNpcmNsZSBjeD0nNTAnIGN5PSc1MCcgcj0nMTEnIHN0cm9rZS13aWR0aD0nMC41Jy8+CiAgICA8L2c+CiAgPC9wYXR0ZXJuPjwvZGVmcz4KICA8cmVjdCB3aWR0aD0nMTAwJyBoZWlnaHQ9JzEwMCcgZmlsbD0ndXJsKCNnKScvPgo8L3N2Zz4="

    # Numbering
    FLYERS_DIR.mkdir(parents=True, exist_ok=True)
    # Find the app's number from apps list
    idx = next((i for i, a in enumerate(apps, 1) if a["name"] == app_name), len(apps) + 1)
    num = f"{idx:03d}"
    out_file = FLYERS_DIR / f"{num}_{app_name}.html"
    out_txt = FLYERS_DIR / f"{num}_{app_name}.txt"

    html = f'''<!DOCTYPE html>
<html lang="fr"><head><meta charset="UTF-8">
<title>Atelier {html_escape(app_name)} \u2014 Workshop DIY</title>
<link href="https://fonts.googleapis.com/css2?family=Fredoka+One&family=Nunito:wght@400;600;700;800;900&display=swap" rel="stylesheet">
<style>
*{{margin:0;padding:0;box-sizing:border-box}}
body{{background:#fff;font-family:'Nunito',sans-serif}}
.flyer{{width:1080px;position:relative;overflow:hidden;padding-bottom:48px;background:{bg}}}
.bg-pattern{{position:absolute;inset:0;pointer-events:none;z-index:1;background-image:url("data:image/svg+xml;base64,{islamic_b64}");background-size:100px 100px}}
.bg-wash{{position:absolute;inset:0;pointer-events:none;z-index:2;background:linear-gradient(160deg,{wash1} 0%,rgba(255,248,220,0.5) 50%,{wash2} 100%)}}
.bismillah{{position:absolute;top:10px;left:50%;transform:translateX(-50%);font-size:15px;letter-spacing:3px;z-index:20;white-space:nowrap;font-family:'Scheherazade New','Arial Unicode MS',serif;color:{bis_color}}}
.topbar{{position:relative;z-index:20;display:flex;align-items:center;justify-content:space-between;padding:48px 56px 24px}}
.logo-box{{background:rgba(255,255,255,0.9);border:2px solid rgba(0,0,0,0.12);border-radius:18px;padding:10px 18px}}
.logo-text{{font-family:'Fredoka One',cursive;font-size:20px;color:#1a1a2e}}
.hero{{position:relative;z-index:20;padding:0 56px 18px}}
.sub-tag{{font-size:12px;font-weight:800;letter-spacing:3px;text-transform:uppercase;display:flex;align-items:center;gap:8px;margin-bottom:8px;color:{accent};opacity:0.7}}
.atelier-label{{font-family:'Fredoka One',cursive;font-size:24px;letter-spacing:3px;text-transform:uppercase;margin-bottom:0;opacity:0.65;color:{accent}}}
.title{{font-family:'Fredoka One',cursive;font-size:82px;line-height:1;margin-bottom:16px;display:flex;align-items:center;gap:12px;color:#1a1a2e}}
.title .acc{{color:{accent}}}
.desc{{font-size:17px;line-height:1.65;max-width:840px;margin-bottom:18px;color:#2c2c3e;font-weight:600}}
.features{{display:flex;flex-direction:column;gap:10px;margin-bottom:24px}}
.feat-item{{display:flex;align-items:center;gap:14px;font-size:16px;font-weight:700;padding:12px 18px;border-radius:14px;color:#1a1a2e;background:rgba(255,255,255,0.75);border-left:4px solid {accent};box-shadow:0 2px 8px rgba(0,0,0,0.06)}}
.feat-item .fi{{font-size:22px;flex-shrink:0}}
.audience-row{{position:relative;z-index:20;display:flex;gap:12px;padding:0 56px 22px;flex-wrap:wrap}}
.aud-pill{{display:flex;align-items:center;gap:9px;padding:10px 22px;border-radius:50px;font-size:15px;font-weight:800;color:#1a1a2e;background:rgba(255,255,255,0.8);box-shadow:0 2px 8px rgba(0,0,0,0.1);border:2px solid rgba(0,0,0,0.08)}}
.price-banner{{position:relative;z-index:20;margin:0 56px 22px;border-radius:20px;padding:22px 28px;display:flex;align-items:center;gap:20px;background:rgba(255,255,255,0.85);box-shadow:0 4px 16px rgba(0,0,0,0.1);border:2px solid rgba(0,0,0,0.07)}}
.price-item{{display:flex;align-items:center;gap:14px;flex:1}}
.price-icon{{font-size:32px}}
.price-lbl{{font-size:11px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:#666;margin-bottom:3px}}
.price-val{{font-size:22px;font-weight:900;color:#1a1a2e}}
.price-divider{{width:2px;height:50px;background:rgba(0,0,0,0.08);border-radius:2px}}
.atelier-banner{{position:relative;z-index:20;margin:0 56px 22px;border-radius:20px;padding:22px 28px;display:flex;align-items:center;justify-content:space-between;gap:24px;background:rgba(255,255,255,0.85);box-shadow:0 4px 16px rgba(0,0,0,0.1);border:2px solid {accent}55}}
.atelier-left{{flex:1}}
.atelier-title{{font-family:'Fredoka One',cursive;font-size:22px;color:#1a1a2e;margin-bottom:8px;display:flex;align-items:center;gap:10px}}
.atelier-title .badge{{font-size:10px;font-weight:900;letter-spacing:2px;text-transform:uppercase;padding:4px 12px;border-radius:20px;background:{accent}22;color:{accent}}}
.atelier-desc{{font-size:14px;font-weight:700;color:#444;line-height:1.5;margin-bottom:8px}}
.atelier-url{{font-size:12px;font-weight:700;word-break:break-all;font-family:monospace;color:#555}}
.atelier-cta{{font-size:14px;font-weight:900;margin-top:10px;color:{accent}}}
.qr-wrap{{display:flex;flex-direction:column;align-items:center;gap:8px}}
.qr-wrap img{{width:130px;height:130px;border-radius:12px;padding:6px;border:3px solid}}
.qr-label{{font-size:10px;font-weight:900;letter-spacing:1.5px;text-transform:uppercase;color:#666}}
.info-row{{position:relative;z-index:20;display:flex;gap:14px;padding:0 56px 18px}}
.info-card{{flex:1;border-radius:16px;padding:16px 20px;display:flex;align-items:center;gap:12px;background:rgba(255,255,255,0.85);box-shadow:0 2px 10px rgba(0,0,0,0.08);border:2px solid rgba(0,0,0,0.07)}}
.info-icon{{font-size:26px;flex-shrink:0}}
.lbl{{font-size:10px;letter-spacing:2px;text-transform:uppercase;color:#888;font-weight:800;margin-bottom:3px}}
.val{{font-size:16px;font-weight:900;color:#1a1a2e;line-height:1.3}}
.contact-bar{{position:relative;z-index:20;display:flex;align-items:center;gap:14px;padding:0 56px 22px;flex-wrap:wrap}}
.ci-item{{font-size:14px;font-weight:700;color:#444;display:flex;align-items:center;gap:6px}}
.dot-sep{{color:#bbb;font-size:18px}}
.footer{{position:relative;z-index:20;margin:0 56px;border-top:2px solid rgba(0,0,0,0.08);padding-top:18px;display:flex;align-items:center;justify-content:space-between}}
.fnote{{font-size:13px;color:#888;font-style:italic;font-weight:600}}
.htags{{display:flex;gap:8px}}
.ht{{font-size:12px;font-weight:800;padding:5px 12px;border-radius:20px;border:2px solid rgba(0,0,0,0.1);color:#555;background:rgba(255,255,255,0.6)}}
</style></head><body>
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
      <div class="feat-item"><span class="fi">{feats[0][0]}</span><span>{feats[0][1]}</span></div>
      <div class="feat-item"><span class="fi">{feats[1][0]}</span><span>{feats[1][1]}</span></div>
      <div class="feat-item"><span class="fi">{feats[2][0]}</span><span>{feats[2][1]}</span></div>
      <div class="feat-item"><span class="fi">{feats[3][0]}</span><span>{feats[3][1]}</span></div>
    </div>
  </div>
  <div class="audience-row">
    <div class="aud-pill">\U0001f466 \u00c0 partir de 10 ans</div>
    <div class="aud-pill">\U0001f4bb PC portable recommand\u00e9</div>
    <div class="aud-pill">\U0001f393 Aucun pr\u00e9requis</div>
  </div>
  <div class="price-banner">
    <div class="price-item"><div class="price-icon">\U0001fa99</div><div><div class="price-lbl">Adh\u00e9rents Workshop-DIY</div><div class="price-val" style="color:#2e7d32;">Gratuit \u2705</div></div></div>
    <div class="price-divider"></div>
    <div class="price-item"><div class="price-icon">\U0001f39f\ufe0f</div><div><div class="price-lbl">Non-adh\u00e9rents</div><div class="price-val">7 \u20ac / personne</div></div></div>
    <div class="price-divider"></div>
    <div class="price-item" style="flex:0.7"><div class="price-icon">\u2139\ufe0f</div><div><div class="price-lbl">Devenir adh\u00e9rent</div><div class="price-val" style="font-size:15px">workshop-diy.org</div></div></div>
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
    <div class="info-card"><div class="info-icon">\U0001f4c5</div><div><div class="lbl">Date</div><div class="val"><em>{ev_date}</em></div></div></div>
    <div class="info-card"><div class="info-icon">\U0001f558</div><div><div class="lbl">Horaire</div><div class="val"><em>{ev_time}</em></div></div></div>
    <div class="info-card"><div class="info-icon">\U0001f4cd</div><div><div class="lbl">Lieu</div><div class="val"><em>{ev_lieu}</em></div></div></div>
  </div>
  <div class="contact-bar">
    <div class="ci-item">\U0001f310 workshop-diy.org</div><span class="dot-sep">\u00b7</span>
    <div class="ci-item">\u2709\ufe0f contact@workshop-diy.org</div><span class="dot-sep">\u00b7</span>
    <div class="ci-item">\U0001f4de 06 19 51 51 73</div>
  </div>
  <div class="footer">
    <div class="fnote">\u2728 Curiosit\u00e9 et sourire bienvenus !</div>
    <div class="htags"><span class="ht">#Atelier{title_acc}{title_rest.lstrip("-")}</span><span class="ht">#WorkshopDIY</span></div>
  </div>
</div></body></html>'''

    with open(out_file, "w", encoding="utf-8") as f:
        f.write(html)

    # Facebook post
    fb = f"""{emoji} Atelier {title_acc}{title_rest} \u2014 Workshop DIY

{desc_fr}

Lors de cet atelier tu vas :
{features[0]}
{features[1]}
{features[2]}
{features[3]}

\U0001f466 \u00c0 partir de 10 ans | \U0001f4bb PC portable recommand\u00e9 | \U0001f393 Aucun pr\u00e9requis

\U0001f4b0 Tarifs :
\U0001fa99 Adh\u00e9rents Workshop-DIY \u2192 Gratuit \u2705
\U0001f39f\ufe0f Non-adh\u00e9rents \u2192 7 \u20ac / personne
\u2139\ufe0f Devenir adh\u00e9rent : workshop-diy.org

\U0001f517 Lancer l\u2019atelier : {url}

\U0001f4c5 {ev_date} | \U0001f558 {ev_time}
\U0001f4cd {ev_lieu}

\U0001f310 workshop-diy.org | \u2709\ufe0f contact@workshop-diy.org | \U0001f4de 06 19 51 51 73

#Atelier{title_acc}{title_rest.replace('-', '')} #WorkshopDIY"""

    with open(out_txt, "w", encoding="utf-8") as f:
        f.write(fb)

    return {
        "file": out_file.name,
        "txt": out_txt.name,
        "preview": f"/flyer-preview/{out_file.name}",
        "facebook": fb,
    }


class LauncherHandler(http.server.BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):
        # Only log errors (4xx/5xx), suppress normal access logs
        msg = fmt % args
        if any(f'" {c}' in msg for c in ("4", "5")):
            log.warning(msg.strip())

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def send_file(self, path, content_type="text/html"):
        try:
            data = Path(path).read_bytes()
            etag = hashlib.md5(data).hexdigest()
            if self.headers.get("If-None-Match") == etag:
                self.send_response(304)
                self.end_headers()
                return
            self.send_response(200)
            self.send_header("Content-Type", f"{content_type}; charset=utf-8")
            self.send_header("Content-Length", len(data))
            self.send_header("ETag", etag)
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            self.wfile.write(data)
        except FileNotFoundError:
            self.send_json({"error": "Not found"}, 404)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")

        # Static files
        if path in ("", "/launcher.html"):
            self.send_file(SCRIPT_DIR / "launcher.html")
            return

        # API: apps data
        if path == "/api/apps":
            self.send_json(load_apps())
            return

        # API: server status
        if path == "/api/status":
            self.send_json(get_status())
            return

        # API: list flyers
        if path == "/api/flyers":
            self.send_json(list_flyers())
            return

        # Flyer preview
        if path.startswith("/flyer-preview/"):
            fname = path.split("/flyer-preview/", 1)[1]
            # Security: prevent path traversal
            safe = Path(fname).name
            fpath = FLYERS_DIR / safe
            if fpath.is_file():
                self.send_file(fpath)
            else:
                self.send_json({"error": "Flyer not found"}, 404)
            return

        self.send_json({"error": "Not found"}, 404)

    def do_OPTIONS(self):
        origin = self.headers.get("Origin", "")
        if origin in ALLOWED_ORIGINS:
            self.send_response(204)
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")
            self.send_header("Access-Control-Max-Age", "3600")
            self.end_headers()
        else:
            self.send_response(403)
            self.end_headers()

    def _check_origin(self):
        origin = self.headers.get("Origin", "")
        if origin and origin not in ALLOWED_ORIGINS:
            self.send_json({"error": "Forbidden origin"}, 403)
            return False
        return True

    def _read_json_body(self):
        raw = self.headers.get("Content-Length", "0")
        try:
            content_len = int(raw)
        except ValueError:
            self.send_json({"error": "Invalid Content-Length"}, 400)
            return None
        if content_len > MAX_BODY:
            self.send_json({"error": "Request too large"}, 413)
            return None
        if content_len == 0:
            return {}
        try:
            return json.loads(self.rfile.read(content_len))
        except (json.JSONDecodeError, ValueError):
            self.send_json({"error": "Invalid JSON"}, 400)
            return None

    def do_POST(self):
        if not self._check_origin():
            return

        body = self._read_json_body()
        if body is None:
            return

        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")

        # Run a launcher option (streaming)
        if path == "/api/run":
            option = body.get("option")
            if isinstance(option, bool) or not isinstance(option, int) or option < 1 or option > MAX_OPTION:
                self.send_json({"error": f"Invalid option (1-{MAX_OPTION})"}, 400)
                return

            if option in TERMINAL_ONLY:
                self.send_json({"error": f"Option {option} requires a terminal. Run: ./launcher.sh {option}"}, 400)
                return

            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Transfer-Encoding", "chunked")
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()

            proc = None
            timer = None
            try:
                proc = subprocess.Popen(
                    ["bash", str(LAUNCHER), str(option)],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    stdin=subprocess.DEVNULL,
                    cwd=str(SCRIPT_DIR),
                    bufsize=1,
                    text=True,
                    env={**os.environ, "TERM": "dumb"},
                    preexec_fn=os.setsid,
                )
                # Kill subprocess after timeout
                def _timeout():
                    if proc.poll() is None:
                        log.warning("Option %d timed out after %ds, killing", option, PROC_TIMEOUT)
                        os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
                timer = threading.Timer(PROC_TIMEOUT, _timeout)
                timer.daemon = True
                timer.start()

                for line in proc.stdout:
                    clean = strip_ansi(line)
                    chunk = f"{len(clean.encode('utf-8')):x}\r\n{clean}\r\n"
                    self.wfile.write(chunk.encode("utf-8"))
                    self.wfile.flush()
                proc.wait()
                # Send terminating chunk
                self.wfile.write(b"0\r\n\r\n")
                self.wfile.flush()
            except Exception as e:
                log.error("Option %d failed: %s", option, e)
                try:
                    err_msg = f"Error: {e}\n"
                    chunk = f"{len(err_msg.encode('utf-8')):x}\r\n{err_msg}\r\n0\r\n\r\n"
                    self.wfile.write(chunk.encode("utf-8"))
                    self.wfile.flush()
                except Exception:
                    pass
            finally:
                if timer is not None:
                    timer.cancel()
                if proc is not None:
                    if proc.stdout:
                        proc.stdout.close()
                    if proc.poll() is None:
                        try:
                            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
                        except OSError:
                            proc.kill()
                    proc.wait()
            return

        # Generate event flyer
        if path == "/api/flyer/event":
            result = generate_event_flyer(body)
            status = 400 if "error" in result else 200
            self.send_json(result, status)
            return

        self.send_json({"error": "Not found"}, 404)


def main():
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), LauncherHandler)
    server.daemon_threads = True
    print(f"\n  \U0001f6e0\ufe0f  Workshop-DIY Web Launcher")
    print(f"  \U0001f310 http://127.0.0.1:{PORT}")
    print(f"  Press Ctrl+C to stop\n")

    # Open browser in background
    t = threading.Timer(0.5, lambda: webbrowser.open(f"http://127.0.0.1:{PORT}"))
    t.daemon = True
    t.start()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Shutting down...")
        server.shutdown()
        server.server_close()
        print("  Bye!")


if __name__ == "__main__":
    main()
