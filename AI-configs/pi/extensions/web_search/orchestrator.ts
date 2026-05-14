import { keyFor, loadAuth } from './config';
import { DEFAULT_PARALLEL, PRIORITY_ORDER, getBackend } from './registry';
import type { BackendName, BackendOutcome, SearchResult } from './types';
import { reserve } from './usage';

export interface OrchestrateOptions {
  query: string;
  numResults: number;
  provider?: BackendName;
  signal: AbortSignal;
}

export interface OrchestrateResult {
  results: SearchResult[];
  outcomes: BackendOutcome[];
  providerBypassed: BackendName | null;
}

const TRACKING_PARAM = /^(utm_|gclid$|fbclid$)/i;

function normalizeUrl(url: string): string {
  try {
    const u = new URL(url);
    u.hash = '';
    const params = new URLSearchParams();
    for (const [k, v] of u.searchParams) {
      if (!TRACKING_PARAM.test(k)) {
        params.append(k, v);
      }
    }
    params.sort();
    const query = params.toString();
    u.search = query ? `?${query}` : '';
    if (u.pathname.length > 1 && u.pathname.endsWith('/')) {
      u.pathname = u.pathname.slice(0, -1);
    }
    return u.toString();
  } catch {
    return url;
  }
}

function dedupe(batches: SearchResult[][]): SearchResult[] {
  const byKey = new Map<string, SearchResult>();
  for (const batch of batches) {
    for (const r of batch) {
      const key = normalizeUrl(r.url);
      const existing = byKey.get(key);
      if (existing) {
        for (const src of r.sources) {
          if (!existing.sources.includes(src)) {
            existing.sources.push(src);
          }
        }
        if (r.snippet && !existing.snippet.includes(r.snippet)) {
          existing.snippet = existing.snippet
            ? `${existing.snippet}\n\n---\n\n${r.snippet}`
            : r.snippet;
        }
        if (!existing.title && r.title) {
          existing.title = r.title;
        }
      } else {
        byKey.set(key, { ...r, sources: [...r.sources] });
      }
    }
  }
  return [...byKey.values()];
}

async function runOne(
  name: BackendName,
  query: string,
  numResults: number,
  apiKey: string,
  signal: AbortSignal,
): Promise<{ outcome: BackendOutcome; results: SearchResult[] }> {
  const startedAt = Date.now();
  const gate = await reserve(name);
  if (!gate.ok) {
    return {
      results: [],
      outcome: {
        backend: name,
        status: gate.reason === 'rate' ? 'skipped-rate' : 'skipped-quota',
        count: 0,
        durationMs: 0,
        message: gate.message,
      },
    };
  }
  try {
    const backend = getBackend(name);
    const results = await backend.run(query, numResults, apiKey, signal);
    await gate.commit();
    return {
      results,
      outcome: {
        backend: name,
        status: 'ok',
        count: results.length,
        durationMs: Date.now() - startedAt,
      },
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return {
      results: [],
      outcome: {
        backend: name,
        status: 'error',
        count: 0,
        durationMs: Date.now() - startedAt,
        message,
      },
    };
  }
}

export async function orchestrate(
  opts: OrchestrateOptions,
): Promise<OrchestrateResult> {
  const auth = await loadAuth();
  const outcomes: BackendOutcome[] = [];
  const batches: SearchResult[][] = [];
  let providerBypassed: BackendName | null = null;

  if (opts.provider) {
    const result = await runOne(
      opts.provider,
      opts.query,
      opts.numResults,
      keyFor(auth, opts.provider),
      opts.signal,
    );
    outcomes.push(result.outcome);
    if (result.outcome.status === 'ok') {
      return {
        results: dedupe([result.results]),
        outcomes,
        providerBypassed: null,
      };
    }
    providerBypassed = opts.provider;
  }

  const targetSlots = DEFAULT_PARALLEL;
  const queue = PRIORITY_ORDER.filter((b) => b !== opts.provider);
  let okCount = 0;

  while (okCount < targetSlots && queue.length > 0) {
    const remaining = targetSlots - okCount;
    const slice = queue.splice(0, remaining);
    const wave = await Promise.all(
      slice.map((name) =>
        runOne(
          name,
          opts.query,
          opts.numResults,
          keyFor(auth, name),
          opts.signal,
        ),
      ),
    );
    for (const r of wave) {
      outcomes.push(r.outcome);
      if (r.outcome.status === 'ok') {
        okCount += 1;
        batches.push(r.results);
      }
    }
  }

  return {
    results: dedupe(batches),
    outcomes,
    providerBypassed,
  };
}
