/**
 * Rate Limit Status - shows Anthropic subscription 5h and 7d usage as a third
 * footer line. Reads `anthropic-ratelimit-unified-*` response headers.
 *
 * Every session that loads this file (other pi instances, subagent children)
 * writes the headers to a shared snapshot. Only UI sessions render it.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent';
import { formatRateLimits } from './format';
import {
  getSnapshotMtimeMs,
  readSnapshot,
  writeSnapshot,
} from './snapshot-store';

const STATUS_KEY = 'rate-limits';
const PROVIDER = 'anthropic';
const POLL_MS = 2000;

export default function (pi: ExtensionAPI) {
  let timer: ReturnType<typeof setInterval> | undefined;

  function stopPolling() {
    clearInterval(timer);
    timer = undefined;
  }

  function render(ctx: ExtensionContext, provider: string | undefined) {
    if (provider !== PROVIDER) {
      ctx.ui.setStatus(STATUS_KEY, undefined);
      return;
    }
    const headers = readSnapshot();
    ctx.ui.setStatus(
      STATUS_KEY,
      headers ? formatRateLimits(ctx, headers) : undefined,
    );
  }

  pi.on('session_start', (_event, ctx) => {
    stopPolling();
    if (!ctx.hasUI) {
      return;
    }
    let lastMtime = getSnapshotMtimeMs();
    render(ctx, ctx.model?.provider);
    timer = setInterval(() => {
      const mtime = getSnapshotMtimeMs();
      if (mtime === lastMtime) {
        return;
      }
      lastMtime = mtime;
      render(ctx, ctx.model?.provider);
    }, POLL_MS);
    timer.unref();
  });

  pi.on('session_shutdown', stopPolling);

  pi.on('model_select', (event, ctx) => {
    if (ctx.hasUI) {
      render(ctx, event.model.provider);
    }
  });

  pi.on('after_provider_response', (event, ctx) => {
    writeSnapshot(event.headers);
    if (!ctx.hasUI) {
      return;
    }
    const text = formatRateLimits(ctx, event.headers);
    if (text === undefined) {
      return;
    }
    ctx.ui.setStatus(STATUS_KEY, text);
  });
}
