# SETUP.md — One-Time Credential Provisioning Runbook

This runbook provisions every credential the native publish path requires. Complete these 8
steps **once**, out-of-band, before any Phase 110 CI run. The Wave 2 preflight job then
verifies presence and fails fast.

This document never performs a publish, never cuts a release, and the iOS mirror repo stays
empty until Phase 111. All values are handled via hidden-input `gh secret set` prompts — no
secret value is ever written down here.

---

## 1. Sonatype Namespace Provisioning

**What this does:** establishes `io.github.sztheory` as a verified Maven Central namespace.

1. Sign in to [central.sonatype.com](https://central.sonatype.com) using the **GitHub OAuth
   login** (the "Login with GitHub" button) as the `szTheory` account.

2. On first GitHub-authenticated login, Sonatype **auto-provisions** `io.github.sztheory`.
   No further action is needed in most cases.

3. **Manual fallback** (if the namespace does not appear after login):
   - Click your username → **View Namespaces**
   - Click **Add Namespace**
   - Enter `io.github.sztheory` and click **Verify Namespace**
   - Sonatype provides a verification key. Create a **temporary public GitHub repository**
     named exactly as the key (e.g. `szTheory/<verification-key>`).
   - Click **Verify** in the Central Portal; Sonatype confirms within minutes.
   - Delete the temporary repository once verified.

**Limitation the preflight cannot check:** The namespace has no status API. The Wave 2
preflight cannot assert that `io.github.sztheory` is verified — the preflight asserts only
that the required secrets are present. The **validated-upload → drop fire-drill** in plan
110-03 is the operational check that proves the namespace is live and functional.

---

## 2. Sonatype User Token

**What this does:** generates a Sonatype API token (not your login credentials) for
authenticating the Maven Central publish CI job.

1. Sign in to [central.sonatype.com](https://central.sonatype.com).
2. Click your username in the top-right → **User Token**.
3. Click **Generate User Token**. Copy the **username** and **password** that are
   displayed (these are the token values, not your login credentials).

4. Set the two secrets in the `szTheory/crosswake` repo:

```bash
gh secret set ORG_GRADLE_PROJECT_mavenCentralUsername --repo szTheory/crosswake
# Paste the Sonatype user token username when prompted
```

```bash
gh secret set ORG_GRADLE_PROJECT_mavenCentralPassword --repo szTheory/crosswake
# Paste the Sonatype user token password when prompted
```

5. Confirm both are set:

```bash
gh secret list --repo szTheory/crosswake
```

---

## 3. GPG Key Generation

**What this does:** creates a GPG keypair whose private key signs Maven artifacts and whose
public key Maven Central verifies.

### Why this specific command

```bash
gpg --quick-generate-key "szTheory <qiksnare13@gmail.com>" rsa4096 sign 0
```

This produces a **primary key with the `sign` capability and no signing subkey**. The
alternatives are dangerous:

- `gpg --gen-key` or `gpg --full-generate-key` (interactive) typically produces a primary
  key plus a signing subkey. When you export with `--export-secret-keys`, both keys are
  included. Maven Central's signature verification checks the primary key against the
  keyserver — **if the uploaded export contains only a subkey signature, Central Portal
  rejects it with a misleading "Invalid signature for file" error** that looks like a file
  corruption issue rather than a key-shape issue.
- `rsa4096 sign 0` specifies: RSA 4096-bit, signing capability only, no expiry (0 = never).
  Adjust the expiry if your key rotation policy requires it.

### Steps

1. Generate the key (use the exact command above):

```bash
gpg --quick-generate-key "szTheory <qiksnare13@gmail.com>" rsa4096 sign 0
```

2. List the key to find its ID:

```bash
gpg --list-secret-keys --keyid-format LONG
```

Note the key fingerprint (e.g., `ABCD1234EFGH5678...`). The **short key ID** is the last
8 hex characters (e.g., `EFGH5678`).

3. Export the private key as ASCII armor:

```bash
gpg --export-secret-keys --armor <KEYID> > crosswake-signing.asc
```

4. Set the three signing secrets:

```bash
gh secret set ORG_GRADLE_PROJECT_signingInMemoryKey --repo szTheory/crosswake
# Paste the entire contents of crosswake-signing.asc when prompted
# (including the -----BEGIN PGP PRIVATE KEY BLOCK----- header and footer)
```

```bash
gh secret set ORG_GRADLE_PROJECT_signingInMemoryKeyId --repo szTheory/crosswake
# Paste the short key ID (last 8 hex chars of the fingerprint)
```

```bash
gh secret set ORG_GRADLE_PROJECT_signingInMemoryKeyPassword --repo szTheory/crosswake
# Paste the GPG key passphrase you chose during key generation
```

5. Delete the exported key file:

```bash
rm crosswake-signing.asc
```

---

## 4. GPG Public Key Upload to Keyservers

**What this does:** makes your GPG public key discoverable by Maven Central's signature
verification. Without this step, Central Portal will reject signed artifacts.

Upload to **both** keyservers:

```bash
gpg --keyserver keys.openpgp.org --send-keys <KEYID>
```

```bash
gpg --keyserver keyserver.ubuntu.com --send-keys <KEYID>
```

**Note on keys.openpgp.org:** This keyserver uses a Verified Key Server (VKS) protocol.
After `--send-keys`, you will receive a confirmation email to `qiksnare13@gmail.com`. You
must click the link in that email to bind your identity to the key. Without email
confirmation, the key is stored but not publicly searchable by email address. By-fingerprint
lookup still works, which is what Central Portal uses.

**Verify from a clean environment** (a machine that has never seen this key, or clear the
local keyring cache first):

```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys <KEYID>
# Expected: "imported: 1"
```

```bash
gpg --keyserver keys.openpgp.org --recv-keys <KEYID>
# Expected: "imported: 1"
```

If either command returns "not changed" or "key not found", wait a few minutes for
propagation and retry.

---

## 5. iOS Mirror Repository Creation

**What this does:** creates the empty public repository that the `ios-mirror` CI job pushes
subtree-split commits to on each release.

```bash
gh repo create szTheory/crosswake-shell-core-ios --public
```

**Critical:** Do **not** initialize with a README (`--add-readme`), license, or any initial
commit. The repository must be **completely empty**. CI seeds it on the first release in
Phase 111 by pushing the subtree-split SHA to `refs/heads/main`. Pushing to an empty remote
is well-defined git behavior; a pre-existing commit would require a force-push.

Verify the repository is empty:

```bash
gh api /repos/szTheory/crosswake-shell-core-ios --jq '.default_branch // "empty"'
# Expected: "empty" or null — no default branch means no commits
```

The mirror stays empty through all of Phase 110.

---

## 6. MIRROR\_PUSH\_TOKEN

**What this does:** creates a fine-grained PAT that the `ios-mirror` CI job uses to push
to `szTheory/crosswake-shell-core-ios`.

1. In GitHub, go to **Settings → Developer settings → Personal access tokens →
   Fine-grained tokens → Generate new token**.

2. Set the following:
   - **Token name:** `crosswake-ios-mirror-push`
   - **Expiration:** your preferred rotation window (90 days recommended)
   - **Resource owner:** `szTheory`
   - **Repository access:** **Only selected repositories** → select
     `szTheory/crosswake-shell-core-ios` (the mirror repo — not the main `crosswake` repo)
   - **Permissions → Repository permissions → Contents:** `Read and write`
   - All other permissions: leave as `No access`

3. Generate the token and copy it immediately (shown only once).

4. Set the secret on the **main crosswake repo** (not the mirror):

```bash
gh secret set MIRROR_PUSH_TOKEN --repo szTheory/crosswake
# Paste the PAT value when prompted
```

**Limitation the preflight cannot check:** Fine-grained PAT scope is not API-checkable via
`gh secret list` or any GitHub API — the preflight asserts only that `MIRROR_PUSH_TOKEN` is
present by name. The true `Contents: write` scope on the mirror repo is validated by the
first `ios-mirror` CI run in Phase 111. If the scope is wrong, that run will fail with a
403 permission error, and you must regenerate the PAT with the correct scope.

---

## 7. Tag Ruleset on the Mirror Repository

**What this does:** adds a GitHub repository ruleset that prevents tags from being
force-moved or deleted on `szTheory/crosswake-shell-core-ios`, as defense-in-depth.

**Note:** The load-bearing tag-immutability guard is the **CI push command itself** (no
`--force` flag, job gated on `releases_created`). Git rejects non-fast-forward tag updates
by default. The ruleset is best-effort defense-in-depth. Do **not** block phase setup on
this step if it fails — continue and document the failure.

Create the ruleset JSON file:

```bash
cat > /tmp/ruleset.json << 'EOF'
{
  "name": "tag-immutability",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/tags/**/*"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "non_fast_forward"
    },
    {
      "type": "deletion"
    }
  ]
}
EOF
```

Apply via the GitHub API (this uses the **Rulesets API**, not the legacy branch-protection
UI that has been blocked in prior phases):

```bash
gh api POST /repos/szTheory/crosswake-shell-core-ios/rulesets \
  --input /tmp/ruleset.json
```

Expected response: a JSON object with `"enforcement": "active"` and `"rules"` containing
`non_fast_forward` and `deletion`.

```bash
rm /tmp/ruleset.json
```

Verify the ruleset is active:

```bash
gh api /repos/szTheory/crosswake-shell-core-ios/rulesets \
  --jq '.[].rules[].type'
# Expected output includes: non_fast_forward, deletion
```

---

## 8. Secret Verification Checklist

Run the following and confirm all 8 names are present:

```bash
gh secret list --repo szTheory/crosswake
```

Required secrets (each must appear in the output):

| Secret Name | Purpose |
|---|---|
| `HEX_API_KEY` | Hex.pm publish (scope `package:crosswake` — already exists) |
| `ORG_GRADLE_PROJECT_mavenCentralUsername` | Sonatype user token username |
| `ORG_GRADLE_PROJECT_mavenCentralPassword` | Sonatype user token password |
| `ORG_GRADLE_PROJECT_signingInMemoryKey` | ASCII-armored GPG private key |
| `ORG_GRADLE_PROJECT_signingInMemoryKeyId` | Short GPG key ID (last 8 hex chars) |
| `ORG_GRADLE_PROJECT_signingInMemoryKeyPassword` | GPG key passphrase |
| `MIRROR_PUSH_TOKEN` | Fine-grained PAT for the iOS mirror repo |
| `RELEASE_PLEASE_TOKEN` | Fine-grained PAT for release-please PR/tag creation |

**If `RELEASE_PLEASE_TOKEN` is missing:** Create a fine-grained PAT scoped to
`szTheory/crosswake` with **Contents: write** and **Pull requests: write** and **Issues:
write** permissions. Set it the same way as `MIRROR_PUSH_TOKEN`:

```bash
gh secret set RELEASE_PLEASE_TOKEN --repo szTheory/crosswake
# Paste the PAT value when prompted
```

This token allows release-please PRs and tags to trigger required CI checks. Without it,
`GITHUB_TOKEN` is used as a fallback, but `GITHUB_TOKEN`-triggered events cannot chain-fire
other workflow runs (confirmed GitHub design limitation, release-please-action issue #1000).

---

## Limitations the Preflight Cannot Check

The Wave 2 preflight (plan 110-03) asserts secret **presence** via `gh secret list` and
performs automated verification where APIs exist. Two limitations are inherent and not
automatable:

### Sonatype Namespace Status

There is no status API for Central Portal namespace verification. The preflight cannot assert
that `io.github.sztheory` is in a "verified" state. The **validated-upload → drop
fire-drill** in plan 110-03 (which uploads a real artifact, polls until `VALIDATED`, then
drops it) is the operational proof that the namespace is functional. If the namespace is
unverified, the upload will fail with a namespace ownership error — that failure surfaces at
the fire-drill stage, not at the preflight stage.

### MIRROR\_PUSH\_TOKEN Scope

GitHub's REST API returns only secret names and update timestamps, not scope details. The
preflight cannot confirm that `MIRROR_PUSH_TOKEN` has `Contents: write` on
`szTheory/crosswake-shell-core-ios` only. Scope is validated by the first live `ios-mirror`
CI run in Phase 111. If the PAT has the wrong scope (e.g., too broad or too narrow), that
run will surface the error.

---

## What This Runbook Does NOT Do

- It does not perform a real Maven Central publish.
- It does not push any commits or tags to the iOS mirror repository.
- It does not cut a Hex release or advance any version numbers.
- It does not modify `mix.exs`, `build.gradle.kts`, or any CI workflow files.

The mirror repository stays **empty** throughout Phase 110. The first real coordinated
publish (Hex + iOS tag + Android Maven, all at `0.1.2`) occurs at the end of Phase 111,
after `gen.shell` templates are rewired to reference published coordinates.

---

*Runbook version: Phase 110 (2026-06-14)*
*Contact: szTheory (qiksnare13@gmail.com)*
