import { test, expect, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';
import path from 'node:path';

/*
 * Phase 155 Plan 07 — PROOF-01: the three-condition merge-blocking browser proof.
 *
 * Three routes because there are three conditions (D-43, D-44 — the corrected
 * wording, replacing ROADMAP.md's superseded criterion 3):
 *
 *   An undeclared capability RAISES and names the missing declaration. An
 *   unavailable capability renders an explicit denial. A merge-blocking browser
 *   route-tour proves that the surface renders, that a shell-side denial renders
 *   and the mutation does not proceed, and that no failure path resolves to
 *   silence. The outbound raise is DELIBERATELY EXCLUDED from this browser lane
 *   because a browser cannot observe a server-side raise, and is asserted
 *   server-side in ExUnit instead (`test/crosswake/bridge/push_test.exs`). This
 *   split is HYBRID, exactly as Phase 154's D-44 labelled its own fails-closed
 *   criterion.
 *
 * NOT CLAIMED by this file (D-48, verbatim — not a footnote):
 *
 *   Not "never" as a universal — only the enumerated CURRENT vocabulary, and
 *   excluding SEED-008's five unbounded string seams (bare-`String` denial
 *   reasons an adopter host can mint at five delegate call sites — see
 *   `CatalogGuard`'s moduledoc). Not native behavior — desktop Chromium plus
 *   `page.addInitScript()` document-start injection is a faithful stand-in for
 *   the shell transport, never a claim about real iOS or Android runtime
 *   behavior. Not the adopter's edited copy — these fallback files are
 *   host-owned and generated once; an adopter who edits them owns the result.
 *   Not that the UI is good — contrast and focus are floors, not verdicts on
 *   visual design. Not reachability on every route — this lane visits exactly
 *   three routes. Not screenshots — every assertion below is semantic.
 *
 * HONEST LABELLING (house style — see `evidence_panel.spec.ts`'s moduledoc and
 * `Crosswake.Bridge.CatalogGuard`'s six-criteria docblock):
 *
 *   A1 — MECHANICAL. Absent-before/present-after, generator-stamp non-vacuity,
 *        the catalog sentence read from source, focus-trap BEHAVIOR (not markup
 *        presence), computed contrast in both schemes, and the APG menu-role
 *        absence are all decidable browser facts.
 *   A2 — MECHANICAL. The doubly-nested wire injection, the rendered denial's
 *        reason, and the negative control (success surface + effect counter
 *        both asserted absent) are all decidable browser facts.
 *   A3 — HYBRID. The rendered-text-changed + MutationObserver dead-air check is
 *        MECHANICAL. The denial-vocabulary coverage check is the HONEST
 *        APPROXIMATION of "never silently degrades" that D-47 defines: every
 *        reason in `Crosswake.Shell.Denial`'s closed vocabulary is either
 *        EXERCISED by this spec or EXPLICITLY EXCLUDED with a stated reason,
 *        and the union must equal the full vocabulary — adding a 15th reason
 *        without updating this file turns the lane red.
 */

const A1_ROUTE = '/saas/approvals/approval-1';
const A2_ROUTE = '/_e2e/undeclared-control';
const A3_ROUTE = '/bridge-proof';

const FALLBACK = '[data-cw-fallback]';
const GENERATED_COMPONENT_PATH =
  'lib/crosswake_example_web/components/crosswake_fallbacks.ex';
const APPROVAL_LIVE_RELATIVE_PATH = 'lib/crosswake_example/saas_portal/approval_live.ex';
// Two directories up from examples/phoenix_host (this project's cwd) to the repo
// root, then into the core library — the same relative-path discipline
// route_tour.spec.ts:19-23 uses to read the bridge protocol version from
// contract.ex rather than hardcoding it.
const CORE_LIB_ROOT = path.join(process.cwd(), '..', '..', 'lib', 'crosswake');

// D-46 discipline: the A1 catalog sentence lives in ONE place —
// approval_live.ex's catalog_sentence/0 — and this spec reads it rather than
// duplicating it as a literal that could silently drift from what the page
// actually renders.
const CATALOG_SENTENCE = readCatalogSentence();

// D-47's honest coverage of the closed denial vocabulary. `closed_vocabulary/0`
// (lib/crosswake/bridge/catalog_guard.ex) is `Enum.map(ShellDenial.reasons(),
// &Atom.to_string/1)` — the actual 14-entry list is authored one hop further, in
// `Crosswake.Shell.Denial`'s `@reasons`. Reading the transitive source keeps this
// honest about WHERE the vocabulary lives while tracking the exact list
// `closed_vocabulary/0` returns.
const CLOSED_VOCABULARY = readClosedVocabulary();

// Exercised for real by this spec's own assertions.
const EXERCISED_REASONS = ['undeclared_capability', 'shell_unreachable'];

// Every other reason in the closed vocabulary, each excluded with a stated
// reason. A 15th reason added to Crosswake.Shell.Denial and left uncategorized
// here fails the coverage test below — that is the mechanism (D-47).
const EXCLUDED_REASONS: Record<string, string> = {
  compatibility_mismatch:
    'a version-negotiation outcome; no route in this lane exercises a SemVer mismatch.',
  unavailable_capability:
    'asserted as the NEGATIVE comparison in A2 (D-13, the two-remediation-collapse guard) — never independently triggered on the wire in this lane.',
  commerce_corridor:
    'a commerce-route activation outcome; no commerce route exists in this lane.',
  origin_denied: 'an external-entry origin check; this lane never simulates an external origin.',
  inactive_route:
    'a compiled-manifest route-activation outcome; every route this lane visits is active.',
  external_entry_denied:
    'an external-entry policy outcome; not exercised by an internal-navigation lane.',
  pack_incompatible: 'an offline-pack version outcome; no offline-pack route is exercised here.',
  gate_denied: 'a kill-switch/gate policy outcome; no gated route is exercised here.',
  kill_switch_active: 'a kill-switch policy outcome; no kill-switched capability is exercised here.',
  step_up_required:
    'an MFA/recent-auth escalation outcome; A1/A2/A3 routes require neither.',
  notification_open_denied:
    'a notification_token-specific outcome; no notification_token push happens here.',
  dependency_missing:
    'an auth-authority companion-absence outcome; this lane never removes an auth companion.',
};

test.describe('PROOF-01 A1 — the fallback surface renders on a real product route', () => {
  test('the generated confirm modal is absent before the trigger, present after, and non-vacuous', async ({
    page,
  }) => {
    await resetShowcase(page);
    await asApprover(page);
    await page.goto(A1_ROUTE);
    await expectLiveViewConnected(page, 'saas-approval');

    // Absent before — not a bare present-after assertion.
    await expect(page.locator(FALLBACK)).toHaveCount(0);

    await page.locator('#native-controls-confirm-trigger').click();

    const fallback = page.locator(FALLBACK);
    await expect(fallback).toHaveCount(1);
    await expect(fallback).toHaveAttribute('role', 'dialog');
    await expect(fallback).toHaveAttribute('data-cw-fallback-tone', 'neutral');
    await expect(fallback).toHaveAttribute('aria-modal', 'true');
  });

  test('the committed generated component carries the generator stamp (non-vacuity)', async () => {
    // Read the committed file through Node's own process, not the browser — this
    // proves the file ON DISK (what the route actually renders from) is real
    // generator output, per D-46's non-vacuity condition for the absent/present
    // pair above.
    const source = readFileSync(path.join(process.cwd(), GENERATED_COMPONENT_PATH), 'utf8');

    expect(source, 'the committed component must carry the FALL-01 provenance stamp').toContain(
      'crosswake:native-controls-ui',
    );
    expect(source).toContain('template_version=2');
  });

  test('the catalog sentence rendered on the page equals the value read from source', async ({ page }) => {
    await resetShowcase(page);
    await asApprover(page);
    await page.goto(A1_ROUTE);

    const text = await normalizedText(page, '#native-controls-fallback-catalog-sentence');
    expect(
      text,
      'the rendered catalog sentence must equal approval_live.ex catalog_sentence/0 verbatim, never a spec-side literal',
    ).toContain(CATALOG_SENTENCE);
  });

  test('the focus trap is BEHAVIOR: Tab and Shift-Tab wrap, Escape closes, focus returns to the trigger', async ({
    page,
  }) => {
    await resetShowcase(page);
    await asApprover(page);
    await page.goto(A1_ROUTE);
    await expectLiveViewConnected(page, 'saas-approval');

    const trigger = page.locator('#native-controls-confirm-trigger');
    await trigger.click();

    const fallback = page.locator(FALLBACK);
    await expect(fallback).toHaveCount(1);

    const actionButton = page.locator('#native-controls-confirm-demo-action');
    const cancelButton = page.locator('#native-controls-confirm-demo-cancel');

    // Initial focus (phx-mounted JS.focus) lands on the action button for the
    // neutral tone — the LAST focusable element in DOM order (Cancel, then
    // Action).
    await expect(actionButton).toBeFocused();

    // JS.focus/JS.pop_focus re-confirm focus two animation frames after their
    // first attempt (LiveView's own belt-and-suspenders against a focus target
    // not existing yet). Waiting out those frames — a real, pollable browser
    // condition, never a fixed-duration wait — avoids a race where a Tab
    // pressed inside that window gets stomped by the delayed re-confirmation.
    await awaitAnimationFrames(page);

    await page.keyboard.press('Tab');
    await expect(
      cancelButton,
      'Tab from the last focusable element must wrap to the first',
    ).toBeFocused();

    await page.keyboard.press('Shift+Tab');
    await expect(
      actionButton,
      'Shift-Tab from the first focusable element must wrap to the last',
    ).toBeFocused();

    await page.keyboard.press('Escape');
    await expect(fallback, 'Escape must close the fallback surface').toHaveCount(0);

    await awaitAnimationFrames(page);
    await expect(trigger, 'focus must return to the trigger on close').toBeFocused();
  });

  test('computed contrast meets the AA text floor, and the focus ring meets 3:1, in both themes', async ({
    page,
  }) => {
    await resetShowcase(page);
    await asApprover(page);
    await page.goto(A1_ROUTE);
    await expectLiveViewConnected(page, 'saas-approval');

    await page.locator('#native-controls-confirm-trigger').click();
    await expect(page.locator(FALLBACK)).toHaveCount(1);
    await expect(page.locator('#native-controls-confirm-demo-action')).toBeFocused();
    // See the focus-trap test's comment: wait out JS.focus's own two-frame
    // re-confirmation before driving Tab, or the delayed re-focus can stomp it.
    await awaitAnimationFrames(page);

    for (const scheme of ['light', 'dark'] as const) {
      if (scheme === 'dark') {
        await page.evaluate(() => document.documentElement.setAttribute('data-theme', 'dark'));
      }

      // Real keyboard focus (not a programmatic .focus()) so :focus-visible
      // actually matches and the outline color renders — the confirm modal
      // opened with focus already on the action button, so one Tab wraps focus
      // to the cancel button.
      await page.keyboard.press('Tab');
      await expect(page.locator('#native-controls-confirm-demo-cancel')).toBeFocused();

      const measured = await page.evaluate(() => {
        const parseRGBA = (value: string): [number, number, number, number] | null => {
          const m = /rgba?\(([^)]+)\)/.exec(value);
          if (!m) return null;
          const p = m[1].split(',').map((x) => parseFloat(x.trim()));
          return [p[0], p[1], p[2], p.length > 3 ? p[3] : 1];
        };

        // Composite the full ancestor background stack bottom-up — reusing
        // evidence_panel.spec.ts's effective-background algorithm verbatim
        // (page.evaluate callbacks cannot import across spec files, so the
        // algorithm is copied byte-identical rather than rewritten).
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

        const contrastRatio = (fg: [number, number, number], bg: [number, number, number]) => {
          const l1 = luminance(fg);
          const l2 = luminance(bg);
          const [hi, lo] = l1 > l2 ? [l1, l2] : [l2, l1];
          return (hi + 0.05) / (lo + 0.05);
        };

        const textRatioFor = (el: Element) => {
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
          return contrastRatio(fg, bg);
        };

        const title = document.querySelector('.cw-fallback-title')!;
        const body = document.querySelector('.cw-fallback-body-copy')!;
        const cancel = document.querySelector('#native-controls-confirm-demo-cancel')!;

        // The focus-ring canary (D-33, D-46): this measurement would have
        // failed before 155-03 landed --cw-status-error-fg and corrected
        // --cw-action-focus-ring — it stands as proof the gate hole this
        // phase closed is genuinely closed.
        const ringBg = effectiveBackground(cancel);
        const ringColor = parseRGBA(getComputedStyle(cancel).outlineColor)!;
        const ringFg: [number, number, number] = [ringColor[0], ringColor[1], ringColor[2]];
        const focusRingRatio = contrastRatio(ringFg, ringBg);

        return {
          titleRatio: textRatioFor(title),
          bodyRatio: textRatioFor(body),
          focusRingRatio,
          dataTheme: document.documentElement.getAttribute('data-theme'),
          outlineStyle: getComputedStyle(cancel).outlineStyle,
        };
      });

      // Non-vacuity: confirm the dark-theme toggle actually took effect before
      // trusting a dark-scheme number.
      if (scheme === 'dark') {
        expect(measured.dataTheme, 'the dark theme toggle must actually reach the page').toBe(
          'dark',
        );
      }

      expect(
        measured.outlineStyle,
        `${scheme}: the focused control must render a real outline, not "none"`,
      ).not.toBe('none');

      expect(
        measured.titleRatio,
        `${scheme}: confirm-modal title contrast must meet WCAG AA 4.5:1 (measured ${measured.titleRatio.toFixed(2)}:1)`,
      ).toBeGreaterThanOrEqual(4.5);

      expect(
        measured.bodyRatio,
        `${scheme}: confirm-modal body contrast must meet WCAG AA 4.5:1 (measured ${measured.bodyRatio.toFixed(2)}:1)`,
      ).toBeGreaterThanOrEqual(4.5);

      expect(
        measured.focusRingRatio,
        `${scheme}: the focus ring must meet WCAG 1.4.11's 3:1 non-text floor (measured ${measured.focusRingRatio.toFixed(2)}:1) — the D-33 gate-hole canary`,
      ).toBeGreaterThanOrEqual(3);

      // Reset for the next iteration.
      await page.keyboard.press('Shift+Tab');
    }
  });

  test('no element on the page declares the APG menu role', async ({ page }) => {
    await resetShowcase(page);
    await asApprover(page);
    await page.goto(A1_ROUTE);
    await expectLiveViewConnected(page, 'saas-approval');

    await page.locator('#native-controls-menu-trigger').click();
    await expect(page.locator('[data-cw-fallback-surface="menu"]')).toHaveCount(1);

    // D-21: the action-menu fallback is buttons in a dialog, never the APG menu
    // contract this phase deliberately declines to implement.
    await expect(page.locator('[role="menu"]')).toHaveCount(0);
    await expect(page.locator('[role="menuitem"]')).toHaveCount(0);
    await expect(page.locator('[aria-haspopup="menu"]')).toHaveCount(0);
  });
});

