/* Crosswake bridge hook — the library-owned client half of the `crosswake.bridge`
 * wire protocol. Hand-authored, dependency-free ESM. There is no build step, no
 * minification, and nothing here is published to a second package registry (D-30):
 * a second registry would open a second version axis and reproduce the documented
 * client/native drift failure this file exists to avoid.
 *
 * Served by the package's own static directory. Mount it in the host endpoint as a
 * fourth static plug and import it from the layout:
 *
 *     plug(Plug.Static, at: "/crosswake", from: :crosswake, gzip: false,
 *          only: ~w(crosswake.esm.js))
 *
 *     <script type="module">
 *       import {CrosswakeBridge} from "/crosswake/crosswake.esm.js";
 *       const liveSocket = new LiveSocket("/live", Socket, {params, hooks: {CrosswakeBridge}});
 *     </script>
 *
 *     <div id="crosswake-bridge" phx-hook="CrosswakeBridge" phx-update="ignore"></div>
 *
 * This file's single most important job is NOT transport. It is synthesizing the
 * unreachable FACT when there is no shell at all (D-34) — which is exactly why the
 * shells cannot ship it: code injected by the shell cannot run when there is no
 * shell. The shells inject facts; the library ships logic.
 *
 * It reports facts and never denials (D-14). Denial microcopy exists once, in
 * Elixir, where it can be localized and cannot drift.
 */

// The four reserved wire event names. Kept byte-identical to lib/crosswake/bridge.ex.
export const DISPATCH_EVENT = "crosswake:bridge";
export const ACK_EVENT = "crosswake:bridge_ack";
export const REPLY_EVENT = "crosswake:bridge_reply";
export const UNREACHABLE_EVENT = "crosswake:bridge_unreachable";
export const NAVIGATION_EVENT = "crosswake:navigation_transition";

// Failing moments Crosswake.Bridge translates into the single :shell_unreachable
// denial. The hook only ever names a moment; it never authors a denial.
export const MOMENT_NO_TRANSPORT = "no_transport";
export const MOMENT_REPLY_TIMEOUT = "reply_timeout";
export const MOMENT_TRANSPORT_ERROR = "transport_error";

// Mirrors Crosswake.Bridge's @default_reply_timeout_ms. The server arms its own
// backstop at this value plus a 2s margin, so the client timer is primary and this
// default never races ahead of a healthy server deadline.
export const DEFAULT_REPLY_TIMEOUT_MS = 10000;

// The name the native side calls back into. Once shipped, renaming this means every
// shell binary in the field is calling a function that no longer exists (D-02).
export const LANDING_PAD = "__reply";

/*
 * Module-scoped single-owner guard (D-39).
 *
 * LiveView delivers a `push_event` to EVERY mounted hook's `handleEvent` callback on
 * the page, not just to the element the event "belongs" to. Two hook elements would
 * therefore post every request to the native shell twice — for haptics that is a
 * double buzz; for a future mutating control it is a duplicated side effect. The
 * first hook to mount owns the bridge; later hooks mount inert and the ownership is
 * handed back on destroy.
 */
let owner = null;

/*
 * Transport selection — the highest-risk logic in this file (D-35, T-154-24).
 *
 * Look up the iOS message handler FIRST, then the injected global, and explicitly
 * typecheck EACH candidate's post method before using it. Do not null-coalesce the
 * two candidates: on iOS the shell injects `window.crosswakeBridge` at document start
 * as a FACTS-ONLY bag (capabilities and thread id, no post method), so a coalescing
 * lookup resolves to the facts bag and posts into the void. The inline script this
 * file replaces already had the ORDER right but only tested the method for
 * truthiness, never for callability.
 */
export function findTransport(scope) {
  const root = scope || globalThis;

  const webkit = root.webkit;
  if (webkit && webkit.messageHandlers) {
    const handler = webkit.messageHandlers.crosswakeBridge;
    if (handler && typeof handler.postMessage === "function") {
      return handler;
    }
  }

  const injected = root.crosswakeBridge;
  if (injected && typeof injected.postMessage === "function") {
    return injected;
  }

  return null;
}

/* The navigation seam intentionally accepts no injected-global or bridge fallback. */
export function findNavigationTransport(scope) {
  const root = scope || globalThis;
  const webkit = root.webkit;
  const handler = webkit && webkit.messageHandlers && webkit.messageHandlers.crosswakeNavigation;

  return handler && typeof handler.postMessage === "function" ? handler : null;
}

