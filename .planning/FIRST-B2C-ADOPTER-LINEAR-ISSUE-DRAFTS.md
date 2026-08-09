# First B2C Adopter — Linear Issue Drafts

These are filing drafts for the adopter board, not Crosswake commitments beyond v21. They use only
the codename and contain no identifying business or personal information. All serve public v1;
there is no Crosswake issue for a web-only customer Alpha.

## Inventory adopter routes and freeze runtime ownership

**Body:** Enumerate every first-adopter route, assign one explicit runtime owner, record mutation
payloads, staleness, auth posture, required audio packs, fallback, and remote-disable behavior.
Freeze the smallest iPhone study slice and document unresolved risks. Do not implement framework
features during this pass.

**Priority:** Urgent  
**Milestone:** Public v1  
**Owner:** Adopter product/architecture  
**Acceptance:** The one-day route-policy map is complete and every route has one owner.

## Port existing tests into the Crosswake host proof scaffold

**Body:** Preserve the adopter's browser tests, unit tests, and fixtures. Configure the generated
Crosswake proof lane with real route IDs, IndexedDB names, mutation identifiers, sync endpoint,
evidence endpoint, router, and iOS shell root. Add only native/offline assertions that browser
automation cannot reach.

**Priority:** Urgent  
**Milestone:** Public v1  
**Owner:** Crosswake proof lane + adopter test integration  
**Acceptance:** Browser proof still passes and the scaffold can launch the iOS-specific proof flow.

## Enforce privacy-safe scoped replay

**Body:** Add opaque scope references to journal and replay envelopes, partition the outbox by
scope, stop replay on logout/account switch, reauthorize at the endpoint, and redact raw answers
from logs, diagnostics, and proof artifacts.

**Priority:** Urgent  
**Milestone:** Public v1  
**Owner:** Crosswake envelope contract + adopter host authorization  
**Acceptance:** Cross-scope tests fail closed and no raw payload appears in captured evidence.

## Install one pronunciation pack on iOS in the foreground

**Body:** Implement the host-supplied iOS pack provider for one immutable pronunciation archive.
Download into application support storage, verify expected size and SHA-256, atomically install,
and expose explicit missing, failed, incompatible, and available lifecycle states.

**Priority:** Urgent  
**Milestone:** Public v1  
**Owner:** Crosswake iOS seam + adopter media/storage implementation  
**Acceptance:** Offline playback works after verified install; interrupted or corrupt installs
never report available.

## Prove the complete study flow on a physical iPhone

**Body:** Execute the ten-step physical-device exit test: pack install, offline selected/free-form
answers, offline audio, kill/relaunch persistence, exactly-once replay, conflict/rejection
recovery, account isolation, remote disablement, and redacted evidence.

**Priority:** Urgent  
**Milestone:** Public v1  
**Owner:** Adopter release engineering  
**Acceptance:** One dated redacted artifact proves the flow against exact Crosswake and shell
versions.

## Prove shell auth continuity against backend authority

**Body:** Wire the first adopter to `crosswake_sigra` for shell handoff, expiry, revocation,
recent-auth, reconnect, logout, and account-switch behavior. Keep credentials, provider identity,
and token authority out of Crosswake core and the WebView.

**Priority:** High  
**Milestone:** Public v1  
**Owner:** `crosswake_sigra` contract + Sigra backend + adopter host wiring  
**Acceptance:** Every stale, revoked, switched, or insufficient session fails closed with a typed
denial and no replay.

## Add server-side disablement for the offline study path

**Body:** Bind study entry and replay to the host flag source through existing `gated_by` policy.
When disabled, block new entry and replay, preserve queued events, and show a recoverable state.
Do not introduce a Crosswake flag service.

**Priority:** High  
**Milestone:** Public v1  
**Owner:** Adopter host  
**Acceptance:** A server-side flag disables the shipped native path without data loss or a new
binary.

