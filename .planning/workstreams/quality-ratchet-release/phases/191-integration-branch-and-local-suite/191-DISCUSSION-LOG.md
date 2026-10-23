# Phase 191: Integration branch and local suite - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-19
**Phase:** 191-integration-branch-and-local-suite
**Areas discussed:** What the planning carry includes, Privacy hit inside history, Known failures: fix or list, Phase 190 review leftovers

**User's choice:** all four areas, plus a request to fan out each decision across every relevant stakeholder lens with an adversarial pass, prefer primary sources and small, flat dependencies, and then "synthesize a coherent set of recommendations ... auto follow those". Four research agents (advisor mode, full_maturity calibration) ran read-only in parallel. The recommendations below were adopted without further questions, per that instruction.

---

## What the planning carry includes

| Option | Description | Selected |
|--------|-------------|----------|
| A1 | Only the uncommitted R-PL "to land" rows | |
| A2 | Full `.planning/` delta vs main, including the v23 archive and committed v24 records, minus listed exclusions | ✓ |
| A3 | A2 plus AGENTS.md, `.tool-versions`, workflows and the Phase 175 code | |
| A4 | Cherry-pick the 149 planning-only recovery commits | |

Split: one commit (C1), **per milestone (C2) ✓**, per top-level group (C3). Who wins: **recovery for planning, main for code, with a three-way check (B1) ✓**. Evidence: **land in full (D1) ✓**, but with the D-21 privacy transform. Wording: **verbatim plus a commit-message note (E1+E3) ✓**. Proof: **content manifest with negative controls (F1) ✓**.
**Notes:** The research found that the inventory's to-land list misses committed recovery-branch planning, and that the archive move breaks 7 main files. That is why there is a resolver commit (D-06).

## Privacy hit inside history

| Option | Description | Selected |
|--------|-------------|----------|
| Final-tree diff only | Fast, but misses intermediate commits | |
| Added lines + new binary blobs + path names + metadata | Every new byte, without re-flagging main | ✓ |
| Reuse scan-privacy-190 | Floods with false hits on Elixir code | |
| Vendored scanner + gitleaks 8.30.1 | Small, flat, already installed | ✓ |
| trufflehog | Network verification, overlaps gitleaks | |
| Severity ladder; rewrite only with user approval | Secrets/adopter → stop and ask; usernames in history → accept | ✓ |
| Squash the candidate | Breaks LAND-01 | |

**Notes:** Main already publishes the username in about 360 files and uses noreply emails throughout. So the scan measures new exposure only, and noreply is enforced.

## Known failures: fix or list

| Option | Description | Selected |
|--------|-------------|----------|
| Root `mix test` only | Doesn't predict CI | |
| `verify_repository.sh --all` + full example-host suite | Covers every named failure | ✓ |
| "No new failure" vs baseline | Main CI would stay red | |
| Zero failures, closed list of exclusions and skips | Predicts CI, fails closed | ✓ |
| Ledger ×5: async/seed fix | Wrong cause | |
| Ledger ×5: `IO.binwrite` + UTF-8 locale | Real cause (`LC_ALL=C` escaping) | ✓ |
| G1/G4/G3/G2/G6: list | CI red | |
| G1/G4/G3/G2/G6: invert in place | Turns probes into regression checks | ✓ |
| Format-only commit | CI format-proof requires it | ✓ |

## Phase 190 review leftovers

| Option | Description | Selected |
|--------|-------------|----------|
| A. Fix all 15 | Scope creep into twin-only and design work | |
| B. Tiered: CI blocker + small shipped defects now, reused tools in 191 successors, the rest in one seed | Lands quickly and safely | ✓ |
| C. Format only | Lands half-done WR-05 and gates that can pass on nothing | |
| D. Follow-up PR after merge | Two approval cycles | |

**Notes:** The WR-02 main claim was refuted (`mark_exited` already catches). WR-04 is the 190 D-07 design.

## Reconciliations between research tracks

- "Pass" semantics: the review track assumed "no new failure"; the suite track showed CI requires zero failures. **Zero failures adopted.**
- "Carry verbatim" vs "no new home paths": **redact in the introducing carry commit, recording both hashes** (D-21).

## Claude's Discretion

- Clone location and branch name, script names and layout, the milestone table rules, commit grouping for WR-01/06, and message wording.

## Deferred Ideas

- SEED-024 (review residue), the hygiene seed for main's existing home paths, the example-host CI lane (Phase 193 fact), recovery AGENTS.md rules as CLEAN-04 input, the GitHub email-privacy setting, and the user's 189 decisions before Phase 193.
