/* Unit tests for the library-owned bridge hook.
 *
 * Node's built-in test runner and a hand-stubbed global object — no test framework
 * dependency, no browser, no build step. Run with:
 *
 *     node --test test/js/
 */

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

import {
  ACK_EVENT,
  BridgeSession,
  CrosswakeBridge,
  DISPATCH_EVENT,
  DEFAULT_REPLY_TIMEOUT_MS,
  LANDING_PAD,
  MOMENT_NO_TRANSPORT,
  MOMENT_REPLY_TIMEOUT,
  MOMENT_TRANSPORT_ERROR,
  REPLY_EVENT,
  UNREACHABLE_EVENT,
  __resetOwner,
  bridgeFacts,
  findNavigationTransport,
  findTransport,
  NAVIGATION_EVENT,
  navigationDelivery
} from "../../priv/static/crosswake.esm.js";

const HOOK_SOURCE = new URL("../../priv/static/crosswake.esm.js", import.meta.url);
const PACKAGE_JSON = new URL("../../package.json", import.meta.url);

// --- stubs -----------------------------------------------------------------

function envelope(overrides) {
  return Object.assign(
    {
      protocol: "crosswake.bridge",
      version: "1.1.0",
      command: "haptics.impact",
      capability: "haptics",
      route_id: "saas-approval",
      active_route_id: "saas-approval",
      origin: "https://app.example.com",
      native_runtime_version: "1.0.0",
      correlation_id: "cwbridge-e1-abc",
      capabilities: { haptics: "1.0.0" },
      installed_packs: {},
      payload: { style: "light" }
    },
    overrides || {}
  );
}

/** The iOS message-handler transport: a real, callable post method. */
function iosScope(trace) {
  return {
    webkit: {
      messageHandlers: {
        crosswakeBridge: {
          postMessage(body) {
            trace.posts.push({ via: "webkit", body: body });
          }
        }
      }
    }
  };
}

/*
 * The D-35 hazard, verbatim: on iOS the shell injects `window.crosswakeBridge` at
 * document start as a facts-only bag with NO post method. Every property read and
 * every call is recorded so a test can assert the hook touched nothing callable.
 */
function factsOnlyScope(trace) {
  const facts = {
    capabilities: { haptics: "1.0.0" },
    threadId: "thread-1"
  };

  return {
    crosswakeBridge: new Proxy(facts, {
      get(target, property) {
        trace.reads.push(String(property));
        const value = target[property];
        if (typeof value === "function") {
          return (...args) => {
            trace.calls.push(String(property));
            return value.apply(target, args);
          };
        }
        return value;
      }
    })
  };
}

/** The Android shape: an injected global that IS a transport. */
function androidScope(trace) {
  return {
    crosswakeBridge: {
      capabilities: { haptics: "1.0.0" },
      threadId: "thread-1",
      postMessage(body) {
        trace.posts.push({ via: "injected", body: body });
      }
    }
  };
}

function newTrace() {
  return { posts: [], pushed: [], reads: [], calls: [], order: [] };
}

function newSession(scope, trace, timerOverrides) {
  const timers = timerOverrides || {};
  return new BridgeSession({
    scope: scope,
    element: { dataset: {} },
    pushEvent: (event, payload) => {
      trace.pushed.push({ event: event, payload: payload });
      trace.order.push("push:" + event);
    },
    setTimeout: timers.setTimeout || ((fn, ms) => ({ fn: fn, ms: ms })),
    clearTimeout: timers.clearTimeout || (() => {})
  });
}

function pushedEvents(trace) {
  return trace.pushed.map((entry) => entry.event);
}

function firstPush(trace, event) {
  return trace.pushed.find((entry) => entry.event === event);
}

function navigationEnvelope(overrides) {
  return Object.assign(
    {
      protocol: "crosswake.navigation_transition",
      version: "1.0.0",
      transition_id: "nav-0123456789abcdef",
      kind: "push_navigate",
      route_id: "route-0123456789abcdef"
    },
    overrides || {}
  );
}

// --- navigation transition transport (D-04 / D-06) ------------------------

test("navigation posts canonical JSON only to the dedicated iOS handler", () => {
  const trace = newTrace();
  const scope = {
    webkit: {
      messageHandlers: {
        crosswakeNavigation: {
          postMessage(body) {
            trace.posts.push({ via: "navigation", body });
          }
        },
        crosswakeBridge: {
          postMessage() {
            trace.posts.push({ via: "bridge" });
          }
        }
      }
    }
  };

  assert.equal(navigationDelivery(scope, navigationEnvelope()), true);
  assert.deepEqual(trace.posts, [
    { via: "navigation", body: JSON.stringify(navigationEnvelope()) }
  ]);
});

