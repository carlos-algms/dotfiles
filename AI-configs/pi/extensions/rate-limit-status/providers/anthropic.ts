import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import { bar, joinParts, pickColor } from '../internal/format-shared.ts';
import { pickByPrefix } from '../internal/pick-by-prefix.ts';
import type { HeaderMap, RateLimitProvider } from '../internal/types.ts';

const PREFIX = 'anthropic-ratelimit-unified-';
const WINDOWS = ['5h', '7d'] as const;
type WindowLabel = (typeof WINDOWS)[number];

const MINUTES_PER_HOUR = 60;
const MINUTES_PER_DAY = 1440;

function resetOf(headers: HeaderMap, label: WindowLabel): number {
  return Number(headers[`${PREFIX}${label}-reset`]);
}

function formatReset(epochSeconds: number, label: WindowLabel): string {
  const minutes = Math.max(
    0,
    Math.round((epochSeconds * 1000 - Date.now()) / 60_000),
  );
  const resetDate = new Date(epochSeconds * 1000);
  const time = resetDate.toLocaleTimeString('en-GB', {
    hour: '2-digit',
    minute: '2-digit',
  });
  const days = Math.floor(minutes / MINUTES_PER_DAY);
  const hours = Math.floor((minutes % MINUTES_PER_DAY) / MINUTES_PER_HOUR);
  const mins = minutes % MINUTES_PER_HOUR;
  const duration = [
    days > 0 ? `${days}d` : '',
    hours > 0 ? `${hours}h` : '',
    mins > 0 ? `${mins}m` : '',
  ]
    .filter(Boolean)
    .join(' ');
  const when =
    label === '5h'
      ? time
      : `${resetDate.toLocaleDateString('en-GB', { weekday: 'short' })} ${time}`;
  return `${duration || '0m'} @ ${when}`;
}

function formatWindow(
  ctx: ExtensionContext,
  label: WindowLabel,
  headers: HeaderMap,
): string | undefined {
  const utilization = Number(headers[`${PREFIX}${label}-utilization`]);
  const reset = resetOf(headers, label);
  if (!Number.isFinite(utilization) || !Number.isFinite(reset)) {
    return undefined;
  }
  const percent = Math.round(utilization * 100);
  return ctx.ui.theme.fg(
    pickColor(percent),
    `${label} ${bar(percent)} ${percent}% (${formatReset(reset, label)})`,
  );
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
      WINDOWS.map((label) => formatWindow(ctx, label, headers)),
    );
  },
} satisfies RateLimitProvider;
