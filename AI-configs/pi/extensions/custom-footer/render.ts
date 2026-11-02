import { truncateToWidth, visibleWidth } from '@earendil-works/pi-tui';

function formatTokens(tokens: number): string {
  if (tokens < 1000) {
    return String(tokens);
  }
  if (tokens < 10000) {
    return `${(tokens / 1000).toFixed(1)}k`;
  }
  if (tokens < 1000000) {
    return `${Math.round(tokens / 1000)}k`;
  }
  return `${(tokens / 1000000).toFixed(1)}M`;
}

export function replaceFooterStats(
  stats: string,
  width: number,
  rate: number | undefined,
  tokens: number | null | undefined,
): string {
  let updated = stats;
  if (rate !== undefined) {
    updated = updated.replace(/CH[\d.]+%/, `CH${rate.toFixed(1)}%`);
  }
  if (tokens !== undefined && tokens !== null) {
    updated = updated.replace(
      /(\d+\.\d+)%\/([\d.]+[kM]?)/,
      `$1% (${formatTokens(tokens)}/$2)`,
    );
  }

  // Spend the existing model-alignment padding before truncating content.
  const extra = visibleWidth(updated) - visibleWidth(stats);
  if (extra > 0) {
    updated = updated.replace(/ {2,}/, (padding) =>
      ' '.repeat(Math.max(2, padding.length - extra)),
    );
  }
  return truncateToWidth(updated, width);
}