test("navigation delivery fails closed for malformed, missing, or throwing handlers", () => {
  assert.equal(navigationDelivery({}, navigationEnvelope()), false);
  assert.equal(navigationDelivery({}, navigationEnvelope({ payload: {} })), false);
  assert.equal(findNavigationTransport({ crosswakeBridge: { postMessage() {} } }), null);

  const scope = {
    webkit: {
      messageHandlers: {
        crosswakeNavigation: {
          postMessage() {
            throw new Error("gone");
          }
        }
      }
    }
  };

  assert.equal(navigationDelivery(scope, navigationEnvelope()), false);
});

test("navigation delivery does not accept inherited envelope fields", () => {
  const inherited = navigationEnvelope();
  const payload = Object.create(inherited);
  payload.protocol = inherited.protocol;

  assert.equal(navigationDelivery({}, payload), false);
});

// --- transport selection (D-35 / T-154-24) ---------------------------------

test("posts through the iOS message handler when it exposes a callable post method", () => {
  const trace = newTrace();
  const session = newSession(iosScope(trace), trace);

  session.dispatch(envelope());

  assert.equal(trace.posts.length, 1);
  assert.equal(trace.posts[0].via, "webkit");
  assert.deepEqual(JSON.parse(trace.posts[0].body), envelope());
});

test("a facts-only injected global is never called and yields the unreachable fact", () => {
  const trace = newTrace();
  const session = newSession(factsOnlyScope(trace), trace);

  session.dispatch(envelope());

  assert.deepEqual(trace.calls, [], "the hook must not invoke anything on the facts bag");
  assert.deepEqual(trace.posts, [], "the hook must not post into the void");

  const unreachable = firstPush(trace, UNREACHABLE_EVENT);
  assert.ok(unreachable, "expected the unreachable fact");
  assert.equal(unreachable.payload.moment, MOMENT_NO_TRANSPORT);
});

test("findTransport returns null for a facts-only bag and the bag stays readable as facts", () => {
  const trace = newTrace();
  const scope = factsOnlyScope(trace);

  assert.equal(findTransport(scope), null);
  assert.deepEqual(bridgeFacts(scope), {
    capabilities: { haptics: "1.0.0" },
    threadId: "thread-1"
  });
});

test("posts through the injected global when it exposes a callable post method", () => {
  const trace = newTrace();
  const session = newSession(androidScope(trace), trace);

  session.dispatch(envelope());

  assert.equal(trace.posts.length, 1);
  assert.equal(trace.posts[0].via, "injected");
});

test("the message-handler path wins when both transports are present", () => {
  const trace = newTrace();
  const scope = Object.assign({}, androidScope(trace), iosScope(trace));
  const session = newSession(scope, trace);

  session.dispatch(envelope());

  assert.equal(trace.posts.length, 1);
  assert.equal(trace.posts[0].via, "webkit");
});

test("with no transport at all the hook posts nothing and reports the no_transport moment", () => {
  const trace = newTrace();
  const session = newSession({}, trace);

  session.dispatch(envelope());

  assert.deepEqual(trace.posts, []);
  assert.deepEqual(pushedEvents(trace), [ACK_EVENT, UNREACHABLE_EVENT]);
  assert.equal(firstPush(trace, UNREACHABLE_EVENT).payload.moment, MOMENT_NO_TRANSPORT);
});

test("a throwing transport reports the transport_error moment", () => {
  const trace = newTrace();
  const scope = {
    crosswakeBridge: {
      postMessage() {
        throw new Error("shell went away");
      }
    }
  };
  const session = newSession(scope, trace);

  session.dispatch(envelope());

  assert.equal(firstPush(trace, UNREACHABLE_EVENT).payload.moment, MOMENT_TRANSPORT_ERROR);
});

// --- ack before transport (D-36) -------------------------------------------

test("the ack is emitted before any transport lookup, for every dispatch", () => {
  const trace = newTrace();
  const base = iosScope(trace);

  // A getter records the exact moment the transport lookup reads `webkit`.
  const scope = {};
  Object.defineProperty(scope, "webkit", {
    get() {
      trace.order.push("lookup:webkit");
      return base.webkit;
    }
  });

  const session = newSession(scope, trace);
  session.dispatch(envelope());

  assert.deepEqual(trace.order, ["push:" + ACK_EVENT, "lookup:webkit"]);
});

