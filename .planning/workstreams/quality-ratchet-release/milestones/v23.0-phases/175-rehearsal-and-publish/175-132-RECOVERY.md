# Plan132 same-attempt local decision recovery

The user subsequently instructed: "ok whats next unblock us and move forward...".
This authorizes correction of the rejected local command. The preceding plain-language ALLOW remains bound to the unchanged displayed card for attempt `d9364591d7faf4a6f9fa70b634bd6c2a`; it is not transferred to another attempt or scope.

The independently repeated offline audit proves canonical scope/reservation and raw card/collector digests match their original approved bindings; authorization/result are absent, lifecycle is reservation-only, and all operation counts are zero. Source inspection proves a mismatched caller collector digest fails before the exclusive authorization write. No prior external read was started or consumed, and no production collector defect was demonstrated.

Recovery is a user-directed exception to Plan132's once-only local decision-invocation limit, recorded after the original safe stop. It does not relax the at-most-one external-read limit or any digest, route, cap, privacy, or release gate. The corrected invocation obtains scope/collector digests from the source-defined inspector and passes those values directly to record_policy_read_decision/6, then run_policy_read/4 immediately on success. No digest is manually retyped at the call boundary. There is one corrective decision call and at most one production read; any failure or uncertainty stops without another call.

The original halted summary is retained as the historical record. The corrected execution and independent terminal audit will be recorded in a separate recovery summary. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. No staging or commit under phase_commit_docs.175=false.
