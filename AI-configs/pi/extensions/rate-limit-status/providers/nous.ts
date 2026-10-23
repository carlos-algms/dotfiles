import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import { bar, count, joinParts, pickColor } from '../internal/format-shared.ts';
import { pickByPrefix } from '../internal/pick-by-prefix.ts';
import type { RateLimitProvider, Snapshot } from '../internal/types.ts';

const PREFIX = 'x-ratelimit-';

/** Four windows: requests and tokens, each per-minute and per-hour. */
const BUCKETS = [
  { label: 'RPM', suffix: 'requests' },
  { label: 'RPH', suffix: 'requests-1h' },
  { label: 'TPM', suffix: 'tokens' },
  { label: 'TPH', suffix: 'tokens-1h' },
] as const;

function formatSeconds(seconds: number): string {
  if (seconds < 60) {
    return `${Math.ceil(seconds)}s`;
  }
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) {
    return `${minutes}m`;
  }
  const mins = minutes % 60;
  return `${Math.floor(minutes / 60)}h${mins > 0 ? ` ${mins}m` : ''}`;
}

/** Resets are relative seconds from capture time; expired buckets are dropped. */
function formatBucket(
  ctx: ExtensionContext,
  { label, suffix }: (typeof BUCKETS)[number],
  { at, headers }: Snapshot,
): string | undefined {
  const limit = Number(headers[`${PREFIX}limit-${suffix}`]);
  const remaining = Number(headers[`${PREFIX}remaining-${suffix}`]);
  const resetAt = at + Number(headers[`${PREFIX}reset-${suffix}`]) * 1000;
  if (
    !Number.isFinite(limit) ||
    !Number.isFinite(remaining) ||
    limit <= 0 ||
    !(resetAt > Date.now())
  ) {
    return undefined;
  }
  const used = Math.max(0, limit - remaining);
  const percent = (used / limit) * 100;
  const resets = formatSeconds((resetAt - Date.now()) / 1000);
  return ctx.ui.theme.fg(
    pickColor(percent),
    `${label} ${bar(percent)} ${count(used)}/${count(limit)} (${resets})`,
  );
}

export const nous = {
  provider: 'nous',
  pick: (raw) => pickByPrefix(raw, PREFIX),
  format(ctx, snapshot) {
    return joinParts(
      ctx,
      BUCKETS.map((bucket) => formatBucket(ctx, bucket, snapshot)),
    );
  },
} satisfies RateLimitProvider;