test("the ack is emitted even when there is no transport at all", () => {
  const trace = newTrace();
  const session = newSession({}, trace);

  session.dispatch(envelope());

  assert.equal(pushedEvents(trace)[0], ACK_EVENT);
  assert.equal(firstPush(trace, ACK_EVENT).payload.correlation_id, "cwbridge-e1-abc");
});

// --- facts, never denials (D-14 / T-154-27) --------------------------------

test("the unreachable report carries a moment and nothing denial-shaped", () => {
  const trace = newTrace();
  const session = newSession({}, trace);

  session.dispatch(envelope());

  const payload = firstPush(trace, UNREACHABLE_EVENT).payload;
  assert.deepEqual(Object.keys(payload).sort(), ["correlation_id", "moment"]);
  assert.equal("denial" in payload, false);
  assert.equal("message" in payload, false);
  assert.equal("reason" in payload, false);
});

test("the shipped source contains no denial microcopy", () => {
  const source = readFileSync(HOOK_SOURCE, "utf8");
  const code = source
    .split("\n")
    .filter((line) => !/^\s*(\/\/|\*|\/\*)/.test(line))
    .join("\n");

  assert.equal(/status:\s*"deny"/.test(code), false);
  assert.equal(/reason:/.test(code), false);
});

// --- reply landing pad (D-02 / T-154-28) -----------------------------------

test("the landing pad routes a reply for an in-flight correlation id to the server", () => {
  const trace = newTrace();
  const scope = androidScope(trace);
  const session = newSession(scope, trace);
  session.installLandingPad();

  session.dispatch(envelope());

  const reply = {
    protocol: "crosswake.bridge",
    version: "1.1.0",
    command: "haptics.impact",
    route_id: "saas-approval",
    correlation_id: "cwbridge-e1-abc",
    status: "ok",
    payload: { style: "light" }
  };

  assert.equal(scope.crosswakeBridge[LANDING_PAD](reply), true);

  const routed = firstPush(trace, REPLY_EVENT);
  assert.ok(routed);
  assert.deepEqual(routed.payload, reply);
});

test("the landing pad drops a reply whose correlation id it does not hold", () => {
  const trace = newTrace();
  const scope = androidScope(trace);
  const session = newSession(scope, trace);
  session.installLandingPad();

  session.dispatch(envelope());

  const dropped = scope.crosswakeBridge[LANDING_PAD]({
    correlation_id: "cwbridge-e1-forged",
    status: "ok"
  });

  assert.equal(dropped, false);
  assert.equal(firstPush(trace, REPLY_EVENT), undefined);
});

test("a second reply for the same correlation id is dropped", () => {
  const trace = newTrace();
  const scope = androidScope(trace);
  const session = newSession(scope, trace);
  session.installLandingPad();
  session.dispatch(envelope());

  const reply = { correlation_id: "cwbridge-e1-abc", status: "ok" };
  assert.equal(scope.crosswakeBridge[LANDING_PAD](reply), true);
  assert.equal(scope.crosswakeBridge[LANDING_PAD](reply), false);

  assert.equal(trace.pushed.filter((e) => e.event === REPLY_EVENT).length, 1);
});

test("the landing pad is installed onto the shell-injected namespace without clobbering it", () => {
  const trace = newTrace();
  const scope = factsOnlyScope(trace);
  const session = newSession(scope, trace);

  session.installLandingPad();

  assert.equal(typeof scope.crosswakeBridge[LANDING_PAD], "function");
  assert.deepEqual(scope.crosswakeBridge.capabilities, { haptics: "1.0.0" });
  assert.equal(scope.crosswakeBridge.threadId, "thread-1");
});

// --- the client-side timer (primary half of the two-timer scheme) ----------

test("the client timer fires the unreachable fact with the timeout moment", () => {
  const trace = newTrace();
  const timers = [];
  const session = newSession(androidScope(trace), trace, {
    setTimeout: (fn, ms) => {
      timers.push({ fn: fn, ms: ms });
      return timers.length;
    }
  });

  session.dispatch(envelope());

  assert.equal(timers.length, 1);
  assert.equal(timers[0].ms, DEFAULT_REPLY_TIMEOUT_MS);

  timers[0].fn();

  assert.equal(firstPush(trace, UNREACHABLE_EVENT).payload.moment, MOMENT_REPLY_TIMEOUT);
});

