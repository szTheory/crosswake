Plan141 fresh tag decision — one attempt only

Attempt: e5d451a21f81d8c12ee8fa0eab0904d1
Plan140 observation: 2026-10-10T21:33:23.646055Z UTC; this is a dated observation.
Plan140 result: fa0292420accd879a1b108db560f17eced8416528195432adf650421826262e2

PR #219: OPEN, draft=false, merged=false
Exact-head version: 0.2.7; base/head/tree: e51698528dc667ef89beb951e4eb1ec91da74981 / 696a27a3be1fcd56efe70923dc0ce286a1c41c6d / 5279cae1daa1fbff3437b673df8ca231fb07c91f
Manifest provenance: github_contents_exact_head at head 696a27a3be1fcd56efe70923dc0ce286a1c41c6d, tree 5279cae1daa1fbff3437b673df8ca231fb07c91f, blob 31da6202a8408ddda013edea104c9d5b1f787438.
Source tag/tree/split: refs/tags/ios-core-v0.2.6 at 998742856a37a97ae7247f6c532f9c154ea20885 / b80f3bf00ef61708120b062bc88738fed88294a9 / 424ab96ede1b92f2b751b54bce04c6e607f0f3c8
Mirror main/prior/target: 424ab96ede1b92f2b751b54bce04c6e607f0f3c8 / 424ab96ede1b92f2b751b54bce04c6e607f0f3c8 / ABSENT
Endpoint/ref/object: https://github.com/szTheory/crosswake-shell-core-ios.git / refs/tags/v0.2.6 / 424ab96ede1b92f2b751b54bce04c6e607f0f3c8
Policy: complete=true, create-only=CREATE_ONLY_ALLOWED, reported role=ADMIN, push=TRUE, policy SHA=e0fd1be13e72c9f68bf5f5fac606fb62668e5101b827197b66126a2fcc877411
Plan140 no-write preview row: accepted=true, count=1, object=424ab96ede1b92f2b751b54bce04c6e607f0f3c8, ref=refs/tags/v0.2.6, force=false, delete=false

Proposed only after a fresh choice: one complete current-fact recheck, one exact-ref non-force/non-delete dry-run, and at most one tag push. No retry if delivery is uncertain.

Reversal cost: the runbook says re-pointing changes what a new `swift package resolve` gets; consumers already resolved retain the old commit in SwiftPM's resolved-package cache. Recovery for this later release also needs a reviewed workflow identity update before the currently hardcoded recovery action can be used; correction must be communicated quickly.

Holds remain: effective write permission and merge policy UNKNOWN; release hold ACTIVE; candidate readiness BLOCKED; REL-13/14/15/17 OPEN; Plans46–48/89 and Plan106 HELD; Phase175 INCOMPLETE. No CI, merge, registry, recovery, or publication.

Internal audit digests: scope=c295c1f8a703cce7b7ce7c3b5459bcf7a1db7ca2049484c855d222fd8d6228ea; Plan140 authorization=649a8713f5d54a7c62a46090bd7806174415538e701ab4f8d4e68333535decaf; collector=8c562e34326e03d252d73b454e193153ea9ac01adb879503cb130c27ea70eeca; Plan140 receipt=fa0292420accd879a1b108db560f17eced8416528195432adf650421826262e2. The inspector prints the exact raw card SHA-256 beside this card.

Reply only: allow or hold. This choice applies only to this displayed attempt.
