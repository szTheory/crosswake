#!/usr/bin/env python3
"""Hermetic selftest of script/android_foreign_promotion.sh.

No network and no real GitHub: `gh` is a fake that answers by matching its argv against fixture
rules, and `git hash-object` answers with a fixture blob (every other git call passes through to
the real git by absolute path). Artifact zips are built with zipfile. One test per counting rule
and one per UNVERIFIED reason, each asserting the exact output line and exit code.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

SCRIPT = Path(__file__).with_name('android_foreign_promotion.sh')
CURRENT_BLOB = 'c' * 40
OLD_BLOB = 'd' * 40
JOB = 'android-foreign-host'
ARTIFACT = 'android-foreign-host-evidence'
LEAK = 'SECRET_GH_STDERR ghp_leakcheck'
REAL_GIT = shutil.which('git')

FAKE_GH = '''#!{python}
import json, os, sys
root = os.environ['FIXTURE_ROOT']
joined = ' '.join(sys.argv[1:])
with open(os.path.join(root, 'gh_calls.log'), 'a') as log:
    log.write(joined + '\\n')
with open(os.path.join(root, 'gh_rules.json')) as handle:
    rules = json.load(handle)
for rule in rules:
    if rule['match'] in joined:
        if rule.get('fail'):
            sys.stderr.write(rule['stderr'] + '\\n')
            sys.exit(1)
        if rule.get('file'):
            with open(os.path.join(root, rule['file']), 'rb') as handle:
                sys.stdout.buffer.write(handle.read())
        else:
            sys.stdout.write(rule['stdout'])
        sys.exit(0)
with open(os.path.join(root, 'unmapped'), 'a') as handle:
    handle.write(joined + '\\n')
sys.stderr.write('unmapped fake gh call\\n')
sys.exit(99)
'''

FAKE_GIT = '''#!{python}
import os, sys
if sys.argv[1:2] == ['hash-object']:
    sys.stdout.write(os.environ['FIXTURE_BLOB'] + '\\n')
    sys.exit(0)
os.execv({real_git!r}, [{real_git!r}] + sys.argv[1:])
'''


def evidence(tests=2, control_reason='could_not_find', blob=CURRENT_BLOB, result='PASS'):
    return {'schema': 1, 'target_version': '0.2.11', 'tests': tests,
            'control_reason': control_reason, 'script_blob': blob, 'result': result,
            'generator': 'published', 'reason': ''}


def run_spec(run_id, sha_char, job='success', artifact='default', status='completed'):
    """job: a conclusion string or None (job absent). artifact: 'default' good evidence,
    None (no artifact), a dict (evidence JSON) or a str (raw file text)."""
    return {'id': run_id, 'sha': sha_char * 40, 'job': job, 'artifact': artifact, 'status': status}


class Fixture:
    def __init__(self, root, runs):
        self.root = Path(root)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.runs = runs
        self.rules = []
        self.zip_count = 0
        self._write_tools()
        self._build_rules()

    def _write_tools(self):
        for name, body in (('gh', FAKE_GH.format(python=sys.executable)),
                           ('git', FAKE_GIT.format(python=sys.executable, real_git=REAL_GIT))):
            path = self.bin / name
            path.write_text(body)
            path.chmod(0o755)

    def _add(self, match, stdout='', **extra):
        self.rules.append({'match': match, 'stdout': stdout, **extra})

    def _build_rules(self):
        self._add('repo view', json.dumps({'nameWithOwner': 'owner/repo'}))
        self._add('workflows/crosswake-ci.yml/runs?event=pull_request', json.dumps({
            'workflow_runs': [{'id': r['id'], 'head_sha': r['sha'], 'status': r['status']}
                              for r in self.runs]}))
        for r in self.runs:
            jobs = [{'name': 'proof-leaf-other', 'conclusion': 'success'}]
            if r['job'] is not None:
                jobs.append({'name': JOB, 'conclusion': r['job']})
            self._add(f"actions/runs/{r['id']}/jobs", json.dumps({'jobs': jobs}))
            artifacts = []
            if r['artifact'] is not None:
                artifacts.append({'id': r['id'] * 10, 'name': ARTIFACT, 'expired': False})
            self._add(f"actions/runs/{r['id']}/artifacts", json.dumps({'artifacts': artifacts}))
            if r['artifact'] is not None:
                payload = evidence() if r['artifact'] == 'default' else r['artifact']
                text = payload if isinstance(payload, str) else json.dumps(payload)
                zip_name = f"artifact-{r['id']}.zip"
                with zipfile.ZipFile(self.root / zip_name, 'w') as archive:
                    archive.writestr('android-foreign-host-evidence.json', text)
                self._add(f"actions/artifacts/{r['id'] * 10}/zip", file=zip_name)

    def fail(self, match):
        """Make the first rule containing `match` exit 1 with leaking stderr text."""
        for rule in self.rules:
            if match in rule['match']:
                rule['fail'] = True
                rule['stderr'] = LEAK
                return
        raise AssertionError(f'no rule matches {match}')

    def commit(self):
        (self.root / 'gh_rules.json').write_text(json.dumps(self.rules))

    def calls(self):
        log = self.root / 'gh_calls.log'
        return log.read_text() if log.exists() else ''

    def env(self, path):
        return {'PATH': path, 'HOME': str(self.root / 'home'), 'FIXTURE_ROOT': str(self.root),
                'FIXTURE_BLOB': CURRENT_BLOB, 'LANG': 'C'}


class PromotionTest(unittest.TestCase):
    def execute(self, runs, mutate=None, reduced_path=False):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = Fixture(tmp, runs)
            if mutate:
                mutate(fixture)
            fixture.commit()
            if reduced_path:
                path = str(fixture.bin)
                argv = ['/bin/bash', str(SCRIPT)]
            else:
                path = f"{fixture.bin}{os.pathsep}{os.environ.get('PATH', '/usr/bin:/bin')}"
                argv = ['bash', str(SCRIPT)]
            proc = subprocess.run(argv, env=fixture.env(path), capture_output=True, text=True,
                                  timeout=60, cwd=tmp)
            self.assertFalse((Path(tmp) / 'unmapped').exists(),
                             'the script made a gh call the fixture does not map')
            calls = fixture.calls()
        combined = proc.stdout + proc.stderr
        self.assertNotIn(LEAK, combined)
        self.assertNotIn('ghp_', combined)
        return proc, calls

    def assertLine(self, proc, line, code):
        self.assertEqual((proc.stdout.splitlines(), proc.returncode), ([line], code),
                         msg=proc.stdout + proc.stderr)

    def derived(self, count, head):
        eligible = 'yes' if count >= 2 else 'no'
        return (f'android_foreign: clean_runs={count}/2 eligible={eligible} head={head} '
                'ci_ran_on=synthetic_merge')

    # 1
    def test_two_clean_runs_with_distinct_heads_are_eligible(self):
        runs = [run_spec(101, 'a'), run_spec(102, 'b'), run_spec(103, 'e')]
        proc, calls = self.execute(runs)
        self.assertLine(proc, 'android_foreign: clean_runs=2/2 eligible=yes head=' + 'a' * 40
                        + ' ci_ran_on=synthetic_merge', 0)
        self.assertIn('actions/runs/102/', calls)
        self.assertNotIn('actions/runs/103/', calls, 'reading must stop at two clean runs')

    # 2
    def test_newest_failed_run_gives_zero(self):
        runs = [run_spec(101, 'a', job='failure', artifact=None), run_spec(102, 'b'),
                run_spec(103, 'e')]
        proc, _ = self.execute(runs)
        self.assertLine(proc, self.derived(0, 'none'), 0)

    # 3
    def test_skipped_run_neither_counts_nor_resets(self):
        runs = [run_spec(101, 'a'), run_spec(102, 'b', job='skipped', artifact=None),
                run_spec(103, 'e')]
        proc, _ = self.execute(runs)
        self.assertLine(proc, self.derived(2, 'a' * 40), 0)

    # 4
    def test_older_script_blob_resets_the_count(self):
        runs = [run_spec(101, 'a'), run_spec(102, 'b', artifact=evidence(blob=OLD_BLOB)),
                run_spec(103, 'e')]
        proc, _ = self.execute(runs)
        self.assertLine(proc, self.derived(1, 'a' * 40), 0)

    # 5
    def test_two_clean_runs_on_one_head_count_once(self):
        runs = [run_spec(101, 'a'), run_spec(102, 'a')]
        proc, _ = self.execute(runs)
        self.assertLine(proc, self.derived(1, 'a' * 40), 0)

    # 6
    def test_inconclusive_control_stops_the_count(self):
        runs = [run_spec(101, 'a', artifact=evidence(control_reason='control_inconclusive')),
                run_spec(102, 'b'), run_spec(103, 'e')]
        proc, _ = self.execute(runs)
        self.assertLine(proc, self.derived(0, 'none'), 0)

    # 7
    def test_run_without_the_job_is_ignored(self):
        runs = [run_spec(101, 'a', job=None, artifact=None), run_spec(102, 'b'),
                run_spec(103, 'e')]
        proc, _ = self.execute(runs)
        self.assertLine(proc, self.derived(2, 'b' * 40), 0)

    # 8
    def test_missing_jq_and_unzip_is_tool_unavailable(self):
        proc, calls = self.execute([run_spec(101, 'a')], reduced_path=True)
        self.assertLine(proc, 'android_foreign: UNVERIFIED tool_unavailable', 2)
        self.assertEqual(calls, '', 'the tool check must run before any gh call')

    # 9
    def test_repo_view_failure_is_repo_unreadable(self):
        proc, _ = self.execute([run_spec(101, 'a')], mutate=lambda f: f.fail('repo view'))
        self.assertLine(proc, 'android_foreign: UNVERIFIED repo_unreadable', 2)

    # 10
    def test_run_listing_failure_is_runs_unreadable(self):
        proc, _ = self.execute([run_spec(101, 'a')],
                               mutate=lambda f: f.fail('workflows/crosswake-ci.yml/runs'))
        self.assertLine(proc, 'android_foreign: UNVERIFIED runs_unreadable', 2)

    # 11
    def test_jobs_read_failure_is_jobs_unreadable(self):
        proc, _ = self.execute([run_spec(101, 'a')],
                               mutate=lambda f: f.fail('actions/runs/101/jobs'))
        self.assertLine(proc, 'android_foreign: UNVERIFIED jobs_unreadable', 2)

    # 12
    def test_artifact_download_failure_is_artifact_unreadable(self):
        proc, _ = self.execute([run_spec(101, 'a')],
                               mutate=lambda f: f.fail('actions/artifacts/1010/zip'))
        self.assertLine(proc, 'android_foreign: UNVERIFIED artifact_unreadable', 2)

    # 13
    def test_non_json_evidence_is_evidence_unparseable(self):
        proc, _ = self.execute([run_spec(101, 'a', artifact='this is not json')])
        self.assertLine(proc, 'android_foreign: UNVERIFIED evidence_unparseable', 2)


if __name__ == '__main__':
    unittest.main()
