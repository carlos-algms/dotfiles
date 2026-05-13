export type Phase = 'fetch' | 'http' | 'read' | 'defuddle';

export interface CauseInfo {
  code?: string;
  message?: string;
  syscall?: string;
  hostname?: string;
  address?: string;
  port?: number | string;
  aggregateCount?: number;
}
