import type { Provider } from '@earendil-works/pi-ai';
import {
  createProvider,
  envApiKeyAuth,
  openAICompletionsApi,
} from '@earendil-works/pi-ai/compat';

import { fetchFreeModels, NOUS_BASE_URL, PROVIDER_ID } from './catalog.ts';

/**
 * No baseline models: the list is fetched. Pi stores each fetch in
 * `models-store.json` and restores it at startup and offline.
 */
export function buildNousProvider(): Provider {
  return createProvider({
    id: PROVIDER_ID,
    name: 'Nous Portal',
    baseUrl: NOUS_BASE_URL,
    auth: { apiKey: envApiKeyAuth('Nous Portal API key', ['NOUS_API_KEY']) },
    models: [],
    api: openAICompletionsApi(),
    fetchModels: ({ signal, baseUrl }) =>
      fetchFreeModels({ fetch, signal, baseUrl }),
  });
}
