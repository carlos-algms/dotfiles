import { asArray, asObject, asString, mapResults, requestJson } from '../http.ts';
import type { SearchBackend, SearchResult } from '../types.ts';

interface TavilyRaw {
  title?: unknown;
  url?: unknown;
  content?: unknown;
}

function mapResult(raw: unknown): SearchResult | null {
  const r = asObject(raw) as TavilyRaw;
  const url = asString(r.url);
  if (!url) {
    return null;
  }
  return {
    title: asString(r.title),
    url,
    snippet: asString(r.content),
    sources: ['tavily'],
  };
}

export const tavily: SearchBackend = {
  name: 'tavily',
  async run(query, numResults, apiKey, signal) {
    if (!apiKey) {
      throw new Error('Tavily apiKey missing in web-search-auth.json');
    }
    const data = await requestJson('https://api.tavily.com/search', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        api_key: apiKey,
        query,
        max_results: numResults,
        search_depth: 'advanced',
        chunks_per_source: 3,
      }),
      signal,
    });
    const root = asObject(data);
    return mapResults(asArray(root.results), mapResult);
  },
};
