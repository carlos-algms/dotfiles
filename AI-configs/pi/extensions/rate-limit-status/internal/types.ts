import type { ExtensionContext } from '@earendil-works/pi-coding-agent';

export type HeaderMap = Record<string, string>;

/** Picked headers plus the capture time, so relative resets can expire. */
export interface Snapshot {
  at: number;
  headers: HeaderMap;
}

/** One provider's rate-limit behavior, resolved by provider id and model. */
export interface RateLimitProvider {
  /** Provider id this module handles (matches `Model.provider`). */
  readonly provider: string;
  /** Restrict to these model ids; undefined = every model of the provider. */
  readonly models?: readonly string[];
  /** Raw response headers (any case) -> lowercased subset this provider consumes. */
  pick?(rawHeaders: HeaderMap): HeaderMap;
  /** Raw provider stream event -> flat map to store, or undefined to ignore. */
  pickEvent?(data: unknown): HeaderMap | undefined;
  /** Time-based line, shown without a snapshot (e.g. DeepSeek peak window). */
  formatTime?(ctx: ExtensionContext): string | undefined;
  /** Footer line, or undefined when no window is usable. */
  format(ctx: ExtensionContext, snapshot: Snapshot): string | undefined;
}
