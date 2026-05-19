const CHROME_UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

export class HttpError extends Error {
  readonly status: number;
  readonly body: string;

  constructor(status: number, statusText: string, body: string) {
    super(`HTTP ${status} ${statusText}: ${body || '(no body)'}`);
    this.status = status;
    this.body = body;
  }
}

export interface RequestOptions {
  method?: 'GET' | 'POST';
  headers?: Record<string, string>;
  body?: string;
  signal: AbortSignal;
}

export async function requestJson(
  url: string,
  opts: RequestOptions,
): Promise<unknown> {
  const response = await fetch(url, {
    method: opts.method ?? 'GET',
    headers: {
      'User-Agent': CHROME_UA,
      Accept: 'application/json',
      ...opts.headers,
    },
    body: opts.body,
    signal: opts.signal,
    redirect: 'follow',
  });

  const raw = await response.text();

  if (!response.ok) {
    throw new HttpError(response.status, response.statusText, raw);
  }

  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw);
  } catch {
    throw new Error(`response was not valid JSON: ${raw.slice(0, 200)}`);
  }
}

export function asString(value: unknown, fallback = ''): string {
  return typeof value === 'string' ? value : fallback;
}

export function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

export function asObject(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

export function mapResults<T>(
  values: unknown[],
  mapper: (raw: unknown) => T | null,
): T[] {
  const out: T[] = [];
  for (const v of values) {
    const mapped = mapper(v);
    if (mapped) {
      out.push(mapped);
    }
  }
  return out;
}
