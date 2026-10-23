import {
  MINUTES_PER_DAY,
  MINUTES_PER_HOUR,
  formatWindow,
  joinParts,
} from '../internal/format-shared.ts';
import type { HeaderMap, RateLimitProvider } from '../internal/types.ts';

const EVENT_TYPE = 'codex.rate_limits';
const USED_SUFFIX = '-used';

/** `300` -> `5h`, `10080` -> `7d`. */
function windowLabel(minutes: number): string {
  if (minutes >= MINUTES_PER_DAY) {
    return `${Math.round(minutes / MINUTES_PER_DAY)}d`;
  }
  return `${Math.round(minutes / MINUTES_PER_HOUR)}h`;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

/** `[label, used, reset]` for a usable window, else undefined. */
function readWindow(value: unknown): [string, number, number] | undefined {
  if (!isRecord(value)) {
    return undefined;
  }
  const { used_percent, window_minutes, reset_at } = value;
  if (
    typeof used_percent !== 'number' ||
    typeof window_minutes !== 'number' ||
    typeof reset_at !== 'number' ||
    window_minutes <= 0
  ) {
    return undefined;
  }
  return [windowLabel(window_minutes), used_percent, reset_at];
}

/**
 * Rate limits arrive as a `codex.rate_limits` stream event, not as headers,
 * on the default WebSocket transport. Stored flat as `<label>-used|reset`.
 */
export const openaiCodex = {
  provider: 'openai-codex',
  pickEvent(data) {
    if (
      !isRecord(data) ||
      data.type !== EVENT_TYPE ||
      !isRecord(data.rate_limits)
    ) {
      return undefined;
    }
    const { primary, secondary } = data.rate_limits;
    const entries = [primary, secondary]
      .map(readWindow)
      .filter((window) => window !== undefined)
      .flatMap(([label, used, reset]) => [
        [`${label}${USED_SUFFIX}`, String(used)] as const,
        [`${label}-reset`, String(reset)] as const,
      ]);
    if (entries.length === 0) {
      return undefined;
    }
    return Object.fromEntries(entries) satisfies HeaderMap;
  },
  format(ctx, { headers }) {
    const labels = Object.keys(headers)
      .filter((key) => key.endsWith(USED_SUFFIX))
      .map((key) => key.slice(0, -USED_SUFFIX.length));
    const live = labels.some(
      (label) => Number(headers[`${label}-reset`]) * 1000 > Date.now(),
    );
    if (!live) {
      return undefined;
    }
    return joinParts(
      ctx,
      labels.map((label) =>
        formatWindow(
          ctx,
          label,
          Number(headers[`${label}${USED_SUFFIX}`]),
          Number(headers[`${label}-reset`]),
        ),
      ),
    );
  },
} satisfies RateLimitProvider;
