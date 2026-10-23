import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { getRateLimitProvider } from './internal/registry.ts';
import { record, render } from './internal/render.ts';

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
    record(ctx, provider, provider.pick?.(event.headers));
  });

  pi.on('provider_stream_event', (event, ctx) => {
    const provider = getRateLimitProvider(event.provider);
    if (!provider) {
      return;
    }
    record(ctx, provider, provider.pickEvent?.(event.data));
  });
}
