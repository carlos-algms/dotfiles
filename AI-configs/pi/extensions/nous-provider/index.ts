import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

import { buildNousProvider } from './provider.ts';

export default function nousProvider(pi: ExtensionAPI): void {
  pi.registerProvider(buildNousProvider());
}
