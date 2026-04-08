#!/usr/bin/env node
/**
 * Workshop-Diy — gen-missing-thumbs.js
 * Generates thumbnails ONLY for apps that don't have one yet.
 * Run from your apps/ repo directory:
 *
 *   npm install puppeteer
 *   node gen-missing-thumbs.js
 *   git add thumbs/ && git commit -m "chore: generate missing thumbs" && git push
 */

const puppeteer = require("puppeteer");
const fs = require("fs");
const path = require("path");

const USER = "abourdim";
const VIEW = (repo) => `https://${USER}.github.io/${repo}/`;
const OUT_DIR = path.join(__dirname, "thumbs");
const DATA_FILE = path.join(__dirname, "apps-data.json");
const TIMEOUT = 25000;
const SETTLE_MS = 2500;
const MAX_RETRIES = 3;

// Apps confirmed missing (65 apps as of 2026-03-24)
const MISSING = [
  "AI-hacker-lab","al-maqlub","apps","arabic-tts","bit-54-activities",
  "ble-dashboard","bonjour","builders-of-light","callgraph","cowsay",
  "crypto-vault","dhcp-lab","dir-pulse","eid","emojis","fihris",
  "flight-tracker","flyers","git-date-rewrite","git-lab","git-pulse",
  "golden-age","hackrf-one","hacktivist-kids","jisr","kalami","linkedin",
  "luminaries-of-islam","mac-weird-keys","makecode-adventures","meridian",
  "morse-code","mqtt-lab","nusuk","ocpp","ollama-bot","ops-catalog",
  "ops-catalog-islamic-kids-apps","ops-catalog-islamic-kids-quizzes",
  "ops-catalog-kids-apps","ops-catalog-kids-quizzes","passassion-report",
  "PlanPilot","posts","prompt-hero","sada","salat-times",
  "sanitize-names-toolkit","satellites","save-our-planet","scapy","sdr-lab",
  "smart-home","sync-files","termlite","tesbih","tethkir","time-machine",
  "tools","true-crypt","tty","warsha","web-kids","web-kvm","wifi-dashboard"
];

if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

// Filter to only truly missing (in case some were added since)
const todo = MISSING.filter(name => {
  const f = path.join(OUT_DIR, `${name}.png`);
  return !fs.existsSync(f);
});

console.log(`\n🔍 Workshop-Diy — Missing Thumbnail Generator`);
console.log(`   ${todo.length} apps to screenshot (${MISSING.length - todo.length} already have thumbs)\n`);

if (todo.length === 0) {
  console.log("✅ All thumbs already generated!");
  process.exit(0);
}

async function shot(browser, name) {
  const url = VIEW(name);
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 800 });
    try {
      await page.goto(url, { waitUntil: "networkidle2", timeout: TIMEOUT });
      await new Promise(r => setTimeout(r, SETTLE_MS));
      const outFile = path.join(OUT_DIR, `${name}.png`);
      await page.screenshot({ path: outFile, type: "png" });
      await page.close();
      return true;
    } catch (err) {
      await page.close();
      if (attempt < MAX_RETRIES) {
        await new Promise(r => setTimeout(r, 1500 * attempt));
      } else {
        return false;
      }
    }
  }
  return false;
}

(async () => {
  console.log("🚀 Launching browser...\n");
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox","--disable-setuid-sandbox","--disable-dev-shm-usage"],
  });

  let ok = 0, fail = 0;
  const failed = [];

  for (let i = 0; i < todo.length; i++) {
    const name = todo[i];
    const pct = Math.round(((i+1)/todo.length)*100);
    const bar = "█".repeat(Math.round(pct/5)) + "░".repeat(20-Math.round(pct/5));
    process.stdout.write(`\r  [${bar}] ${pct}% (${i+1}/${todo.length}) ${name.padEnd(35)}`);

    const success = await shot(browser, name);
    if (success) ok++;
    else { fail++; failed.push(name); }
  }

  await browser.close();

  console.log(`\n\n🎉 Done!`);
  console.log(`   ✅ Success: ${ok}`);
  console.log(`   ❌ Failed : ${fail}`);
  if (failed.length > 0) {
    console.log(`\n   Failed apps (private or no index.html):`);
    failed.forEach(n => console.log(`     - ${n}`));
  }
  console.log(`\n📁 Thumbs saved in: ${OUT_DIR}`);
  console.log(`\nNext steps:`);
  console.log(`   git add thumbs/`);
  console.log(`   git commit -m "chore: generate missing thumbnails (${ok} new)"`);
  console.log(`   git push`);
})();
