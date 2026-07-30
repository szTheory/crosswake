import { test, expect, type Page } from '@playwright/test';

/*
 * Phase 154 Plan 08, Task 2 — the six judgements that used to be a human checkpoint.
 *
 * This file exists because the phase's closing gate was a `checkpoint:human-verify`
 * asking a person to open the AdminPilot approval route in a desktop browser and
 * decide whether the evidence panel "reads as the fail-closed thesis". Five of the
 * six judgements in that checkpoint turned out to have a mechanical form. They are
 * A–F below. G (doctor advisory actionability) and H (the guard's six-step recipe)
 * are ExUnit and live in test/crosswake/proof/.
 *
 * HONEST LABELLING (house style — see Crosswake.Bridge.CatalogGuard's moduledoc,
 * which labels its six criteria MECHANICAL / MECHANICAL-ONLY-IN-THE-NEGATIVE /
 * HYBRID / MECHANICAL-BY-PROXY rather than letting a proxy wear a proof's badge).
 * Each check below carries the same labelling. Where a check is a PROXY for the
 * human judgement it replaces, its docblock says so and says what it does not see.
 *
 *   A — MECHANICAL. Exact teaching sentences plus an enumerated forbidden-vocabulary
 *       sweep. Copy identity is decidable; "reads well" is not, and is not claimed.
 *   B — MECHANICAL. Document order and containment are decidable facts.
 *   C — PARTIAL PROXY. The accessibility semantics (role, aria-*, error classes) and
 *       the absence of a retry affordance are mechanical. Whether a reader FEELS
 *       blamed is not, and this file does not claim to test it.
 *   D — MECHANICAL. Two labels, two values, and the inequality that catches the
 *       "same string printed twice" failure mode.
 *   E — PARTIAL PROXY. The contrast ratio is computed, not eyeballed, and the scheme
 *       emulation is asserted to have actually taken effect. WCAG AA contrast is a
 *       floor for legibility, not a verdict on visual design.
 *   F — PROXY, stated plainly. This verifies the ANNOUNCEMENT CONTRACT: that the
 *       node carrying role/aria-live/aria-atomic is the same DOM node whose text
 *       mutates. It does NOT verify that a screen reader speaks it, at what time,
 *       or in what voice. No headless browser can.
 */

const APPROVAL_ROUTE = '/saas/approvals/approval-1';
const PANEL = '#haptics-evidence';
const REPLY = '#haptics-reply';

/*
 * A — the enumerated forbidden vocabulary for the IDLE panel.
 *
 * Enumerated in the test, never derived, so adding a token is a reviewable diff.
 * These are apology and empty-state tokens: a panel that has nothing to show yet
 * should teach what will happen, not apologise for the absence.
 */
const IDLE_FORBIDDEN_VOCABULARY = [
  'coming soon',
  'not yet',
  'nothing here',
  'nothing to show',
  'unavailable at this time',
  'todo',
  'unsupported browser',
  'not supported',
  'no data',
  'sorry',
  'oops',
  'under construction',
  'work in progress',
  'placeholder',
  'try again',
  'something went wrong',
  'check back',
];

/*
 * C — the enumerated FAULT vocabulary for the post-approval denial.
 *
 * A denial that reads as policy says what did not happen and why the decision
 * still stands. A denial that reads as fault reaches for these words.
 */
const DENIAL_FAULT_VOCABULARY = [
  'error',
  'failed',
  'failure',
  'broken',
  'went wrong',
  'crash',
  'exception',
  'invalid',
  'retry',
  'try again',
  'please try',
  'oops',
  'sorry',
  'problem',
];

/* C — class-name substrings that carry error semantics. */
const ERROR_SEMANTIC_CLASS_TOKENS = [
  'error',
  'danger',
  'invalid',
  'fail',
  'alert',
  'warning',
  'destructive',
];

