// Regenerates the 13" iPad App Store screenshots (2064x2752) using the
// current build's code, driven headlessly against the local system Chrome
// via puppeteer-core (no bundled Chromium download).
//
// Usage:
//   npm install --no-save puppeteer-core   # once
//   node tools/gen-ipad-screenshots.mjs
//
// Loads index.html directly via file:// (single self-contained file), seeds
// localStorage with some progress/achievements so the level-select and
// achievements screens look populated rather than all-locked, then drives
// the game's own JS globals (GameState, Slingshot, PhysicsEngine, Game.*) to
// force each scene instead of simulating real touch gestures.

import puppeteer from 'puppeteer-core';
import path from 'node:path';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OUT_DIR = path.join(ROOT, 'store-screenshots', 'ipad-13');
const INDEX = 'file://' + path.join(ROOT, 'index.html');

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const W = 2064, H = 2752;

fs.mkdirSync(OUT_DIR, { recursive: true });

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function main() {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: true,
    defaultViewport: { width: W, height: H, deviceScaleFactor: 1 },
  });
  const page = await browser.newPage();
  await page.setViewport({ width: W, height: H, deviceScaleFactor: 1 });

  // Seed save data BEFORE the app boots so GameState.init() picks it up:
  // levels 1-8 with a mix of star ratings (grid looks alive, not all-locked),
  // level 9 unlocked-not-played, rest locked; a handful of achievements
  // unlocked (achievements screen shows a realistic mix).
  await page.evaluateOnNewDocument(() => {
    localStorage.setItem('astro_progress', JSON.stringify([4,4,3,4,2,3,4,3,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]));
    localStorage.setItem('astro_achievements', JSON.stringify([
      'first_steps','star_hunter','sharpshooter','bounce_master','portal_jumper','lvl_01','lvl_02','lvl_04'
    ]));
  });

  await page.goto(INDEX, { waitUntil: 'load' });
  await sleep(600); // let the title-screen canvas animation spin up

  async function shot(name) {
    await page.screenshot({ path: path.join(OUT_DIR, name), type: 'png' });
    console.log('  saved', name);
  }

  // ── 1. title.png — title screen ──
  console.log('title.png');
  await shot('title.png');

  // ── 2. aim.png — mid-aim on level 3 ──
  console.log('aim.png');
  await page.evaluate(() => {
    GameState.startLevel(2); // level 3, matches the previous shot
  });
  await sleep(500);
  await page.evaluate(() => {
    const ship = PhysicsEngine.ball;
    Slingshot.active = true;
    Slingshot.launched = false;
    Slingshot.startX = ship.x; Slingshot.startY = ship.y;
    // Pull back down-left, a natural-looking aim toward the upper-right target.
    Slingshot.curX = ship.x - 70; Slingshot.curY = ship.y + 80;
  });
  await sleep(200);
  await shot('aim.png');

  // ── 3. flight.png — ball mid-flight ──
  console.log('flight.png');
  await page.evaluate(() => {
    GameState.startLevel(4); // level 5: boosters galaxy, visually rich
  });
  await sleep(500);
  await page.evaluate(() => {
    Slingshot.active = false; Slingshot.launched = true;
    PhysicsEngine.ball.launch(260, -420);
  });
  await sleep(550); // a few physics steps in, still clearly mid-flight
  await shot('flight.png');

  // ── 4. galaxies.png — level select grid ──
  console.log('galaxies.png');
  await page.evaluate(() => { Game.showLevelSelect(); });
  await sleep(400);
  await shot('galaxies.png');

  // ── 5. ach.png — achievements screen ──
  console.log('ach.png');
  await page.evaluate(() => { Game.showAchievements(); });
  await sleep(400);
  await shot('ach.png');

  // ── 6. skins.png — ship skins screen ──
  console.log('skins.png');
  await page.evaluate(() => { Game.closeAchievements(); Game.showSkins(); });
  await sleep(400);
  await shot('skins.png');

  await browser.close();
  console.log('\nDone ->', OUT_DIR);
}

main().catch(e => { console.error(e); process.exit(1); });
