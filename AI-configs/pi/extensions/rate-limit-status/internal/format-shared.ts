import type { ExtensionContext } from '@earendil-works/pi-coding-agent';

const BAR_WIDTH = 10;

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
