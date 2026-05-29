# Phase 29: Release Workflows And Supply-Chain Hardening - Discussion Log

## Resolved Gray Areas & Recommendations

| Area | Recommendation / Rationale | Status |
| :--- | :--- | :--- |
| **`googleapis/release-please-action` SHA Pinning** | The `oarlock` template uses `@v4` for this action. To satisfy **REL-05**, we MUST pin it to a SHA. The current SHA for `v4` is `5c625bfb5d1ff62eadeeb3772007f7f66fdcf071` (v4.1.3). We will use this explicit SHA and add the comment `# v4.1.3`. | ✓ |
| **Dependabot Schedule** | We will configure `.github/dependabot.yml` with a `weekly` schedule for the `github-actions` ecosystem. This provides a good balance between security updates and PR noise. | ✓ |
| **Required Secrets** | The workflows require `HEX_API_KEY` to publish to hex.pm, and optionally `RELEASE_PLEASE_TOKEN` (fine-grained PAT) for bypassing branch protection when creating Release PRs. These will need to be configured in the repository's GitHub Secrets by the maintainer. We will proceed with the workflow code under the assumption these will be injected at runtime. | ✓ |
| **Verification Loop Substitution** | In the Hex publish job, the `curl` loop verifies publish success via the Hex API. We will substitute `oarlock` with `crosswake` in the URL: `https://hex.pm/api/packages/crosswake/releases/${VERSION}`. | ✓ |

## Next Steps
The discuss phase is complete. All architectural decisions align with the canonical `oarlock` patterns, updated for strict SHA-pinning compliance.
We are ready to move to `/gsd-plan-phase 29`.
