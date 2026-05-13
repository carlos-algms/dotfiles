import { spawn } from 'node:child_process';

export async function runDefuddle(
  html: string,
  signal: AbortSignal,
): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn('defuddle', ['parse', '/dev/stdin', '--md'], {
      stdio: ['pipe', 'pipe', 'pipe'],
      signal,
    });

    const stdoutChunks: Buffer[] = [];
    const stderrChunks: Buffer[] = [];

    child.stdout.on('data', (chunk: Buffer) => stdoutChunks.push(chunk));
    child.stderr.on('data', (chunk: Buffer) => stderrChunks.push(chunk));

    child.on('error', (err: NodeJS.ErrnoException) => {
      if (err.code === 'ENOENT') {
        reject(
          new Error(
            'defuddle not found on PATH. Install with: npm install -g defuddle',
          ),
        );
        return;
      }
      reject(err);
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve(Buffer.concat(stdoutChunks).toString('utf8'));
        return;
      }
      const stderr = Buffer.concat(stderrChunks).toString('utf8').trim();
      reject(
        new Error(
          `defuddle exited with code ${code}: ${stderr || '(no stderr)'}`,
        ),
      );
    });

    child.stdin.end(html, 'utf8');
  });
}
