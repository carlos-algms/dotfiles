/**
 * Rate Limit Status - shows Anthropic subscription 5h and 7d usage as a third
 * footer line. Reads `anthropic-ratelimit-unified-*` response headers.
 */

import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { formatRateLimits } from './format';

const STATUS_KEY = 'rate-limits';

export default function (pi: ExtensionAPI) {
  pi.on('after_provider_response', (event, ctx) => {
    const text = formatRateLimits(ctx, event.headers);
    if (text === undefined) {
      return;
    }
    ctx.ui.setStatus(STATUS_KEY, text);
  });
}