function navigationEnvelope(payload) {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    return null;
  }

  const allowed = ["protocol", "version", "transition_id", "kind", "route_id", "restoration_ref"];
  const keys = Object.keys(payload);
  const required = ["protocol", "version", "transition_id", "kind", "route_id"];
  const opaque = /^(?:nav|route|restore)-[0-9a-f]{16}$/;

  if (
    keys.some((key) => !allowed.includes(key)) ||
    required.some((key) => !(key in payload)) ||
    payload.protocol !== "crosswake.navigation_transition" ||
    payload.version !== "1.0.0" ||
    !["push_patch", "push_navigate"].includes(payload.kind) ||
    typeof payload.transition_id !== "string" || !/^nav-[0-9a-f]{16}$/.test(payload.transition_id) ||
    typeof payload.route_id !== "string" || !/^route-[0-9a-f]{16}$/.test(payload.route_id) ||
    ("restoration_ref" in payload &&
      (typeof payload.restoration_ref !== "string" || !/^restore-[0-9a-f]{16}$/.test(payload.restoration_ref)))
  ) {
    return null;
  }

  const envelope = {
    protocol: payload.protocol,
    version: payload.version,
    transition_id: payload.transition_id,
    kind: payload.kind,
    route_id: payload.route_id
  };

  if ("restoration_ref" in payload) {
    envelope.restoration_ref = payload.restoration_ref;
  }

  return envelope;
}

/* Best-effort local delivery only: no acknowledgement, reply, or fallback authority. */
export function navigationDelivery(scope, payload) {
  const envelope = navigationEnvelope(payload);
  const transport = findNavigationTransport(scope);

  if (!envelope || !transport) {
    return false;
  }

  try {
    transport.postMessage(JSON.stringify(envelope));
    return true;
  } catch (_error) {
    return false;
  }
}

/** Reads the facts both shells inject at document start. Never a transport. */
export function bridgeFacts(scope) {
  const root = scope || globalThis;
  const injected = root.crosswakeBridge;

  if (!injected) {
    return { capabilities: {}, threadId: null };
  }

  return {
    capabilities: injected.capabilities || {},
    threadId: typeof injected.threadId === "string" ? injected.threadId : null
  };
}

function correlationIdOf(payload) {
  if (!payload || typeof payload !== "object") {
    return null;
  }

  const id = payload.correlation_id;
  return typeof id === "string" && id.length > 0 ? id : null;
}

