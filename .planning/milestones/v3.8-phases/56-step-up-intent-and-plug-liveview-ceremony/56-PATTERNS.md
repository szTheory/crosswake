# Phase 56: Step-Up Intent And Plug/LiveView Ceremony - Pattern Map

**Mapped:** 2026-06-02
**Scope:** Step-up intent contracts, example-host persistence/ceremony, Plug/LiveView adapters, and support truth promotion.

## Closest Existing Analogs

| New/Modified Surface | Closest Existing Analog | Pattern To Reuse |
|----------------------|-------------------------|------------------|
| `lib/crosswake/companions/sigra/step_up.ex` | `lib/crosswake/companions/sigra/handoff.ex` | Pure nested structs, `new_*` constructors, closed lifecycle vocabularies, forbidden locator keys, `SessionAuthorityLane` projection requirements, host-owned renewal instructions. |
| `lib/crosswake/companions/sigra/step_up_ceremony.ex` | `lib/crosswake/companions/sigra/evaluator.ex` | Transport-agnostic return tuples and pure denial handling; no Repo, Plug.Conn, LiveView, Phoenix.Token, or session mutation in core. |
| Step-up denial codes | `lib/crosswake/companions/sigra/denial_codes.ex` | Append exact stable code strings and safe detail keys to the canonical registry; preserve public `:step_up_required`. |
| Example-host step-up persistence | `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex` | Phoenix.Token locator, Ecto.Multi issue/consume/revoke/audit, conditional `update_all`, manifest route validation, projection into `SessionAuthorityLane`. |
| Example-host session renewal | `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` | Host applies returned instructions with `configure_session(conn, renew: true)` after backend success. Extend with explicit CSRF rotation/deletion and transient step-up cleanup. |
| LiveView step-up adapter | `examples/phoenix_host/lib/crosswake_example/selective_native/on_mount.ex` | Host-owned `on_mount` module returns `{:halt, socket}` after redirect; delegate policy semantics out of the hook. |
| Route authority proof | `test/crosswake/proof/phase55_session_handoff_tickets_test.exs` and `test/crosswake/proof/phase54_sigra_session_authority_test.exs` | Root ExUnit proof drives example-host code and asserts Crosswake route-gate authority boundaries without adding Ecto/Phoenix deps to core. |
| Support/docs truth promotion | `55-03-PLAN.md` and Phase 55 summaries | Promote support truth first, derive doctor/operator/docs from canonical fields, then add proof for obsolete deferred wording and overclaim non-claims. |

## Concrete Code Patterns

### Pure Contract Pattern

`Crosswake.Companions.Sigra.Handoff` sets the template:

- Structs are nested under the domain module.
- Required fields are enforced with `@enforce_keys`.
- Client-presented locator payloads are bounded and reject authority-bearing keys.
- Success contracts require a `%SessionAuthorityLane{}` and host renewal instructions.
- Core does not mutate `Plug.Conn`.

Phase 56 should mirror this with `StepUpIntentLocator`, `StepUpIntentRecord`, `StepUpChallenge`, `StepUpConsumeRequest`, `StepUpCompletion`, `StepUpAuditEvent`, and step-up-specific renewal/CSRF/socket instructions.

### Evaluator Boundary Pattern

`Crosswake.Companions.Sigra.Evaluator` already documents the boundary:

- It is pure and transport-agnostic.
- It returns `{:allow, result}` or `{:deny, %Crosswake.Shell.Denial{}}`.
- It never issues intents, renews sessions, halts LiveViews, or validates provider returns.

`StepUpCeremony.evaluate_or_issue/3` should call or accept this evaluator result and add only challenge/intention orchestration. It should still avoid Phoenix/Ecto/LiveView ownership in core.

### Denial Registry Pattern

`DenialCodes` has one `@codes` list, one `@allowed_detail_keys` list, `valid_code?/1`, `allowed_detail_keys/0`, and `sanitize_details/1`.

Phase 56 should add `auth.step_up_intent.*` codes and safe keys in that file, with tests proving unsafe raw token/session/actor/org/device/provider/passkey/OAuth/CSRF/nonce/PKCE fields are dropped.

### Ecto Consume Pattern

`CrosswakeExample.SaaSPortal.Handoff.consume_ticket/3` uses:

- A query with state, consumed, revoked, and expiry conditions.
- `Ecto.Multi.update_all(:consume, query, set: ...)`.
- A follow-up `Multi.run` that requires exactly one affected row.
- Projection and audit inside the same transaction.

Step-up consume should use the same conditional pattern for `:issued` or `:challenged` intent states. Do not load an intent, branch in Elixir, then update by primary key without state/expiry predicates.

### Route Target Pattern

Handoff issue/redeem validates manifest-known routes and rejects arbitrary `return_to` inputs. Step-up should persist `return_route_id` plus typed params and deny route mismatches instead of redirecting to caller-provided paths.

### Host Renewal Pattern

`CrosswakeExample.SaaSPortal.Auth.apply_handoff_renewal/2` applies `configure_session(conn, renew: true)` only after successful backend redemption. Step-up should add a sibling helper such as `apply_step_up_completion/2` or extend the renewal instruction contract with:

- `renew_session?: true`
- `rotate_csrf?: true`
- explicit `put_session`
- explicit `delete_session`
- `live_socket_invalidation`

### Support Truth Pattern

Phase 55 established that `SupportMatrix.auth_contract_truth/0` is the canonical auth truth source. Doctor, publish readiness, operator inspection, guides, and fixtures should derive from it. Phase 56 should update shipped/deferred fields there first, then fan out.

## Files To Read Before Editing

- `.planning/phases/56-step-up-intent-and-plug-liveview-ceremony/56-CONTEXT.md`
- `.planning/phases/56-step-up-intent-and-plug-liveview-ceremony/56-RESEARCH.md`
- `.planning/phases/56-step-up-intent-and-plug-liveview-ceremony/56-VALIDATION.md`
- `lib/crosswake/companions/sigra/handoff.ex`
- `lib/crosswake/companions/sigra/contracts.ex`
- `lib/crosswake/companions/sigra/evaluator.ex`
- `lib/crosswake/companions/sigra/denial_codes.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex`
- `test/crosswake/proof/phase55_session_handoff_tickets_test.exs`
- `test/crosswake/proof/phase54_sigra_session_authority_test.exs`
- `lib/crosswake/support_matrix/support_matrix.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/publish_readiness.ex`
- `lib/crosswake/operator_inspection.ex`
- `guides/companions.md`
- `guides/support_matrix.md`

## Pattern Mapping Complete
