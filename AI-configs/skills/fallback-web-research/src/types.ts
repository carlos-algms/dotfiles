export const BACKEND_NAMES = [
  'langsearch',
  'tavily',
  'exa',
  'brave',
  'marginalia',
] as const;

const BACKEND_NAME_SET: ReadonlySet<string> = new Set(BACKEND_NAMES);

export type BackendName = (typeof BACKEND_NAMES)[number];

export function isBackendName(value: string): value is BackendName {
  return BACKEND_NAME_SET.has(value);
}

export interface SearchResult {
  title: string;
  url: string;
  snippet: string;
  sources: BackendName[];
}

export interface BackendOutcome {
  backend: BackendName;
  status: 'ok' | 'skipped-quota' | 'skipped-rate' | 'error';
  count: number;
  durationMs: number;
  message?: string;
}

export interface SearchBackend {
  name: BackendName;
  run(
    query: string,
    numResults: number,
    apiKey: string | undefined,
    signal: AbortSignal,
  ): Promise<SearchResult[]>;
}
