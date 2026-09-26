#!/usr/bin/env bash
set -euo pipefail

operation="${REL17_OPERATION:-}"
package="${REL17_PACKAGE:-}"
receipt_digest="${REL17_RECEIPT_DIGEST:-}"
leg_run_id="${REL17_LEG_RUN_ID:-}"
merge_oid="${REL17_MERGE_OID:-}"
envelope_file="${REL17_ENVELOPE_FILE:-}"
source_dir="${REL17_SOURCE_DIR:-}"

if [[ -z "$operation" || -z "$package" || -z "$receipt_digest" || -z "$leg_run_id" || -z "$merge_oid" || -z "$envelope_file" || -z "$source_dir" ]]; then
  printf '%s\n' 'REL-17 BLOCKED stage=post_merge operation=unknown reason=missing_evidence next=gather_fresh_evidence_and_request_a_new_gate' >&2
  exit 1
fi

exec mix crosswake.release.gate \
  --operation "$operation" \
  --stage post_merge \
  --package "$package" \
  --receipt-digest "$receipt_digest" \
  --leg-run-id "$leg_run_id" \
  --merge-oid "$merge_oid" \
  --envelope-file "$envelope_file" \
  --source-dir "$source_dir"
