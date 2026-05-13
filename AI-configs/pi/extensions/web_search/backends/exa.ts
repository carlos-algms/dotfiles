import { asArray, asObject, asString, mapResults, requestJson } from '../http';
import type { SearchBackend, SearchResult } from '../types';

interface ExaRaw {
  title?: unknown;
  url?: unknown;
  summary?: unknown;
  text?: unknown;
}

function mapResult(raw: unknown): SearchResult | null {
  const r = asObject(raw) as ExaRaw;
  const url = asString(r.url);
  if (!url) {
    return null;
  }
  const summary = asString(r.summary);
  const text = asString(r.text);
  return {
    title: asString(r.title),
    url,
    snippet: summary || text.slice(0, 500),
    sources: ['exa'],
  };
}

export const exa: SearchBackend = {
  name: 'exa',
  async run(query, numResults, apiKey, signal) {
    if (!apiKey) {
      throw new Error('Exa apiKey missing in web-search-auth.json');
    }
    const data = await requestJson('https://api.exa.ai/search', {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query,
        numResults,
        contents: { summary: true },
      }),
      signal,
    });
    const root = asObject(data);
    return mapResults(asArray(root.results), mapResult);
  },
};
