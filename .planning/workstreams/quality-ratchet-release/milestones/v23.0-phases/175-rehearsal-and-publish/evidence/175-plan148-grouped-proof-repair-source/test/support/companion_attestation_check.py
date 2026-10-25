import copy
import importlib.util
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("attestation", ROOT / "script/release_candidate/companion_attestation.py")
a = importlib.util.module_from_spec(spec)
spec.loader.exec_module(a)


class AttestationTest(unittest.TestCase):
    def fixture(self):
        head, tree, base = "a" * 40, "b" * 40, "c" * 40
        candidate = dict(pr=115, base_oid=base, head_oid=head, tree_oid=tree, ci_run_id=100)
        ci = dict(id=100, head_sha=head, status="completed", conclusion="success", name="Crosswake CI")
        hex_run = dict(ci, id=200, name="Hex candidate rehearsal and recovery", event="workflow_dispatch")
        receipt = dict(state="PASS", head=head, tree=tree, base=base, run_id="100", external_state_changed=False)
        rehearsal = dict(requested_head=head, observed_head=head, observed_tree=tree, observed_base=base,
                         run_id="200", run_head=head, run_conclusion="success", external_state_changed=False, package_count=6)
        rows = [dict(package=name, version="0.1.1", candidate_ref=head, outer_checksum="d"*64,
                     metadata_digest="e"*64, payload_digest="f"*64) for name in
                ["crosswake", "crosswake_rulestead", "crosswake_rindle", "crosswake_sigra", "crosswake_chimeway", "crosswake_threadline"]]
        return [candidate, ci, hex_run, receipt, rehearsal, rows, (head, tree, base, 115, 100, 200, "0.1.1")]

    def test_exact_sources_pass(self):
        row = a.validate(*self.fixture())
        self.assertEqual(row["package"], "crosswake_chimeway")
        self.assertEqual(row["run_id"], 200)

    def test_mutated_sources_fail(self):
        for index, key, value in [(0,"head_oid","9"*40),(1,"conclusion","failure"),
                                  (2,"event","push"),(3,"base","9"*40),
                                  (4,"external_state_changed",True),(4,"package_count",5)]:
            with self.subTest(index=index, key=key):
                facts = self.fixture();facts[index][key] = value
                with self.assertRaises(AssertionError): a.validate(*facts)

    def test_other_package_missing_row_or_ref_cannot_mint_receipt(self):
        for key, value in [("candidate_ref","9"*40),("version","0.9.0"),("payload_digest","bad"),("package","other")]:
            with self.subTest(key=key):
                facts=self.fixture(); facts[5][4][key]=value
                with self.assertRaises(AssertionError): a.validate(*facts)
        facts=self.fixture();facts[5].pop()
        with self.assertRaises(AssertionError): a.validate(*facts)

    def test_canonical_source_bytes_match_release_guard_projection(self):
        value=dict(run_id=100,head_oid="a"*40,conclusion="success")
        self.assertEqual(a.canonical(value), '{"conclusion":"success","head_oid":"' + "a"*40 + '","run_id":100}')


if __name__ == "__main__": unittest.main()
