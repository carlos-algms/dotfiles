import { anthropic } from '../providers/anthropic.ts';
import { deepseek } from '../providers/deepseek.ts';
import { nous } from '../providers/nous.ts';
import { openaiCodex } from '../providers/openai-codex.ts';
import type { RateLimitProvider } from './types.ts';

const PROVIDERS = new Map<string, RateLimitProvider>([
  [anthropic.provider, anthropic],
  [deepseek.provider, deepseek],
  [nous.provider, nous],
  [openaiCodex.provider, openaiCodex],
]);

export function getRateLimitProvider(
  provider: string | undefined,
  modelId?: string,
): RateLimitProvider | undefined {
  const entry = provider ? PROVIDERS.get(provider) : undefined;
  if (
    entry?.models &&
    (modelId === undefined || !entry.models.includes(modelId))
  ) {
    return;
  }
  return entry;
}
