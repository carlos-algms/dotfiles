import assert from 'node:assert/strict';
import { test } from 'node:test';
import type {
  AutocompleteProvider,
  AutocompleteSuggestions,
} from '@earendil-works/pi-tui';
import { createEmojiProvider } from './provider.ts';
import { fuzzy } from './test-fuzzy.ts';
import type { Emoji } from './types.ts';

const emojis: Emoji[] = [
  { emoji: '😀', label: 'grinning face', tags: ['smile'] },
  { emoji: '😐️', label: 'neutral face', tags: [] },
  { emoji: '🤷', label: 'person shrugging', tags: ['idk'] },
];
const signal = new AbortController().signal;
const FROM_CURRENT: AutocompleteSuggestions = {
  items: [{ value: 'cur', label: 'cur' }],
  prefix: 'cur',
};

interface Setup {
  provider: AutocompleteProvider;
  picked: string[];
  recents: string[];
}

function setup(): Setup {
  const picked: string[] = [];
  const recents: string[] = [];
  const current: AutocompleteProvider = {
    triggerCharacters: ['@'],
    getSuggestions: async () => FROM_CURRENT,
    applyCompletion: (lines, cursorLine) => ({
      lines: ['from current'],
      cursorLine,
      cursorCol: 0,
    }),
    shouldTriggerFileCompletion: () => false,
  };
  const provider = createEmojiProvider(current, {
    emojis,
    fuzzyMatch: fuzzy,
    getRecents: () => recents,
    onPick: (emoji) => picked.push(emoji),
    limit: 50,
  });
  return { provider, picked, recents };
}

async function suggest(
  provider: AutocompleteProvider,
  text: string,
): Promise<AutocompleteSuggestions | null> {
  return provider.getSuggestions([text], 0, text.length, { signal });
}

test('adds ":" to the trigger characters and keeps the existing ones', () => {
  assert.deepEqual(setup().provider.triggerCharacters, ['@', ':']);
});

test('delegates text that has no emoji token', async () => {
  assert.equal(await suggest(setup().provider, 'look at @src'), FROM_CURRENT);
});

test('does not trigger on a colon inside a word', async () => {
  assert.equal(await suggest(setup().provider, 'foo:shru'), FROM_CURRENT);
});

test('does not trigger once a space follows the token', async () => {
  assert.equal(await suggest(setup().provider, ':shru '), FROM_CURRENT);
});

test('a bare ":" at the line start lists emojis with the colon as prefix', async () => {
  const result = await suggest(setup().provider, ':');
  assert.equal(result?.prefix, ':');
  assert.deepEqual(
    result?.items.map((i) => i.value),
    ['😀', '😐️', '🤷'],
  );
});

test('" :shru" after text matches by fuzzy name and keeps the typed token as prefix', async () => {
  const result = await suggest(setup().provider, 'hello :shru');
  assert.equal(result?.prefix, ':shru');
  assert.deepEqual(
    result?.items.map((i) => i.value),
    ['🤷'],
  );
});

test('items show the emoji and its name', async () => {
  const result = await suggest(setup().provider, ':neutral');
  assert.deepEqual(result?.items, [{ value: '😐️', label: '😐️ neutral face' }]);
});

test('returns null when the token matches nothing', async () => {
  assert.equal(await suggest(setup().provider, ':zzz'), null);
});

test('reads recents on every request so a new pick moves to the top', async () => {
  const { provider, recents } = setup();
  recents.unshift('🤷');
  const result = await suggest(provider, ':');
  assert.equal(result?.items[0]?.value, '🤷');
});

test('applyCompletion swaps the token for the emoji and moves the cursor after it', () => {
  const { provider, picked } = setup();
  const result = provider.applyCompletion(
    ['hi :shru there'],
    0,
    8,
    { value: '🤷', label: '🤷 person shrugging' },
    ':shru',
  );
  assert.deepEqual(result, {
    lines: ['hi 🤷 there'],
    cursorLine: 0,
    cursorCol: 'hi 🤷'.length,
  });
  assert.deepEqual(picked, ['🤷']);
});

test('applyCompletion delegates items that are not emojis', () => {
  const { provider, picked } = setup();
  const result = provider.applyCompletion(
    ['@sr'],
    0,
    3,
    { value: '@src/', label: 'src/' },
    '@sr',
  );
  assert.deepEqual(result.lines, ['from current']);
  assert.deepEqual(picked, []);
});

test('shouldTriggerFileCompletion delegates to the wrapped provider', () => {
  assert.equal(
    setup().provider.shouldTriggerFileCompletion?.(['x'], 0, 1),
    false,
  );
});
