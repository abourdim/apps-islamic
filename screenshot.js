/**
 * Workshop-Diy — screenshot.js
 * Enhanced thumbnail generator
 *  - Reads apps-data.json for app list
 *  - Supports CHANGED_REPOS env var for incremental builds
 *  - Retries failed screenshots (up to 3 attempts)
 *  - Progress bar in terminal
 */

const puppeteer = require("puppeteer");
const fs = require("fs");
const path = require("path");

const USER = "abourdim";
const VIEW = (repo) => `https://${USER}.github.io/${repo}/`;
const OUT_DIR = path.join(__dirname, "thumbs");
const DATA_FILE = path.join(__dirname, "apps-data.json");
const MAX_RETRIES = 3;
const TIMEOUT = 20000;
const SETTLE_MS = 2000;

// ──────── Load app list ────────
function loadApps() {
  // If CHANGED_REPOS env is set, only screenshot those
  const changedEnv = process.env.CHANGED_REPOS || "";
  if (changedEnv.trim()) {
    const names = changedEnv.trim().split("\n").filter(Boolean);
    console.log(`📋 Incremental mode: ${names.length} repos to screenshot`);
    return names;
  }

  // Otherwise, read from apps-data.json
  try {
    const data = JSON.parse(fs.readFileSync(DATA_FILE, "utf-8"));
    const names = data.apps.map((a) => a.name);
    console.log(`📋 Full mode: ${names.length} apps from apps-data.json`);
    return names;
  } catch (e) {
    console.warn("⚠️  Could not read apps-data.json, using hardcoded list");
    return [
      "all","bit-bot","bit-playground","magic-hands","bitmoji-lab","rxy",
      "usb-logger","ble-logger","mission-control","classroom","claude-toolkit",
      "crypto-academy","arabic-translator","arabic-speaker","piper-arabic-tts",
      "teachable-machine","face-quest","talking-robot","face-tracking",
      "pentest-lab","production-chain","puppeteer-playground"
    ];
  }
}

// ──────── Progress bar ────────
function progressBar(current, total, name) {
  const pct = Math.round((current / total) * 100);
  const filled = Math.round(pct / 5);
  const bar = "█".repeat(filled) + "░".repeat(20 - filled);
  process.stdout.write(`\r  [${bar}] ${pct}% (${current}/${total}) ${name.padEnd(25)}`);
}

// ──────── Screenshot with retry ────────
async function screenshotApp(browser, name, outFile) {
  const url = VIEW(name);

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 800 });

    try {
      await page.goto(url, { waitUntil: "networkidle2", timeout: TIMEOUT });
      // Give animations / lazy content a moment to settle
      await new Promise((r) => setTimeout(r, SETTLE_MS));
      await page.screenshot({ path: outFile, type: "png" });
      await page.close();
      return true;
    } catch (err) {
      await page.close();
      if (attempt < MAX_RETRIES) {
        // Wait before retry
        await new Promise((r) => setTimeout(r, 1000 * attempt));
      } else {
        console.warn(`\n   ⚠️  ${name}: failed after ${MAX_RETRIES} attempts (${err.message})`);
        return false;
      }
    }
  }
  return false;
}

// ──────── Main ────────
(async () => {
  const apps = loadApps();

  if (apps.length === 0) {
    console.log("ℹ️  No apps to screenshot.");
    return;
  }

  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

  console.log(`🚀 Launching browser...`);
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"],
  });

  let success = 0;
  let failed = 0;

  for (let i = 0; i < apps.length; i++) {
    const name = apps[i];
    const outFile = path.join(OUT_DIR, `${name}.png`);
    progressBar(i + 1, apps.length, name);

    const ok = await screenshotApp(browser, name, outFile);
    if (ok) success++;
    else failed++;
  }

  await browser.close();

  console.log(`\n`);
  console.log(`🎉 Done! ${success} succeeded, ${failed} failed`);
  console.log(`📁 Thumbnails saved in ${OUT_DIR}`);
})();
