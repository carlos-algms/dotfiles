import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import { getRateLimitProvider } from './registry.ts';
import { readSnapshot, writeSnapshot } from './snapshot-store.ts';
import type { HeaderMap, RateLimitProvider, Snapshot } from './types.ts';

const STATUS_KEY = 'rate-limits';

function show(
  ctx: ExtensionContext,
  provider: RateLimitProvider | undefined,
  snapshot: Snapshot | undefined,
): void {
  ctx.ui.setStatus(
    STATUS_KEY,
    provider && snapshot ? provider.format(ctx, snapshot) : undefined,
  );
}

/** Store and show a captured map. Empty or missing maps keep the last footer. */
export function record(
  ctx: ExtensionContext,
  provider: RateLimitProvider,
  captured: HeaderMap | undefined,
): void {
  if (!captured || Object.keys(captured).length === 0) {
    return;
  }
  const snapshot = writeSnapshot(provider.provider, captured);
  if (ctx.hasUI) {
    show(ctx, provider, snapshot);
  }
}

/** Read the shared snapshot for `providerId` and render it, or clear the line. */
export function render(
  ctx: ExtensionContext,
  providerId: string | undefined,
): void {
  const provider = getRateLimitProvider(providerId);
  show(ctx, provider, provider && readSnapshot(provider.provider));
}
