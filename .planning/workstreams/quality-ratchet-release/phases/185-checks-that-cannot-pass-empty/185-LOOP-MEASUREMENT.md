# Phase 185 loop measurement (GUARD-02, report mode)

What was checked: every `for`, `Enum.each`, `Enum.reduce`, `Enum.map` and `Enum.flat_map` loop whose body contains `assert` or `refute`, in the 45 test files the v25 milestone added or changed, to see which could pass over an empty collection. Nothing here is a blocking rule.

Scope command (D-06), run at the product candidate HEAD (b898e110):

    git diff --name-only --diff-filter=AM d0dbdf7 50fcd57   (filtered to *_test.exs)

That gives exactly 45 files (185-v25-files.txt). Phase 184's later test files are in the separate supplement at the end and do not change the headline count.

Scanner (D-07): a one-off, read-only AST scan, `185-loop-scan.exs`, run as `elixir 185-loop-scan.exs . 185-v25-files.txt --expect 45 --require test/crosswake/proof_lane/twin_receipt_test.exs:289`. It raises unless it reads exactly 45 existing files and reports the known :289 site; the committed output is `185-LOOP-SCAN.txt` (TOTAL files=45 sites=96). The committed scan is authoritative over the research estimate of about 96 sites (the two happen to agree). Line numbers in the tables are those of the pre-fix scan; fixed rows give the shifted location in the before -> after column.

Blind spots of the scan (listed again in the scan header):

- assertions made in helpers called from a loop are not seen
- with, Stream and Enum.all?/any? assertion shapes are not treated as loops with a floor
- loops whose body only filters (no assert/refute) are not reported
- guards living in helpers or setup blocks are not seen; the guard hint is textual within one test/def scope
- example-host files are parsed but are not run by the main suite (the one example-host file here was run in its own mix project)

## Per-file site counts (45 files, 96 sites, zeros included)

| file | sites |
|---|---|
| examples/phoenix_host/test/crosswake_example/e2e/twin_fault_controller_test.exs | 2 |
| examples/phoenix_host/test/crosswake_example/host_command_seam_test.exs | 0 |
| examples/phoenix_host/test/crosswake_example/page_title_test.exs | 0 |
| examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs | 1 |
| test/crosswake/doctor/doctor_host_commands_test.exs | 1 |
| test/crosswake/doctor/doctor_origin_mode_test.exs | 5 |
| test/crosswake/doctor/doctor_test.exs | 3 |
| test/crosswake/guides/host_command_seam_guide_test.exs | 5 |
| test/crosswake/guides/loopback_origin_guide_test.exs | 1 |
| test/crosswake/guides/native_shell_upgrade_test.exs | 3 |
| test/crosswake/manifest/builder_test.exs | 0 |
| test/crosswake/manifest/host_command_seam_fixture_test.exs | 0 |
| test/crosswake/manifest/host_commands_test.exs | 0 |
| test/crosswake/manifest/manifest_test.exs | 0 |
| test/crosswake/operator_inspection/formatter_test.exs | 0 |
| test/crosswake/operator_inspection_host_commands_test.exs | 0 |
| test/crosswake/policy/host_commands_test.exs | 5 |
| test/crosswake/proof/phase134_template_version_drift_test.exs | 0 |
| test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs | 2 |
| test/crosswake/proof/phase180_twin_feasibility_test.exs | 0 |
| test/crosswake/proof/phase64_runtime_line_policy_test.exs | 8 |
| test/crosswake/proof_lane/recovery_edges_test.exs | 0 |
| test/crosswake/proof_lane/template_contract_test.exs | 7 |
| test/crosswake/proof_lane/twin_fault_boundary_test.exs | 0 |
| test/crosswake/proof_lane/twin_journey_test.exs | 1 |
| test/crosswake/proof_lane/twin_producers_test.exs | 4 |
| test/crosswake/proof_lane/twin_receipt_test.exs | 5 |
| test/crosswake/router_host_commands_test.exs | 5 |
| test/crosswake/shell/host_command_seam_swift_constant_test.exs | 0 |
| test/crosswake/shell/ios_host_config_test.exs | 7 |
| test/crosswake/shell/ios_host_generation_host_commands_test.exs | 3 |
| test/crosswake/shell/ios_host_migration_graph_test.exs | 0 |
| test/crosswake/shell/ios_host_migration_security_test.exs | 1 |
| test/crosswake/shell/ios_host_origin_mode_test.exs | 3 |
| test/crosswake/shell/managed_outputs_test.exs | 0 |
| test/crosswake/shell/shell_package_test.exs | 0 |
| test/crosswake/support_matrix/renderer_test.exs | 6 |
| test/mix/tasks/crosswake.docs.sync_test.exs | 2 |
| test/mix/tasks/crosswake_doctor_test.exs | 0 |
| test/mix/tasks/crosswake_gen_proof_lane_test.exs | 6 |
| test/mix/tasks/crosswake_gen_shell_host_commands_test.exs | 0 |
| test/mix/tasks/crosswake_gen_shell_host_test.exs | 3 |
| test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs | 3 |
| test/mix/tasks/crosswake_inspect_test.exs | 0 |
| test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs | 4 |

