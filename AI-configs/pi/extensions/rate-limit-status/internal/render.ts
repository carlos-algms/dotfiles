import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import { getRateLimitProvider } from './registry.ts';
import { readSnapshot } from './snapshot-store.ts';
import type { RateLimitProvider, Snapshot } from './types.ts';

const STATUS_KEY = 'rate-limits';

export function show(
  ctx: ExtensionContext,
  provider: RateLimitProvider | undefined,
  snapshot: Snapshot | undefined,
): void {
  ctx.ui.setStatus(
    STATUS_KEY,
    provider && snapshot ? provider.format(ctx, snapshot) : undefined,
  );
}

/** Read the shared snapshot for `providerId` and render it, or clear the line. */
export function render(
  ctx: ExtensionContext,
  providerId: string | undefined,
): void {
  const provider = getRateLimitProvider(providerId);
  show(ctx, provider, provider && readSnapshot(provider.provider));
}
