// crosswake-proof-lane template_version=5
import { type ProofLaneAdapter } from './proof_lane';

const HOST_ADAPTER_ERROR = 'PL-BROWSER-HOST-ADAPTER';
const hostAdapterUnavailable = (): Promise<never> => Promise.reject(new Error(HOST_ADAPTER_ERROR));

export type LocalQueueObservation = {
  queuedCount: number;
  outboxEmpty: boolean;
};

export type LocalLifecycleObservation = {
  phase: 'offline' | 'relaunch' | 'reconnected';
};

export type LocalRecoveryObservation = {
  state: 'saved_locally' | 'syncing' | 'needs_attention' | 'sync_paused';
};

export const proofLaneHostAdapter = {
  navigate: async () => hostAdapterUnavailable(),
  performMutation: async () => hostAdapterUnavailable(),
  readQueuedRecord: async () => hostAdapterUnavailable(),
  reconnect: async () => hostAdapterUnavailable(),
  assertBackendConfirmation: async () => hostAdapterUnavailable(),
  assertOutboxEmpty: async () => hostAdapterUnavailable(),
  assertDuplicateIdempotency: async () => hostAdapterUnavailable(),
  observeLocalQueue: async (): Promise<LocalQueueObservation> => hostAdapterUnavailable(),
  observeLocalLifecycle: async (): Promise<LocalLifecycleObservation> => hostAdapterUnavailable(),
  observeLocalRecovery: async (): Promise<LocalRecoveryObservation> => hostAdapterUnavailable(),
} satisfies ProofLaneAdapter;
