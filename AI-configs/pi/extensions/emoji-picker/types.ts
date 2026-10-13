/** Subset of an `emojibase-data` entry (en/data.json). */
export interface RawSkin {
  emoji: string;
  label: string;
  tone: number | number[];
  gender?: 0 | 1 | null;
}

export interface RawEmoji {
  emoji: string;
  label: string;
  tags?: string[];
  group?: number;
  gender?: 0 | 1 | null;
  skins?: RawSkin[];
}

export interface Emoji {
  emoji: string;
  label: string;
  tags: readonly string[];
}
