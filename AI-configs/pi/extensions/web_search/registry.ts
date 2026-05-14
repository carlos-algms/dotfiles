import { brave } from './backends/brave';
import { exa } from './backends/exa';
import { langsearch } from './backends/langsearch';
import { marginalia } from './backends/marginalia';
import { tavily } from './backends/tavily';
import type { BackendName, SearchBackend } from './types';

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
