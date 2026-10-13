/**
 * Drops tags that cannot change a search result. Any query that matches a tag
 * also matches a longer text that contains it (the label, or another tag), so
 * a tag that is a substring of the label or of another tag is redundant.
 */
export function pruneTags(label: string, tags: readonly string[]): string[] {
  const lowerLabel = label.toLowerCase();
  const lower = tags.map((tag) => tag.toLowerCase());
  return tags.filter((_tag, index) => {
    const tag = lower[index] ?? '';
    if (lowerLabel.includes(tag)) {
      return false;
    }
    // Equal duplicates: keep the first only.
    return !lower.some(
      (other, otherIndex) =>
        otherIndex !== index &&
        other.includes(tag) &&
        (other !== tag || otherIndex < index),
    );
  });
}