function replyTimeoutFor(payload, element) {
  const declared = payload && payload.reply_timeout_ms;
  if (typeof declared === "number") {
    return declared;
  }

  const attribute =
    element && element.dataset ? element.dataset.crosswakeReplyTimeout : undefined;

  if (typeof attribute === "string" && attribute.length > 0) {
    if (attribute === "infinity") {
      return 0;
    }

    const parsed = Number.parseInt(attribute, 10);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  return DEFAULT_REPLY_TIMEOUT_MS;
}

/*
 * The bridge session — one per owning hook element.
 *
 * `pushEvent` is the LiveView hook's own push function; `scope` is the global object
 * the transport lookup and landing pad live on. Both are injected so the whole file
 * is testable against a hand-stubbed global with no browser and no test framework.
 */
export class BridgeSession {
  constructor({ pushEvent, scope, element, setTimeout: setTimer, clearTimeout: clearTimer }) {
    this.pushEvent = pushEvent;
    this.scope = scope || globalThis;
    this.element = element || null;
    this.setTimer = setTimer || ((fn, ms) => globalThis.setTimeout(fn, ms));
    this.clearTimer = clearTimer || ((handle) => globalThis.clearTimeout(handle));

    // The hook's own in-flight map — the client-side third layer of the
    // exactly-once scheme (D-23). A reply for an id this map does not hold is
    // dropped here, before it can reach the server at all (T-154-28).
    this.inFlight = new Map();
  }

  installLandingPad() {
    // The shells inject `window.crosswakeBridge` at document start; never clobber
    // it — augment it. When there is no shell at all the namespace is created so
    // the landing pad has a stable home either way.
    if (!this.scope.crosswakeBridge) {
      this.scope.crosswakeBridge = {};
    }

    this.scope.crosswakeBridge[LANDING_PAD] = (reply) => this.receiveReply(reply);
  }

  removeLandingPad() {
    if (this.scope.crosswakeBridge) {
      delete this.scope.crosswakeBridge[LANDING_PAD];
    }
  }

  /*
   * Handles one server dispatch.
   *
   * The ack is emitted BEFORE any transport lookup or post (D-36). That ordering is
   * what makes the server-armed deadline measure WIRING rather than shell latency,
   * and it is why a mount handshake was rejected: an adopter can register the hooks
   * map correctly and still omit the hook element from this particular route's tree,
   * which a mount handshake would false-negative. The result is the strongest form
   * of CTRL-02 — there is no configuration in which a push resolves to silence.
   */
  dispatch(payload) {
    const correlationId = correlationIdOf(payload);

    this.pushEvent(ACK_EVENT, { correlation_id: correlationId });

    const transport = findTransport(this.scope);

    if (!transport) {
      this.reportUnreachable(correlationId, MOMENT_NO_TRANSPORT);
      return;
    }

    try {
      transport.postMessage(JSON.stringify(payload));
    } catch (_error) {
      // A throwing transport is a FACT about the shell, not a denial. Core owns
      // the microcopy; the hook only names the moment.
      this.reportUnreachable(correlationId, MOMENT_TRANSPORT_ERROR);
      return;
    }

    this.armReplyTimer(correlationId, replyTimeoutFor(payload, this.element));
  }

  armReplyTimer(correlationId, timeoutMs) {
    if (!correlationId) {
      return;
    }

    if (!(timeoutMs > 0)) {
      // An opted-out (human-in-the-loop) ask gets no client timer, mirroring the
      // server's `timeout: :infinity` option.
      this.inFlight.set(correlationId, null);
      return;
    }

    const handle = this.setTimer(() => {
      if (this.inFlight.has(correlationId)) {
        this.reportUnreachable(correlationId, MOMENT_REPLY_TIMEOUT);
      }
    }, timeoutMs);

    this.inFlight.set(correlationId, handle);
  }

  /*
   * The reply landing pad the native side calls (D-02).
   *
   * Drops any reply whose correlation id is not in this hook's own in-flight map —
   * the first of two independent gates. The server re-checks against its own
   * in-flight map, the correlation id, and the per-mount epoch; neither gate trusts
   * the other (T-154-28).
   */
  receiveReply(reply) {
    const parsed = typeof reply === "string" ? safeParse(reply) : reply;
    const correlationId = correlationIdOf(parsed);

    if (!correlationId || !this.inFlight.has(correlationId)) {
      return false;
    }

    this.clearInFlight(correlationId);
    this.pushEvent(REPLY_EVENT, parsed);
    return true;
  }

  /* Reports a FACT, never a denial (D-14, T-154-27). */
  reportUnreachable(correlationId, moment) {
    this.clearInFlight(correlationId);
    this.pushEvent(UNREACHABLE_EVENT, { correlation_id: correlationId, moment: moment });
  }

  clearInFlight(correlationId) {
    if (!correlationId || !this.inFlight.has(correlationId)) {
      return;
    }

    const handle = this.inFlight.get(correlationId);
    if (handle !== null && handle !== undefined) {
      this.clearTimer(handle);
    }

    this.inFlight.delete(correlationId);
  }

  teardown() {
    for (const correlationId of Array.from(this.inFlight.keys())) {
      this.clearInFlight(correlationId);
    }

    this.removeLandingPad();
  }
}

function safeParse(text) {
  try {
    return JSON.parse(text);
  } catch (_error) {
    return null;
  }
}

/*
 * The LiveView hook object. Register it in the socket's hooks map as
 * `CrosswakeBridge` and put `phx-hook="CrosswakeBridge"` on ONE element per page.
 */
export const CrosswakeBridge = {
  mounted() {
    if (owner !== null) {
      // A second hook element mounted on the same page. It stays inert rather than
      // double-posting every dispatch to the shell (D-39, T-154-25).
      this.crosswakeOwned = false;
      return;
    }

    owner = this;
    this.crosswakeOwned = true;

    this.crosswakeSession = new BridgeSession({
      pushEvent: (event, payload) => this.pushEvent(event, payload),
      scope: this.crosswakeScope || globalThis,
      element: this.el
    });

    this.crosswakeSession.installLandingPad();
    this.handleEvent(DISPATCH_EVENT, (payload) => this.crosswakeSession.dispatch(payload));
    this.handleEvent(NAVIGATION_EVENT, (payload) =>
      navigationDelivery(this.crosswakeScope || globalThis, payload)
    );
  },

  destroyed() {
    if (!this.crosswakeOwned) {
      return;
    }

    if (this.crosswakeSession) {
      this.crosswakeSession.teardown();
    }

    owner = null;
    this.crosswakeOwned = false;
  }
};

/* Test seam only — resets the module-scoped single-owner guard. */
export function __resetOwner() {
  owner = null;
}

export default CrosswakeBridge;
