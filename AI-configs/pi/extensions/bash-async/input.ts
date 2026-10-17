interface OpenPanelInput {
  panelOpen: boolean;
  editorText: string;
  editorFocused: boolean;
  jobCount: number;
}

/** `→` opens the panel only from an empty, focused prompt with a job to show. Otherwise the key passes through. */
export function shouldOpenPanel(input: OpenPanelInput): boolean {
  return (
    !input.panelOpen &&
    input.editorFocused &&
    input.editorText === '' &&
    input.jobCount > 0
  );
}

const EDITOR_METHODS = [
  'render',
  'invalidate',
  'handleInput',
  'getText',
  'setText',
];

/**
 * pi-tui has no focus getter, and `instanceof` is unreliable across module
 * boundaries, so detect the prompt editor by its methods (same as pi-subagents).
 */
export function isEditorFocused(focused: unknown): boolean {
  if (!focused || typeof focused !== 'object') {
    return false;
  }
  const candidate = focused as Record<string, unknown>;
  return EDITOR_METHODS.every((name) => typeof candidate[name] === 'function');
}
