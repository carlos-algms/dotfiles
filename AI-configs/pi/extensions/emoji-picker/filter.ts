import { pruneTags } from './tags.ts';
import type { Emoji, RawEmoji } from './types.ts';

const FLAGS_GROUP = 9;
const LIGHT_TONE = 1;
// Woman, optional skin-tone modifier, then a ZWJ joiner: 👩‍💻, 👩🏻‍💻.
const WOMAN_SEQUENCE = /^👩[\u{1F3FB}-\u{1F3FF}]?\u200d/u;

// "man: light skin tone, beard" -> "man: beard"; "man: light skin tone" -> "man";
// "kiss: man, man, light skin tone" -> "kiss: man, man".
function stripTone(label: string): string {
  return label.replace(
    /(: |, )light skin tone(, |$)/,
    (_match, separator: string, tail: string) => (tail ? separator : ''),
  );
}

function isFemale(variant: { emoji: string; gender?: 0 | 1 | null }): boolean {
  return variant.gender === 0 || WOMAN_SEQUENCE.test(variant.emoji);
}

export function selectEmojis(raw: readonly RawEmoji[]): Emoji[] {
  const result: Emoji[] = [];
  for (const entry of raw) {
    // No group: regional indicators, the building blocks of flags.
    if (entry.group === undefined || entry.group === FLAGS_GROUP) {
      continue;
    }
    // Scalar tone only: array tones are mixed-tone pairs.
    const variant =
      entry.skins?.find((skin) => skin.tone === LIGHT_TONE) ?? entry;
    if (isFemale(variant)) {
      continue;
    }
    const label = stripTone(variant.label);
    result.push({
      emoji: variant.emoji,
      label,
      tags: pruneTags(label, entry.tags ?? []),
    });
  }
  return result;
}
