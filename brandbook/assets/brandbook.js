/* brandbook/assets/brandbook.js
   Scroll-spy, copy-hex, live WCAG contrast badges.
   No eval. No innerHTML from variables. No remote calls. ~60 logic lines.
   D-01: zero-build, file:// compatible. T-105-02: static textContent only.
*/

// ── Inlined WCAG contrast logic from brandbook/tools/contrast.mjs ──
function linearize(c) {
  const s = c / 255;
  return s <= 0.04045 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}

function luminance(r, g, b) {
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}

function parseHex(hex) {
  const clean = hex.replace('#', '');
  if (!/^[0-9a-fA-F]{6}$/.test(clean)) throw new Error('Invalid hex: ' + hex);
  return [
    parseInt(clean.slice(0, 2), 16),
    parseInt(clean.slice(2, 4), 16),
    parseInt(clean.slice(4, 6), 16),
  ];
}

function contrast(hex1, hex2) {
  const [r1, g1, b1] = parseHex(hex1);
  const [r2, g2, b2] = parseHex(hex2);
  const l1 = luminance(r1, g1, b1);
  const l2 = luminance(r2, g2, b2);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

// ── DOMContentLoaded ──
document.addEventListener('DOMContentLoaded', function () {

  // 1. Live contrast badges
  // Elements carrying data-fg + data-bg get a ratio + PASS/FAIL injected into .badge child
  document.querySelectorAll('[data-fg][data-bg]').forEach(function (el) {
    const badge = el.querySelector('.badge');
    if (!badge) return;
    try {
      const ratio = contrast(el.dataset.fg, el.dataset.bg);
      const pass = ratio >= 4.5;
      badge.textContent = ratio.toFixed(2) + ':1 ' + (pass ? 'PASS' : 'FAIL');
      badge.classList.add(pass ? 'badge--pass' : 'badge--fail');
    } catch (_) {
      badge.textContent = 'ERR';
    }
  });

  // 2. Copy-hex: delegated click handler on [data-copy-hex]
  document.addEventListener('click', function (e) {
    const btn = e.target.closest('[data-copy-hex]');
    if (!btn) return;
    const hex = btn.dataset.copyHex;
    if (!hex || !/^#[0-9a-fA-F]{6}$/.test(hex)) return;
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(hex).then(function () {
        const prev = btn.textContent;
        btn.textContent = 'Copied!';
        setTimeout(function () { btn.textContent = prev; }, 1200);
      }).catch(function () {});
    }
  });

  // 3. Scroll-spy via IntersectionObserver
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.book-nav a[href^="#"]');
  if (!sections.length || !navLinks.length) return;

  const linkMap = {};
  navLinks.forEach(function (a) {
    linkMap[a.getAttribute('href').slice(1)] = a;
  });

  const observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        navLinks.forEach(function (a) { a.classList.remove('active'); });
        const active = linkMap[entry.target.id];
        if (active) active.classList.add('active');
      }
    });
  }, { rootMargin: '-30% 0px -60% 0px', threshold: 0 });

  sections.forEach(function (s) { observer.observe(s); });
});
