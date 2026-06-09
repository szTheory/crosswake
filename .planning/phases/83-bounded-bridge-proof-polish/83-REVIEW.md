---
phase: 83-bounded-bridge-proof-polish
reviewed: 2026-06-08T22:09:37Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex
  - examples/phoenix_host/test/crosswake_example/bridge_proof_live_test.exs
  - examples/phoenix_host/lib/crosswake_example/router.ex
  - examples/QUICK_START.md
  - script/verify_bounded_bridge_proof.sh
findings:
  critical: 1
  warning: 2
  info: 2
  total: 5
status: issues_found
---

# Phase 83: Code Review Report

**Reviewed:** 2026-06-08T22:09:37Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The review covered the implementation of the bounded bridge capability integration, the supporting route configurations, and the documentation. While the routing and shell script verification mechanisms are well structured, there are notable issues within the LiveView implementation. A critical XSS vulnerability exists due to unescaped JSON payload injection within an inline script tag. Furthermore, the test implementation bypasses standard LiveView testing practices, leading to highly brittle assertions. 

## Critical Issues

### CR-01: XSS Vulnerability via Unescaped JSON in Script Tag

**File:** `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex:56`
**Issue:** `Jason.encode!(request)` converts the request map to a JSON string, which is then embedded directly into a `<script>` block via `<%= Phoenix.HTML.raw(...) %>`. Because `Jason.encode!` does not escape HTML control characters like `<` or `/`, any string containing `</script>` within the request payload (such as in the text or URL values) will prematurely terminate the script tag, exposing the application to an XSS vulnerability. Additionally, invoking side-effects by mutating script tags is an anti-pattern in LiveView.
**Fix:** 
Use `push_event/3` to send data securely to the client, and handle the bridge invocation using a LiveView hook. If inline scripts are absolutely necessary, the payload must be appropriately escaped.

Recommended Hook Approach:
```elixir
# In handle_event/3:
def handle_event("share", _params, socket) do
  {:noreply, push_event(socket, "crosswake-bridge", share_request())}
end

# Remove the script block from `render/1` and instead implement a JS hook:
# window.addEventListener("phx:crosswake-bridge", (e) => {
#   const payload = e.detail;
#   if (window.webkit?.messageHandlers?.crosswakeBridge) {
#     window.webkit.messageHandlers.crosswakeBridge.postMessage(payload);
#   } else if (window.crosswakeBridge?.postMessage) {
#     window.crosswakeBridge.postMessage(payload);
#   }
# });
```
Alternatively, if staying with the inline script approach:
```elixir
defp bridge_script(request) do
  payload_json = request |> Jason.encode!() |> String.replace("</", "<\\/")
  
  """
  (() => {
    const payload = #{payload_json};
    // ...
```

## Warnings

### WR-01: Brittle Test Implementation Bypassing LiveView Lifecycle

**File:** `examples/phoenix_host/test/crosswake_example/bridge_proof_live_test.exs:18-20`
**Issue:** The test manually constructs a `%Phoenix.LiveView.Socket{}` struct to call `handle_event/3`, and then manually invokes `BridgeProofLive.render/1` using `Phoenix.HTML.Safe.to_iodata/1`. This brittle approach completely bypasses the standard LiveView lifecycle (`mount`, `handle_params`, etc.) and tightly couples the test to the internal representation of the Socket struct. This will break if the implementation starts relying on other standard socket fields (like `endpoint`) or when LiveView updates its internal representations.
**Fix:** 
Use the standard `Phoenix.LiveViewTest` macros to render and interact with the component.
```elixir
import Phoenix.LiveViewTest

test "renders bridge script on share click", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/bridge-proof")
  
  refute render(view) =~ "crosswake-share-"
  
  html = view |> element("button", "Share") |> render_click()
  
  assert html =~ "crosswake-share-"
  assert html =~ "crosswakeBridge.postMessage"
end
```

### WR-02: Deprecated Helpers Import

**File:** `examples/phoenix_host/test/crosswake_example/bridge_proof_live_test.exs:5`
**Issue:** The `Phoenix.LiveView.Helpers` module is deprecated in LiveView 0.18+ and causes a compiler warning. The functions it provided are now part of `Phoenix.Component`.
**Fix:** Remove the import line, or replace it with `import Phoenix.Component` if needed.

## Info

### IN-01: Documentation Mismatch with UI Implementation

**File:** `examples/QUICK_START.md:52`
**Issue:** The quick start documentation instructs the user to tap a button labeled **"Trigger Native Share"**, but the button rendered in `bridge_proof_live.ex` is simply labeled **"Share"**.
**Fix:** Update the documentation to match the actual UI label.
```markdown
3.  On the **Bridge Proof** page, you should see a button labeled **Share**.
4.  Tap the **Share** button.
```

### IN-02: Volatile Correlation ID Strategy

**File:** `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex:47`
**Issue:** Using `System.unique_integer([:positive])` for generating the correlation ID provides values that reset upon node restarts. While acceptable for a simple proof, it doesn't guarantee true uniqueness across node reboots or in distributed setups.
**Fix:** Consider using a UUID standard for robustness:
```elixir
"correlation_id" => "share-#{Ecto.UUID.generate()}"
```

---

_Reviewed: 2026-06-08T22:09:37Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