test.describe('PROOF-01 A2 — a shell-side denial renders and the mutation does not proceed', () => {
  test('the doubly-nested injected denial renders inline, is the undeclared reason (not unavailable), and the mutation is absent', async ({
    page,
  }) => {
    // page.addInitScript runs at document start — the exact injection point both
    // real shells use for window.crosswakeBridge (route_tour.spec.ts's own
    // precedent). The DOUBLY-nested shape is copied verbatim from
    // crosswake-shell-core-android's BridgeChannel.kt deny(): a single-nested
    // injection would still pass even against a decoder regression, because the
    // Elixir decoder currently tolerates both (D-46).
    await page.addInitScript(() => {
      const shell: Record<string, unknown> = {
        postMessage(raw: string) {
          const request = JSON.parse(raw);
          // Deferred past the CURRENT synchronous call stack (never a
          // fixed-duration delay): the hook records the correlation id in its
          // in-flight map in the statement immediately following its own
          // transport.postMessage(...) call, so any deferral past that
          // synchronous return is sufficient — replying inline, before
          // postMessage itself returns, would be dropped by the hook's
          // in-flight gate, correctly (route_tour.spec.ts's own precedent).
          queueMicrotask(() => {
            (shell.__reply as (reply: unknown) => void)({
              protocol: request.protocol,
              version: request.version,
              command: request.command,
              route_id: request.route_id,
              correlation_id: request.correlation_id,
              status: 'deny',
              payload: {},
              denial: {
                command: request.command,
                route_id: request.route_id,
                correlation_id: request.correlation_id,
                denial: {
                  reason: 'undeclared_capability',
                  code: 'undeclared_capability',
                  message: 'The native shell does not recognize this capability as declared.',
                  route_id: request.route_id,
                  hint: null,
                },
              },
            });
          });
        },
      };

      (window as unknown as Record<string, unknown>).crosswakeBridge = shell;
    });

    await page.goto(A2_ROUTE);
    await expectLiveViewConnected(page, 'e2e-a2-shell-denial');

    const successNode = page.locator('#undeclared-control-success');
    const effectNode = page.locator('#undeclared-control-effect');
    await expect(successNode).toHaveCount(0);
    await expect(effectNode).toHaveAttribute('data-cw-effect-count', '0');

    await page.locator('#undeclared-control-trigger').click();

    const alert = page.locator('[data-cw-fallback-alert]');
    await expect(alert).toHaveCount(1, { timeout: 20000 });
    await expect(alert).toHaveAttribute('role', 'alert');

    await expect(
      alert,
      'the rendered reason must be the undeclared one',
    ).toHaveAttribute('data-cw-fallback-alert', 'undeclared');
    await expect(alert).toContainText("isn't available here");

    // The two-remediation-collapse regression guard (D-13, D-46): the undeclared
    // and unavailable/stale-binary remediations must never collapse into one.
    await expect(
      alert,
      'must NOT render as the unavailable/stale-binary kind',
    ).not.toHaveAttribute('data-cw-fallback-alert', 'stale_binary');
    await expect(
      alert,
      'must NOT render the unavailable/stale-binary remediation copy',
    ).not.toContainText('needs a newer version');
    await expect(
      alert,
      'D-13: the raw unavailable_capability reason string must never leak into the rendered undeclared remediation',
    ).not.toContainText('unavailable_capability');

    // The negative control that matters (D-46): a rendered denial is not
    // evidence the mutation did not happen — assert BOTH independently.
    await expect(successNode, 'the success surface must stay absent on denial').toHaveCount(0);
    await expect(
      effectNode,
      'the server-side effect must show no change on denial',
    ).toHaveAttribute('data-cw-effect-count', '0');
  });
});

