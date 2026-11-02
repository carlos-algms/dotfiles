import type { Usage } from '@earendil-works/pi-ai';
import type { ExtensionContext } from '@earendil-works/pi-coding-agent';

type UsageSession = Pick<
  ExtensionContext['sessionManager'],
  'getSessionId' | 'getLeafId' | 'getEntries'
>;

export function createSessionCacheHitRate(): (
  sessionManager: UsageSession,
) => number | undefined {
  let cachedSession: string | undefined;
  let cachedLeaf: string | null | undefined;
  let cacheHitRate: number | undefined;

  return function sessionCacheHitRate(sessionManager): number | undefined {
    const session = sessionManager.getSessionId();
    const leaf = sessionManager.getLeafId();
    if (session === cachedSession && leaf === cachedLeaf) {
      return cacheHitRate;
    }

    let reads = 0;
    let prompt = 0;
    for (const entry of sessionManager.getEntries()) {
      let usage: Usage | undefined;
      if (
        entry.type === 'usage' ||
        entry.type === 'compaction' ||
        entry.type === 'branch_summary'
      ) {
        usage = entry.usage;
      } else if (
        entry.type === 'message' &&
        (entry.message.role === 'assistant' ||
          entry.message.role === 'toolResult')
      ) {
        usage = entry.message.usage;
      }
      if (usage) {
        reads += usage.cacheRead;
        prompt += usage.input + usage.cacheRead + usage.cacheWrite;
      }
    }
    cachedSession = session;
    cachedLeaf = leaf;
    cacheHitRate = prompt > 0 ? (reads / prompt) * 100 : undefined;
    return cacheHitRate;
  };
}
