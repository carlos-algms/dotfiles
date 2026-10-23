import type { ExtensionContext } from '@earendil-works/pi-coding-agent';

export type HeaderMap = Record<string, string>;

/** Picked headers plus the capture time, so relative resets can expire. */
export interface Snapshot {
  at: number;
  headers: HeaderMap;
}

/** One provider's rate-limit behavior, resolved by provider id. */
export interface RateLimitProvider {
  /** Provider id this module handles (matches `Model.provider`). */
  readonly provider: string;
  /** Raw response headers (any case) -> lowercased subset this provider consumes. */
  pick?(rawHeaders: HeaderMap): HeaderMap;
  /** Raw provider stream event -> flat map to store, or undefined to ignore. */
  pickEvent?(data: unknown): HeaderMap | undefined;
  /** Footer line, or undefined when no window is live. */
  format(ctx: ExtensionContext, snapshot: Snapshot): string | undefined;
}
