import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

const REMINDER =
  'TERSE-MODE active. Honor it unless user says "verbose" or "normal mode".';

export default function (pi: ExtensionAPI) {
  pi.on('context', async (event, _ctx) => {
    const messages = event.messages;
    for (let i = messages.length - 1; i >= 0; i--) {
      const m = messages[i];
      if (m.role !== 'user') continue;

      const tag = `\n\n<system-reminder>\n${REMINDER}\n</system-reminder>`;

      if (typeof m.content === 'string') {
        m.content = m.content + tag;
      } else if (Array.isArray(m.content)) {
        m.content = [...m.content, { type: 'text', text: tag }];
      }
      break;
    }
    return { messages };
  });
}
