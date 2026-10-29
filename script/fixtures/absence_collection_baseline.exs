# Reviewed after actual-main b8398c38 and the three known glob repairs.
# No discovery/evaluation of repository source occurs here. Every digest below
# identifies one metadata-free normalized AST expression in its exact context.
# Counts are deliberately literal: identical expressions in other contexts and
# duplicate occurrences are not exempt. Remove stale rows explicitly, with reason.
#
# The two remaining glob checks retain their existing one-time inventory scope.
# The universal assertions retain existing behavior (including intentional absence
# predicates); this bounded checker does not infer producer/helper cardinalities.
# These are ratchet residuals, not claims that every old assertion proves presence.
groups = [
  {"test/crosswake/bearings_report_test.exs", "Crosswake.BearingsReportTest",
   [
     {~s|describe "fixtures and source"/test "no workflow references the report"|,
      ~w(d9ff607111f1059953c2623d5caf53e05100cb6f7bdba9627c9ccbffe277fb4f), "glob_without_count",
      "Existing workflow absence inventory; retain exact occurrence until its owner adds a scope floor."}
   ]},
  {"test/crosswake/planning/first_adopter_context_test.exs",
   "Crosswake.Planning.FirstAdopterContextTest",
   [
     {~s|test "filesystem discovery includes current Phase 158 planning artifacts"|,
      ~w(ff683c52cad8c56ced873c00b5f28c0a85fd8a8f81cf2eed1871228935feec7b), "glob_without_count",
      "Existing historical planning inventory; no new adopter work or automatic scope expansion."},
     {~s|test "routing matrix classifies every active path once with non-empty required destinations"|,
      ~w(0452248642b374150a4dfcf1e13fce3b5a4432ea0671efdda25f7c0cdf8582eb), "unsafe_collection",
      "Existing routing projection; helper cardinality is outside this lexical pass."},
     {~s|test "single-digit commercial amounts are prose-aware while positional placeholders are preserved"|,
      ~w(c91382173da07ccf16f102cb69f5cec84bab50729cb3dee2af49a20386a71918), "unsafe_collection",
      "Existing synthetic prose cases; retain exact expression only."}
   ]},
  {"test/crosswake/bridge/push_test.exs", "Crosswake.Bridge.PushTest",
   [
     {~s|describe "Task 1: epoch, exactly-once delivery, and resolve/2 (D-20..D-25)"/test "the adopter's ref never appears in the pushed client-event payload"|,
      ~w(0056e9c9a50fd11edf8159fe6effa98b64b85b34c10636661045785626a0d688), "unsafe_collection",
      "Intentional exclusion over a payload projection; no new privacy exception."}
   ]},
  {"packages/crosswake_chimeway/test/crosswake/companions/chimeway/contracts_test.exs",
   "Crosswake.Companions.Chimeway.ContractsTest",
   [
     {~s|test "to_map stringifies atom keys and values and omits nils for all contract structs"|,
      ~w(72721bee0f455deec9cbfc2863934bac33560d66312c630c9aca6af6e1579754 fbd77e5cc90d784f1749ef7e5c0087b8c13b20f3cc6a5f22a36ae5e709946bca),
      "unsafe_collection",
      "Existing map key/value projections; preserve both exact universal properties."}
   ]},
  {"test/crosswake/doctor/doctor_threadline_test.exs", "Crosswake.Doctor.ThreadlineTest",
   [
     {~s|describe "phase_95_threadline_findings (OPER-03)"/test "does NOT emit threadline.plug_missing when plug is present in router"|,
      ~w(4f9088db0890e4bb2b5d68e18af5c1f6944cde8fcc7001696755c4f971bae6e9), "unsafe_collection",
      "Intentional absence of a diagnostic; empty findings are valid."},
     {~s|describe "phase_95_threadline_findings (OPER-03)"/test "emits threadline.ledger_schema_invalid :advisory when configured module is not an Ecto schema"|,
      ~w(8744a7c6acb05fbd3c03bac0f6f90dc2ed3fd67418d0678f05fbad940308beac be5118b53cf4294d2a433ad9cd94b1d15bdb7cade266b7d0872ca6b1956115a6),
      "unsafe_collection",
      "Intentional exclusion of unrelated diagnostics in an invalid-schema result."},
     {~s|describe "phase_95_threadline_findings (OPER-03)"/test "emits threadline.pii_forbidden_field_present even when install manifest is missing"|,
      ~w(4f9088db0890e4bb2b5d68e18af5c1f6944cde8fcc7001696755c4f971bae6e9), "unsafe_collection",
      "Intentional absence of plug diagnostic; preserve separate context identity."},
     {~s|describe "phase_95_threadline_findings (OPER-03)"/test "runs threadline schema checks with bare-atom audit_ledger config and canonical schema passes"|,
      ~w(3997106295bab8c9e9c932fcf41722e403cacf034bdba6a2d93466cc1a9a5244 ba591d559adaa5833e5f16e135588f9dc676403f13e597f247bcd14406bd71f9),
      "unsafe_collection", "Canonical schema deliberately emits neither schema error family."}
   ]},
  {"test/crosswake/doctor/doctor_test.exs", "Crosswake.DoctorTest",
   [
     {~s|describe "bridge hook wiring findings"/test "the wiring grep never fails doctor on its own"|,
      ~w(a134baebfa2ecbc0570166589e99e6c52d32d399afb0d5a1739228ffeb4f4a6a), "unsafe_collection",
      "Advisory-only diagnostic must not become a blocking error."},
     {~s|describe "capability rebuild finding (D-49, CTRL-05)"/test "a capability with a non-:none rebuild class declared on no active route produces no finding"|,
      ~w(c4181da4ae89c5f7ec359cbd11529002d385e18a4d230d7ef3750c99cf98e556), "unsafe_collection",
      "No active route intentionally permits empty findings."},
     {~s|describe "native controls ui findings"/test "a stamp matching the current template_version produces no drift finding (negative control)"|,
      ~w(4bb8ad275994101ebcc5504acae2850dde39189df28c526122e6de2590980ebd), "unsafe_collection",
      "Matching stamp intentionally omits drift diagnostic."},
     {~s|describe "native controls ui findings"/test "the wiring finding never fails doctor on its own"|,
      ~w(eb5c71adda35ada480a0c7b623cb0c575d308379da84c45baef73fcab2bf8427), "unsafe_collection",
      "Advisory-only wiring result intentionally has no error."},
     {~s|test "a pre-shell host stays green without making native support claims"|,
      ~w(414a75cf36cc5d0e6d613751b3f24566bb1d1e8b94b1bb793dd84190b4f1865f), "unsafe_collection",
      "Pre-shell host intentionally has no native support promotion."},
     {~s|test "commerce_summary does not emit commerce.corridor.role_unknown when every route role maps to canonical SupportMatrix taxonomy"|,
      ~w(0ae18396836ef0c63b69fd37bd3283fbf1e759e9cfa902969e9b8249004a6aed 52016f6190001012eee316396423627b88a7d821d0dc4c3660cd9393a3f16e5d),
      "unsafe_collection", "Canonical taxonomy intentionally excludes unknown-role diagnostics."},
     {~s|test "commerce_summary returns the not_applicable freshness baseline when no commerce routes exist"|,
      ~w(1a635bda7a1364d7c3544ca33c6a6d5311c61e6f6910955ea076457b137db51b 6bdd0b0d069d26c7505f7825bb8a8495e663e31b2fec4315b63640e36a6b6a13),
      "unsafe_collection", "No commerce routes intentionally permits empty freshness findings."},
     {~s|test "doctor findings are structured and formatter output stays stable when proof hooks pass"|,
      ~w(20465c34c718f5b27e5ad617d867f590124a599d56b9c819d486ebdb00219adb), "unsafe_collection",
      "Existing structured findings property; producer count is outside lexical pass."},
     {~s|test "fresh entitlement freshness suppresses the stale snapshot finding"|,
      ~w(1a635bda7a1364d7c3544ca33c6a6d5311c61e6f6910955ea076457b137db51b), "unsafe_collection",
      "Fresh entitlement intentionally omits stale diagnostic."},
     {~s|test "native_rebuild_satisfied? suppresses the native rebuild finding without removing rebuild_requirements truth"|,
      ~w(6bdd0b0d069d26c7505f7825bb8a8495e663e31b2fec4315b63640e36a6b6a13), "unsafe_collection",
      "Satisfied rebuild intentionally suppresses diagnostic."},
     {~s|test "phase 19 commerce corridor findings now carry proof_class labels"|,
      ~w(ca604cf8578330f3d2c0bfa99dc62260b08e3c10c7655909d3b059408f21e96d), "unsafe_collection",
      "Existing proof-class projection; retain exact property pending owner cardinality work."}
   ]},
  {"test/crosswake/guides/evidence_manifest_test.exs", "Crosswake.Guides.EvidenceManifestTest",
   [
     {~s|test "allowed labels are literal capability-map and proof-posture vocabulary"|,
      ~w(176a3a91e6944c27afa4c91305bc2f11a56119b1b8cc00f1421f0f21fe80958c 2d141bb6576ab3aa03b95c372d02887f7ef911a5108ce5ef2f332ff535d2e3b1 b25875427c22c179c44e49805b295965ea59e8ff80e7ac5c4f8ca366d2e07178 d5c7d2d779357862980cb7da0bc90b2547c6dbc3a6a1abdd2b509e76fd9e6f10),
      "unsafe_collection",
      "Four existing vocabulary projections; optional-manifest tautology is separately removed by plan02."}
   ]},
  {"test/crosswake/guides/release_boundaries_test.exs", "Crosswake.Guides.ReleaseBoundariesTest",
   [
     {~s|test "read-only release status projects the exact candidate boundary"|,
      ~w(69bda8bc5e7aef0e7cc163fcb08845164be172f91d72acccbc350fe8e25fa939), "unsafe_collection",
      "Existing release projection; no release authority is changed."}
   ]},
  {"test/crosswake/manifest/builder_test.exs", "Crosswake.Manifest.BuilderTest",
   [
     {~s|describe "Capability rebuild + interaction — structurally unconstructable without both (D-51, D-52, D-54)"/test "all 15 public catalog entries build successfully and each declares an explicit interaction value"|,
      ~w(ffe863fd653039fde134cd6067da9a029302294ca8049c0760e45cebbe993023), "unsafe_collection",
      "Existing builder projection; cross-call cardinality not inferred."}
   ]},
  {"test/crosswake/manifest/validator_test.exs", "Crosswake.Manifest.ValidatorTest",
   [
     {~s|test "an empty unknown-blocking topology remains a valid non-promoting manifest section"|,
      ~w(3407844ee67f453c7310f3bdb64f7b991abfa05dd8c8497b62f162cd288144b0), "unsafe_collection",
      "Explicit empty topology intentionally produces no blocking error."},
     {~s|test "malformed topology entries fail closed without raising or echoing supplied values"|,
      ~w(6d5b7fd2c1dedaa12d1e161f8850bf2ce868d65e6a69be28c60d740638430fb0), "unsafe_collection",
      "Existing error privacy projection; exact behavior retained."},
     {~s|test "manifest compile returns structured validation failures instead of opaque strings"|,
      ~w(d93c143561c3c4c51a4c70a558515b29b54336104624749050eb8cfb1b5c05bf), "unsafe_collection",
      "Existing structured error projection; helper cardinality not inferred."},
     {~s|test "manifest validation stays backward-compatible for routes without commerce declarations"|,
      ~w(fbd6f76715440c2514dd77fabbeb0559fafa5f89850fd884bf04414cb28b0935), "unsafe_collection",
      "No commerce declaration intentionally produces no commerce error."},
     {~s|test "policy validation prefers family-first capability vocabulary while keeping compatibility aliases narrow"|,
      ~w(3fa8f03d6c5d6722e78f271df535505efdebfbe3862bffb0827392114385484c c0ffcb3717de16939c45beecf639a2d365f55c73b1262092f40eccc8e38aea5c),
      "unsafe_collection", "Intentional vocabulary inclusion/exclusion over error projections."},
     {~s|test "topology validation accumulates graph and version failures without echoing rejected values"|,
      ~w(723197125da5de874f62436af34b3e81ab834c838351da0c6c977d3bf07b30cb), "unsafe_collection",
      "Existing topology diagnostic privacy property; exact occurrence retained."}
   ]},
  {"test/crosswake/manifest/manifest_test.exs", "Crosswake.ManifestTest",
   [
     {~s|test "manifest keeps schema 1.1.0 while commerce corridor fields remain additive"|,
      ~w(8cf4c13584d1117f09823e8d5be169f83ccbf0254df225b67855d56aede51858), "unsafe_collection",
      "Existing additive schema projection; no schema migration."}
   ]},
  {"test/crosswake/policy/compiler_test.exs", "Crosswake.Policy.CompilerTest",
   [
     {~s|test "valid routes across all three public runtimes compile into normalized policy output"|,
      ~w(42a15c70a71f0d7eded715bca36dc9d9e3935fb8dcffa910a2ee5e65acafd644), "unsafe_collection",
      "Existing compiler projection; future policy plan owns expanded product checks."}
   ]},
  {"test/crosswake/proof/phase165_ci_integrity_test.exs",
   "Crosswake.Proof.Phase165CiIntegrityTest",
   [
     {~s|test "brand visual proof stays visibly red and outside required authority"|,
      ~w(47ab55342378ea0ff4560da6aea79ec75001ad933ff008737a9b022aa5009444 50457232e37019c143f3019aa069f5b2b790227c1b29d3949fe96b0a0486b215 e989eff4a98955413bfa32de155f77e1adbfe78b36c775bf91139a13471f9652),
      "unsafe_collection",
      "Three intentional exclusion predicates preserve advisory visual authority."}
   ]},
  {"test/crosswake/proof/phase165_ci_policy_test.exs", "Crosswake.Proof.Phase165CiPolicyTest",
   [
     {~s|test "fixture corpus is closed, adversarial, and deterministic"|,
      ~w(e2155912eac243aa261202d322cb7732965a408fbc45cfec0425e84b58064700), "unsafe_collection",
      "Existing corpus projection; bounded checker does not infer loader cardinality."}
   ]},
  {"test/crosswake/proof/phase166_repository_quality_test.exs",
   "Crosswake.Proof.Phase166RepositoryQualityTest",
   [
     {~s|test "artifact policy is closed, ordered, non-overlapping, and narrow"|,
      ~w(5eeef9ff14f1c0844819bdc13c4c4a6dd4cfc152c6fe6929a3de5dc25738bca9), "unsafe_collection",
      "Existing artifact policy projection; exact occurrence retained."},
     {~s|test "ownership validator emits the exact deterministic remediation queue"|,
      ~w(69006cd92a0dc3da989127acb1ee6e9b175338d0ee5b9da7ef71e6dbd7a91356), "unsafe_collection",
      "Existing remediation projection; exact queue assertions remain unchanged."}
   ]},
  {"test/crosswake/proof/phase169_diagnostic_legibility_test.exs",
   "Crosswake.Proof.Phase169DiagnosticLegibilityTest",
   [
     {~s|describe "Task 2: the two crash shapes classify distinctly and cascade loudly (D-03, D-08)"/test "the crash-before-roster fixture yields :unavailable with the never-started message, and the five scoped checks + owner check are :unverifiable (exit 3)"|,
      ~w(80dbdb838953e75599ed95c34930a9a5f9fd4f9302ce9c3e851dad4204ebde99), "unsafe_collection",
      "Existing crash classification projection; context distinguishes identical expression."},
     {~s|describe "Task 2: the two crash shapes classify distinctly and cascade loudly (D-03, D-08)"/test "the roster-then-crash fixture yields :unverifiable with the terminated-early message, and the five scoped checks + owner check are :unverifiable (exit 3)"|,
      ~w(80dbdb838953e75599ed95c34930a9a5f9fd4f9302ce9c3e851dad4204ebde99), "unsafe_collection",
      "Existing second crash classification; separate exact context, not a wildcard."}
   ]},
  {"test/crosswake/proof/phase172_per_package_ref_test.exs",
   "Crosswake.Proof.Phase172PerPackageRefTest",
   [
     {~s|describe "the three claim strings are reachable through the public evaluator, not merely present in source (SC#4)"/test "a fully-proven family reaches the fully_proven claim for every package"|,
      ~w(8f1a7b9023cb5c24bcc4663d01f0ce18271bea0792130eada3fdfb30038e7c00), "unsafe_collection",
      "Existing claim projection; no publishing claim promoted."}
   ]},
  {"test/crosswake/proof/phase180_twin_feasibility_test.exs",
   "Crosswake.Proof.Phase180TwinFeasibilityTest",
   [
     {~s|test "G1 control: validator accepts a known capability without a capabilities error"|,
      ~w(a624018107577673606be59ae8a7560045bd9cbdb79e6e0c879ae96aedebd57a), "unsafe_collection",
      "Intentional absence of capability error; no device proof promotion."}
   ]},
  {"packages/crosswake_sigra/test/crosswake/proof/phase54_sigra_session_authority_test.exs",
   "Crosswake.Proof.Phase54SigraSessionAuthorityTest",
   [
     {~s|test "canonical auth denial taxonomy remains under the public step-up shell reason"|,
      ~w(b3d278eb5e5f73c2424985976a4f41ac2afb66988d48361790a7a7944264b496), "unsafe_collection",
      "Existing denial taxonomy projection; fail-closed authority unchanged."}
   ]},
  {"test/crosswake/proof/phase64_runtime_line_policy_test.exs",
   "Crosswake.Proof.Phase64RuntimeLinePolicyTest",
   [
     {~s|test "rebuild_matrix carries no row with evidence_tier :device_verified (blind spot closure)"|,
      ~w(12c16d7bf26cbe955c6af87e65b482ce02fb1fa4a5e19de846311fc3942736e4), "unsafe_collection",
      "Intentional exclusion of unsupported device evidence."}
   ]},
  {"test/crosswake/proof/phase65_diagnostic_export_seam_test.exs",
   "Crosswake.Proof.Phase65DiagnosticExportSeamTest",
   [
     {~s|test "Bridge.Contract.commands/0 has no diagnostics.* entry"|,
      ~w(c881d7eceba8355b6fc69dd3b921b243da52991fe10f0ef94f19be98b7db0092), "unsafe_collection",
      "Intentional forbidden-command absence over existing API."}
   ]},
  {"test/crosswake/proof/phase7_saas_lane_test.exs", "Crosswake.Proof.Phase7SaaSLaneTest",
   [
     {~s|test "only the approval detail route declares the bounded haptics capability"|,
      ~w(8010e1107ff13cafcb0ec233ac1c184e1ceda6c3ea35499a6c49499b1d414255), "unsafe_collection",
      "Existing route capability projection; exact occurrence retained."}
   ]},
  {"test/crosswake/proof_lane/navigation_shell_advisory_test.exs",
   "Crosswake.ProofLane.NavigationShellAdvisoryTest",
   [
     {~s|test "derives passed assertions only from an exact canonical current-run observation"|,
      ~w(7f58b6732d76669d22ada1dc5b9b6c8449e8775cef46a835ebaf876f5c07da40), "unsafe_collection",
      "Existing observation projection; no twin/device claim expanded."}
   ]},
  {"test/crosswake/proof_lane/twin_fault_boundary_test.exs",
   "Crosswake.ProofLane.TwinFaultBoundaryTest",
   [
     {~s|test "the control listener accepts only the closed command set and reports integers only"|,
      ~w(2549210eda81da55b0dc9f97680d9d450f524631a090cd4e43015d92a8c9f283), "unsafe_collection",
      "Existing listener integer projection; exact occurrence retained."}
   ]},
  {"test/crosswake/proof_lane/twin_producers_test.exs", "Crosswake.ProofLane.TwinProducersTest",
   [
     {~s|describe "host_adapter, app_process, boundary and backend rules"/test "boundary counters decide the three boundary ids"|,
      ~w(07282ab8f4862c45a060f4498cb800e7c0f42336ee120a1a3e4ded29783833e0), "unsafe_collection",
      "Existing boundary counter projection; producer cardinality not inferred."},
     {~s|describe "producer ownership"/test "each producer emits exactly its owner's ids with the documented totals"|,
      ~w(1a2c4ce80e7cabc2d3fe17b5e20f03718edee29feecd0c78c04dcd06ec6c3436), "unsafe_collection",
      "Existing ownership projection retains separately asserted totals."}
   ]},
  {"test/crosswake/release_candidate/cleanroom_test.exs",
   "Crosswake.ReleaseCandidate.CleanroomTest",
   [
     {~s|test "candidate-local proof normalizes six payloads, five profiles, and two isolated installs"|,
      ~w(a4767e0887d5db2b1b3282f46b868c8671e33324ad63f6fd81c5e4a54cc672cd aba00f30f42bf55c38b3f0f315445d1be215b5cc0cdf5bea18e7d623c86b86c0 f7dec829ad1caa6853435c1bc2985848c85df101603fe8a73302431300ffc284),
      "unsafe_collection",
      "Existing three profile properties; cleanroom receiver remains phase197."},
     {~s|test "exact-public proof requires six registry payloads, the same profiles, and live status"|,
      ~w(8f1a7b9023cb5c24bcc4663d01f0ce18271bea0792130eada3fdfb30038e7c00), "unsafe_collection",
      "Existing public claim projection; no release operation authorized."},
     {~s|test "one attested package with five fully-proven packages reports ATTESTED, not COMPLETE"|,
      ~w(301c79ee79728ca65a595927ad1cf675b175965253ddc0d31fb89636cd039c82), "unsafe_collection",
      "Existing filtered claim projection; filtered collections require their own proof in new code."}
   ]},
  {"test/crosswake/release_candidate/coordinate_test.exs",
   "Crosswake.ReleaseCandidate.CoordinateTest",
   [
     {~s|test "links only Hex, iOS, and Android at the candidate coordinate"|,
      ~w(07043850eb4f3c21ea1f9764295dc2a019054fae150879a0410d4fc69f32d6b0), "unsafe_collection",
      "Intentional exclusion of mismatched companion coordinate."}
   ]},
  {"test/crosswake/release_candidate/mirror_test.exs", "Crosswake.ReleaseCandidate.MirrorTest",
   [
     {~s|test "publish permits only immediate ancestor or equal main with immutable atomic refs"|,
      ~w(153098f13236e5cdc1b3a5c996f96e534511c2ff127e412b12dd3cef4a7d745f d674c65ff436622c0db14b01fd52ee600ba21c101dc16a680d75cc1fa645c590),
      "unsafe_collection", "Intentional forbidden push-argument absence; no push performed."},
     {~s|test "recovery alone constructs exact force-with-lease after separate receipt approval"|,
      ~w(ab0cf70705a54be2784fa2157c953743ccb81021149a84cc7608903095957151), "unsafe_collection",
      "Intentional exclusion of recovery-only arguments in ordinary modes."}
   ]},
  {"test/crosswake/shell/diagnostic_export_test.exs", "Crosswake.Shell.DiagnosticExportTest",
   [
     {~s|describe "to_map/1"/test "stringifies atom values and rejects nils"|,
      ~w(71ce67f6dac1e22b5908337867ba3bb9ef4c9498bffdd9f97d4545700c98344a c3e43112f568e64621818e15cb178b228c697a2ccc4b39c1896fa6ac4122fe9f),
      "unsafe_collection",
      "Intentional exclusion of nil/atom export values; exact two properties retained."}
   ]},
  {"test/crosswake/support_matrix/support_matrix_test.exs", "Crosswake.SupportMatrixTest",
   [
     {~s|test "commerce corridor support truth stays provider-neutral and uses canonical denial taxonomy"|,
      ~w(b5b9b6f2701235f0f4f5c4807269f335eb1a4f8e77eba1ea7c105820d995c27d), "unsafe_collection",
      "Intentional provider-specific prerequisite exclusion."},
     {~s|test "release policy stays hybrid instead of repo-wide lockstep versioning"|,
      ~w(28a76cc0410c2a2a21ce45c140d946b77cec4c1117819a64caeeb38f7b27ccfa 2e3687a97d3bfd533b5b7d80f3852a7b65b442c80434fb3a0a2e9bbb3038f14c),
      "unsafe_collection",
      "Existing filtered release-policy properties; no support claim changed."}
   ]},
  {"test/mix/tasks/crosswake_gen_proof_lane_test.exs", "Mix.Tasks.Crosswake.Gen.ProofLaneTest",
   [
     {~s|test "check and diff are byte-for-byte read-only and diff reports only safe sorted statuses"|,
      ~w(d3bc002f9f39d003b1a1c0dde1cdfd1b101c3c544c00e4e847d8ef48c1aa0ca1 d995f35c349c3fc3e76b3733a2ffa21063af2a0286209ee3a0ca76df5ef9ea2c),
      "unsafe_collection", "Existing status/privacy projections over diff results."},
     {~s|test "concurrent generators preserve host-owned destinations"|,
      ~w(0473c66cb5a42dc9f259ffc5c40d79d141b93d6f56a24c498a3d2a42e8602700), "unsafe_collection",
      "Existing task outcomes projection; concurrency setup cardinality not inferred."},
     {~s|test "generator actions ignore a poisoned former shared helper cache"|,
      ~w(d3966e9430e280f53e0634994fc8c87604df71f3226d8034c9d4739054bf94fd), "unsafe_collection",
      "Existing generator diff projection; exact occurrence retained."}
   ]},
  {"test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs",
   "Mix.Tasks.Crosswake.ProofLane.PhysicalIphoneTest",
   [
     {~s|test "a complete owner-disjoint report joins only after ready preflight"|,
      ~w(4bd8c0c41fe790e76fa6f320a12f139726b0c4585d2f210d19d899ab806a53ba), "unsafe_collection",
      "Existing synthetic report assertions; no physical-device claim."},
     {~s|test "readiness JSON returns all stable prerequisite categories without running reports"|,
      ~w(7a17837512eb8d5df09af840be60bb14fe6fb47ee7c4e46037649c0ff58d1ec6), "unsafe_collection",
      "Existing readiness projection; does not run a device report."}
   ]},
  {"test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs",
   "Mix.Tasks.Crosswake.ProofLane.VerifyTwinTest",
   [
     {~s|test "backend environment is closed and flag names are gated"|,
      ~w(e278dcee24c2144f4ec4dc1cd1e0a37b6668aebd3968c184f674067c02752ee5), "unsafe_collection",
      "Intentional forbidden environment-key absence."}
   ]},
  {"test/mix/tasks/crosswake_release_status_test.exs", "Mix.Tasks.Crosswake.Release.StatusTest",
   [
     {~s|test "all-ok live probes produce one ok presence check, no unverifiable check, and exit 0"|,
      ~w(a50c72ae42785293705a6dff29fff57d20bb11cc6a05b41e5c778aaf449aa12c), "unsafe_collection",
      "Intentional absence of unverifiable registry diagnostic."},
     {~s|test "an unreachable registry is never laundered into the bootstrap carve-out"|,
      ~w(10557c114e7f6d89b2c1e8da0d05691f89f6a03e79345ef67c1b6198243ed0b5), "unsafe_collection",
      "Intentional exclusion of bootstrap laundering diagnostics."},
     {~s|test "an unreleased bootstrap companion is advisory, not fatal"|,
      ~w(a50c72ae42785293705a6dff29fff57d20bb11cc6a05b41e5c778aaf449aa12c), "unsafe_collection",
      "Intentional absence diagnostic in a distinct bootstrap context."},
     {~s|test "live probes split definite absence from unverifiable, and both fail closed (D-18)"|,
      ~w(7e67b27db47191f0e6871b476b4cbe659a35d9ffe9a522b90f6584912eb2d2ad), "unsafe_collection",
      "Intentional absence of unrelated registry evidence."}
   ]}
]

for {file, module, rows} <- groups,
    {context, expressions, category, reason} <- rows,
    expression <- expressions do
  %{
    file: file,
    context: "module " <> module <> "/" <> context,
    expression: expression,
    category: category,
    count: 1,
    reason: reason
  }
end