test.describe('AdminPilot evidence panel — the automated form of the Phase 154 human gate', () => {
  test('A: the idle panel teaches the seam and apologises for nothing', async ({ page }) => {
    // The unauthenticated/member default first: this is what a developer who has
    // done no session setup sees, and it is the copy most likely to rot.
    await resetShowcase(page);
    await page.goto(APPROVAL_ROUTE);
    await expect(page.locator(PANEL)).toHaveCount(1);
    await assertIdlePanelCopy(page, 'member (default session)');

    // Then the approver session, which is the state the human checkpoint described
    // ("BEFORE approving"). Same copy is required — the idle teaching must not be
    // role-dependent.
    await asApprover(page);
    await page.goto(APPROVAL_ROUTE);
    await assertIdlePanelCopy(page, 'approver session');

    // Non-vacuity: the idle panel must NOT already contain dispatch or reply rows.
    // Without this, every assertion above would also pass on the post-approval panel.
    await expect(page.locator(REPLY)).toHaveCount(0);
    await expect(page.locator(`${PANEL} dl`)).toHaveCount(0);
  });

  test('B: approval success is stated independently of, and before, the denial', async ({ page }) => {
    await approveAndAwaitDenial(page);

    const order = await page.evaluate(
      ({ panelSelector, replySelector }) => {
        const panel = document.querySelector(panelSelector)!;
        const denial = document.querySelector(replySelector)!;
        const successNodes = Array.from(document.querySelectorAll('p')).filter((p) =>
          (p.textContent ?? '').includes('Phoenix recorded the decision'),
        );

        return {
          successCount: successNodes.length,
          // Node.DOCUMENT_POSITION_FOLLOWING === 4. Every success node must report
          // the denial node as FOLLOWING it in document order.
          allPrecedeDenial: successNodes.every(
            (n) => (n.compareDocumentPosition(denial) & 4) !== 0,
          ),
          anyInsideHapticsPanel: successNodes.some((n) => panel.contains(n)),
          successText: successNodes
            .map((n) => (n.textContent ?? '').replace(/\s+/g, ' ').trim())
            .join(' | '),
        };
      },
      { panelSelector: PANEL, replySelector: REPLY },
    );

    expect(order.successCount, 'the approval-success text must be rendered at all').toBeGreaterThan(0);
    expect(
      order.allPrecedeDenial,
      'every approval-success node must PRECEDE the haptics denial in document order — a reader reaches the outcome before the aside about it',
    ).toBe(true);
    expect(
      order.anyInsideHapticsPanel,
      'no approval-success node may be a descendant of the haptics panel — success that lives inside the optional-control panel is success conditioned on the optional control',
    ).toBe(false);

    // The success sentence stands on its own terms: it never mentions the shell,
    // the denial, or the reason. Deleting the whole haptics panel would not change it.
    expect(order.successText).toContain('Phoenix recorded the decision');
    expect(order.successText).not.toContain('shell_unreachable');
    expect(order.successText).not.toContain('declined');
  });

  test('C: the denial reads as policy, not as fault', async ({ page }) => {
    await approveAndAwaitDenial(page);

    const reply = page.locator(REPLY);

    // role="status" is polite-and-informational. role="alert" is interruptive and
    // means "something is wrong". The distinction IS the judgement being made here.
    await expect(reply).toHaveAttribute('role', 'status');

    const semantics = await page.evaluate(
      ({ panelSelector, errorClassTokens }) => {
        const panel = document.querySelector(panelSelector)!;
        const all = [panel, ...Array.from(panel.querySelectorAll('*'))] as HTMLElement[];

        return {
          alertRoles: all.filter((e) => e.getAttribute('role') === 'alert').length,
          ariaInvalid: all.filter((e) => e.getAttribute('aria-invalid') === 'true').length,
          errorClasses: all
            .map((e) => (typeof e.className === 'string' ? e.className : ''))
            .filter((c) => errorClassTokens.some((t: string) => c.toLowerCase().includes(t))),
          // A retry/spinner/waiting affordance says "this is a transient failure you
          // can act on". A policy denial is neither transient nor actionable here.
          buttons: all.filter(
            (e) => e.tagName === 'BUTTON' || e.getAttribute('role') === 'button',
          ).length,
          ariaBusy: all.filter((e) => e.getAttribute('aria-busy') === 'true').length,
          progressbars: all.filter((e) => e.getAttribute('role') === 'progressbar').length,
          elementCount: all.length,
        };
      },
      { panelSelector: PANEL, errorClassTokens: ERROR_SEMANTIC_CLASS_TOKENS },
    );

    // Non-vacuity: the sweep must have had a subject.
    expect(semantics.elementCount, 'the haptics panel must contain elements to sweep').toBeGreaterThan(5);

    expect(semantics.alertRoles, 'no element in the haptics panel may carry role="alert"').toBe(0);
    expect(semantics.ariaInvalid, 'no element in the haptics panel may carry aria-invalid="true"').toBe(0);
    expect(
      semantics.errorClasses,
      'no element in the haptics panel may carry an error-semantic class',
    ).toEqual([]);
    expect(semantics.buttons, 'the haptics panel offers nothing to click — there is nothing to retry').toBe(0);
    expect(semantics.ariaBusy, 'the haptics panel is not busy — the reply already arrived').toBe(0);
    expect(semantics.progressbars, 'the haptics panel shows no progress affordance').toBe(0);

    // The affirmation, in the SAME node as the denial — a reader who reads only the
    // live-region announcement still learns the approval survived.
    const replyText = await normalizedText(page, REPLY);
    expect(replyText, 'the denial node itself must carry the affirmation').toContain(
      'The approval stands.',
    );
    expect(replyText).toContain('Crosswake does nothing rather than fake one');

    for (const token of DENIAL_FAULT_VOCABULARY) {
      expect(
        replyText.toLowerCase(),
        `the denial must not reach for fault vocabulary: ${JSON.stringify(token)}`,
      ).not.toContain(token);
    }
  });

  test('D: the two identity rows teach the distinction rather than printing one string twice', async ({ page }) => {
    await approveAndAwaitDenial(page);

    const rows = await page.evaluate(
      ({ panelSelector }) => {
        const panel = document.querySelector(panelSelector)!;
        const out: Record<string, string> = {};
        const terms = Array.from(panel.querySelectorAll('dt'));

        for (const dt of terms) {
          const dd = dt.nextElementSibling;
          if (dd && dd.tagName === 'DD') {
            out[(dt.textContent ?? '').replace(/\s+/g, ' ').trim()] = (dd.textContent ?? '')
              .replace(/\s+/g, ' ')
              .trim();
          }
        }

        return out;
      },
      { panelSelector: PANEL },
    );

    // The disambiguating parentheticals are the teaching. Without them the two rows
    // are two mystery strings; with them the reader learns there are two vocabularies.
    expect(
      Object.keys(rows),
      'both identity labels must render with their disambiguating parentheticals',
    ).toEqual(expect.arrayContaining(['Capability (route policy)', 'Command (wire protocol)']));

    expect(rows['Capability (route policy)']).toBe('haptics');
    expect(rows['Command (wire protocol)']).toBe('haptics.impact');

    // The load-bearing assertion. A refactor that collapsed the family form and the
    // wire form back into one string would leave both rows rendering, both labelled,
    // and both WRONG — and only this inequality would go red.
    expect(
      rows['Capability (route policy)'],
      'the route-policy capability and the wire command must not be the same string — collapsing them is the drift this panel exists to make visible',
    ).not.toBe(rows['Command (wire protocol)']);
  });

  test('E: the denial reply text meets WCAG AA contrast in this project colour scheme', async ({ page }, testInfo) => {
    const scheme = testInfo.project.use.colorScheme ?? 'light';

    await approveAndAwaitDenial(page);

    const measured = await page.evaluate(
      ({ replySelector }) => {
        const parseRGBA = (value: string): [number, number, number, number] | null => {
          const m = /rgba?\(([^)]+)\)/.exec(value);
          if (!m) return null;
          const p = m[1].split(',').map((x) => parseFloat(x.trim()));
          return [p[0], p[1], p[2], p.length > 3 ? p[3] : 1];
        };

        // Composite the full ancestor background stack bottom-up rather than stopping
        // at the first non-transparent colour, so a translucent surface over a dark
        // page is measured as what the eye actually receives.
        const effectiveBackground = (el: Element): [number, number, number] => {
          const stack: Array<[number, number, number, number] | null> = [];
          let node: Element | null = el;
          while (node) {
            stack.push(parseRGBA(getComputedStyle(node).backgroundColor));
            node = node.parentElement;
          }
          stack.push([255, 255, 255, 1]);

          let out: [number, number, number] | null = null;
          for (let i = stack.length - 1; i >= 0; i--) {
            const c = stack[i];
            if (!c) continue;
            if (out === null) {
              out = [c[0], c[1], c[2]];
              continue;
            }
            const a = c[3];
            out = [
              c[0] * a + out[0] * (1 - a),
              c[1] * a + out[1] * (1 - a),
              c[2] * a + out[2] * (1 - a),
            ];
          }
          return out ?? [255, 255, 255];
        };

        const luminance = (rgb: [number, number, number]) => {
          const [r, g, b] = rgb.map((v) => {
            const s = v / 255;
            return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
          });
          return 0.2126 * r + 0.7152 * g + 0.0722 * b;
        };

        const ratioFor = (el: Element) => {
          const bg = effectiveBackground(el);
          const rawFg = parseRGBA(getComputedStyle(el).color)!;
          const fg: [number, number, number] =
            rawFg[3] < 1
              ? [
                  rawFg[0] * rawFg[3] + bg[0] * (1 - rawFg[3]),
                  rawFg[1] * rawFg[3] + bg[1] * (1 - rawFg[3]),
                  rawFg[2] * rawFg[3] + bg[2] * (1 - rawFg[3]),
                ]
              : [rawFg[0], rawFg[1], rawFg[2]];

          const l1 = luminance(fg);
          const l2 = luminance(bg);
          const [hi, lo] = l1 > l2 ? [l1, l2] : [l2, l1];
          return { ratio: (hi + 0.05) / (lo + 0.05), backgroundLuminance: luminance(bg) };
        };

        const reply = document.querySelector(replySelector)!;
        const verdict = reply.querySelector('strong')!;

        return {
          reply: ratioFor(reply),
          verdict: ratioFor(verdict),
          prefersDark: window.matchMedia('(prefers-color-scheme: dark)').matches,
        };
      },
      { replySelector: REPLY },
    );

    // NON-VACUITY, and the reason this test is worth having twice: without it the
    // "dark" project would silently measure the light palette and pass for the wrong
    // reason. Assert the emulation actually reached the page before trusting a number.
    expect(
      measured.prefersDark,
      `the ${scheme} project must actually be emulating ${scheme} — otherwise both projects measure the same palette`,
    ).toBe(scheme === 'dark');

    if (scheme === 'dark') {
      expect(
        measured.reply.backgroundLuminance,
        'the dark scheme must render the reply on a dark effective background',
      ).toBeLessThan(0.2);
    } else {
      expect(
        measured.reply.backgroundLuminance,
        'the light scheme must render the reply on a light effective background',
      ).toBeGreaterThan(0.5);
    }

    expect(
      measured.reply.ratio,
      `denial detail text contrast in ${scheme} must meet WCAG AA 4.5:1 (measured ${measured.reply.ratio.toFixed(2)}:1)`,
    ).toBeGreaterThanOrEqual(4.5);

    expect(
      measured.verdict.ratio,
      `denial verdict text contrast in ${scheme} must meet WCAG AA 4.5:1 (measured ${measured.verdict.ratio.toFixed(2)}:1)`,
    ).toBeGreaterThanOrEqual(4.5);
  });

  test('F: the live region is the node that mutates — the announcement contract, not audible speech', async ({ page }) => {
    /*
     * PROXY, stated plainly. This proves the ANNOUNCEMENT CONTRACT holds:
     *
     *   - the reply node carries role="status" aria-live="polite" aria-atomic="true";
     *   - the text that changes on approval changes INSIDE that same node object,
     *     not in a sibling that a screen reader would never announce.
     *
     * It does NOT prove a screen reader speaks it, when it speaks it, or how it
     * sounds. That remains unautomated and unclaimed. The failure mode this DOES
     * catch is the common one: a refactor that moves the mutating text out of the
     * live region (or wraps the live region around a container that never mutates),
     * leaving markup that still passes every static aria attribute assertion.
     */
    await resetShowcase(page);
    await asApprover(page);
    await page.goto(APPROVAL_ROUTE);
    await expect(page.locator(PANEL)).toHaveCount(1);

    await page.evaluate(() => {
      const w = window as unknown as {
        __cwAnnouncements: Array<{
          nodeTag: number;
          id: string;
          role: string | null;
          live: string | null;
          atomic: string | null;
          text: string;
        }>;
        __cwNodeSeq: number;
      };

      w.__cwAnnouncements = [];
      w.__cwNodeSeq = 0;

      // Stamp each distinct live-region DOM NODE with a monotonic tag. Equal tags
      // across two announcements is object identity: the same node mutated twice.
      const record = (el: Element) => {
        const tagged = el as Element & { __cwNodeTag?: number };
        if (tagged.__cwNodeTag === undefined) {
          tagged.__cwNodeTag = ++w.__cwNodeSeq;
        }
        w.__cwAnnouncements.push({
          nodeTag: tagged.__cwNodeTag,
          id: el.id,
          role: el.getAttribute('role'),
          live: el.getAttribute('aria-live'),
          atomic: el.getAttribute('aria-atomic'),
          text: (el.textContent ?? '').replace(/\s+/g, ' ').trim(),
        });
      };

      new MutationObserver((records) => {
        for (const r of records) {
          const target = r.target.nodeType === 1 ? (r.target as Element) : r.target.parentElement;
          if (target) {
            const live = target.closest('[aria-live]');
            if (live) record(live);
          }
          for (const added of Array.from(r.addedNodes)) {
            if (added.nodeType === 1 && (added as Element).matches?.('[aria-live]')) {
              record(added as Element);
            }
          }
        }
      }).observe(document.body, { subtree: true, childList: true, characterData: true });
    });

    await page.getByRole('button', { name: 'Approve request' }).click();
    await expect(page.locator(REPLY)).toContainText('Shell declined', { timeout: 20000 });

    // Static half of the contract.
    const reply = page.locator(REPLY);
    await expect(reply).toHaveAttribute('role', 'status');
    await expect(reply).toHaveAttribute('aria-live', 'polite');
    await expect(reply).toHaveAttribute('aria-atomic', 'true');

    const announcements = await page.evaluate(
      () => (window as unknown as { __cwAnnouncements: Array<Record<string, unknown>> }).__cwAnnouncements,
    );

    expect(
      announcements.length,
      'the mutation observer must have seen at least two announcements — the armed-deadline state and the denial',
    ).toBeGreaterThanOrEqual(2);

    for (const a of announcements) {
      expect(a.id, 'every announcement must originate on the haptics reply node').toBe('haptics-reply');
      expect(a.role).toBe('status');
      expect(a.live).toBe('polite');
      expect(a.atomic).toBe('true');
    }

    // Object identity across the whole sequence: one node, mutated — not a fresh
    // node per render and not a sibling carrying the text.
    const tags = new Set(announcements.map((a) => a.nodeTag));
    expect(
      tags.size,
      'all announcements must come from ONE DOM node — a new node per render would announce, but a sibling carrying the text would not',
    ).toBe(1);

    const texts = announcements.map((a) => String(a.text));
    expect(
      texts.some((t) => t.includes('Waiting for the shell')),
      'the live region must announce the armed-deadline state',
    ).toBe(true);
    expect(
      texts.some((t) => t.includes('Shell declined') && t.includes('The approval stands.')),
      'the live region must announce the denial AND the affirmation atomically, in one node',
    ).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// Helpers — self-sufficient setup. Every test seeds its own data through the
// compile-time-gated /_e2e helpers rather than assuming a hand-seeded server.
// ---------------------------------------------------------------------------

async function resetShowcase(page: Page) {
  const reset = await page.request.post('/_e2e/showcase-reset');
  expect(reset.ok(), 'deterministic showcase reset must succeed').toBe(true);
}

async function asApprover(page: Page) {
  const session = await page.request.post('/_e2e/saas-session', { data: { user_id: 'approver-1' } });
  expect(session.ok(), 'approver-1 e2e session helper must succeed').toBe(true);
}

async function normalizedText(page: Page, selector: string): Promise<string> {
  const raw = await page.locator(selector).textContent();
  return (raw ?? '').replace(/\s+/g, ' ').trim();
}

async function assertIdlePanelCopy(page: Page, sessionLabel: string) {
  const text = await normalizedText(page, PANEL);

  // The exact teaching sentences. Exact, not fuzzy: this copy is the thing the
  // human checkpoint was asked to judge, so a silent rewrite must be a red diff.
  const required = [
    'The route declares haptics as a bounded, low-frequency confirmation.',
    'Approval success does not depend on window.webkit or window.crosswakeBridge.',
    'No haptics request sent. Phoenix sends one only after an approval commits.',
  ];

  for (const sentence of required) {
    expect(text, `idle panel [${sessionLabel}] must carry the teaching sentence verbatim`).toContain(
      sentence,
    );
  }

  const lowered = text.toLowerCase();
  for (const token of IDLE_FORBIDDEN_VOCABULARY) {
    expect(
      lowered,
      `idle panel [${sessionLabel}] must not reach for apology/empty-state vocabulary: ${JSON.stringify(token)}`,
    ).not.toContain(token);
  }
}

async function approveAndAwaitDenial(page: Page) {
  await resetShowcase(page);
  await asApprover(page);
  await page.goto(APPROVAL_ROUTE);
  await expect(page.locator(PANEL)).toHaveCount(1);
  await page.getByRole('button', { name: 'Approve request' }).click();

  // Wait on the machine-readable envelope carrying a reply, which is the positive
  // reply-arrival gate the route tour already uses (D-75) — not a sleep.
  await expect(page.locator(PANEL)).toHaveAttribute('data-cw-envelope', /"reply":\{/, {
    timeout: 20000,
  });
  await expect(page.locator(REPLY)).toContainText('Shell declined', { timeout: 20000 });
}