test("a delivered reply cancels the client timer", () => {
  const trace = newTrace();
  const timers = [];
  const cleared = [];
  const scope = androidScope(trace);
  const session = newSession(scope, trace, {
    setTimeout: (fn, ms) => {
      timers.push({ fn: fn, ms: ms });
      return timers.length;
    },
    clearTimeout: (handle) => cleared.push(handle)
  });
  session.installLandingPad();

  session.dispatch(envelope());
  scope.crosswakeBridge[LANDING_PAD]({ correlation_id: "cwbridge-e1-abc", status: "ok" });

  assert.deepEqual(cleared, [1]);

  timers[0].fn();
  assert.equal(firstPush(trace, UNREACHABLE_EVENT), undefined);
});

test("data-crosswake-reply-timeout=\"infinity\" arms no client timer", () => {
  const trace = newTrace();
  const timers = [];
  const session = new BridgeSession({
    scope: androidScope(trace),
    element: { dataset: { crosswakeReplyTimeout: "infinity" } },
    pushEvent: (event, payload) => trace.pushed.push({ event: event, payload: payload }),
    setTimeout: (fn, ms) => {
      timers.push({ fn: fn, ms: ms });
      return timers.length;
    },
    clearTimeout: () => {}
  });

  session.dispatch(envelope());

  assert.deepEqual(timers, []);
});

// --- the single-owner guard (D-39 / T-154-25) ------------------------------

function mountHook(scope, trace, handlers) {
  const hook = Object.create(CrosswakeBridge);
  hook.el = { dataset: {} };
  hook.crosswakeScope = scope;
  hook.pushEvent = (event, payload) => trace.pushed.push({ event: event, payload: payload });
  hook.handleEvent = (event, callback) => handlers.push({ event: event, callback: callback });
  hook.mounted();
  return hook;
}

test("two mounted hook elements produce exactly one post per dispatch", () => {
  __resetOwner();

  const trace = newTrace();
  const scope = androidScope(trace);
  const handlers = [];

  const first = mountHook(scope, trace, handlers);
  const second = mountHook(scope, trace, handlers);

  assert.equal(first.crosswakeOwned, true);
  assert.equal(second.crosswakeOwned, false);

  // LiveView broadcasts a push_event to EVERY registered handler on the page.
  handlers
    .filter((entry) => entry.event === DISPATCH_EVENT)
    .forEach((entry) => entry.callback(envelope()));

  assert.equal(trace.posts.length, 1, "exactly one post reaches the shell");
  assert.equal(trace.pushed.filter((e) => e.event === ACK_EVENT).length, 1);

  first.destroyed();
  second.destroyed();
  __resetOwner();
});

test("two mounted hook elements produce exactly one navigation delivery", () => {
  __resetOwner();

  const trace = newTrace();
  const scope = {
    webkit: {
      messageHandlers: {
        crosswakeNavigation: {
          postMessage(body) {
            trace.posts.push({ via: "navigation", body });
          }
        }
      }
    }
  };
  const handlers = [];
  const first = mountHook(scope, trace, handlers);
  const second = mountHook(scope, trace, handlers);

  handlers
    .filter((entry) => entry.event === NAVIGATION_EVENT)
    .forEach((entry) => entry.callback(navigationEnvelope()));

  assert.equal(trace.posts.length, 1);
  assert.equal(trace.posts[0].via, "navigation");

  first.destroyed();
  second.destroyed();
  __resetOwner();
});

test("ownership is released on destroy so a later mount can take over", () => {
  __resetOwner();

  const trace = newTrace();
  const scope = androidScope(trace);
  const handlers = [];

  const first = mountHook(scope, trace, handlers);
  first.destroyed();

  const second = mountHook(scope, trace, handlers);
  assert.equal(second.crosswakeOwned, true);

  second.destroyed();
  __resetOwner();
});

test("teardown removes the landing pad but leaves the injected facts intact", () => {
  const trace = newTrace();
  const scope = androidScope(trace);
  const session = newSession(scope, trace);

  session.installLandingPad();
  session.teardown();

  assert.equal(scope.crosswakeBridge[LANDING_PAD], undefined);
  assert.deepEqual(scope.crosswakeBridge.capabilities, { haptics: "1.0.0" });
});

// --- the repo-root manifest (D-30 / T-154-SC) ------------------------------

test("the repo-root manifest is private and has zero dependencies", () => {
  const manifest = JSON.parse(readFileSync(PACKAGE_JSON, "utf8"));

  assert.equal(manifest.private, true);
  assert.deepEqual(manifest.dependencies, undefined);
  assert.deepEqual(manifest.devDependencies, undefined);
});
