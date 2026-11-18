import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import { record } from './render.ts';
import type { RateLimitProvider } from './types.ts';

/** One GET per provider per window; the footer tolerates a brief lag. */
const REFRESH_MIN_MS = 10_000;

interface State {
  inFlight: boolean;
  /** Start of the last fetch, so failures also count against the throttle. */
  at: number;
  timer?: ReturnType<typeof setTimeout>;
}

const states = new Map<string, State>();

function stateOf(provider: string): State {
  let state = states.get(provider);
  if (!state) {
    state = { inFlight: false, at: 0 };
    states.set(provider, state);
  }
  return state;
}

async function run(
  ctx: ExtensionContext,
  provider: RateLimitProvider,
  refresh: NonNullable<RateLimitProvider['refresh']>,
): Promise<void> {
  const state = stateOf(provider.provider);
  state.inFlight = true;
  state.at = Date.now();
  try {
    record(ctx, provider, await refresh(ctx));
  } catch {
    // keep the last snapshot; the next trigger retries
  } finally {
    state.inFlight = false;
  }
}

/**
 * Refetch a provider snapshot. Throttled per provider with one fetch in flight;
 * `trailing` schedules the update a blocked call would otherwise drop.
 */
export function refreshProvider(
  ctx: ExtensionContext,
  provider: RateLimitProvider | undefined,
  trailing = false,
): void {
  const refresh = provider?.refresh;
  if (!provider || !refresh) {
    return;
  }
  const state = stateOf(provider.provider);
  const wait = state.at + REFRESH_MIN_MS - Date.now();
  if (state.inFlight || wait > 0) {
    if (trailing && !state.inFlight && state.timer === undefined) {
      state.timer = setTimeout(
        () => {
          state.timer = undefined;
          refreshProvider(ctx, provider);
        },
        Math.max(wait, 0),
      );
      state.timer.unref();
    }
    return;
  }
  void run(ctx, provider, refresh);
}

/**
 * Clear armed timers and throttle state. Not called on session shutdown: a
 * process hosts many sessions (subagent children included), so one session
 * ending must not drop another's refresh.
 */
export function stopRefreshes(): void {
  for (const state of states.values()) {
    clearTimeout(state.timer);
  }
  states.clear();
}
