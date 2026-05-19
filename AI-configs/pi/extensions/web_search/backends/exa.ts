import { asArray, asObject, asString, mapResults, requestJson } from '../http.ts';
import type { SearchBackend, SearchResult } from '../types.ts';

interface ExaRaw {
  title?: unknown;
  url?: unknown;
  summary?: unknown;
  highlights?: unknown;
  text?: unknown;
}

function mapResult(raw: unknown): SearchResult | null {
  const r = asObject(raw) as ExaRaw;
  const url = asString(r.url);
  if (!url) {
    return null;
  }
  const summary = asString(r.summary);
  const highlights = Array.isArray(r.highlights)
    ? r.highlights.filter((h): h is string => typeof h === 'string').join(' ... ')
    : '';
  const text = asString(r.text);
  const snippet = [summary, highlights, text].filter(Boolean).join('\n\n') || text;
  return {
    title: asString(r.title),
    url,
    snippet,
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
        contents: {
          summary: true,
          highlights: { numSentences: 3, highlightsPerUrl: 1 },
          text: { maxCharacters: 2000 },
        },
      }),
      signal,
    });
    const root = asObject(data);
    return mapResults(asArray(root.results), mapResult);
  },
};
