/**
 * emoji-picker: type ` :name` to pick an emoji from the autocomplete dropdown.
 * Recently picked emojis rank first; they persist in the XDG state dir.
 */
import { homedir } from 'node:os';
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { fuzzyMatch } from '@earendil-works/pi-tui';
import { EMOJIS } from './emojis.ts';
import { createEmojiProvider } from './provider.ts';
import {
  loadRecents,
  pushRecent,
  recentsPath,
  recordRecent,
} from './recents.ts';

const MAX_RESULTS = 50;

export default function (pi: ExtensionAPI): void {
  pi.on('session_start', async (_event, ctx) => {
    const path = recentsPath(process.env, homedir());
    let recents = await loadRecents(path);
    // Serialise writes so picks apply in order.
    let saving: Promise<void> = Promise.resolve();

    ctx.ui.addAutocompleteProvider((current) =>
      createEmojiProvider(current, {
        emojis: EMOJIS,
        fuzzyMatch,
        getRecents: () => recents,
        limit: MAX_RESULTS,
        onPick(emoji) {
          recents = pushRecent(recents, emoji);
          saving = saving
            .then(async () => {
              recents = await recordRecent(path, emoji);
            })
            .catch((error: unknown) => {
              ctx.ui.notify(
                `emoji-picker: cannot save recents: ${String(error)}`,
                'warning',
              );
            });
        },
      }),
    );
  });
}
