import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { getRateLimitProvider } from './internal/registry.ts';
import { record, render } from './internal/render.ts';

const POLL_MS = 2000;

export default function rateLimitStatus(pi: ExtensionAPI): void {
  let timer: ReturnType<typeof setInterval> | undefined;
  let currentProvider: string | undefined;

  function stopPolling() {
    clearInterval(timer);
    timer = undefined;
  }

  function startPolling(ctx: ExtensionContext) {
    if (timer) {
      return;
    }
    timer = setInterval(() => render(ctx, currentProvider), POLL_MS);
    timer.unref();
  }

  pi.on('session_start', (_event, ctx) => {
    stopPolling();
    if (!ctx.hasUI) {
      return;
    }
    currentProvider = ctx.model?.provider;
    render(ctx, currentProvider);
    if (getRateLimitProvider(currentProvider)) {
      startPolling(ctx);
    }
  });

  pi.on('session_shutdown', () => {
    stopPolling();
  });

  pi.on('model_select', (event, ctx) => {
    if (!ctx.hasUI) {
      return;
    }
    currentProvider = event.model.provider;
    render(ctx, currentProvider);
    if (getRateLimitProvider(currentProvider)) {
      startPolling(ctx);
    } else {
      stopPolling();
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
