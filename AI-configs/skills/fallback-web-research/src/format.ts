import type { BackendName, BackendOutcome, SearchResult } from './types.ts';

const RESULT_SEPARATOR = '\n\n========\n\n';

export function formatResults(results: SearchResult[]): string {
  if (results.length === 0) {
    return '(no results)';
  }
  return results
    .map((r, idx) => {
      const title = r.title || r.url;
      const provider = r.sources.join(', ');
      const lines = [
        `## Result ${idx + 1}: ${title}`,
        `- URL: ${r.url}`,
        `- provider: ${provider}`,
      ];
      if (r.snippet) {
        lines.push('', r.snippet.trim());
      }
      return lines.join('\n');
    })
    .join(RESULT_SEPARATOR);
}

export function formatFooter(
  query: string,
  outcomes: BackendOutcome[],
  durationMs: number,
  resultCount: number,
  providerBypassed: BackendName | null,
  aiSummarised: boolean,
): string {
  const summary = outcomes
    .map((o) => {
      const detail =
        o.status === 'ok'
          ? `ok (${o.count}, ${o.durationMs}ms)`
          : `${o.status}${o.message ? `: ${o.message}` : ''}`;
      return `  ${o.backend}: ${detail}`;
    })
    .join('\n');
  const lines = [
    '---',
    '',
    `query: ${query}`,
    `results: ${resultCount} after dedupe`,
    `ai-summary: ${aiSummarised ? 'ok' : 'fallback (raw results)'}`,
    `total duration: ${durationMs}ms`,
    'backends:',
    summary || '  (none)',
  ];
  if (providerBypassed) {
    lines.push(
      `provider override "${providerBypassed}" bypassed (unavailable); fell through to queue.`,
    );
  }
  return lines.join('\n');
}
