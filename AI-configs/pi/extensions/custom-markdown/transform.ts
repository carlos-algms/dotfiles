import type { MarkdownTransformContext } from '@earendil-works/pi-coding-agent';

export function transformUserMarkdown(
  markdown: string,
  context: MarkdownTransformContext,
): string {
  if (context.messageType !== 'user') {
    return markdown;
  }

  const output: string[] = [];
  let previousQuote = false;
  let fence = '';

  for (const line of markdown.split('\n')) {
    const source = line.replace(/\r$/, '');
    if (fence) {
      const closing = /^ {0,3}(`+|~+)[ \t]*$/.exec(source)?.[1];
      if (
        closing &&
        closing.charAt(0) === fence.charAt(0) &&
        closing.length >= fence.length
      ) {
        fence = '';
      }
      output.push(line);
      continue;
    }

    if (previousQuote && !source.startsWith('>') && source.trim() !== '') {
      output.push(output.at(-1)?.endsWith('\r') ? '\r' : '');
    }

    const opening = /^ {0,3}(`{3,}|~{3,})(.*)$/.exec(source);
    const markers = opening?.[1];
    if (markers && !(markers.startsWith('`') && opening[2]?.includes('`'))) {
      fence = markers;
    }
    previousQuote = source.startsWith('>');
    output.push(line);
  }

  return output.join('\n');
}
