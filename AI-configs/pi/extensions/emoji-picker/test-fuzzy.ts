import type { FuzzyMatch } from './match.ts';

// Subsequence matcher; shorter text scores better. Stands in for pi-tui's `fuzzyMatch`,
// which node cannot resolve outside the pi runtime.
export const fuzzy: FuzzyMatch = (query, text) => {
  let next = 0;
  for (const char of text.toLowerCase()) {
    if (char === query.toLowerCase()[next]) {
      next++;
    }
  }
  return { matches: next === query.length, score: text.length };
};
