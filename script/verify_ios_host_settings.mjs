import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { realpathSync } from 'node:fs';
import { runCli, verifyIosHostSettings } from '../priv/crosswake/verify_ios_host_settings.mjs';

export { verifyIosHostSettings };

const argumentPath = process.argv[1] && path.resolve(process.argv[1]);
const modulePath = path.resolve(fileURLToPath(import.meta.url));
let isDirectEntrypoint = argumentPath === modulePath;
try {
  isDirectEntrypoint = argumentPath && realpathSync(argumentPath) === realpathSync(modulePath);
} catch {}
if (isDirectEntrypoint) {
  runCli();
}
