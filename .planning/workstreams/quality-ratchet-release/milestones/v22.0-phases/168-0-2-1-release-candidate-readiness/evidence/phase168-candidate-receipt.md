# Crosswake 0.2.1 Release Candidate Receipt

Crosswake 0.2.1 release candidate — READY FOR APPROVAL. Reversible checks PASS 12/12. Mirror write authority PASS; dry-run only; no refs or packages changed. Next: review the dossier, then approve release PR head `1051ab90cf75e918c6f596f84578ac77eadf45af`.

## Exact candidate identity

| Field | Value |
| --- | --- |
| State | `READY FOR APPROVAL` |
| Version | `0.2.1` |
| Release PR | `#57` |
| Head / ref | `1051ab90cf75e918c6f596f84578ac77eadf45af` |
| Tree | `ecf63228243bfe7c2d6a377be996aa374b31d91f` |
| Protected-default base | `9533049d1ee5239b122b43749ff90f8ace7c7f6b` |
| Candidate CI run | `34776247650` — `COMPLETED/SUCCESS` at the exact head |
| Candidate refresh SHA-256 | `e80f9e8583d571b92c304570929a07602bae355069cae9466016932228c63f92` |
| Trusted Hex rehearsal run | `34777036279` — `SUCCESS` |
| Trusted iOS rehearsal run | `34777037998` — `SUCCESS` |
| Next action | `approve_exact_candidate` |

The receipt binds identical `bound` and `observed` identities. Any drift makes this receipt stale and suppresses approval.

## Linked immutable scope

Approval covers one linked Crosswake `0.2.1` release unit:

- Hex: `crosswake@0.2.1`
- SwiftPM: `crosswake-shell-core-ios@0.2.1`
- Maven: `io.github.sztheory:crosswake-shell-core-android:0.2.1`

The receipt's schema-safe Android coordinate is `crosswake-shell-core-android@0.2.1`; it denotes the full Maven coordinate above.

Companion PRs `#115`, `#146`, and `#147` remain open, unchanged, excluded, and unauthorized by this decision.

## Reversible proof

All 12 closed checks are `PASS`: candidate CI, exact identity, five twice-installed clean rooms, coordinate floor, external state, mirror authority, package family, and the full pinned repository suite.

| Proof | SHA-256 |
| --- | --- |
| Candidate CI receipt | `443c3c905b4b1ea739272dadd490727ab8fc60bfb6bec51f45fb491d29ada109` |
| Candidate refresh | `e80f9e8583d571b92c304570929a07602bae355069cae9466016932228c63f92` |
| Clean room: rulestead | `16efdca0c41ba99e84cacceef4179f71373cb1c9fb69389ab0ce81bff88cbc78` |
| Clean room: rindle | `88d4d5d133407d3495cfe118aed88aa40d87ca0453e6989c4f03c2285d002d46` |
| Clean room: sigra | `aa44b43999d11c1e3a30d8340a2093410edb7aa708a58d1369187d7f8b057a87` |
| Clean room: chimeway | `894829f8d2bd412d630ef2b55f76d6659c93758381acd487a87ef2170020a0f6` |
| Clean room: threadline | `c3fd94a9b65b1500e70b0dbd1e96a8fdd3d7fc92467f0ba1a040585187c72775` |
| Cursor-complete companion inventory | `ed47831bb8c2d3348b920b14bb423fa3a634196d174bd55c21665c170898bffc` |
| Trusted Hex rehearsal | `5cc7cfa5874170c06a591b2f04b819532c24ebe5297a7dce4e1a56ec0052a6c2` |
| Trusted iOS rehearsal | `a8b61d66b5c352843a0a73c542be4d9f08ba86747363532ffa500d3d01b3f626` |
| Mirror authority and dry-run plan | `fcb6cd0fb1c4d3605eed27694fe465c88481cd7991d27a363d213c21b5cfd5f5` |
| Six-package family | `694f6d44c9563b8f6875d1df66b8dee52576c6f6a6dd411451722b5515062251` |
| Pinned full repository verification | `78e5b3219a91c980a78553ff423f73625712f2fc06e22a15e978e8102719a569` |

## Configuration and workflow identity

