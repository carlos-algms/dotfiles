import { anthropic } from '../providers/anthropic.ts';
import { nous } from '../providers/nous.ts';
import { openaiCodex } from '../providers/openai-codex.ts';
import type { RateLimitProvider } from './types.ts';

const PROVIDERS = new Map<string, RateLimitProvider>([
  [anthropic.provider, anthropic],
  [nous.provider, nous],
  [openaiCodex.provider, openaiCodex],
]);

export function getRateLimitProvider(
  provider: string | undefined,
): RateLimitProvider | undefined {
  if (!provider) {
    return undefined;
  }
  return PROVIDERS.get(provider);
}
