# Phase 193 PR dispositions

Plain-language summary: this file records what should happen to each pull request that was open on
2026-10-24. It only records; nothing was merged, closed, commented on or updated. Phase 193 merges
no PR except its own two. Each row names the head commit that was seen on 2026-10-24. Dependabot
rebases move heads, so the final check compares PR numbers and reports any head change as
information only. For the PRs whose Crosswake CI failed, the failure causes were not read.

Source: a live read of the open PR list and the latest `Crosswake CI` check run on each head
(`193-EVIDENCE/open-prs-09-193.txt`).

| PR | Title | Head seen | Disposition | Reason |
|---|---|---|---|---|
| 210 | chore(deps): bump actions/checkout from 7.0.0 to 7.0.1 | b2668e5e82cf (2026-10-24) | hold | Crosswake CI fails on its head; cause not read |
| 211 | chore(deps): bump erlef/setup-beam from 1.24.0 to 1.24.1 | 79c426f61166 (2026-10-24) | hold | Crosswake CI fails on its head; cause not read |
| 236 | chore: release main | 4c35a88e1397 (2026-10-24) | hold | no release in v27; Crosswake CI fails on its head; cause not read |
| 238 | Maintain release guides and assertion references | 3e8a4b2601b5 (2026-10-24) | redo after landing | its files still differ from main and touch the assertion ledgers that Phases 191 and 192 changed; Crosswake CI passes on its head, but that is not enough evidence |
| 239 | chore(deps): bump actions/setup-node from 7.0.0 to 7.1.0 | c064db797719 (2026-10-24) | green: merge only as a separate decision | Crosswake CI passes on its head; needs a SHA-pin provenance check first (main pins actions by SHA) |
| 240 | chore(deps): bump actions/upload-artifact from 7.0.1 to 7.0.2 | e26fe524aa04 (2026-10-24) | green: merge only as a separate decision | Crosswake CI passes on its head; needs a SHA-pin provenance check first (main pins actions by SHA) |
| 241 | chore(deps): bump actions/download-artifact from 8.0.1 to 8.0.2 | 0e794279ff50 (2026-10-24) | green: merge only as a separate decision | Crosswake CI passes on its head; needs a SHA-pin provenance check first (main pins actions by SHA) |
