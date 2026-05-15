import { mkdtemp, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { runDefuddle } from './defuddle';
import { enrichError } from './errors';
import {
  BROWSER_HEADERS,
  extForType,
  parseContentType,
  readCapped,
  readHttpErrorExcerpt,
} from './http';
import { buildFooter, renderCall, renderResult } from './render';
import type { Phase } from './types';

const DEFAULT_TIMEOUT_MS = 30_000;

export default function piWebFetchTool(pi: ExtensionAPI) {
  pi.registerTool({
    name: 'web_fetch',
    label: 'Web Fetch',
    description:
      'Fetch known http/https URLs for full-page reading, source verification, ' +
      'JSON, and plain text.',
    promptSnippet: 'Fetch a known URL as markdown, JSON, or text.',
    promptGuidelines: [
      'Use web_fetch when you already have a URL and need full page content, source verification, JSON, or plain text.',
      'Prefer web_fetch over curl/wget for http/https GET; web_fetch converts HTML to markdown and formats JSON/text for the model.',
      'Do not use web_fetch for topic discovery; use web_search first when you only have a topic or keywords.',
      'Use gh, not web_fetch, for github.com repos, files, issues, PRs, releases, and API data; use web_fetch on GitHub only when gh cannot retrieve the URL.',
      'Fall back from web_fetch to bash and curl/defuddle only for non-GET requests or unsupported schemes/content types.',
    ],
    parameters: Type.Object({
      url: Type.String({
        description: 'The URL to fetch (http or https only).',
      }),
      timeoutMs: Type.Optional(
        Type.Integer({
          minimum: 1000,
          maximum: 300_000,
          description: 'Request timeout in milliseconds. Default 30000.',
        }),
      ),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
      const rawUrl = params.url.trim().replace(/^@/, '');
      let url: URL;
      try {
        url = new URL(rawUrl);
      } catch {
        throw new Error(`invalid URL: ${rawUrl}`);
      }
      if (url.protocol !== 'http:' && url.protocol !== 'https:') {
        throw new Error(
          `unsupported scheme: ${url.protocol}. Only http: and https: are allowed.`,
        );
      }

      const timeoutMs = params.timeoutMs ?? DEFAULT_TIMEOUT_MS;
      const timeoutSignal = AbortSignal.timeout(timeoutMs);
      const combinedSignal = signal
        ? AbortSignal.any([signal, timeoutSignal])
        : timeoutSignal;

      const startedAt = Date.now();
      let phase: Phase = 'fetch';
      let httpExtras: string[] | undefined;

      try {
        const response = await fetch(url, {
          method: 'GET',
          headers: BROWSER_HEADERS,
          redirect: 'follow',
          signal: combinedSignal,
        });

        if (!response.ok) {
          phase = 'http';
          httpExtras = [];
          if (response.url && response.url !== url.href) {
            httpExtras.push(`final-url: ${response.url}`);
          }
          const excerpt = await readHttpErrorExcerpt(response);
          if (excerpt) {
            httpExtras.push(`body: ${excerpt}`);
          }
          throw new Error(`HTTP ${response.status} ${response.statusText}`);
        }

        const status = response.status;
        const finalUrl = response.url;
        const finalUrlChanged = finalUrl !== url.href;
        const ct = parseContentType(response.headers.get('content-type'));

        phase = 'read';
        const { buffer, bytes } = await readCapped(response, combinedSignal);

        const detailsBase = {
          url: url.href,
          finalUrl,
          status,
          contentType: ct.type,
          bytes,
        };

        if (bytes === 0) {
          return {
            content: [
              {
                type: 'text',
                text: finalUrlChanged
                  ? `Final URL: ${finalUrl}\n\n(empty body)`
                  : '(empty body)',
              },
            ],
            details: { ...detailsBase, source: 'empty' },
          };
        }

        if (ct.isMarkdown) {
          const body = buffer.toString('utf8');
          const footer = buildFooter({
            source: 'cloudflare-md',
            requestedUrl: url.href,
            finalUrl,
            durationMs: Date.now() - startedAt,
            bytes,
          });
          return {
            content: [{ type: 'text', text: `${body}\n\n${footer}` }],
            details: { ...detailsBase, source: 'cloudflare-md' },
          };
        }

        if (ct.isJson) {
          const raw = buffer.toString('utf8');
          let pretty: string;
          let source: 'json' | 'json-raw';
          try {
            pretty = JSON.stringify(JSON.parse(raw), null, 2);
            source = 'json';
          } catch {
            pretty = raw;
            source = 'json-raw';
          }
          const fenced = `\`\`\`json\n${pretty}\n\`\`\``;
          const text = finalUrlChanged
            ? `${fenced}\n\nFinal URL: ${finalUrl}`
            : fenced;
          return {
            content: [{ type: 'text', text }],
            details: { ...detailsBase, source },
          };
        }

        if (ct.isHtml) {
          const html = buffer.toString('utf8');
          phase = 'defuddle';
          const md = await runDefuddle(html, combinedSignal);
          const footer = buildFooter({
            source: 'defuddle',
            requestedUrl: url.href,
            finalUrl,
            durationMs: Date.now() - startedAt,
            bytes,
          });
          return {
            content: [{ type: 'text', text: `${md}\n\n${footer}` }],
            details: { ...detailsBase, source: 'defuddle' },
          };
        }

        if (ct.isText) {
          const body = buffer.toString('utf8');
          const text = finalUrlChanged
            ? `${body}\n\nFinal URL: ${finalUrl}`
            : body;
          return {
            content: [{ type: 'text', text }],
            details: { ...detailsBase, source: 'text' },
          };
        }

        const dir = await mkdtemp(join(tmpdir(), 'pi-webfetch-'));
        const ext = extForType(ct.type);
        const filePath = join(dir, `download.${ext}`);
        await writeFile(filePath, buffer);

        const summary = [
          `Binary/unsupported content saved to disk.`,
          `URL: ${url.href}`,
          finalUrlChanged ? `Final URL: ${finalUrl}` : null,
          `Path: ${filePath}`,
          `Content-Type: ${ct.type}`,
          `Bytes: ${bytes}`,
        ]
          .filter(Boolean)
          .join('\n');

        return {
          content: [{ type: 'text', text: summary }],
          details: { ...detailsBase, source: 'binary', filePath },
        };
      } catch (err) {
        throw enrichError({
          err,
          url: url.href,
          phase,
          timeoutMs,
          elapsedMs: Date.now() - startedAt,
          outerSignal: signal,
          timeoutSignal,
          extraLines: httpExtras,
        });
      }
    },

    renderCall,
    renderResult,
  });
}
