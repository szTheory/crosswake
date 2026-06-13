---
phase: 102
slug: brand-audit-token-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-11
---

# Phase 102 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js scripts (dependency-free, ESM) + structural greps — no test framework needed for doc/token artifacts; `mix test` untouched |
| **Config file** | none — Wave 0 installs nothing (zero npm deps this phase) |
| **Quick run command** | `node brandbook/tools/contrast.mjs --check && node brandbook/tools/compile-tokens.js --verify` |
| **Full suite command** | `node brandbook/tools/contrast.mjs --check && node brandbook/tools/compile-tokens.js --verify && node -e "JSON.parse(require('fs').readFileSync('brandbook/tokens/crosswake.tokens.json','utf8'))"` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (once the scripts exist)
- **After every plan wave:** Run the full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

> Filled by planner with final task IDs. Verification commands per requirement (from 102-RESEARCH.md Validation Architecture):

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | AUDT-01 | — | N/A | structural | `grep -c '^## ' brandbook/AUDIT.md` (= 14 sections) + `grep -E 'KEEP|TIGHTEN|REWORK|ADD|REMOVE' brandbook/AUDIT.md` + every REWORK row carries a "Cost:" | ❌ W0 n/a | ⬜ pending |
| TBD | TBD | TBD | AUDT-02 | — | N/A | script | `node brandbook/tools/contrast.mjs --check` exits 0; matrix in AUDIT.md appendix covers all approved pairings incl. Stone 600 rows | ❌ | ⬜ pending |
| TBD | TBD | TBD | AUDT-03 | — | N/A | structural | AUDIT.md cites `lib/mix/tasks/crosswake.gen.offline_ui.ex` blue/amber values (`#699cc9`, `#e1b982`) vs app.css teal with explicit verdict | ❌ | ⬜ pending |
| TBD | TBD | TBD | AUDT-04 | — | N/A | manual | User ratification checkpoint — see Manual-Only Verifications | ❌ | ⬜ pending |
| TBD | TBD | TBD | TOKN-01 | — | N/A | script | JSON parses; DTCG structure check: primitive + semantic groups, `$value`/`$type` on every leaf, `runtime.{liveview,offline,native,sensitive,bridge}` present | ❌ | ⬜ pending |
| TBD | TBD | TBD | TOKN-02 | — | N/A | script | `node brandbook/tools/compile-tokens.js --verify` exits 0 (regenerated output matches committed tokens.css byte-for-byte); GENERATED header present | ❌ | ⬜ pending |
| TBD | TBD | TBD | TOKN-03 | — | N/A | structural | All 12 states accounted for: grep tokens.css for hover/focus-ring tokens + status.{success,warning,error,info} + text.{muted,subtle}; AUDIT.md §7 documents the state→mechanism mapping table | ❌ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no test framework install. The two dependency-free scripts (`contrast.mjs`, `compile-tokens.js`) are themselves phase deliverables and double as the validation harness once written (earliest wave).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| User ratifies audit-driven font/color changes | AUDT-04 | Human judgment gate — taste + downstream cascade decision | Present ratification summary listing EVERY change: Stone 600 #756D63 addition, text.muted remap, Stone 500 narrowing to text.subtle, dark-mode text.muted → mist-200, Wake 500/Mist 200 $description guards, Phase 103 mandatory wake-cuts rider. User approves via checkpoint before phase close. |
| Audit prose quality (decisive, no filler, costs stated) | AUDT-01 | Editorial judgment | Spot-read Executive Judgment + scorecard sections against 102-AUDIT-BRIEF.md behavior constraints |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
