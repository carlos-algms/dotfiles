import type { Emoji } from './types.ts';

export interface FuzzyResult {
  matches: boolean;
  score: number;
}

/** Lower score is better. Same contract as `fuzzyMatch` from `@earendil-works/pi-tui`. */
export type FuzzyMatch = (query: string, text: string) => FuzzyResult;

// Literal substrings beat subsequence matches: pi-tui's matcher is greedy, so `shru` can rank
// "straight ruler" above "person shrugging" and `idk` can match "medium-dark".
type Tier = 0 | 1 | 2 | 3; // name substring, tag substring, name subsequence, tag subsequence

interface Ranked {
  emoji: Emoji;
  recentIndex: number;
  tier: Tier;
  score: number;
}

const NOT_RECENT = Number.POSITIVE_INFINITY;

function rank(
  emoji: Emoji,
  query: string,
  fuzzyMatch: FuzzyMatch,
): Pick<Ranked, 'tier' | 'score'> | undefined {
  const needle = query.toLowerCase();
  const candidates: Pick<Ranked, 'tier' | 'score'>[] = [];
  const texts: [string, Tier, Tier][] = [
    [emoji.label, 0, 2],
    ...emoji.tags.map((tag): [string, Tier, Tier] => [tag, 1, 3]),
  ];
  for (const [text, substringTier, subsequenceTier] of texts) {
    const result = fuzzyMatch(query, text);
    if (result.matches) {
      candidates.push({
        tier: text.toLowerCase().includes(needle)
          ? substringTier
          : subsequenceTier,
        score: result.score,
      });
    }
  }
  return candidates.sort((a, b) => a.tier - b.tier || a.score - b.score)[0];
}

function byRelevance(a: Ranked, b: Ranked): number {
  if (a.recentIndex !== b.recentIndex) {
    return a.recentIndex < b.recentIndex ? -1 : 1;
  }
  return a.tier - b.tier || a.score - b.score;
}

/** Recents first (newest first), then name matches, then tag-only matches. Empty query matches all. */
export function searchEmojis(
  emojis: readonly Emoji[],
  query: string,
  recents: readonly string[],
  fuzzyMatch: FuzzyMatch,
  limit: number,
): Emoji[] {
  const needle = query.trim();
  const ranked: Ranked[] = [];
  for (const emoji of emojis) {
    const found =
      needle === ''
        ? { tier: 0 as Tier, score: 0 }
        : rank(emoji, needle, fuzzyMatch);
    if (!found) {
      continue;
    }
    const index = recents.indexOf(emoji.emoji);
    ranked.push({
      emoji,
      recentIndex: index === -1 ? NOT_RECENT : index,
      ...found,
    });
  }
  // Array.prototype.sort is stable, so ties keep dataset order.
  return ranked
    .sort(byRelevance)
    .slice(0, limit)
    .map((entry) => entry.emoji);
}
