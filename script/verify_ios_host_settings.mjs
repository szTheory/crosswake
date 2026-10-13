import path from 'node:path';
import { runCli, verifyIosHostSettings } from '../priv/crosswake/verify_ios_host_settings.mjs';

export { verifyIosHostSettings };

if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname)) {
  runCli();
}