| Artifact | SHA-256 |
| --- | --- |
| Release Please config | `495ad615d3c9f2a33e24da8da26829540e27f1115a69073ca1b376a5bf295d2d` |
| Release Please manifest | `d94068745bf813eed7465163b3d5c0064c0a123eebb409ce1caecb1ce6c9195b` |
| Crosswake CI workflow | `224e8749db6dbcb92892e7fee35096342828c24a10f5b6ab9698fbdbd14df80d` |
| Release Please workflow | `afe0d693b9db7f1974eeb8372594b25bb4b45148c675f5e073facdb2c521c21c` |
| Hex publish workflow | `77dc224a1149f09aee9ebb12b7aa29d50845c6a481b06d0594fe67fdafddab3f` |
| iOS mirror workflow | `975abc17ae43fe5421c5becb1dee75ef3faabbc16c2ebc329f590c23f9b5a0eb` |

## Package family identity

| Package | Outer SHA-256 | Payload SHA-256 | Metadata SHA-256 |
| --- | --- | --- | --- |
| `crosswake` | `ffa220c26980696849497479fa23d47eae44796cfc06f2775999ffca0ed7fc90` | `f2977e1268ca03cadd7b4435d10966169b7d3bd916d1b0fee11c282ff71f7045` | `04960151c60f480da42f06e874a178df40e37cd55992ec133463898c4be73fbe` |
| `crosswake_rulestead` | `6f7f135c748de0e0c10d287905f14c90168e232cbe07b3b8686e50646d5b3088` | `07673bb94f307c2860a846efce4f611aae4f47d7ae6585ff77af0026899cb956` | `c9147b3c184604e11141f36d097257c42a31b40de18c1531c4c1177fb2dcde83` |
| `crosswake_rindle` | `5a26bc64808aec1d9189d62b76c805024bf55118aaa01116f6349037893e301f` | `6f5cd4cb01cb527cdafa50086a4941f3a8602408832dd2aba159cba72883ef14` | `7c0765a3a5408863a726e73a869a597accf7d83ab3bcb8f90ae508afa842b472` |
| `crosswake_sigra` | `6505eefc05dab6cae73d941856589498807474c5774ef67dbea73f6d1cf83807` | `40fd71d0b7a578591b27172ae9157e3428d8ab7450af2aefc67042c1f359fd10` | `76d69c05106ca6550cfbbc0785603be7a64bcb223951a8a5b02eba288c78457a` |
| `crosswake_chimeway` | `2d66ff7713e1c95311db93e154b35059bf0d0282b4cad97c154532b0a968cc16` | `30177d880285e18e9aa86b53e8d0744a68fab80cbb14dd6ed1f0eb5044935980` | `9f7e44ec50c196a18a9ccaff9ceba03ec9e9bc02e393589ef93313351144d58b` |
| `crosswake_threadline` | `251ee57290aecc9a7403a14832f86869bb486eac4b2db10bcb5d958a58c223b8` | `fccc3e280bb9160a16b75b6bfdef2f79ece1eaa6c6452e4bf39dc5b8c3ad0b2b` | `794181a869476b2baaeccd747dbddc97e327a5c2cfd5f2a5cef8ce748dfeaff2` |

## Mirror rehearsal

| Field | Value |
| --- | --- |
| Authorization | `PROVEN`; exercised in trusted dry-run only |
| Planned tag | `v0.2.1` |
| Split commit | `424ab96ede1b92f2b751b54bce04c6e607f0f3c8` |
| Current mirror main | `658d60253c58b7e0aedb576f16f40766fa677f23` |
| Plan SHA-256 | `fcb6cd0fb1c4d3605eed27694fe465c88481cd7991d27a363d213c21b5cfd5f5` |

No mirror ref was pushed. No `0.2.1` package or semantic tag exists. External publication state is `NONE`, `external_state.changed` is `false`, and the successful-coordinate set is empty.

## Approval consequence

The fixed postapproval graph is: exact approved merge/tree guard → Release Please semantic tags → independent Hex, SwiftPM mirror, and Maven publication children → exact public proofs → fail-closed linked rollup.

D-19 is one-way. Independent children can succeed partially; that result is retained as `PARTIAL`. Any already-public coordinate remains immutable. A failed child may be recovered only from its exact authorized refs, or by a forward fix and new version. Tags are never moved and packages are never replaced.

## Decision

Approve only the exact displayed head and the SHA-256 of the canonical JSON receipt, or stop without changing external state. Approval is not implied by review, delay, or non-response.

## Checkpoint outcome

At `2026-09-13T19:49:41Z`, the maintainer approved exactly:

`approve exact head 1051ab90cf75e918c6f596f84578ac77eadf45af receipt 359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78`

The approval matches the canonical JSON receipt byte-for-byte. Plan 168-08 records the decision only: it did not merge PR `#57`, publish a package, create or push a tag, update a mirror ref, or dispatch the postapproval graph. A separate executor must independently revalidate the approved identity immediately before performing any authorized exact-head merge.
