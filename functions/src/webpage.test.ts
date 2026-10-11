import assert from "node:assert/strict";
import { test } from "node:test";
import { extractPage, isPrivateAddress } from "./webpage.js";

const HTML = `<!doctype html><html><head>
<title>Barock-Weihnachtsmarkt &amp; mehr | Stadt Ludwigsburg</title>
<meta property="og:image" content="/media/wm-hero.jpg">
<meta name="twitter:image" content="https://cdn.example.org/wm-hero.jpg">
<script type="application/ld+json">{"@type":"Event","name":"Barock-Weihnachtsmarkt",
"startDate":"2026-11-24","image":["https://cdn.example.org/stand1.jpg","https://cdn.example.org/stand2.jpg"]}</script>
<style>body{color:red}</style><script>var tracking = 1;</script>
</head><body>
<header><img src="/img/logo.png" alt="Logo"></header>
<h1>Barock-Weihnachtsmarkt</h1><p>Vom 24.11. bis 22.12. auf dem Marktplatz.<br>Täglich 11&ndash;21 Uhr.</p>
<img src="/media/engel.jpg" alt="Lichterengel über dem Markt" width="1200">
<img src="/media/klein.jpg" width="80"><img src="data:image/png;base64,AAAA">
<img srcset="/media/b-400.jpg 400w, /media/b-1600.jpg 1600w" alt="Buden">
<!-- versteckt --></body></html>`;

test("extracts title, text, JSON-LD and images", () => {
  const page = extractPage(HTML, new URL("https://www.ludwigsburg.de/wm"));
  assert.equal(page.title, "Barock-Weihnachtsmarkt & mehr | Stadt Ludwigsburg");
  assert.match(page.text, /Vom 24\.11\. bis 22\.12\. auf dem Marktplatz\.\nTäglich 11–21 Uhr\./);
  assert.doesNotMatch(page.text, /tracking|color:red|versteckt/);
  assert.equal(page.jsonLd.length, 1);
  assert.deepEqual(
    page.images.map((i) => i.url),
    [
      "https://www.ludwigsburg.de/media/wm-hero.jpg",
      "https://cdn.example.org/wm-hero.jpg",
      "https://cdn.example.org/stand1.jpg",
      "https://cdn.example.org/stand2.jpg",
      "https://www.ludwigsburg.de/media/engel.jpg",
      "https://www.ludwigsburg.de/media/b-1600.jpg",
    ],
  );
  assert.equal(page.images[4].alt, "Lichterengel über dem Markt");
});

test("blocks non-public addresses", () => {
  for (const ip of ["127.0.0.1", "10.1.2.3", "172.20.0.1", "192.168.1.1", "169.254.169.254", "::1", "fd00::1", "::ffff:10.0.0.1", "0.0.0.0"]) {
    assert.equal(isPrivateAddress(ip), true, ip);
  }
  for (const ip of ["8.8.8.8", "142.250.185.110", "2a00:1450:4001:82a::200e"]) {
    assert.equal(isPrivateAddress(ip), false, ip);
  }
});
