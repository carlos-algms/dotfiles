import { asArray, asObject, asString, mapResults, requestJson } from '../http';
import type { SearchBackend, SearchResult } from '../types';

interface LangSearchRaw {
  name?: unknown;
  url?: unknown;
  snippet?: unknown;
  summary?: unknown;
}

function mapResult(raw: unknown): SearchResult | null {
  const r = asObject(raw) as LangSearchRaw;
  const url = asString(r.url);
  if (!url) {
    return null;
  }
  const title = asString(r.name);
  const summary = asString(r.summary);
  const snippet = summary || asString(r.snippet);
  return { title, url, snippet, sources: ['langsearch'] };
}

export const langsearch: SearchBackend = {
  name: 'langsearch',
  async run(query, numResults, apiKey, signal) {
    if (!apiKey) {
      throw new Error('LangSearch apiKey missing in web-search-auth.json');
    }
    const data = await requestJson('https://api.langsearch.com/v1/web-search', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query,
        count: numResults,
        summary: true,
      }),
      signal,
    });
    const root = asObject(data);
    const webPages = asObject(asObject(root.data).webPages);
    return mapResults(asArray(webPages.value), mapResult);
  },
};
