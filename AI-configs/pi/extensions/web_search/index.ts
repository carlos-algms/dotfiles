import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { keyHint } from '@earendil-works/pi-coding-agent';
import { Text } from '@earendil-works/pi-tui';
import { Type } from 'typebox';
import { formatFooter, formatResults } from './format.ts';
import { orchestrate } from './orchestrator.ts';
import {
  DEFAULT_NUM_RESULTS,
  MAX_NUM_RESULTS,
  PRIORITY_ORDER,
} from './registry.ts';
import type { BackendName } from './types.ts';

const DEFAULT_TIMEOUT_MS = 30_000;

export default function piWebSearchTool(pi: ExtensionAPI) {
  pi.registerTool({
    name: 'web_search',
    label: 'Web Search',
    description:
      'Search the web for open-ended questions, current facts, keyword lookups, ' +
      'documentations, definitions, and source discovery.',
    promptSnippet:
      'Search the web (2 providers in parallel, URL-deduped). Returns Markdown results with provider summaries/snippets.',
    promptGuidelines: [
      'Use web_search for open-ended web lookup; prefer it over curl or guessed URLs.',
      'Runs 2 providers in parallel and dedupes by URL; do not repeat the same query to compare providers.',
      'Default numResults is enough. If results miss, rephrase with different keywords (max 2-3 attempts, then report what is missing). More results do not improve relevance.',
      'Results are provider snippets/summaries, not full pages. Use web_fetch on a result URL for details.',
      'No pagination, domain or date filters.',
      'For github.com use gh; for a known URL use web_fetch.',
      'Omit provider by default. Set only for a clear fit: exa code/docs/papers (semantic), tavily current events, brave mainstream, langsearch broad, marginalia indie/small-web.',
    ],
    parameters: Type.Object({
      query: Type.String({
        description: 'Search query. Plain English or keywords.',
      }),
      numResults: Type.Optional(
        Type.Integer({
          minimum: 1,
          maximum: MAX_NUM_RESULTS,
          description: `Results per provider (default ${DEFAULT_NUM_RESULTS}, max ${MAX_NUM_RESULTS}). Keep the default; rephrasing the query improves results, more results do not.`,
        }),
      ),
      provider: Type.Optional(
        Type.Union(
          PRIORITY_ORDER.map((name) => Type.Literal(name)),
          {
            description:
              'Force a single backend. Omit unless there is a clear fit; falls back to the default pair if unavailable.',
          },
        ),
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
      const body = formatResults(outcome.results);
      const durationMs = Date.now() - startedAt;

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
        .split(/\n========\n/)
        .map((r) => r.trim())
        .filter((r) => r.length > 0);
      const ellipsis = theme.fg('muted', '...');
      const folded = results.map((r) => {
        const rLines = r.split('\n');
        const header = rLines[0] ?? '';
        const meta: string[] = [];
        let bodyStart = 1;
        for (let i = 1; i < rLines.length; i++) {
          const line = rLines[i] ?? '';
          if (line.startsWith('- ')) {
            meta.push(line);
            continue;
          }
          bodyStart = i;
          break;
        }
        const snippet = rLines
          .slice(bodyStart)
          .map((l) => l.trim())
          .filter(Boolean)
          .join(' ');
        const short =
          snippet.length > SNIPPET_CHAR_LIMIT
            ? snippet.slice(0, SNIPPET_CHAR_LIMIT).trimEnd()
            : snippet;
        const out = [header, ...meta];
        if (short) {
          out.push(`  ${short}`);
        }
        out.push(ellipsis);
        return out.join('\n');
      });

      const hint = theme.fg('muted', keyHint('app.tools.expand', 'to expand'));
      const parts: string[] = [folded.join('\n\n')];
      if (footerText) parts.push(footerText);
      parts.push(hint);
      comp.setText(parts.join('\n\n'));
      return comp;
    },
  });
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