test.describe('PROOF-01 A3 — no failure path resolves to silence', () => {
  test('rendered outcome text changes from the idle copy with no dead air (MutationObserver)', async ({
    page,
  }) => {
    await page.goto(A3_ROUTE);
    await expectLiveViewConnected(page, 'bridge-proof');

    const reply = page.locator('#crosswake-bridge-reply');
    await expect(reply).toContainText(
      'No share request sent. Phoenix sends one when you press Share.',
    );

    await page.evaluate(() => {
      const w = window as unknown as { __cwMutationCount: number };
      w.__cwMutationCount = 0;
      const target = document.querySelector('#crosswake-bridge-reply')!;
      new MutationObserver((records) => {
        w.__cwMutationCount += records.length;
      }).observe(target, { subtree: true, childList: true, characterData: true });
    });

    await page.getByRole('button', { name: 'Share' }).click();

    // No shell is present in this browser context — desktop Chromium with no
    // window.crosswakeBridge injected, the same "no honest way to fake a shell"
    // reality /bridge-proof itself demonstrates. The reply-deadline backstop
    // (armed at timeout + 2s) delivers :shell_unreachable.
    await expect(
      reply,
      'text must CHANGE from the idle copy, not merely be non-empty',
    ).toContainText('Shell declined: shell_unreachable', { timeout: 20000 });
    await expect(reply).not.toContainText('No share request sent.');

    const mutationCount = await page.evaluate(
      () => (window as unknown as { __cwMutationCount: number }).__cwMutationCount,
    );
    expect(
      mutationCount,
      'no dead air: the mutation observer must have recorded at least one mutation',
    ).toBeGreaterThanOrEqual(1);
  });

  test('the exercised + explicitly-excluded denial reasons equal the full closed vocabulary', () => {
    const exercisedAndExcluded = [...EXERCISED_REASONS, ...Object.keys(EXCLUDED_REASONS)];
    const accounted = new Set(exercisedAndExcluded);

    expect(
      accounted.size,
      'no reason may be both exercised and excluded',
    ).toBe(exercisedAndExcluded.length);

    expect(
      [...accounted].sort(),
      'every reason in Crosswake.Shell.Denial.reasons/0 must be exercised or explicitly excluded — a 15th reason left uncategorized must turn this red',
    ).toEqual([...CLOSED_VOCABULARY].sort());
  });
});