## Site dispositions

Buckets are the ledger's existing names (D-08): safe-by-construction, safe-guarded, safe-cardinality-pinned, safe-compile-time-literal, needs-fix. `waived-by-design` appears once, report only. Nothing was added to `script/collection_assertion_ledger.json`.

| file | line | kind | source class | disposition | disposition_basis | before -> after |
|---|---|---|---|---|---|---|
| twin_fault_controller_test.exs | 254 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| twin_fault_controller_test.exs | 270 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| phase180_twin_feasibility_test.exs | 47 | for | runtime | needs-fix -> safe-guarded | refute-only loop over manifest routes; added `assert map_size(manifest["routes"]) > 0` before the loop (extends D-09's list as D-09 allows) | no floor -> floor before loop (now L47-L49) |
| doctor_host_commands_test.exs | 146 | for | runtime | safe-guarded | `assert codes(found)` pins exactly two findings above the loop | - |
| doctor_origin_mode_test.exs | 351 | for | runtime | safe-by-construction | `reports` is a literal 3-element list bound in the same test | - |
| doctor_origin_mode_test.exs | 356 | for | runtime | safe-by-construction | `forbidden` is a literal list bound earlier in the same test | - |
| doctor_origin_mode_test.exs | 360 | for | runtime | needs-fix -> safe-guarded | refute-only loop over concatenated findings; findings bound and `assert [_ | _] = findings` added per report (green on all three reports, so a per-report floor holds) | loop over inline concatenation -> `findings = ...; assert [_ | _] = findings` before the loop |
| doctor_origin_mode_test.exs | 364 | for | runtime | safe-by-construction | `forbidden` is a literal list bound earlier in the same test | - |
| doctor_origin_mode_test.exs | 370 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| doctor_test.exs | 859 | for | runtime | waived-by-design (report only; never in the ledger) | the in-file comment says no commerce finding emits proof_class :advisory today and the contract is conditional ("IF such findings appear"); asserting at least one would be false on today's tree | unchanged (D-09 single waiver) |
| doctor_test.exs | 907 | for | runtime | safe-guarded | `assert advisory_findings != []` a few lines above | - |
| doctor_test.exs | 1083 | for | runtime | safe-by-construction | `sensitive_artifacts` is a literal list bound earlier in the test | - |
| host_command_seam_guide_test.exs | 16 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| host_command_seam_guide_test.exs | 50 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| host_command_seam_guide_test.exs | 70 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| host_command_seam_guide_test.exs | 105 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| host_command_seam_guide_test.exs | 126 | for | runtime | safe-by-construction | `files` is a `~w(...)` list piped through Enum.map | - |
| loopback_origin_guide_test.exs | 11 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| native_shell_upgrade_test.exs | 94 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| native_shell_upgrade_test.exs | 99 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| native_shell_upgrade_test.exs | 104 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| host_commands_test.exs | 74 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| host_commands_test.exs | 115 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| host_commands_test.exs | 125 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| host_commands_test.exs | 140 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| host_commands_test.exs | 160 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| phase170_vacuous_assertion_ledger_test.exs | 115 | Enum.each | runtime | safe-guarded | `assert committed["rows"] != []` immediately above | - |
| phase170_vacuous_assertion_ledger_test.exs | 400 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| phase64_runtime_line_policy_test.exs | 93 | for | runtime | safe-by-construction | literal list bound in the test | - |
| phase64_runtime_line_policy_test.exs | 113 | for | runtime | safe-by-construction | literal list bound in the test | - |
| phase64_runtime_line_policy_test.exs | 192 | for | runtime | safe-guarded | `assert length(action_classes) > 0` above the loop | - |
| phase64_runtime_line_policy_test.exs | 249 | for | runtime | safe-guarded | `assert is_list(matrix) and length(matrix) > 0` above the loop | - |
| phase64_runtime_line_policy_test.exs | 382 | for | runtime | safe-guarded | re-checked: `assert is_list(rebuild_matrix) and length(rebuild_matrix) > 0` sits above and the loop maps 1:1 | - |
| phase64_runtime_line_policy_test.exs | 416 | for | runtime | needs-fix -> safe-guarded | loop was a tautology over a filter (same predicate asserted in the body); added `assert [_ | _] = ios_entries` with a message before the loop | no floor -> floor before loop |
| phase64_runtime_line_policy_test.exs | 460 | for | runtime | needs-fix -> safe-guarded | same tautology shape over the :jvm_hermetic filter; added `assert [_ | _] = android_entries` before the loop | no floor -> floor before loop |
| phase64_runtime_line_policy_test.exs | 757 | for | runtime | safe-guarded | `assert length(android_entries) > 0` above the loop | - |
| template_contract_test.exs | 129 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| template_contract_test.exs | 148 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| template_contract_test.exs | 167 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| template_contract_test.exs | 344 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| template_contract_test.exs | 397 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| template_contract_test.exs | 409 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| template_contract_test.exs | 468 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| twin_journey_test.exs | 25 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| twin_producers_test.exs | 77 | for | runtime | safe-by-construction | `groups` is a literal 6-tuple list with positive counts; body also refutes an empty observations list and pins length | - |
| twin_producers_test.exs | 316 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| twin_producers_test.exs | 377 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| twin_producers_test.exs | 401 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| twin_receipt_test.exs | 110 | for | runtime | needs-fix -> safe-cardinality-pinned | body asserts per join, so an empty identity_joins() would pass; added `assert length(joins) == 7` before the loop (extends D-09's list) | `for join <- TwinReceipt.identity_joins()` -> `joins = ...; assert length(joins) == 7; for join <- joins` |
| twin_receipt_test.exs | 164 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| twin_receipt_test.exs | 214 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| twin_receipt_test.exs | 286 | for | runtime | safe-guarded | `assert length(decoded["groups"]) == 10` above the loop | - |
| twin_receipt_test.exs | 289 | for | runtime | needs-fix -> safe-cardinality-pinned | inner loop over each group's sub_observations had no floor; added `assert [_ | _] = g["sub_observations"]` and an exact per-group count from TwinReceipt.roster/0 (T01..T10 = 4,5,3,7,4,5,5,3,5,8) | no floor -> two floor lines at the head of the group loop body (now L295-L296) |
| router_host_commands_test.exs | 33 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| router_host_commands_test.exs | 45 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| router_host_commands_test.exs | 52 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| router_host_commands_test.exs | 57 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| router_host_commands_test.exs | 64 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_config_test.exs | 26 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_config_test.exs | 70 | Enum.each | runtime | safe-by-construction | `cases` is a literal list | - |
| ios_host_config_test.exs | 147 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_config_test.exs | 162 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_config_test.exs | 193 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_config_test.exs | 206 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_config_test.exs | 213 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_generation_host_commands_test.exs | 39 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_generation_host_commands_test.exs | 49 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_generation_host_commands_test.exs | 152 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| ios_host_migration_security_test.exs | 200 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_origin_mode_test.exs | 34 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_origin_mode_test.exs | 67 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| ios_host_origin_mode_test.exs | 139 | for | runtime | safe-by-construction | `cases` is a literal list of 3 | - |
| renderer_test.exs | 81 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| renderer_test.exs | 109 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| renderer_test.exs | 207 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| renderer_test.exs | 255 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| renderer_test.exs | 266 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| renderer_test.exs | 415 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| crosswake.docs.sync_test.exs | 55 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| crosswake.docs.sync_test.exs | 126 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| crosswake_gen_proof_lane_test.exs | 299 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| crosswake_gen_proof_lane_test.exs | 309 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| crosswake_gen_proof_lane_test.exs | 325 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| crosswake_gen_proof_lane_test.exs | 657 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| crosswake_gen_proof_lane_test.exs | 678 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| crosswake_gen_proof_lane_test.exs | 691 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| crosswake_gen_shell_host_test.exs | 134 | Enum.each | runtime | safe-by-construction | re-checked: `native_paths` is a literal list of Path.join calls (bound at L108) | - |
| crosswake_gen_shell_host_test.exs | 143 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| crosswake_gen_shell_host_test.exs | 411 | Enum.each | runtime | safe-by-construction | `invalid_cases` is a literal 6-tuple list | - |
| crosswake_gen_shell_origin_mode_test.exs | 99 | for | runtime | needs-fix -> safe-guarded | golden manifest files compared by key set only, which passes when both sides are empty; added `assert map_size(expected) > 0` before the loop (an exact count would couple to the golden file; extends D-09's list) | no floor -> `assert map_size(expected) > 0` before loop |
| crosswake_gen_shell_origin_mode_test.exs | 331 | for | nonempty_list_expr | safe-by-construction | source is a list expression with at least one literal element (`++` with a literal, or a range) | - |
| crosswake_gen_shell_origin_mode_test.exs | 336 | for | runtime | needs-fix -> safe-guarded | refute-only loop over forbidden_ats_keys(); an empty list would make the 'no forbidden keys' check vacuous; keys bound and `assert [_ | _] = keys` added (extends D-09's list) | inline call in comprehension -> `keys = ...; assert [_ | _] = keys` |
| crosswake_proof_lane_verify_twin_test.exs | 93 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| crosswake_proof_lane_verify_twin_test.exs | 296 | for | literal | safe-compile-time-literal | iterates a list literal, attribute, sigil or range | - |
| crosswake_proof_lane_verify_twin_test.exs | 601 | for | nonempty_list_expr | needs-fix -> safe-cardinality-pinned | lines ++ two files; research :582 loop; fixed in 185-04: before -> after = no floor -> `assert length(lines) == 4` at L647 (loop now at L649; shifted by 185-02 and 185-04 additions) | fixed 185-04 |
| crosswake_proof_lane_verify_twin_test.exs | 659 | for | runtime | needs-fix -> safe-cardinality-pinned | refute loop over texts built from the run's output lines; fixed in 185-04: before -> after = no floor -> `assert length(lines) == 4` at L709 (loop now at L711; research :640; shifted by earlier additions) | fixed 185-04 |

## Notes

- Fixed sites extending D-09's enumerated list (D-09 allows the scan to extend it): `twin_receipt_test.exs` :110 (an empty identity_joins() would pass), `crosswake_gen_shell_origin_mode_test.exs` :99 and :336 (golden key-set comparison passes when both sides are empty; an empty forbidden-keys list makes the refute vacuous), and the example-host `phase180_twin_feasibility_test.exs` :47 (the floor must precede the loop). D-09's `phase64` :412 is the :416 loop's test.
- Re-checked and recorded, not changed: `phase64_runtime_line_policy_test.exs` :382 (guarded) and `crosswake_gen_shell_host_test.exs` :134 (literal list).
- `crosswake_proof_lane_verify_twin_test.exs`: the two loops the research numbered :582 and :640 appear in this scan as L601 and L659 because earlier 185 plans added tests above them. Both are fixed in 185-04: floors `assert length(lines) == 4` now at L647 and L709 of the candidate file (final numbers; 185-05 may re-scan).
- `doctor_test.exs` :859 is the only waiver: its loop is explicitly conditional on advisory commerce findings that no current finding emits, so an at-least-one floor would be false today. It is a report row only.
- Floor for `twin_receipt_test.exs` :289: the expected count comes from the compile-time roster (`TwinReceipt.roster/0`), a different code path from `project/2`, but both derive from the roster. The floor catches a projection that drops sub-observations; it does not catch a roster change.
- The example-host test file was run in its own mix project: 7 tests, 5 pass; the two gate tests G2 and G6 fail at their own `refute` lines (the example router declares `host.study.audio.play`), not at the added floor. This is existing behaviour of those gates, recorded in the summary.

## Phase 184 supplement (informational)

Phase 184's later test files (git diff 50fcd57..b898e110, *_test.exs) were scanned the same way: 6 files, 27 sites, in `185-LOOP-SCAN.184.txt`. They are not part of the headline count of 45 files and were not triaged or changed here.

## D-12 statement

No repo-wide blocking rule, CI lane or new check script is added in this phase, whatever the counts above are. The ledger is not extended. VACG-01 (a general vacuous-assertion rule) and the ledger-scaffolding sunset stay deferred.

## After-scan (final tree)

`185-LOOP-SCAN.after.txt` is the scan re-run on the final uncommitted Phase 185 tree (45 files, 96 sites, exit 0). It is the after-scan; `185-LOOP-SCAN.txt` is the before-scan. Final floor line numbers are as listed in the rows above.
