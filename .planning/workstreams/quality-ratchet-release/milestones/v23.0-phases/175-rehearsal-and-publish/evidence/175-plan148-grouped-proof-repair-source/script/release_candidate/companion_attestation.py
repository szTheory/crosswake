#!/usr/bin/env python3
"""Read-only preparation for the planned companion receipt; no release authority."""
import hashlib
import json
import os
import pathlib
import re
import subprocess
import urllib.error
import urllib.request

REPOSITORY = "szTheory/crosswake"


def gh(path):
    return json.loads(subprocess.check_output(["gh", "api", f"repos/{REPOSITORY}/{path}"], timeout=30))


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def validate(candidate, ci, hex_run, ci_receipt, rehearsal, rows, selectors):
    head, tree, base, pr, ci_id, hex_id, version = selectors
    assert candidate == {"pr": pr, "base_oid": base, "head_oid": head, "tree_oid": tree, "ci_run_id": ci_id}
    for run, number, name in [(ci, ci_id, "Crosswake CI"), (hex_run, hex_id, "Hex candidate rehearsal and recovery")]:
        assert run["id"] == number and run["head_sha"] == head
        assert run["status"] == "completed" and run["conclusion"] == "success" and run["name"] == name
    assert hex_run["event"] == "workflow_dispatch"
    assert ci_receipt["state"] == "PASS" and ci_receipt["head"] == head and ci_receipt["tree"] == tree
    assert ci_receipt["base"] == base and int(ci_receipt["run_id"]) == ci_id
    assert ci_receipt["external_state_changed"] is False
    assert rehearsal["requested_head"] == head and rehearsal["observed_head"] == head
    assert rehearsal["observed_tree"] == tree and rehearsal["observed_base"] == base
    assert int(rehearsal["run_id"]) == hex_id and rehearsal["run_head"] == head
    assert rehearsal["run_conclusion"] == "success" and rehearsal["external_state_changed"] is False
    assert rehearsal["package_count"] == 6
    assert [row["package"] for row in rows] == ["crosswake", "crosswake_rulestead", "crosswake_rindle", "crosswake_sigra", "crosswake_chimeway", "crosswake_threadline"]
    selected = [row for row in rows if row["package"] == "crosswake_chimeway"]
    assert len(selected) == 1
    row = selected[0]
    assert row["version"] == version and row["candidate_ref"] == head
    for key in ["outer_checksum", "metadata_digest", "payload_digest"]:
        assert re.fullmatch(r"[0-9a-f]{64}", row[key])
    return {key: row[key] for key in ["package", "version", "candidate_ref", "outer_checksum", "metadata_digest", "payload_digest"]} | {"run_id": hex_id}


def main():
    head, tree, base = [os.environ[key] for key in ["CANDIDATE_HEAD", "CANDIDATE_TREE", "CANDIDATE_BASE"]]
    for value in [head, tree, base]:
        assert re.fullmatch(r"[0-9a-f]{40}", value)
    version = os.environ["CANDIDATE_VERSION"]
    assert re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version)
    pr, ci_id, hex_id = [int(os.environ[key]) for key in ["CANDIDATE_PR", "CANDIDATE_CI_RUN_ID", "HEX_RUN_ID"]]
    assert pr > 0 and ci_id > 0 and hex_id > 0
    root = pathlib.Path(os.environ["OUTPUT_DIR"])
    assert not root.exists()
    root.mkdir(mode=0o700)
    info = gh(f"pulls/{pr}")
    assert info["state"] == "open" and info["draft"] is False
    assert info["head"]["sha"] == head and info["base"]["sha"] == base and info["base"]["ref"] == "main"
    assert gh(f"git/commits/{head}")["tree"]["sha"] == tree
    assert gh("git/ref/heads/main")["object"]["sha"] == base
    candidate = {"pr": pr, "base_oid": base, "head_oid": head, "tree_oid": tree, "ci_run_id": ci_id}
    ci, hex_run = gh(f"actions/runs/{ci_id}"), gh(f"actions/runs/{hex_id}")
    for run, number, name in [(ci, ci_id, "Crosswake CI"), (hex_run, hex_id, "Hex candidate rehearsal and recovery")]:
        assert run["id"] == number and run["head_sha"] == head and run["conclusion"] == "success" and run["status"] == "completed" and run["name"] == name
    for number, name, directory in [(ci_id, f"phase168-candidate-ci-{head}", "ci"), (hex_id, "candidate-rehearsal-hex", "hex")]:
        subprocess.run(["gh", "run", "download", str(number), "--repo", REPOSITORY, "--name", name, "--dir", str(root / directory)], check=True, timeout=120)
    ci_receipt = json.loads((root / "ci/release-candidate-ci-receipt.json").read_bytes())
    rehearsal = json.loads((root / "hex/rehearsal.json").read_bytes())
    manifest_bytes = (root / "hex/packages/artifacts.json").read_bytes()
    assert hashlib.sha256(manifest_bytes).hexdigest() == rehearsal["package_artifacts_sha256"]
    assert hashlib.sha256(pathlib.Path(".github/workflows/hex-publish.yml").read_bytes()).hexdigest() == rehearsal["workflow_sha256"]
    row = validate(candidate, ci, hex_run, ci_receipt, rehearsal, json.loads(manifest_bytes), (head, tree, base, pr, ci_id, hex_id, version))
    declared = pathlib.Path("packages/crosswake_chimeway/mix.exs").read_text()
    assert re.search(r'@version\s+"([^"]+)"', declared).group(1) == version
    try:
        response = urllib.request.urlopen(f"https://hex.pm/api/packages/crosswake_chimeway/releases/{version}", timeout=30)
    except urllib.error.HTTPError as error:
        assert error.code == 404
    else:
        response.close()
        raise AssertionError("companion target is already public")
    projected_ci = {"run_id": ci_id, "head_oid": head, "conclusion": "success"}
    projected_hex = {"run_id": hex_id, "head_oid": head, "package": "crosswake_chimeway", "version": version, "external_state_changed": False, "target_absent": True}
    facts = {"candidate": candidate, "ci": projected_ci, "hex_rehearsal": projected_hex, "package_row": row}
    sources = {}
    for key, value in facts.items():
        name = key.replace("_", "-") + ".json"
        data = canonical(value)
        (root / name).write_text(data)
        sources[key] = {"path": name, "bytes": data}
    payload = {"package": "crosswake_chimeway", "version": version, **facts, "sources": sources}
    (root / "input.json").write_text(canonical(payload))
    # Re-read mutable candidate pointers after acquisition; never preserve account fields.
    latest = gh(f"pulls/{pr}")
    assert latest["state"] == "open" and latest["head"]["sha"] == head and latest["base"]["sha"] == base
    assert gh("git/ref/heads/main")["object"]["sha"] == base


if __name__ == "__main__":
    try:
        main()
    except Exception:
        raise SystemExit("Companion receipt blocked: source, run, artifact, or target validation failed.")
