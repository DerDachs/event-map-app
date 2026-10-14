// Renders PNG versions of the logos, the website icons and the social preview image
// with Playwright (Chromium). Run from the repository root after build_logos.py:
//
//     node brand/tools/export_png.js
//
// Needs the `playwright` package (npm i -g playwright, or NODE_PATH pointing to it).
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '../..');
const logo = (f) => path.join(root, 'brand/logo', f);
const png = (f) => path.join(root, 'brand/logo/png', f);
const site = (f) => path.join(root, 'website/assets', f);

// [svg, output, height in px, background or null for transparent]
const targets = [
  ['market-mate-logo.svg', png('market-mate-logo.png'), 256, null],
  ['market-mate-logo-on-dark.svg', png('market-mate-logo-on-dark.png'), 256, null],
  ['market-mate-logo-stacked.svg', png('market-mate-logo-stacked.png'), 512, null],
  ['market-mate-mark.svg', png('market-mate-mark-512.png'), 512, null],
  ['market-mate-app-icon.svg', png('market-mate-app-icon-1024.png'), 1024, null],
  ['cellarworks-logo.svg', png('cellarworks-logo.png'), 256, null],
  ['cellarworks-logo-on-dark.svg', png('cellarworks-logo-on-dark.png'), 256, null],
  ['cellarworks-mark.svg', png('cellarworks-mark-512.png'), 512, null],
  // Website
  ['favicon.svg', site('favicon.png'), 64, null],
  ['market-mate-app-icon.svg', site('apple-touch-icon.png'), 180, null],
];

(async () => {
  fs.mkdirSync(path.join(root, 'brand/logo/png'), { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage();

  for (const [svg, out, height] of targets) {
    const src = 'data:image/svg+xml;base64,' + fs.readFileSync(logo(svg)).toString('base64');
    await page.setContent(
      `<html><body style="margin:0;background:transparent"><img id="i" src="${src}" style="height:${height}px;display:block"></body></html>`
    );
    await page.waitForFunction(() => document.getElementById('i').complete);
    await page.locator('#i').screenshot({ path: out, omitBackground: true });
    console.log('wrote', path.relative(root, out));
  }

  // Social preview (Open Graph), 1200 x 630
  await page.setViewportSize({ width: 1200, height: 630 });
  await page.goto('file://' + path.join(root, 'brand/tools/og-image.html'));
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({ path: site('og-image.png') });
  console.log('wrote website/assets/og-image.png');

  await browser.close();
})();
