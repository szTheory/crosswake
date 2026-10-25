---
phase: 191
review: 191-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    fixed_in: "LAND-FIX 4a6c1af2f2304e7c3a72ca845a2409a7a9e0d682"
    title: "Locale-independence test does not detect the bug it was added for"
  - id: WR-02
    severity: warning
    disposition: fixed
    fixed_in: "LAND-FIX 4a6c1af2f2304e7c3a72ca845a2409a7a9e0d682"
    title: "Vacuity-convention test silently drops missing roster phases"
  - id: WR-03
    severity: warning
    disposition: fixed
    fixed_in: "SYNC-2 2525bdce728b792a8fa52bc5d3b944ddd3652a4a (scanner carried; control S33)"
    title: "Privacy scanner skips unreadable git notes without failing"
  - id: IN-01
    severity: info
    disposition: deferred
    deferred_to: "follow-up after landing"
    title: "usable_activation_origin?/1 accepts any well-formed http(s) origin"
  - id: IN-02
    severity: info
    disposition: deferred
    deferred_to: "follow-up after landing"
    title: "Inline copy of the evidence-path resolver can drift"
---

# Phase 191 review disposition

The code review (191-REVIEW.md) found 0 critical, 3 warning and 2 info items. None is in production code. Phase 192 triaged them (D-03):

- WR-01 is fixed in the LAND-FIX commit. The locale test now compares the snapshot bytes with the committed ledger under both the C locale and a UTF-8 locale. The C locale alone could not see the bug, because the output device is already latin1 there; the UTF-8 locale is where a missing latin1 switch changes the bytes. The script also asserts `:ok` on the latin1 switch.
- WR-02 is fixed in the same LAND-FIX commit. Every roster phase is resolved, a missing roster folder is now reported instead of dropped, and a negative control proves a missing entry shows up.
- WR-03 is fixed in the phase privacy scanner, not in clone code, so the fix reached the branch through the SYNC-2 sync commit.
- IN-01 and IN-02 are deferred by D-03 to a follow-up after landing.

This updated file is written after the sync and lands in Phase 193's normal flow (R-2). The copy inside the PR still says `open`.
