import type { LineMotion } from './line-edits.ts';

export type FindKind = 'f' | 'F' | 't' | 'T';
// ; repeats the last find, , reverses it.
export const FLIP_FIND: Record<FindKind, FindKind> = {
  f: 'F',
  F: 'f',
  t: 'T',
  T: 't',
};
type EditPrefix = 'd' | 'c';
type CharEdit = `${EditPrefix}${'t' | 'f'}`;
type ObjectEdit = `${EditPrefix}${'i' | 'a'}`;

export type PendingOp =
  | EditPrefix
  | 'g'
  | 'gu'
  | 'gU'
  | 'dg'
  | 'cg'
  | CharEdit
  | ObjectEdit
  | FindKind;

type Step =
  | PendingOp
  | { kind: 'cancel' | 'firstLine' }
  | { kind: 'find'; find: FindKind; target: string }
  | { kind: 'lineEdit'; range: LineMotion; change: boolean }
  | {
      kind: 'motionEdit';
      sequence: string;
      forward: boolean;
      guardLineStart: boolean;
      change: boolean;
    }
  | { kind: 'textObject'; key: string; outer: boolean; change: boolean }
  | { kind: 'charEdit'; target: string; inclusive: boolean; change: boolean }
  | { kind: 'wordEndEdit'; change: boolean }
  | { kind: 'case'; sequences: string[]; upper: boolean };

// One row per motion. Both operators read it: d/c send `delete` (with
// `forward` meaning the delete never joins lines), or `wordEnd` for the region
// de/dE need; gu/gU move over `cursor` to find the region. `guardLineStart`
// makes the operator a no-op at column 0.
// CSI-u for Alt+D so the sequence also works in Kitty keyboard mode.
type Motion = {
  cursor: string[];
  guardLineStart?: true;
} & ({ delete: string; forward?: true } | { wordEnd: true });

export const MOTIONS: Record<string, Motion> = {
  w: { delete: '\x1b[100;3u', forward: true, cursor: ['\x1b[1;3C'] },
  W: { delete: '\x1b[100;3u', forward: true, cursor: ['\x1b[1;3C'] },
  e: { wordEnd: true, cursor: ['\x1b[1;3C'] },
  E: { wordEnd: true, cursor: ['\x1b[1;3C'] },
  b: { delete: '\x17', cursor: ['\x1b[1;3D'] },
  B: { delete: '\x17', cursor: ['\x1b[1;3D'] },
  h: { delete: '\x7f', cursor: ['\x1b[D'], guardLineStart: true },
  l: { delete: '\x1b[3~', forward: true, cursor: ['\x1b[C'] },
  '0': { delete: '\x15', cursor: ['\x01'], guardLineStart: true },
  $: { delete: '\x0b', forward: true, cursor: ['\x05'] },
};
const CANCEL = { kind: 'cancel' } as const;

function isFindKind(key: string): key is FindKind {
  return key in FLIP_FIND;
}

// Null passes the key to the editor; cancel consumes it without an action.
export function resolvePendingOperator(
  pending: PendingOp | null,
  key: string,
  escape: boolean,
): Step | null {
  if (escape) {
    return pending ? CANCEL : null;
  }
  if (!pending) {
    return key === 'd' || key === 'c' || key === 'g' || isFindKind(key)
      ? key
      : null;
  }
  if (key.charCodeAt(0) < 32) {
    return null;
  }

  switch (pending) {
    case 'g':
      if (key === 'g') {
        return { kind: 'firstLine' };
      }
      return key === 'u' ? 'gu' : key === 'U' ? 'gU' : CANCEL;
    case 'f':
    case 'F':
    case 't':
    case 'T':
      return key.length === 1
        ? { kind: 'find', find: pending, target: key }
        : CANCEL;
    case 'd':
    case 'c': {
      const change = pending === 'c';
      if (key === pending) {
        return { kind: 'lineEdit', range: 'current', change };
      }
      if (
        key === 't' ||
        key === 'f' ||
        key === 'g' ||
        key === 'i' ||
        key === 'a'
      ) {
        return `${pending}${key}`;
      }
      if (key === 'G' || key === 'j' || key === 'k') {
        const range = key === 'G' ? 'toLast' : key === 'j' ? 'down' : 'up';
        return { kind: 'lineEdit', range, change };
      }
      const motion = MOTIONS[key];
      if (!motion) {
        return CANCEL;
      }
      if ('wordEnd' in motion) {
        return { kind: 'wordEndEdit', change };
      }

      return {
        kind: 'motionEdit',
        sequence: motion.delete,
        forward: motion.forward === true,
        guardLineStart: motion.guardLineStart === true,
        change,
      };
    }
    case 'dg':
    case 'cg':
      return key === 'g'
        ? { kind: 'lineEdit', range: 'toFirst', change: pending === 'cg' }
        : CANCEL;
    case 'di':
    case 'da':
    case 'ci':
    case 'ca':
      return {
        kind: 'textObject',
        key,
        outer: pending.endsWith('a'),
        change: pending.startsWith('c'),
      };
    case 'dt':
    case 'df':
    case 'ct':
    case 'cf':
      return key.length === 1
        ? {
            kind: 'charEdit',
            target: key,
            inclusive: pending.endsWith('f'),
            change: pending.startsWith('c'),
          }
        : CANCEL;
    case 'gu':
    case 'gU': {
      const motion = MOTIONS[key];

      return motion
        ? { kind: 'case', sequences: motion.cursor, upper: pending === 'gU' }
        : CANCEL;
    }
    default:
      return pending satisfies never;
  }
}
