# Continue — Phase 3 / Native Shell Boot And Bounded Bridge

## Last action

Committed and pushed the full Phase 2/3 checkpoint to `origin/main` at `24c8389`, then repaired Xcode first-launch state with `xcodebuild -runFirstLaunch`. Re-running `script/verify_generated_ios_shell.sh` now fails because no iPhone simulator runtimes are installed, while `script/verify_generated_android_shell.sh` still fails at `:app:crosswakeApi34Setup` when the managed emulator closes during snapshot creation.

## Next action

On a new machine with more free disk, clone `https://github.com/szTheory/crosswake.git`, run `xcodebuild -runFirstLaunch`, install at least one iPhone simulator runtime in `Xcode > Settings > Components`, verify `xcrun simctl list runtimes` shows a runtime, then run:

```bash
mix test test/crosswake/bridge/contract_test.exs \
  test/crosswake/bridge/registry_test.exs \
  test/crosswake/compatibility/compatibility_test.exs \
  test/crosswake/doctor/doctor_test.exs \
  test/mix/tasks/crosswake_doctor_test.exs \
  test/mix/tasks/crosswake_gen_shell_test.exs
./script/verify_generated_ios_shell.sh
./script/verify_generated_android_shell.sh
```

## Why

The repo-side Phase 3 code and targeted tests are already in good shape. The remaining work is host proof: iOS needs an installed simulator runtime, and Android needs a machine where the emulator-managed device setup can complete reliably.

## Open threads

- This machine only had about `7.7Gi` free after the Xcode first-launch repair; that is likely too tight for simulator and emulator assets.
- `~/Library/Caches` had several large reclaimable entries on the old machine, but no cleanup was committed because the better path is finishing proof on a cleaner machine.
- The portable backup bundle `crosswake-checkpoint-24c8389.bundle` exists only on the old machine and was not pushed; the GitHub repo is now the canonical handoff.

## Do not

- Do NOT mark Phase 3 complete until both `script/verify_generated_ios_shell.sh` and `script/verify_generated_android_shell.sh` pass on real host-owned generated projects.
- Do NOT weaken the current `verification required` doctor/docs posture just to get around missing local toolchains.
- Do NOT spend time debugging old CoreSimulator plug-in errors first; `xcodebuild -runFirstLaunch` already cleared that class of failure, and the current iOS blocker is now simply missing simulator runtimes.