// ---------------------------------------------------------------------------
// Helpers — self-sufficient setup, mirroring evidence_panel.spec.ts's and
// route_tour.spec.ts's house style rather than assuming a hand-seeded server.
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

async function expectLiveViewConnected(page: Page, routeId: string) {
  await expect(
    page.locator('[data-phx-main]').first(),
    `${routeId}: LiveView must connect before a server round-trip is possible`,
  ).toHaveClass(/phx-connected/);
}

// LiveView's JS.focus/JS.pop_focus commands re-confirm their target two
// animation frames after the first attempt. Waiting out real frames (never a
// fixed-duration delay) is the only race-free way to drive keyboard focus
// immediately afterward without the delayed re-confirmation stomping it.
async function awaitAnimationFrames(page: Page, count = 2) {
  await page.evaluate(
    (frames) =>
      new Promise<void>((resolve) => {
        let remaining = frames;
        const tick = () => {
          remaining -= 1;
          if (remaining <= 0) {
            resolve();
          } else {
            requestAnimationFrame(tick);
          }
        };
        requestAnimationFrame(tick);
      }),
    count,
  );
}

function readCatalogSentence(): string {
  const source = readFileSync(path.join(process.cwd(), APPROVAL_LIVE_RELATIVE_PATH), 'utf8');
  const match = /defp catalog_sentence, do: "([^"]+)"/.exec(source);
  if (!match) {
    throw new Error(
      'catalog_sentence/0 not found in approval_live.ex — has the source moved? Update the regex, not a hardcoded literal.',
    );
  }
  return match[1];
}

function readClosedVocabulary(): string[] {
  const source = readFileSync(path.join(CORE_LIB_ROOT, 'shell', 'denial.ex'), 'utf8');
  const match = /@reasons \[([\s\S]*?)\]/.exec(source);
  if (!match) {
    throw new Error(
      'Crosswake.Shell.Denial @reasons not found — has the source moved? Update the regex, not a hardcoded list.',
    );
  }
  // Strip Elixir line comments before matching — the block carries explanatory
  // comments (e.g. "never :unavailable_capability (D-12, D-13)") whose prose
  // itself contains atom-shaped substrings that must not be double-counted.
  const withoutComments = match[1]
    .split('\n')
    .map((line) => line.replace(/#.*$/, ''))
    .join('\n');

  return Array.from(withoutComments.matchAll(/:([a-z_]+)/g)).map((m) => m[1]);
}
