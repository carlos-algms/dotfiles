import type { Model } from '@earendil-works/pi-ai';

export const PROVIDER_ID = 'nous';
export const NOUS_BASE_URL = 'https://inference-api.nousresearch.com/v1';

const REQUEST_TIMEOUT_MS = 15_000;

/** The fields of a Nous `/v1/models` entry this extension reads. */
export interface RawModel {
  id: string;
  name?: string;
  pricing?: { prompt?: string; completion?: string };
  top_provider?: { context_length?: number; max_completion_tokens?: number };
  architecture?: { input_modalities?: string[] };
  reasoning?: unknown;
}

export type NousModel = Model<'openai-completions'>;
type FetchLike = (input: string, init?: RequestInit) => Promise<Response>;

function isRawModel(value: unknown): value is RawModel {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    typeof value.id === 'string'
  );
}

export function parseModelList(body: unknown): RawModel[] {
  if (
    typeof body !== 'object' ||
    body === null ||
    !('data' in body) ||
    !Array.isArray(body.data)
  ) {
    throw new Error('Nous /models: unexpected body');
  }
  return body.data.filter(isRawModel);
}

/** Prices are `$/token` strings. Both must parse to 0, so embedding models (input only) are out. */
export function isFree(model: RawModel): boolean {
  return (
    Number.parseFloat(model.pricing?.prompt ?? '') === 0 &&
    Number.parseFloat(model.pricing?.completion ?? '') === 0
  );
}

function isPositive(value: number | undefined): value is number {
  return value !== undefined && value > 0;
}

/** Pi accepts only these two; Nous also lists video. */
function toInput(
  modalities: readonly string[] | undefined,
): ('text' | 'image')[] {
  const allowed = (modalities ?? []).filter(
    (modality): modality is 'text' | 'image' =>
      modality === 'text' || modality === 'image',
  );
  return allowed.length > 0 ? allowed : ['text'];
}

/**
 * Limits come from `top_provider`, not the top-level `context_length`, which often
 * differs. A model without a usable limit is skipped: a guessed limit would either
 * compact too early or be rejected mid-conversation.
 */
export function toModel(raw: RawModel, baseUrl: string): NousModel | undefined {
  const contextWindow = raw.top_provider?.context_length;
  const maxTokens = raw.top_provider?.max_completion_tokens;
  if (!isPositive(contextWindow) || !isPositive(maxTokens)) {
    return undefined;
  }
  return {
    id: raw.id,
    name: raw.name ?? raw.id,
    api: 'openai-completions',
    provider: PROVIDER_ID,
    baseUrl,
    input: toInput(raw.architecture?.input_modalities),
    reasoning: raw.reasoning != null,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow,
    maxTokens,
  };
}

export interface FetchFreeModelsOptions {
  fetch: FetchLike;
  signal: AbortSignal;
  baseUrl?: string;
}

/** `/models` is public, so no credential is sent. */
export async function fetchFreeModels({
  fetch,
  signal,
  baseUrl = NOUS_BASE_URL,
}: FetchFreeModelsOptions): Promise<NousModel[]> {
  const base = baseUrl.replace(/\/+$/, '');
  const url = `${base}/models`;
  const response = await fetch(url, {
    headers: { accept: 'application/json' },
    signal: AbortSignal.any([signal, AbortSignal.timeout(REQUEST_TIMEOUT_MS)]),
  });
  if (!response.ok) {
    throw new Error(`${url} -> HTTP ${response.status}`);
  }
  return parseModelList(await response.json())
    .filter(isFree)
    .flatMap((raw) => toModel(raw, base) ?? []);
}
