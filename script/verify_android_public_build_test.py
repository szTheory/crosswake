#!/usr/bin/env python3
"""Exercise existing release consumer propagation/build boundary without a network."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('verify_android_public_build.sh')


class PublicBuildTest(unittest.TestCase):
    def exercise(self, statuses, gradle_exit=0, version='0.2.10'):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            tools = root / 'bin'
            tools.mkdir()
            project = root / 'generated'
            project.mkdir()
            (root / 'statuses').write_text('\n'.join(statuses) + '\n')
            (tools / 'curl').write_text('''#!/usr/bin/env python3
import os
from pathlib import Path
p=Path(os.environ['FIXTURE_ROOT'])/'statuses'
a=p.read_text().splitlines()
p.write_text('\\n'.join(a[1:])+'\\n')
print(a[0], end='')
''')
            (project / 'gradlew').write_text('''#!/usr/bin/env bash
printf '%s\\n' "$*" >> "$FIXTURE_ROOT/builds"
exit "$FIXTURE_GRADLE_EXIT"
''')
            (tools / 'curl').chmod(0o755)
            env = dict(os.environ, PATH=str(tools) + ':' + os.environ['PATH'],
                       FIXTURE_ROOT=str(root), FIXTURE_GRADLE_EXIT=str(gradle_exit),
                       CROSSWAKE_MAVEN_POLL_ATTEMPTS='3', CROSSWAKE_MAVEN_POLL_DELAY='0')
            result = subprocess.run(['bash', str(SCRIPT), str(project), version],
                                    env=env, capture_output=True, text=True)
            builds = (root / 'builds').read_text().splitlines() if (root / 'builds').exists() else []
            return result, builds

    def test_public_coordinate_then_one_full_build(self):
        result, builds = self.exercise(['200', '200'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(builds, ['build --no-daemon --refresh-dependencies'])

    def test_missing_coordinate_polls_without_building(self):
        result, builds = self.exercise(['404', '404', '200', '200'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(builds), 1)

    def test_build_failure_is_not_retried_or_called_propagation(self):
        result, builds = self.exercise(['200', '200'], 7)
        self.assertEqual(result.returncode, 7)
        self.assertEqual(len(builds), 1)
        self.assertNotIn('timed out', result.stderr)

    def test_timeout_never_builds(self):
        result, builds = self.exercise(['404', '404'] * 3)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(builds, [])

    def test_authorization_error_is_fatal(self):
        result, builds = self.exercise(['403'])
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(builds, [])

    def test_missing_aar_never_builds(self):
        result, builds = self.exercise(['200', '404'] * 3)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(builds, [])

    def test_invalid_version_never_builds(self):
        result, builds = self.exercise([], version='../other')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(builds, [])


if __name__ == '__main__':
    unittest.main()
