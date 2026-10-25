# Post-Plan130 Unblock Finding

Date: 2026-10-10. Workstream: `quality-ratchet-release`.

## Finding and Limit

The current collector's `currentReadHeaders` authenticates only `/user` and collaborator-permission GETs. Its ruleset list and detail GETs remain anonymous even after a credential is present and authenticated access has been projected. `currentPolicySnapshot` nevertheless requires an explicit array-valued `bypass_actors` on every ruleset detail before it can report complete policy.

[GitHub's repository ruleset documentation](https://docs.github.com/en/rest/repos/rules#get-a-repository-ruleset) states that `bypass_actors` is returned only when the requesting user has write access to the ruleset. An anonymous response may therefore validly omit it. The source-bound no-network reproduction below simulates that documented redaction and ends with complete=false/tag_policy=UNKNOWN despite an available synthetic credential and ADMIN access projection.

This establishes a reproducible acquisition limitation and a materially distinct repair path. It does **not** establish which predicate caused Plan129's live complete=false result. The old restricted authentication scope is not authority to send credentials to more endpoints. A repair must introduce an explicit reviewed authentication boundary and a fresh displayed scope before any later external read. Missing fields remain UNKNOWN; do not weaken the completeness check or infer bypass rights from ADMIN.

## Exact Local Reproduction

Source: `script/release_candidate/plan105_mirror_tag_collector.mjs`.
Source SHA-256: `e3e4f3feab95a71a79ffd42a6f0ef0bdc59464fdcf86adb6d90461f2ad414ec1`.

The following exact command ran with injected synthetic responses and exited **1**, reproducing the missing authenticated policy observation. No request, credential/helper lookup, remote Git operation, dry-run, or tag operation was made by the probe. A separate public documentation lookup supplied the API contract; no candidate/provider-state lookup occurred.

```sh
node --input-type=module <<'JS'
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { createHash } from 'node:crypto';
const source=readFileSync('script/release_candidate/plan105_mirror_tag_collector.mjs','utf8');
function slice(start,end){const a=source.indexOf(start),b=source.indexOf(end,a);if(a<0||b<a)throw Error('source-boundary-invalid');return source.slice(a,b);}
const context={CURRENT_READ_LIMITS:{ruleset_pages:4,ruleset_details:16},API:'https://api.github.com',TARGET_REF:'refs/tags/v0.2.6',URL,Object,Array,Number,RegExp,Set,sha256:x=>createHash('sha256').update(x).digest('hex'),stable:JSON.stringify,parseLink:()=>null,currentReadFailure:()=>{throw Error('unexpected-failure');}};
vm.createContext(context);
vm.runInContext(slice('function currentReadHeaders(', 'async function currentReadGet(')+slice('function globMatch(', 'async function getWithHeaders(')+slice('async function currentPolicySnapshot(', 'async function currentGitRead('),context);
const seen=[];
const fakeHeader='Basic SYNTHETIC_ONLY';
context.currentReadGet=async (route,state)=>{
 const auth=context.currentReadHeaders(route,state).Authorization===fakeHeader;
 seen.push({kind:route.includes('?')?'list':'detail',authenticated:auth});
 if(route.includes('?'))return {body:[{id:71,source_type:'Repository',source:'szTheory/crosswake-shell-core-ios'}],link:null};
 const body={id:71,target:'tag',source_type:'Repository',source:'szTheory/crosswake-shell-core-ios',enforcement:'disabled',conditions:{ref_name:{include:['refs/tags/v*'],exclude:[]}},rules:[]};
 if(auth)body.bypass_actors=[];
 return {body,link:null};
};
const actual=await context.currentPolicySnapshot({authHeader:fakeHeader},'UNKNOWN',{permission:'TRUE',permission_role:'ADMIN',identity_match:'TRUE'});
console.log(JSON.stringify({probe:'authenticated_policy_observation',source_sha256:createHash('sha256').update(source).digest('hex'),requests:seen,actual_complete:actual.complete,actual_tag_policy:actual.tag_policy,expected_complete_for_authenticated_documented_response:true,network_requests:0,credential_lookups:0}));
if(actual.complete!==true){console.error('REPRODUCED: ruleset requests omit the already-available credential, so the documented redacted response cannot produce complete policy.');process.exitCode=1;}
JS
```

Observed: both simulated requests authenticated=false; complete=false; tag_policy=UNKNOWN; source digest matches the value above. The synthetic disabled tag ruleset is a controlled fixture, not a statement about the real mirror's rules. The probe intentionally exposes the acquisition mismatch; it is not a new permanent test lane or passing product acceptance claim.

## Narrow Next Work

The Plan130 stop permitted reopening after a specific failing no-network reproduction. This finding supplies a distinct policy-acquisition limitation supported by the official API contract. The next step is **planning a local repair only**, not another current-information attempt:

`$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`

Confine the follow-up to an explicitly scoped authenticated ruleset-read boundary, fixed repository/route allowlisting, identity/permission prerequisites, safe handling of omitted bypass fields, and fake response/header regressions. Preserve historical scope semantics and terminal evidence. Do not silently broaden credential disclosure under the old v1 scope or reuse a spent approval. Do not add a credential fallback, API polling, or release action. Any unsupported ruleset interpretation remains fail closed.

Candidate version remains a separate unresolved question: `currentPullVersion` found no accepted title token, and the title bytes were not retained. The exact PR head's release manifest and `mix.exs` objects were unavailable in this checkout. No package version was inferred. An alternative exact-head version source, if needed, requires its own explicitly reviewed acquisition scope; it must not be smuggled into this authentication-only repair.

Any later external read requires a fresh displayed card and a new plain-language allow/hold bound internally. Any tag action still requires a complete current preflight, effective policy/permission, one exact-ref dry-run, and its own separate decision. The policy repair alone will not satisfy Plan106's Plan119-pinned precondition, resolve candidate version, or clear REL-17.

## Handoff

Last completed phase: **174**. Last completed plan: **Plan130/Wave34**. Phase175 remains **IN PROGRESS/INCOMPLETE / RELEASE-BLOCKED**. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Plan129's attempt and ALLOW remain spent. This new local finding does not alter Plan130's summary or any prior result. Planning artifacts remain uncommitted under `phase_commit_docs.175=false`.
