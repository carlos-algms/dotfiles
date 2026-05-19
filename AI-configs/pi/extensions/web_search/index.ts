import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { keyHint } from '@earendil-works/pi-coding-agent';
import { Text } from '@earendil-works/pi-tui';
import { Type } from 'typebox';
import { summarizeResults } from './ai-summary.ts';
import { formatFooter, formatResults } from './format.ts';
import { orchestrate } from './orchestrator.ts';
import { PRIORITY_ORDER } from './registry.ts';
import type { BackendName } from './types.ts';

const DEFAULT_TIMEOUT_MS = 30_000;
const DEFAULT_NUM_RESULTS = 10;

export default function piWebSearchTool(pi: ExtensionAPI) {
  pi.registerTool({
    name: 'web_search',
    label: 'Web Search',
    description:
      'Search the web for open-ended questions, current facts, keyword lookups, ' +
      'documentations, definitions, and source discovery.',
    promptSnippet:
      'Search the web via parallel providers with fallback and ai dedupe and returns Markdown results.',
    promptGuidelines: [
      'Use web_search for open-ended web lookup; prefer web_search over curl or guessed URLs.',
      'web_search searches 2 providers in parallel and dedupes, do not repeat the same query to compare backends.',
      'Use web_search again with better keywords when results are weak or confidence is low.',
      'You can use web_fetch on web_search result URLs when summaries are insufficient or user ask for details',
      'Use gh for github.com lookups; web_search is not for direct-source fetches.',
      'Use web_search provider only for backend debugging or clear fit: exa code/docs/repos, semantic, find-similar, papers; tavily current web, RAG snippets, extract/crawl; brave independent mainstream; langsearch free broad; marginalia indie/small-web long-tail.',
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
      const aiBody = await summarizeResults(
        query,
        outcome.results,
        combinedSignal,
      );
      const body = aiBody ?? formatResults(outcome.results);
      const durationMs = Date.now() - startedAt;

      const footer = formatFooter(
        query,
        outcome.outcomes,
        durationMs,
        outcome.results.length,
        outcome.providerBypassed,
        aiBody !== null,
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
