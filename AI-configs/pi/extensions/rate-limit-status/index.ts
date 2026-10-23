import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { getRateLimitProvider } from './internal/registry.ts';
import { render, show } from './internal/render.ts';
import { writeSnapshot } from './internal/snapshot-store.ts';

const POLL_MS = 2000;

export default function rateLimitStatus(pi: ExtensionAPI): void {
  let timer: ReturnType<typeof setInterval> | undefined;

  function stopPolling() {
    clearInterval(timer);
    timer = undefined;
  }

  pi.on('session_start', (_event, ctx) => {
    stopPolling();
    if (!ctx.hasUI) {
      return;
    }
    render(ctx, ctx.model?.provider);
    // Re-render every tick, not on mtime change: countdowns and expiry move.
    timer = setInterval(() => render(ctx, ctx.model?.provider), POLL_MS);
    timer.unref();
  });

  pi.on('session_shutdown', stopPolling);

  pi.on('model_select', (event, ctx) => {
    if (ctx.hasUI) {
      render(ctx, event.model.provider);
    }
  });

  pi.on('after_provider_response', (event, ctx) => {
    const provider = getRateLimitProvider(ctx.model?.provider);
    if (!provider) {
      return;
    }
    const headers = provider.pick(event.headers);
    // Responses without rate-limit headers keep the last good footer line.
    if (Object.keys(headers).length === 0) {
      return;
    }
    const snapshot = writeSnapshot(provider.provider, headers);
    if (ctx.hasUI) {
      show(ctx, provider, snapshot);
    }
  });
}
