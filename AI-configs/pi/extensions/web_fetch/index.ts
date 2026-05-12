import { spawn } from 'node:child_process';
import { mkdtemp, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';

const MAX_BYTES = 10 * 1024 * 1024;
const DEFAULT_TIMEOUT_MS = 30_000;

const CHROME_UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

const BROWSER_HEADERS: Record<string, string> = {
  'User-Agent': CHROME_UA,
  Accept:
    'text/markdown, application/json;q=0.95, text/html;q=0.9, application/xhtml+xml;q=0.9, */*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.9',
  'Accept-Encoding': 'gzip, deflate, br',
  'Upgrade-Insecure-Requests': '1',
  'Sec-Fetch-Dest': 'document',
  'Sec-Fetch-Mode': 'navigate',
  'Sec-Fetch-Site': 'none',
  'Sec-Fetch-User': '?1',
};

const EXT_BY_TYPE: Record<string, string> = {
  'application/pdf': 'pdf',
  'application/zip': 'zip',
  'application/gzip': 'gz',
  'application/x-tar': 'tar',
  'application/octet-stream': 'bin',
  'image/png': 'png',
  'image/jpeg': 'jpg',
  'image/gif': 'gif',
  'image/webp': 'webp',
  'image/svg+xml': 'svg',
  'video/mp4': 'mp4',
  'audio/mpeg': 'mp3',
};

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

      const response = await fetch(url, {
        method: 'GET',
        headers: BROWSER_HEADERS,
        redirect: 'follow',
        signal: combinedSignal,
      });

      if (!response.ok) {
        throw new Error(
          `HTTP ${response.status} ${response.statusText} for ${url.href}`,
        );
      }

      const status = response.status;
      const finalUrl = response.url;
      const finalUrlChanged = finalUrl !== url.href;
      const ct = parseContentType(response.headers.get('content-type'));

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
    },
  });
}

function parseContentType(header: string | null): {
  type: string;
  isMarkdown: boolean;
  isJson: boolean;
  isHtml: boolean;
  isText: boolean;
} {
  const type = (header ?? '').split(';')[0]?.trim().toLowerCase() ?? '';
  return {
    type,
    isMarkdown: type === 'text/markdown' || type === 'text/x-markdown',
    isJson: type === 'application/json' || /\+json$/.test(type),
    isHtml: type === 'text/html' || type === 'application/xhtml+xml',
    isText: type.startsWith('text/'),
  };
}

function extForType(type: string): string {
  if (EXT_BY_TYPE[type]) {
    return EXT_BY_TYPE[type];
  }
  const subtype = type.split('/')[1]?.replace(/[^a-z0-9]/g, '');
  return subtype || 'bin';
}

function formatSize(bytes: number): string {
  if (bytes < 1024) {
    return `${bytes} B`;
  }
  if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  }
  return `${(bytes / 1024 / 1024).toFixed(2)} MB`;
}

function buildFooter(args: {
  source: 'cloudflare-md' | 'defuddle';
  requestedUrl: string;
  finalUrl: string;
  durationMs: number;
  bytes: number;
}): string {
  const sourceLabel =
    args.source === 'cloudflare-md'
      ? 'cloudflare-md (Markdown for Agents, served by origin)'
      : 'defuddle (may have dropped non-article content)';
  const lines = [
    '---',
    '',
    `source: ${sourceLabel}`,
    `url: ${args.requestedUrl}`,
  ];
  if (args.finalUrl !== args.requestedUrl) {
    lines.push(`final-url: ${args.finalUrl}`);
  }
  lines.push(`duration: ${args.durationMs}ms`);
  lines.push(`size: ${formatSize(args.bytes)}`);
  return lines.join('\n');
}

async function readCapped(
  response: Response,
  signal: AbortSignal,
): Promise<{ buffer: Buffer; bytes: number }> {
  const declared = Number(response.headers.get('content-length'));
  if (Number.isFinite(declared) && declared > MAX_BYTES) {
    throw new Error(
      `response too large: content-length ${declared} bytes exceeds cap ${MAX_BYTES}`,
    );
  }

  const reader = response.body?.getReader();
  if (!reader) {
    return { buffer: Buffer.alloc(0), bytes: 0 };
  }

  const chunks: Buffer[] = [];
  let bytes = 0;

  while (true) {
    if (signal.aborted) {
      await reader.cancel().catch(() => {});
      throw new Error('aborted');
    }
    const { done, value } = await reader.read();
    if (done) {
      break;
    }
    if (!value) {
      continue;
    }
    bytes += value.byteLength;
    if (bytes > MAX_BYTES) {
      await reader.cancel().catch(() => {});
      throw new Error(
        `response too large: exceeded cap ${MAX_BYTES} bytes mid-stream`,
      );
    }
    chunks.push(Buffer.from(value));
  }

  return { buffer: Buffer.concat(chunks), bytes };
}

async function runDefuddle(html: string, signal: AbortSignal): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn('defuddle', ['parse', '/dev/stdin', '--md'], {
      stdio: ['pipe', 'pipe', 'pipe'],
      signal,
    });

    const stdoutChunks: Buffer[] = [];
    const stderrChunks: Buffer[] = [];

    child.stdout.on('data', (chunk: Buffer) => stdoutChunks.push(chunk));
    child.stderr.on('data', (chunk: Buffer) => stderrChunks.push(chunk));

    child.on('error', (err: NodeJS.ErrnoException) => {
      if (err.code === 'ENOENT') {
        reject(
          new Error(
            'defuddle not found on PATH. Install with: npm install -g defuddle',
          ),
        );
        return;
      }
      reject(err);
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve(Buffer.concat(stdoutChunks).toString('utf8'));
        return;
      }
      const stderr = Buffer.concat(stderrChunks).toString('utf8').trim();
      reject(
        new Error(
          `defuddle exited with code ${code}: ${stderr || '(no stderr)'}`,
        ),
      );
    });

    child.stdin.end(html, 'utf8');
  });
}
