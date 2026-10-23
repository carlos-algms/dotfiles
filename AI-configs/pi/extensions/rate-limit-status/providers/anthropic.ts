import { formatWindow, joinParts } from '../internal/format-shared.ts';
import { pickByPrefix } from '../internal/pick-by-prefix.ts';
import type { HeaderMap, RateLimitProvider } from '../internal/types.ts';

const PREFIX = 'anthropic-ratelimit-unified-';
const WINDOWS = ['5h', '7d'] as const;
type WindowLabel = (typeof WINDOWS)[number];

function resetOf(headers: HeaderMap, label: WindowLabel): number {
  return Number(headers[`${PREFIX}${label}-reset`]);
}

export const anthropic = {
  provider: 'anthropic',
  pick: (raw) => pickByPrefix(raw, PREFIX),
  format(ctx, { headers }) {
    const live = WINDOWS.some(
      (label) => resetOf(headers, label) * 1000 > Date.now(),
    );
    if (!live) {
      return undefined;
    }
    return joinParts(
      ctx,
      WINDOWS.map((label) =>
        formatWindow(
          ctx,
          label,
          Math.round(Number(headers[`${PREFIX}${label}-utilization`]) * 100),
          resetOf(headers, label),
        ),
      ),
    );
  },
} satisfies RateLimitProvider;
