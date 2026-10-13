import assert from 'node:assert/strict';
import { test } from 'node:test';
import { selectEmojis } from './filter.ts';
import type { RawEmoji } from './types.ts';

const smile: RawEmoji = {
  emoji: '😀',
  label: 'grinning face',
  tags: ['smile'],
  group: 0,
};
const ZWJ = '\u200d';

function names(raw: RawEmoji[]): string[] {
  return selectEmojis(raw).map((e) => e.label);
}

test('maps an entry to emoji, label and tags', () => {
  assert.deepEqual(selectEmojis([smile]), [
    { emoji: '😀', label: 'grinning face', tags: ['smile'] },
  ]);
});

test('prunes tags that the final label already contains', () => {
  const entry: RawEmoji = {
    emoji: '😀',
    label: 'grinning face',
    tags: ['face', 'smile'],
    group: 0,
  };
  assert.deepEqual(selectEmojis([entry])[0]?.tags, ['smile']);
});

test('defaults missing tags to an empty list', () => {
  assert.deepEqual(
    selectEmojis([{ emoji: '😐️', label: 'neutral face', group: 0 }])[0]?.tags,
    [],
  );
});

test('drops flags (group 9)', () => {
  const flag: RawEmoji = {
    emoji: '🇺🇸',
    label: 'flag: United States',
    group: 9,
  };
  assert.deepEqual(names([smile, flag]), ['grinning face']);
});

test('drops entries without a group (regional indicators)', () => {
  const indicator: RawEmoji = { emoji: '🇦', label: 'regional indicator A' };
  assert.deepEqual(names([smile, indicator]), ['grinning face']);
});

test('drops female variants (gender 0) and keeps male and neutral ones', () => {
  const entries: RawEmoji[] = [
    { emoji: '🤷', label: 'person shrugging', group: 1, gender: null },
    { emoji: '🤷‍♂️', label: 'man shrugging', group: 1, gender: 1 },
    { emoji: '🤷‍♀️', label: 'woman shrugging', group: 1, gender: 0 },
  ];
  assert.deepEqual(names(entries), ['person shrugging', 'man shrugging']);
});

test('drops sequences that start with a woman and a ZWJ, keeps the standalone woman', () => {
  const entries: RawEmoji[] = [
    { emoji: '👩', label: 'woman', group: 1, gender: null },
    {
      emoji: `👩${ZWJ}💻`,
      label: 'woman technologist',
      group: 1,
      gender: null,
    },
  ];
  assert.deepEqual(names(entries), ['woman']);
});

test('replaces a toneable base with its light-tone variant, inheriting tags', () => {
  const man: RawEmoji = {
    emoji: '👨',
    label: 'man',
    tags: ['adult', 'bro'],
    group: 1,
    skins: [
      { emoji: '👨🏻', label: 'man: light skin tone', tone: 1 },
      { emoji: '👨🏿', label: 'man: dark skin tone', tone: 5 },
    ],
  };
  assert.deepEqual(selectEmojis([man]), [
    { emoji: '👨🏻', label: 'man', tags: ['adult', 'bro'] },
  ]);
});

test('ignores mixed-tone pairs and picks the same-tone variant', () => {
  const pair: RawEmoji = {
    emoji: '🧑‍🤝‍🧑',
    label: 'people holding hands',
    group: 1,
    skins: [
      {
        emoji: '🧑🏻‍🤝‍🧑🏼',
        label: 'people holding hands: light skin tone, medium-light skin tone',
        tone: [1, 2],
      },
      { emoji: '🧑🏻‍🤝‍🧑🏻', label: 'people holding hands: light skin tone', tone: 1 },
    ],
  };
  assert.deepEqual(names([pair]), ['people holding hands']);
});

test('applies the strip rules to the light-tone variant', () => {
  const entries: RawEmoji[] = [
    {
      emoji: '🤷‍♀️',
      label: 'woman shrugging',
      group: 1,
      gender: 0,
      skins: [
        {
          emoji: '🤷🏻‍♀️',
          label: 'woman shrugging: light skin tone',
          tone: 1,
          gender: 0,
        },
      ],
    },
    {
      emoji: `👩${ZWJ}💻`,
      label: 'woman technologist',
      group: 1,
      skins: [
        {
          emoji: `👩🏻${ZWJ}💻`,
          label: 'woman technologist: light skin tone',
          tone: 1,
        },
      ],
    },
    {
      emoji: '👩',
      label: 'woman',
      group: 1,
      skins: [{ emoji: '👩🏻', label: 'woman: light skin tone', tone: 1 }],
    },
  ];
  assert.deepEqual(names(entries), ['woman']);
});

test('drops the skin tone from the label but keeps other details', () => {
  const entries: RawEmoji[] = [
    {
      emoji: '🧔',
      label: 'person: beard',
      group: 1,
      skins: [
        {
          emoji: '🧔🏻',
          label: 'person: light skin tone, beard',
          tone: 1,
        },
      ],
    },
    {
      emoji: '🚶‍➡️',
      label: 'person walking facing right',
      group: 1,
      skins: [
        {
          emoji: '🚶🏻‍➡️',
          label: 'person walking facing right: light skin tone',
          tone: 1,
        },
      ],
    },
  ];
  assert.deepEqual(names(entries), [
    'person: beard',
    'person walking facing right',
  ]);
});

test('drops a trailing skin tone that follows a comma list', () => {
  const kiss: RawEmoji = {
    emoji: '👨‍❤️‍💋‍👨',
    label: 'kiss: man, man',
    group: 1,
    skins: [
      {
        emoji: '👨🏻‍❤️‍💋‍👨🏻',
        label: 'kiss: man, man, light skin tone',
        tone: 1,
      },
    ],
  };
  assert.deepEqual(names([kiss]), ['kiss: man, man']);
});
