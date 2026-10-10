import type { ExtensionContext } from '@earendil-works/pi-coding-agent';

const MINUTES_PER_HOUR = 60;
const MINUTES_PER_DAY = 1440;
const BAR_WIDTH = 10;

type WindowLabel = '5h' | '7d';

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
  if (label === '5h') {
    return `${minutes}m @ ${time}`;
  }
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
  const weekday = resetDate.toLocaleDateString('en-GB', { weekday: 'short' });
  return `${duration || '0m'} @ ${weekday} ${time}`;
}

function makeBar(percent: number): string {
  const filled = Math.floor((Math.min(percent, 100) * BAR_WIDTH) / 100);
  return '█'.repeat(filled) + '░'.repeat(BAR_WIDTH - filled);
}

function pickColor(percent: number): 'error' | 'warning' | 'dim' {
  if (percent >= 90) {
    return 'error';
  }
  if (percent >= 70) {
    return 'warning';
  }
  return 'dim';
}

function formatWindow(
  ctx: ExtensionContext,
  label: WindowLabel,
  headers: Record<string, string>,
): string | undefined {
  const utilization = Number(
    headers[`anthropic-ratelimit-unified-${label}-utilization`],
  );
  const reset = Number(headers[`anthropic-ratelimit-unified-${label}-reset`]);
  if (!Number.isFinite(utilization) || !Number.isFinite(reset)) {
    return undefined;
  }

  const percent = Math.round(utilization * 100);
  return ctx.ui.theme.fg(
    pickColor(percent),
    `${label} ${makeBar(percent)} ${percent}% (${formatReset(reset, label)})`,
  );
}

export function formatRateLimits(
  ctx: ExtensionContext,
  rawHeaders: Record<string, string>,
): string | undefined {
  const headers = Object.fromEntries(
    Object.entries(rawHeaders).map(([key, value]) => [
      key.toLowerCase(),
      value,
    ]),
  );
  const parts = [
    formatWindow(ctx, '5h', headers),
    formatWindow(ctx, '7d', headers),
  ].filter((part) => part !== undefined);
  if (parts.length === 0) {
    return undefined;
  }
  return parts.join(ctx.ui.theme.fg('dim', ' | '));
}
