import { asArray, asObject, asString, mapResults, requestJson } from '../http';
import type { SearchBackend, SearchResult } from '../types';

interface BraveRaw {
  title?: unknown;
  url?: unknown;
  description?: unknown;
}

function mapResult(raw: unknown): SearchResult | null {
  const r = asObject(raw) as BraveRaw;
  const url = asString(r.url);
  if (!url) {
    return null;
  }
  return {
    title: asString(r.title),
    url,
    snippet: asString(r.description),
    sources: ['brave'],
  };
}

export const brave: SearchBackend = {
  name: 'brave',
  async run(query, numResults, apiKey, signal) {
    if (!apiKey) {
      throw new Error('Brave apiKey missing in web-search-auth.json');
    }
    const url =
      `https://api.search.brave.com/res/v1/web/search?` +
      `q=${encodeURIComponent(query)}&count=${numResults}`;
    const data = await requestJson(url, {
      headers: {
        'X-Subscription-Token': apiKey,
        Accept: 'application/json',
      },
      signal,
    });
    const root = asObject(data);
    const web = asObject(root.web);
    return mapResults(asArray(web.results), mapResult);
  },
};
