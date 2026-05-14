import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { keyHint } from '@earendil-works/pi-coding-agent';
import { Text } from '@earendil-works/pi-tui';
import { Type } from 'typebox';
import { orchestrate } from './orchestrator';
import { PRIORITY_ORDER } from './registry';
import type { BackendName, BackendOutcome, SearchResult } from './types';

const DEFAULT_TIMEOUT_MS = 30_000;
const DEFAULT_NUM_RESULTS = 3;

export default function piWebSearchTool(pi: ExtensionAPI) {
  pi.registerTool({
    name: 'web_search',
    label: 'Web Search',
    description:
      'Search the web across multiple providers (LangSearch, Tavily, Exa, Marginalia) ' +
      'in parallel, dedupe by URL, and return markdown-formatted results with per-result ' +
      'source tags. Runs the top 2 priority backends by default; falls through to lower ' +
      'priority on quota exhaustion or failure. Provide `provider` to force a single ' +
      'backend (override falls back to the queue if that backend is unavailable).',
    promptSnippet:
      'Search the web via multiple providers in parallel with auto-fallback and dedupe.',
    promptGuidelines: [
      'Use web_search for any open-ended web lookup instead of bash curl or guessing URLs. The tool already runs 2 providers in parallel and dedupes - do not call it repeatedly with rephrased queries to "compare backends".',
      'Set `provider` on web_search only when comparing a known backend or when one backend uniquely suits the query (e.g. Marginalia for indie blogs, Exa for semantic / find-similar). Default fan-out covers most queries.',
    ],
    parameters: Type.Object({
      query: Type.String({
        description: 'Search query. Plain English or keywords.',
      }),
      numResults: Type.Optional(
        Type.Integer({
          minimum: 1,
          maximum: 20,
          description: `Results per backend (default ${DEFAULT_NUM_RESULTS}). Multiply by 2 for the parallel-backend total before dedupe.`,
        }),
      ),
      provider: Type.Optional(
        Type.Union(PRIORITY_ORDER.map((name) => Type.Literal(name))),
      ),
      timeoutMs: Type.Optional(
        Type.Integer({
          minimum: 1000,
          maximum: 300_000,
          description: `Per-request timeout in ms (default ${DEFAULT_TIMEOUT_MS}).`,
        }),
      ),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
      const query = params.query.trim();
      if (!query) {
        throw new Error('query is empty');
      }
      const numResults = params.numResults ?? DEFAULT_NUM_RESULTS;
      const timeoutMs = params.timeoutMs ?? DEFAULT_TIMEOUT_MS;

      const timeoutSignal = AbortSignal.timeout(timeoutMs);
      const combinedSignal = signal
        ? AbortSignal.any([signal, timeoutSignal])
        : timeoutSignal;

      const startedAt = Date.now();
      const outcome = await orchestrate({
        query,
        numResults,
        provider: params.provider as BackendName | undefined,
        signal: combinedSignal,
      });
      const durationMs = Date.now() - startedAt;

      const body = formatResults(outcome.results);
      const footer = formatFooter(
        query,
        outcome.outcomes,
        durationMs,
        outcome.results.length,
        outcome.providerBypassed,
      );

      return {
        content: [{ type: 'text', text: `${body}\n\n${footer}` }],
        details: {
          query,
          numResults,
          provider: params.provider ?? null,
          providerBypassed: outcome.providerBypassed,
          durationMs,
          resultCount: outcome.results.length,
          outcomes: outcome.outcomes,
        },
      };
    },

    renderCall(args, theme, context) {
      const comp =
        (context.lastComponent as Text | undefined) ?? new Text('', 0, 0);
      let text = theme.fg('toolTitle', theme.bold('web_search'));
      if (typeof args?.query === 'string' && args.query) {
        text += ' ' + theme.fg('accent', `"${args.query}"`);
      }
      if (typeof args?.provider === 'string' && args.provider) {
        text += ' ' + theme.fg('muted', `(provider: ${args.provider})`);
      }
      comp.setText(text);
      return comp;
    },

    renderResult(result, { expanded }, theme, context) {
      const comp =
        (context.lastComponent as Text | undefined) ?? new Text('', 0, 0);
      const first = result.content[0];
      const text = first && first.type === 'text' ? first.text : '';

      if (expanded || context.isError || !text) {
        comp.setText(text);
        return comp;
      }

      const lines = text.split('\n');
      const footerStart = findFooterStart(lines);

      let bodyLines: string[];
      let footerText: string;
      if (footerStart === -1) {
        bodyLines = lines;
        footerText = '';
      } else {
        bodyLines = lines.slice(0, footerStart);
        while (bodyLines.length > 0 && bodyLines[bodyLines.length - 1] === '') {
          bodyLines.pop();
        }
        footerText = lines.slice(footerStart).join('\n');
      }

      const bodyText = bodyLines.join('\n').trim();
      if (!bodyText || bodyText === '(no results)') {
        comp.setText(text);
        return comp;
      }

      const SNIPPET_CHAR_LIMIT = 200;
      const results = bodyText
        .split(/\n\n+/)
        .filter((r) => r.trim().length > 0);
      const ellipsis = theme.fg('muted', '...');
      const folded = results.map((r) => {
        const rLines = r.split('\n');
        const header = rLines[0];
        const snippet = rLines
          .slice(1)
          .map((l) => l.trim())
          .filter(Boolean)
          .join(' ');
        const short =
          snippet.length > SNIPPET_CHAR_LIMIT
            ? snippet.slice(0, SNIPPET_CHAR_LIMIT).trimEnd()
            : snippet;
        const out = [header];
        if (short) out.push(`  ${short}`);
        out.push(ellipsis);
        return out.join('\n');
      });

      const hint = theme.fg(
        'muted',
        keyHint('app.tools.expand', 'to expand'),
      );
      const parts: string[] = [folded.join('\n\n')];
      if (footerText) parts.push(footerText);
      parts.push(hint);
      comp.setText(parts.join('\n\n'));
      return comp;
    },
  });
}

function formatResults(results: SearchResult[]): string {
  if (results.length === 0) {
    return '(no results)';
  }
  return results
    .map((r) => {
      const tag = r.sources.join(', ');
      const title = r.title || r.url;
      const lines = [`- [${title}](${r.url}) (${tag})`];
      if (r.snippet) {
        lines.push(`  ${r.snippet.replace(/\s+/g, ' ').trim()}`);
      }
      return lines.join('\n');
    })
    .join('\n\n');
}

function formatFooter(
  query: string,
  outcomes: BackendOutcome[],
  durationMs: number,
  resultCount: number,
  providerBypassed: BackendName | null,
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
    `total duration: ${durationMs}ms`,
    `backends:`,
    summary || '  (none)',
  ];
  if (providerBypassed) {
    lines.push(
      `provider override "${providerBypassed}" bypassed (unavailable); fell through to queue.`,
    );
  }
  return lines.join('\n');
}

function findFooterStart(lines: string[]): number {
  for (let i = lines.length - 1; i >= 2; i--) {
    if (
      lines[i] === '---' &&
      lines[i - 1] === '' &&
      i + 2 < lines.length &&
      lines[i + 1] === '' &&
      lines[i + 2]?.startsWith('query:')
    ) {
      return i;
    }
  }
  return -1;
}
