import type { ExtensionContext } from '@earendil-works/pi-coding-agent';

const BAR_WIDTH = 10;
export const MINUTES_PER_HOUR = 60;
export const MINUTES_PER_DAY = 1440;

export function pickColor(percent: number): 'error' | 'warning' | 'dim' {
  if (percent >= 90) {
    return 'error';
  }
  if (percent >= 70) {
    return 'warning';
  }
  return 'dim';
}

export function bar(percent: number): string {
  const filled = Math.floor((Math.min(percent, 100) * BAR_WIDTH) / 100);
  return '█'.repeat(filled) + '░'.repeat(BAR_WIDTH - filled);
}

/** `<duration> @ <HH:MM>`; day-long windows (`7d`) prefix the weekday. */
function formatReset(epochSeconds: number, label: string): string {
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
  const when = label.endsWith('d')
    ? `${resetDate.toLocaleDateString('en-GB', { weekday: 'short' })} ${time}`
    : time;
  return `${duration || '0m'} @ ${when}`;
}

/** One coloured `<label> <bar> <percent>% (<reset>)` segment, or undefined. */
export function formatWindow(
  ctx: ExtensionContext,
  label: string,
  percent: number,
  resetEpochSeconds: number,
): string | undefined {
  if (!Number.isFinite(percent) || !Number.isFinite(resetEpochSeconds)) {
    return undefined;
  }
  return ctx.ui.theme.fg(
    pickColor(percent),
    `${label} ${bar(percent)} ${percent}% (${formatReset(resetEpochSeconds, label)})`,
  );
}

export function count(value: number): string {
  return value.toLocaleString('en-GB');
}

export function joinParts(
  ctx: ExtensionContext,
  parts: (string | undefined)[],
): string | undefined {
  const present = parts.filter((part): part is string => part !== undefined);
  if (present.length === 0) {
    return undefined;
  }
  return present.join(ctx.ui.theme.fg('dim', ' | '));
}
