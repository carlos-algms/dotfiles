import type { Register } from 'claude-code';
import { expandFenceSnippet } from './fence-snippet';

type Offer = { text: string; end: number; inside: number };

export const register: Register = (on) => {
  // shortcut: a module variable is lost on reload, at worst one taken fence leaves the cursor at its end
  let offer: Offer | undefined;

  on('prompt.autocomplete', async ($, e, next) => {
    const rows = await next(e);
    // Taking a row puts the cursor after it and asks again: move it inside.
    if (offer && e.text === offer.text && e.cursor === offer.end) {
      const { inside } = offer;
      offer = undefined;
      await $.prompt.fill({ text: e.text, cursor: inside });
      return rows;
    }
    const box = expandFenceSnippet(e.text, e.cursor);
    if (!box) {
      offer = undefined;
      return rows;
    }
    const tail = e.text.length - e.cursor;
    const text = box.text.slice(e.start, box.text.length - tail);
    offer = { text: box.text, end: box.text.length - tail, inside: box.cursor };
    return {
      suggestions: [
        { text, label: 'press Tab to generate fenced block' },
        ...rows.suggestions,
      ],
    };
  });
};
