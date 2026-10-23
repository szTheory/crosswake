# v25 acceptance footguns

Status: research recommendations; these are proposed regression/experiment gates, not executed Crosswake tests.

| Footgun | Required control |
|---|---|
| Loading production runtime config requires DB/secret values merely to generate native resources | Compile-only generator requirements; fixture with deliberately unavailable runtime variable; no app start |
| CLI/config/sidecar each become separate authoring truth | One ordinary host declaration; explicit conflict handling; metadata is projection only |
| Regeneration overwrites native host edits or silently preserves stale JSON | Exact file ownership and recognized generation schema; nonwriting check/diff; controlled updates/migration |
| Several individually atomic file writes are advertised as one atomic transaction | Preflight/staging plus explicit interrupted-update detection/recovery; build check rejects incomplete output |
| xcconfig settings are masked or configuration file becomes an app resource | Inspect effective settings per app/test target and SDK/config; resource exclusion check |
| HTTPS URL is parsed as xcconfig comment | Serialize origin in canonical JSON, not unescaped xcconfig |
| Auth/CDN origins silently widen route/bridge origin authority | Separate primary navigation/bridge, host auth continuation and media acquisition policies; no wildcard additions |
| Static activation looks like session/replay authorization | No credentials/account/scope/grant in activation; runtime host admission remains required |
| Safari/hidden WebView/old native suite is called generated-app coverage | Bind actual installed generated candidate, visible study WebView and matching controller/bridge |
| Separate native audio pass is called island audio | Normal visible island action → registered host delegate → verified installed bytes → actual native playback observation |
| Test-only API request replaces normal app replay | Observe ordinary app transport and independently query real Ecto effects; explicit synthetic authority limit |
| Page reload/native storage is called WebView process persistence | Terminate/relaunch actual app; same persistent WebKit store; no reset/reinstall during lifecycle |
| Browser offline toggle is called native/network isolation | Verify denial at actual tested target transport; no whole-laptop network mutations |
| Existing cleanup touches shared DB/server | Fresh owned DB and process; readiness/source identity; no default-port reuse or shared row deletion |
| One declared SHA masks older package/app/static/backend inputs | Independently bind selected/resolved dependencies, installed build, loaded assets and backend to expected identities |
| Artifact existence, missing case or callback exception becomes green | Closed expected scenario/observation roster, owner mapping and explicit fail/blocked/pass rules |
| Simulator receipts weaken physical report | Separate twin-only derived record; unchanged physical schema and zero promotion mapping |
| Retry passes erase diagnostic history | Retain failed attempt/cause privately; new identified attempt only after concrete repair |
| Raw output or low-entropy private identifiers/hashes leak | Closed safe results and privacy-checked restricted diagnostics; disable sensitive traces/screenshots/result attachments; private retention never exempts payloads from policy |
| A digital twin becomes a new product | Canonical ten groups, narrow missing joins, no UI dashboard/matrix/generic platform |
| A required automated observation cannot run but is labeled diminishing returns | Stop incomplete/blocked; only recorded hardware/adopter limits may remain after virtual completion |

See [SUMMARY.md](SUMMARY.md) for selected decisions and [PROOF-CHALLENGE.md](PROOF-CHALLENGE.md) for source-bound anti-overclaim gates. Accessibility/copy changes are limited to operating the tested states; current brandbook applies without reopening polish.
