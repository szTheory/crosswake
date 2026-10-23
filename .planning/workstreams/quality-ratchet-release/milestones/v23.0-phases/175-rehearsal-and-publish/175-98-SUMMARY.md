---
phase: 175-rehearsal-and-publish
plan: 98
status: complete
completed: 2026-10-07
---

# Plan98 Execution Summary

Plan98 made one approved, bounded public read and preserved the observed source, mirror, and PR facts. Its terminal record remains `BLOCKED / SUBTREE_SPLIT_UNAVAILABLE`: the collector's split command exited before it could record the source commit and split OIDs.

## What the read found

- Source tag `ios-core-v0.2.6` resolved to commit `998742856a37a97ae7247f6c532f9c154ea20885`.
- The iOS mirror's `main` and `v0.2.5` both point to `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`; target tag `v0.2.6` is absent.
- PR #219 is open, not draft, and not merged. Its recorded base, head, and tree match the historical comparison pin.
- Plan98 used exactly six API requests and seven Git spawns. The stored preflight and journals are unchanged.

## Local cause and result

This was a Crosswake collector bug. It cloned the source with `--no-checkout`, then ran `git subtree split`. The installed `git subtree` command requires the prefix directory to exist in the working tree, so it stopped even though the exact source commit contains that directory.

In a disposable local clone, checking out Plan98's exact source commit before running the split succeeded. It produced split commit `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`, the same commit as mirror `main` and tag `v0.2.5`; the split tree equals the source iOS prefix tree at `b80f3bf00ef61708120b062bc88738fed88294a9`. This used no network and did not alter the project checkout. The separate supplemental record is `evidence/175-plan98-split-reproduction.json`.

## Handoff

Plan98's sealed preflight stays terminal `BLOCKED`; the local result supplements it without rewriting it. Plan99 fixes the collector to check out the exact source commit before splitting and adds local regression coverage. No second public read is part of Plan99. Write permission remains `UNKNOWN`, tag authority `NONE`, release readiness `BLOCKED`, and the release hold remains active.
