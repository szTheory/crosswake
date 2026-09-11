import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import test from 'node:test';

const configUrl = pathToFileURL('examples/phoenix_host/playwright.config.ts').href;
const inspectedFields = `
  const config = (await import(${JSON.stringify(configUrl)})).default;
  console.log(JSON.stringify({
    retries: config.retries,
    workers: config.workers,
    reporter: config.reporter,
    outputDir: config.outputDir,
    snapshotPathTemplate: config.snapshotPathTemplate,
    reuseExistingServer: config.webServer.reuseExistingServer,
    trace: config.use.trace,
    serviceWorkers: config.use.serviceWorkers,
    projectNames: config.projects.map((project) => project.name),
  }));
`;

function evaluateConfig(environment = {}) {
  const env = { ...process.env };
  for (const key of [
    'CI',
    'CROSSWAKE_REPOSITORY_VERIFY',
    'CROSSWAKE_PLAYWRIGHT_REPORT_DIR',
    'CROSSWAKE_PLAYWRIGHT_RESULT_DIR',
    'CROSSWAKE_PLAYWRIGHT_ARTIFACT_DIR',
  ]) delete env[key];
  Object.assign(env, environment);

  const result = spawnSync(
    process.execPath,
    ['--no-warnings', '--experimental-strip-types', '--input-type=module', '--eval', inspectedFields],
    { cwd: process.cwd(), env, encoding: 'utf8' },
  );
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(result.stdout);
}

test('repository mode owns first-attempt server and output state', () => {
  const config = evaluateConfig({
    CI: '1',
    CROSSWAKE_REPOSITORY_VERIFY: '1',
    CROSSWAKE_PLAYWRIGHT_REPORT_DIR: '/invocation/report',
    CROSSWAKE_PLAYWRIGHT_RESULT_DIR: '/invocation/results',
    CROSSWAKE_PLAYWRIGHT_ARTIFACT_DIR: '/invocation/artifacts',
  });

  assert.equal(config.retries, 0);
  assert.equal(config.reuseExistingServer, false);
  assert.deepEqual(config.reporter, [['html', { open: 'never', outputFolder: '/invocation/report' }]]);
  assert.equal(config.outputDir, '/invocation/results');
  assert.equal(config.snapshotPathTemplate, '/invocation/artifacts/{testFilePath}/{arg}{ext}');
  assert.equal(config.workers, 1);
  assert.equal(config.serviceWorkers, 'block');
  assert.equal(config.trace, 'retain-on-failure');
  assert.deepEqual(config.projectNames, ['chromium', 'chromium-light', 'chromium-dark']);
});

test('ordinary local mode preserves zero retries and existing-server reuse', () => {
  const config = evaluateConfig();
  assert.equal(config.retries, 0);
  assert.equal(config.reuseExistingServer, true);
  assert.equal(config.reporter, 'html');
  assert.equal(config.outputDir, undefined);
  assert.equal(config.snapshotPathTemplate, undefined);
  assert.equal(config.trace, 'on-first-retry');
});

test('generic CI mode remains distinct from explicit repository verification', () => {
  const config = evaluateConfig({ CI: '1' });
  assert.equal(config.retries, 2);
  assert.equal(config.reuseExistingServer, false);
  assert.equal(config.reporter, 'html');
  assert.equal(config.outputDir, undefined);
  assert.equal(config.snapshotPathTemplate, undefined);
  assert.equal(config.trace, 'on-first-retry');
});
