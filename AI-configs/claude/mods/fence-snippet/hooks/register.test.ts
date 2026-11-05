import { expect, test } from 'claude-code/testing';
import type { Engine } from 'claude-code/testing';
import type {
  PromptAutocompleteInput,
  PromptAutocompleteResult,
  PromptAutocompleteSuggestion,
  PromptFillInput,
} from 'claude-code';

type RaiseAutocomplete = (
  e: PromptAutocompleteInput,
) => Promise<PromptAutocompleteResult>;

// shortcut: the kit raises prompt.autocomplete at run time but its Engine type omits it, drop the cast once typed
function autocomplete(
  $: Engine,
  e: PromptAutocompleteInput,
): Promise<PromptAutocompleteResult> {
  return (
    $.prompt as unknown as { autocomplete: RaiseAutocomplete }
  ).autocomplete(e);
}

const ENGINE_ROW: PromptAutocompleteSuggestion = { text: '@engine' };

function ask(text: string, cursor = text.length): PromptAutocompleteInput {
  const start = text.slice(0, cursor).search(/\S+$/);
  return { text, cursor, token: text.slice(start, cursor), start };
}

const offers = [
  { name: 'lone backtick', text: '`', row: '````\n\n````' },
  { name: 'backtick + language', text: '`ts', row: '````ts\n\n````' },
  { name: 'bare language', text: 'c++', row: '````c++\n\n````' },
  { name: 'trigger on a later line', text: 'see:\n`sh', row: '````sh\n\n````' },
  {
    name: 'after a closed fence',
    text: '```\ncode\n```\n`ts',
    row: '````ts\n\n````',
  },
  {
    name: 'text after the cursor line',
    text: '`ts\nmore',
    row: '````ts\n\n````',
    cursor: 3,
  },
];

for (const { name, text, row, cursor } of offers) {
  test(`offers a fence row before the engine's: ${name}`, async ($, on) => {
    on('prompt.autocomplete', () => ({ suggestions: [ENGINE_ROW] }));

    expect(await autocomplete($, ask(text, cursor))).toEqual({
      suggestions: [
        { text: row, label: 'press Tab to generate fenced block' },
        ENGINE_ROW,
      ],
    });
  });
}

const noOffers = [
  { name: 'cursor not at end of line', edit: ask('`ts', 2) },
  { name: 'line with spaces', edit: ask('hello world') },
  { name: 'double backtick', edit: ask('``') },
  { name: 'inside a fence it made', edit: ask('````ts\nQQQ\n````', 10) },
  { name: 'inside an unclosed fence', edit: ask('```\n`ts') },
  { name: 'inside a tilde fence', edit: ask('~~~\nsh') },
  { name: 'shorter inner fence', edit: ask('````\n```\n`ts') },
];

for (const { name, edit } of noOffers) {
  test(`keeps the engine's rows only: ${name}`, async ($, on) => {
    on('prompt.autocomplete', () => ({ suggestions: [ENGINE_ROW] }));

    expect(await autocomplete($, edit)).toEqual({
      suggestions: [ENGINE_ROW],
    });
  });
}

test('taking the row moves the cursor inside the fence', async ($, on) => {
  const fills: PromptFillInput[] = [];
  on('prompt.autocomplete', () => ({ suggestions: [] }));
  on('prompt.fill', (_, e) => {
    fills.push(e);
    return { isFilled: true };
  });

  await autocomplete($, ask('see:\n`ts'));
  await autocomplete($, ask('see:\n````ts\n\n````'));

  expect(fills).toHaveLength(1);
  expect(fills[0]).toMatchObject({ text: 'see:\n````ts\n\n````', cursor: 12 });
});

test('a typed fence with no offer before it leaves the cursor', async ($, on) => {
  const fills: PromptFillInput[] = [];
  on('prompt.autocomplete', () => ({ suggestions: [] }));
  on('prompt.fill', (_, e) => {
    fills.push(e);
    return { isFilled: true };
  });

  await autocomplete($, ask('````ts\n\n````'));

  expect(fills).toEqual([]);
});
