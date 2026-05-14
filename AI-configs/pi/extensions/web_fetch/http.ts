const MAX_BYTES = 10 * 1024 * 1024;

const CHROME_UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

export const BROWSER_HEADERS: Record<string, string> = {
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
  'image/x-icon': 'ico',
  'image/vnd.microsoft.icon': 'ico',
  'video/mp4': 'mp4',
  'audio/mpeg': 'mp3',
};

export interface ContentTypeInfo {
  type: string;
  isMarkdown: boolean;
  isJson: boolean;
  isHtml: boolean;
  isText: boolean;
}

export function parseContentType(header: string | null): ContentTypeInfo {
  const type = (header ?? '').split(';')[0]?.trim().toLowerCase() ?? '';
  return {
    type,
    isMarkdown: type === 'text/markdown' || type === 'text/x-markdown',
    isJson: type === 'application/json' || /\+json$/.test(type),
    isHtml: type === 'text/html' || type === 'application/xhtml+xml',
    isText: type.startsWith('text/'),
  };
}

export function extForType(type: string): string {
  if (EXT_BY_TYPE[type]) {
    return EXT_BY_TYPE[type];
  }
  const subtype = type.split('/')[1]?.replace(/[^a-z0-9]/g, '');
  return subtype || 'bin';
}

export async function readCapped(
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

export async function readHttpErrorExcerpt(
  response: Response,
): Promise<string | undefined> {
  const ct = (response.headers.get('content-type') ?? '').toLowerCase();
  const looksTextual =
    ct === '' ||
    ct.startsWith('text/') ||
    ct.includes('json') ||
    ct.includes('xml') ||
    ct.includes('javascript');
  if (!looksTextual) {
    return undefined;
  }

  const reader = response.body?.getReader();
  if (!reader) {
    return undefined;
  }

  const READ_CAP = 8 * 1024;
  const DISPLAY_CAP = 400;

  try {
    const chunks: Buffer[] = [];
    let bytes = 0;
    while (bytes < READ_CAP) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }
      if (!value) {
        continue;
      }
      chunks.push(Buffer.from(value));
      bytes += value.byteLength;
    }
    await reader.cancel().catch(() => {});
    const raw = Buffer.concat(chunks)
      .toString('utf8')
      .replace(/\s+/g, ' ')
      .trim();
    if (!raw) {
      return undefined;
    }
    return raw.length > DISPLAY_CAP ? `${raw.slice(0, DISPLAY_CAP)}...` : raw;
  } catch {
    await reader.cancel().catch(() => {});
    return undefined;
  }
}
