export type BackendName = 'langsearch' | 'tavily' | 'exa' | 'marginalia';

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
