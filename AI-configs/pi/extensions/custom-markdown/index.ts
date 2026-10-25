import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { transformUserMarkdown } from './transform.ts';

export default function customMarkdown(
  pi: Pick<ExtensionAPI, 'registerMarkdownTransformer'>,
) {
  pi.registerMarkdownTransformer(transformUserMarkdown);
}
