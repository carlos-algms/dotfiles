import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import { formatWindow, joinParts } from '../internal/format-shared.ts';
import type { HeaderMap, RateLimitProvider } from '../internal/types.ts';

const PROVIDER = 'opencode-go';
const ENDPOINT = 'https://opencode.ai/zen/go/v1/usage';
const TIMEOUT_MS = 5000;

/** Window label in the footer -> meter name in the endpoint's body. */
const WINDOWS = [
  ['5h', 'rolling'],
  ['7d', 'weekly'],
  ['1M', 'monthly'],
] as const;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

/** `[percent, reset epoch seconds]` for one meter, or undefined. */
function readMeter(value: unknown): [number, number] | undefined {
  if (!isRecord(value)) {
    return undefined;
  }
  const { percent, resetsAt, status } = value;
  if (typeof percent !== 'number' || typeof resetsAt !== 'string') {
    return undefined;
  }
  const reset = Date.parse(resetsAt) / 1000;
  if (!Number.isFinite(reset)) {
    return undefined;
  }
  // A refused window is exhausted whatever percent it reports.
  const used = status === 'rate-limited' ? 100 : percent;
  return [Math.round(used * 10) / 10, reset];
}

/** `{usage:{rolling,weekly,monthly}}` -> `<label>-used` and `<label>-reset`. */
export function pickUsage(body: unknown): HeaderMap | undefined {
  if (!isRecord(body) || !isRecord(body.usage)) {
    return undefined;
  }
  const usage = body.usage;
  const entries = WINDOWS.flatMap(([label, meter]) => {
    const read = readMeter(usage[meter]);
    return read
      ? ([
          [`${label}-used`, String(read[0])],
          [`${label}-reset`, String(read[1])],
        ] as const)
      : [];
  });
  return entries.length > 0 ? Object.fromEntries(entries) : undefined;
}

/**
 * Go sends no rate-limit headers and `usage.opencode.allowance` is a per-request
 * delta in plan dollars, so read the meters the OpenCode client reads. Auth is
 * the key Pi stored for the provider; the workspace comes from the key.
 */
export const opencodeGo = {
  provider: PROVIDER,
  async refresh(ctx: ExtensionContext) {
    const apiKey = await ctx.modelRegistry.getApiKeyForProvider(PROVIDER);
    if (!apiKey) {
      return undefined;
    }
    const response = await fetch(ENDPOINT, {
      headers: { authorization: `Bearer ${apiKey}` },
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    if (!response.ok) {
      await response.body?.cancel();
      return undefined;
    }
    return pickUsage(await response.json());
  },
  format(ctx, { headers }) {
    const live = WINDOWS.some(
      ([label]) => Number(headers[`${label}-reset`]) * 1000 > Date.now(),
    );
    if (!live) {
      return undefined;
    }
    return joinParts(
      ctx,
      WINDOWS.map(([label]) =>
        formatWindow(
          ctx,
          label,
          Number(headers[`${label}-used`]),
          Number(headers[`${label}-reset`]),
        ),
      ),
    );
  },
} satisfies RateLimitProvider;
