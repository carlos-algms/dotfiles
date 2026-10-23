import type { MessageRenderer } from '@earendil-works/pi-coding-agent';
import { keyHint } from '@earendil-works/pi-coding-agent';
import { Box, Spacer, Text } from '@earendil-works/pi-tui';
import { collapseCompletion } from './format.ts';

const COLLAPSED_TAIL_LINES = 5;

/** Same box and label as pi's default custom message, with the tail cut until expanded. */
export const renderCompletion: MessageRenderer = (message, options, theme) => {
  const content =
    typeof message.content === 'string'
      ? message.content
      : message.content
          .flatMap((part) => (part.type === 'text' ? [part.text] : []))
          .join('\n');
  const { text, hidden } = options.expanded
    ? { text: content, hidden: 0 }
    : collapseCompletion(content, COLLAPSED_TAIL_LINES);

  const box = new Box(options.outputPad, 1, (line) =>
    theme.bg('customMessageBg', line),
  );
  box.addChild(
    new Text(
      theme.fg('customMessageLabel', `\x1b[1m[${message.customType}]\x1b[22m`),
      0,
      0,
    ),
  );
  box.addChild(new Spacer(1));
  box.addChild(new Text(theme.fg('customMessageText', text), 0, 0));
  if (hidden > 0) {
    box.addChild(
      new Text(
        theme.fg(
          'muted',
          `... (${hidden} earlier lines, ${keyHint('app.tools.expand', 'to expand')})`,
        ),
        0,
        0,
      ),
    );
  }
  return box;
};
