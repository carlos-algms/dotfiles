import { brave } from './backends/brave.ts';
import { exa } from './backends/exa.ts';
import { langsearch } from './backends/langsearch.ts';
import { marginalia } from './backends/marginalia.ts';
import { tavily } from './backends/tavily.ts';
import type { BackendName, SearchBackend } from './types.ts';

export const PRIORITY_ORDER: BackendName[] = [
  'exa',
  'tavily',
  'brave',
  'langsearch',
  'marginalia',
];

export const DEFAULT_PARALLEL = 2;

const ALL: Record<BackendName, SearchBackend> = {
  langsearch,
  tavily,
  exa,
  brave,
  marginalia,
};

export function getBackend(name: BackendName): SearchBackend {
  return ALL[name];
}
