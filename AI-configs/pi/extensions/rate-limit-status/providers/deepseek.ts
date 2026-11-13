import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import type {
  RateLimitProvider,
  Snapshot,
} from '../internal/types.ts';

const MODEL_ID = 'deepseek-flash';

/**
 * $/M token rates, from https://api-docs.deepseek.com/quick_start/pricing.
 * DeepSeek bills off-peak at half the peak price; re-read that page to update.
 */
export const PEAK_RATES = { input: 0.3, cacheRead: 0.006, output: 1.2 };
export const OFF_PEAK_RATES = { input: 0.15, cacheRead: 0.003, output: 0.6 };

/**
 * Peak hours: Mon-Fri 01:00-04:00 and 06:00-10:00 UTC.
 * shortcut: Chinese public holidays are also off-peak, not modelled here
 * add a holiday table if the discount starts to matter.
 */
export function isPeak(date: Date = new Date()): boolean {
  const day = date.getUTCDay();
  const minute = date.getUTCHours() * 60 + date.getUTCMinutes();
  const inWindow = (start: number, end: number) =>
    minute >= start && minute < end;
  return (
    day >= 1 && day <= 5 && (inWindow(60, 240) || inWindow(360, 600))
  );
}

/** Structurally matches the session model we mutate in place. */
interface CostLike {
  input: number;
  output: number;
  cacheRead: number;
}
interface ModelLike {
  provider: string;
  id: string;
  cost: CostLike;
}

/**
 * Rewrite the live model cost to the rate in effect now, so
 * `calculateCost` stamps each request at the right price.
 * Set-and-forget: repeat writes are idempotent.
 */
export function syncDeepSeekCost(
  model: ModelLike | undefined,
  date: Date = new Date(),
): void {
  if (
    !model?.cost ||
    model.provider !== 'deepseek' ||
    model.id !== MODEL_ID
  ) {
    return;
  }
  const rates = isPeak(date) ? PEAK_RATES : OFF_PEAK_RATES;
  model.cost.input = rates.input;
  model.cost.cacheRead = rates.cacheRead;
  model.cost.output = rates.output;
}

/** `deepseek off-peak −50%` when discounted, `deepseek peak` otherwise. */
function timeLine(ctx: ExtensionContext): string | undefined {
  const peak = isPeak();
  return ctx.ui.theme.fg(
    peak ? 'warning' : 'dim',
    peak ? 'deepseek peak' : 'deepseek off-peak −50%',
  );
}

export const deepseek = {
  provider: 'deepseek',
  models: [MODEL_ID],
  // Snapshot-based formatting never applies: DeepSeek sends no rate-limit headers.
  format(_ctx: ExtensionContext, _snapshot: Snapshot) {
    return undefined;
  },
  formatTime: timeLine,
} satisfies RateLimitProvider;
