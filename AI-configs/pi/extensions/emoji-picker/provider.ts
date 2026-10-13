import type {
  AutocompleteItem,
  AutocompleteProvider,
} from '@earendil-works/pi-tui';
import { searchEmojis } from './match.ts';
import type { FuzzyMatch } from './match.ts';
import type { Emoji } from './types.ts';

export interface EmojiProviderDeps {
  emojis: readonly Emoji[];
  fuzzyMatch: FuzzyMatch;
  getRecents: () => readonly string[];
  onPick: (emoji: string) => void;
  limit: number;
}

const TRIGGER = ':';
// ":" starting a token (line start or after whitespace) up to the cursor.
const EMOJI_TOKEN = /(?:^|\s)(:\S*)$/;

function toItem(emoji: Emoji): AutocompleteItem {
  return { value: emoji.emoji, label: `${emoji.emoji} ${emoji.label}` };
}

export function createEmojiProvider(
  current: AutocompleteProvider,
  deps: EmojiProviderDeps,
): AutocompleteProvider {
  const known = new Set(deps.emojis.map((entry) => entry.emoji));
  return {
    triggerCharacters: [...(current.triggerCharacters ?? []), TRIGGER],

    async getSuggestions(lines, cursorLine, cursorCol, options) {
      const beforeCursor = (lines[cursorLine] ?? '').slice(0, cursorCol);
      const token = EMOJI_TOKEN.exec(beforeCursor)?.[1];
      if (token === undefined) {
        return current.getSuggestions(lines, cursorLine, cursorCol, options);
      }
      const found = searchEmojis(
        deps.emojis,
        token.slice(TRIGGER.length),
        deps.getRecents(),
        deps.fuzzyMatch,
        deps.limit,
      );
      return found.length === 0
        ? null
        : { items: found.map(toItem), prefix: token };
    },

    applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
      if (!prefix.startsWith(TRIGGER) || !known.has(item.value)) {
        return current.applyCompletion(
          lines,
          cursorLine,
          cursorCol,
          item,
          prefix,
        );
      }
      const line = lines[cursorLine] ?? '';
      const start = cursorCol - prefix.length;
      const nextLines = [...lines];
      nextLines[cursorLine] =
        line.slice(0, start) + item.value + line.slice(cursorCol);
      deps.onPick(item.value);
      return {
        lines: nextLines,
        cursorLine,
        cursorCol: start + item.value.length,
      };
    },

    shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
      return (
        current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ??
        true
      );
    },
  };
}
