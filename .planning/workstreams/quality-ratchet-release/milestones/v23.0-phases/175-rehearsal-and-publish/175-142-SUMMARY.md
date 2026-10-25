---
phase: 175-rehearsal-and-publish
plan: 142
subsystem: release-candidate
tags: [tag-apply, authorization, durable-intent, readback]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan140's independently audited exact-head receipt
provides:
  - Separate Plan142 Mix/Elixir/Node tag-decision and bounded-apply path
  - Synced one-use authorization, write-intent journal, terminal result, and independent inspector
  - Local injected-adapter proof for HOLD, success, tamper, drift, rejection, and uncertain delivery
affects: [175-next-tag-plan, REL-13, REL-17]
requirements-completed: []
coverage:
  - id: D1
    description: A fresh choice is bound to one Plan142 attempt, card, collector, and Plan140 receipt; HOLD stops before the Node adapter.
    requirement: REL-17
    verification:
      - kind: integration
        ref: test/crosswake/release_candidate/plan142_tag_apply_test.exs#local HOLD and Mix-to-Elixir-to-Node ALLOW
        status: pass
    human_judgment: false
  - id: D2
    description: One exact preview and durable intent precede the immediate full recheck and at most one create-only push; uncertain delivery stays UNKNOWN after readback.
    requirement: REL-13
    verification:
      - kind: unit
        ref: script/release_candidate/plan142_tag_apply.test.mjs
        status: pass
      - kind: integration
        ref: test/crosswake/release_candidate/plan142_tag_apply_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Independent terminal inspection rejects tampered outcomes and only recognizes the exact target, main, and prior-ref tuple; Plan140 and Plan141 evidence remain intact.
    verification:
      - kind: integration
        ref: test/crosswake/release_candidate/plan142_tag_apply_test.exs#terminal inspection and preserved Plan141 evidence
        status: pass
      - kind: integration
        ref: HEX_OFFLINE=1 MIX_ENV=test mix run -e Plan141 independent inspections
        status: pass
    human_judgment: false
---

# Phase 175 Plan 142: Local Tag-Apply Path

Plan142 adds a separate Mix/Elixir/Node path that can bind a new plain `allow` or `hold` to one fresh card, persist the choice, record a synced write intent, perform the exact bounded apply path, and independently inspect its terminal evidence.

The local Mix-to-Elixir-to-Node fixture completed both HOLD and ALLOW. The ALLOW path checked the full saved Plan140 tuple twice, accepted one exact preview, read back the durable intent before proceeding, made one injected push call, and required exact target, main, and prior-ref readback. Fact drift, malformed preview, journal tampering, mismatched refs, rejection, and uncertain delivery stop without retry. When delivery was ambiguous, the fixture's later readback saw the expected refs but the result remained `UNKNOWN`.

## Verification

- Plan142 ExUnit: 7 tests, 0 failures.
- Plan142 Node suite: 4 tests, 0 failures; Node syntax check passed.
- Plan141 regression suite: 3 tests, 0 failures. Plan141 remains `PENDING`, its card SHA remains `54065cb029048f58315949d5b7b38d1b0d716b99bfd2f19eb186a98424ef50c1`, and its collector SHA remains `8c562e34326e03d252d73b454e193153ea9ac01adb879503cb130c27ea70eeca`.
- Plan140 receipt independently audited with digest `fa0292420accd879a1b108db560f17eced8416528195432adf650421826262e2`.
- Scoped formatter and `git diff --check` passed.

These checks used temporary evidence roots and injected adapters. They did not read a credential, contact GitHub or remote Git, create a repository card or attempt, push a tag, run CI, or perform a release operation.

## Release status and next action

Plan142 completes its local repair only. REL-13/14/15/17 remain open; readiness is blocked; effective write permission and merge policy remain unknown; tag authority is none; the release hold stays active. Plan141's unbound reply is not authorization for a new attempt. Plan106 remains held because its precondition is pinned to Plan119.

**Next GSD command:** `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`. Use it to create a separate reviewed operation plan for a new Plan142 card and its own fresh plain choice. Do not execute Plan106 unchanged or reuse the Plan141 reply.

No files were staged or committed; the active phase override forbids Git metadata changes and worktrees.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-10*
