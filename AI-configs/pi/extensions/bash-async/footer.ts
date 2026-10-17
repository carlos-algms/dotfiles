/** Text for the running-job count. `undefined` when no job runs. */
export function formatFooter(count: number): string | undefined {
  if (count === 0) {
    return undefined;
  }
  return `${count} async running · → to inspect`;
}

/** Widget lines: the text, left-aligned and cut to the width, or none. */
export function footerLines(count: number, width: number): string[] {
  const text = formatFooter(count);
  if (text === undefined) {
    return [];
  }
  return [text.slice(0, width)];
}
