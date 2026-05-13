import { asArray, asObject, asString, mapResults, requestJson } from '../http';
import type { SearchBackend, SearchResult } from '../types';

interface MarginaliaRaw {
  url?: unknown;
  title?: unknown;
  description?: unknown;
}

function mapResult(raw: unknown): SearchResult | null {
  const r = asObject(raw) as MarginaliaRaw;
  const url = asString(r.url);
  if (!url) {
    return null;
  }
  return {
    title: asString(r.title),
    url,
    snippet: asString(r.description),
    sources: ['marginalia'],
  };
}

export const marginalia: SearchBackend = {
  name: 'marginalia',
  async run(query, numResults, apiKey, signal) {
    const key = apiKey || 'public';
    const url =
      `https://api2.marginalia-search.com/search?` +
      `query=${encodeURIComponent(query)}&count=${numResults}`;
    const data = await requestJson(url, {
      headers: { 'API-Key': key },
      signal,
    });
    const root = asObject(data);
    return mapResults(asArray(root.results), mapResult);
  },
};
