import type {
  AgentToolResult,
  Theme,
  ToolRenderResultOptions,
} from '@earendil-works/pi-coding-agent';
import { formatSize, keyHint } from '@earendil-works/pi-coding-agent';
import { Text } from '@earendil-works/pi-tui';

/**
 * Structural subset of pi's `ToolRenderContext` covering only fields read here.
 * pi does not re-export `ToolRenderContext` from the package root, so this
 * stays decoupled from internal pi paths while remaining contravariantly
 * compatible with the full type.
 */
interface RenderContext {
  lastComponent?: unknown;
  isError?: boolean;
}

export function buildFooter(args: {
  source: 'cloudflare-md' | 'defuddle';
  requestedUrl: string;
  finalUrl: string;
  durationMs: number;
  bytes: number;
}): string {
  const sourceLabel =
    args.source === 'cloudflare-md'
      ? 'cloudflare-md (Markdown for Agents, served by origin)'
      : 'defuddle (may have dropped non-article content)';
  const lines = [
    '---',
    '',
    `source: ${sourceLabel}`,
    `url: ${args.requestedUrl}`,
  ];
  if (args.finalUrl !== args.requestedUrl) {
    lines.push(`final-url: ${args.finalUrl}`);
  }
  lines.push(`duration: ${args.durationMs}ms`);
  lines.push(`size: ${formatSize(args.bytes)}`);
  return lines.join('\n');
}

export function renderCall(
  args: { url?: unknown } | undefined,
  theme: Theme,
  context: RenderContext,
): Text {
  const comp =
    (context.lastComponent as Text | undefined) ?? new Text('', 0, 0);
  let text = theme.fg('toolTitle', theme.bold('web_fetch'));
  if (typeof args?.url === 'string' && args.url) {
    text += ' ' + theme.fg('accent', args.url);
  }
  comp.setText(text);
  return comp;
}

export function renderResult(
  result: AgentToolResult<unknown>,
  options: ToolRenderResultOptions,
  theme: Theme,
  context: RenderContext,
): Text {
  const comp =
    (context.lastComponent as Text | undefined) ?? new Text('', 0, 0);
  const first = result.content[0];
  const text = first?.type === 'text' ? first.text : '';

  if (options.expanded || context.isError || !text) {
    comp.setText(text);
    return comp;
  }

  const HEAD_LINES = 22;
  const lines = text.split('\n');
  const footerStart = findFooterStart(lines);

  if (footerStart === -1) {
    if (lines.length <= HEAD_LINES) {
      comp.setText(text);
      return comp;
    }
    const head = lines.slice(0, HEAD_LINES).join('\n');
    const hidden = lines.length - HEAD_LINES;
    const hint = `... (${hidden} more lines, ${lines.length} total, ${keyHint('app.tools.expand', 'to expand')})`;
    comp.setText(`${head}\n\n${theme.fg('muted', hint)}`);
    return comp;
  }

  const body = lines.slice(0, footerStart);
  while (body.length > 0 && body[body.length - 1] === '') {
    body.pop();
  }
  const footer = lines.slice(footerStart).join('\n');

  if (body.length <= HEAD_LINES) {
    comp.setText(`${body.join('\n')}\n\n${footer}`);
    return comp;
  }

  const head = body.slice(0, HEAD_LINES).join('\n');
  const hidden = body.length - HEAD_LINES;
  const hint = `... (${hidden} more lines, ${body.length} total, ${keyHint('app.tools.expand', 'to expand')})`;
  comp.setText(`${head}\n\n${theme.fg('muted', hint)}\n\n${footer}`);
  return comp;
}

function findFooterStart(lines: string[]): number {
  for (let i = lines.length - 1; i >= 2; i--) {
    if (
      lines[i] === '---' &&
      lines[i - 1] === '' &&
      i + 2 < lines.length &&
      lines[i + 1] === '' &&
      lines[i + 2]?.startsWith('source:')
    ) {
      return i;
    }
  }
  return -1;
}
