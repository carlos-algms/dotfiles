import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { refreshProvider } from './internal/refresh.ts';
import { getRateLimitProvider } from './internal/registry.ts';
import { record, render } from './internal/render.ts';
import { syncDeepSeekCost } from './providers/deepseek.ts';

const POLL_MS = 2000;

export default function rateLimitStatus(pi: ExtensionAPI): void {
  let timer: ReturnType<typeof setInterval> | undefined;
  let currentProvider: string | undefined;
  let currentModelId: string | undefined;

  function stopPolling() {
    clearInterval(timer);
    timer = undefined;
  }

  function startPolling(ctx: ExtensionContext) {
    if (timer) {
      return;
    }
    timer = setInterval(
      () => render(ctx, currentProvider, currentModelId),
      POLL_MS,
    );
    timer.unref();
  }

  function track(
    ctx: ExtensionContext,
    providerId: string | undefined,
    modelId: string | undefined,
  ) {
    currentProvider = providerId;
    currentModelId = modelId;
    render(ctx, currentProvider, currentModelId);
    if (getRateLimitProvider(currentProvider, currentModelId)) {
      startPolling(ctx);
    } else {
      stopPolling();
    }
  }

  // Refreshing is UI-independent: headless runs still write the shared snapshot.
  function refreshFor(ctx: ExtensionContext, trailing = false) {
    refreshProvider(
      ctx,
      getRateLimitProvider(ctx.model?.provider, ctx.model?.id),
      trailing,
    );
  }

  pi.on('session_start', (_event, ctx) => {
    stopPolling();
    syncDeepSeekCost(ctx.model);
    refreshFor(ctx);
    if (ctx.hasUI) {
      track(ctx, ctx.model?.provider, ctx.model?.id);
    }
  });

  pi.on('session_shutdown', () => {
    stopPolling();
  });

  pi.on('model_select', (event, ctx) => {
    syncDeepSeekCost(event.model);
    refreshFor(ctx);
    if (ctx.hasUI) {
      track(ctx, event.model.provider, event.model.id);
    }
  });

  pi.on('before_provider_request', (_event, ctx) => {
    syncDeepSeekCost(ctx.model);
  });

  pi.on('after_provider_response', (event, ctx) => {
    const provider = getRateLimitProvider(
      ctx.model?.provider,
      ctx.model?.id,
    );
    if (!provider) {
      return;
    }
    record(ctx, provider, provider.pick?.(event.headers));
    refreshProvider(ctx, provider);
  });

  // Final boundary of a run: pick up the update the throttle dropped above.
  pi.on('agent_settled', (_event, ctx) => {
    refreshFor(ctx, true);
  });

  pi.on('provider_stream_event', (event, ctx) => {
    const provider = getRateLimitProvider(event.provider, event.model);
    if (!provider) {
      return;
    }
    record(ctx, provider, provider.pickEvent?.(event.data));
  });
}
