# 16-02 Summary

Implemented manifest-first deep-link entry enforcement across Elixir and both checked-in native shells.

Key outcomes:
- Added the shared denial reason `external_entry_denied`.
- Enforced external-entry approval for inbound activation sources while preserving `inactive_route` for truly unknown routes.
- Brought Elixir and iOS path matching up to Android’s segment-aware `/.../:id` behavior.
- Updated iOS and Android activation tests to cover dynamic segments and entry-denied routes.

Verification:
- `mix test test/crosswake/shell/activation_test.exs`
- `xcodebuild test -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'platform=iOS Simulator,name=iPhone 17'`
- Android source updated, but local Android test execution was blocked by a missing JDK.
