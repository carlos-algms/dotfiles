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
      'Fetch a URL (GET only) and return its content in an LLM-friendly form: ' +
      'markdown for HTML pages (via Cloudflare Accept: text/markdown when supported, ' +
      'otherwise via defuddle), pretty-printed JSON for JSON responses, raw text ' +
      'for plain text, or a temp-file path for binary content. Spoofs a Chrome ' +
      'User-Agent to reduce 403s from sites that block default HTTP clients. ' +
      'Allows http and https only. Caps response size at 10MB.',
    promptSnippet:
      'Retrieve URL contents as markdown/JSON/text. GET only. Prefer over bash curl/wget.',
    promptGuidelines: [
      'Use web_fetch to retrieve URL contents instead of bash curl/wget; it handles markdown conversion, JSON pretty-printing, bot-block workarounds, and TLS safely. Only fall back to bash for non-GET requests or when web_fetch returns an unsupported scheme/content-type error.',
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
          `Path: ${filePath}`,
          `Content-Type: ${ct.type}`,
          `Bytes: ${bytes}`,
          finalUrlChanged ? `Final URL: ${finalUrl}` : null,
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
