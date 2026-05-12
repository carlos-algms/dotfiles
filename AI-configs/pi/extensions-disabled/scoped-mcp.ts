import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import {
  existsSync,
  lstatSync,
  mkdirSync,
  symlinkSync,
  unlinkSync,
} from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

export default async function (_pi: ExtensionAPI) {
  const home = homedir();
  const cwd = process.cwd();
  const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(home, '.pi/agent');

  const scopes: Array<[string, string]> = [
    [join(home, 'work'), join(agentDir, 'mcp-work.json')],
    [join(home, 'projects'), join(agentDir, 'mcp-personal.json')],
  ];

  const match = scopes.find(
    ([prefix]) => cwd === prefix || cwd.startsWith(prefix + '/'),
  );
  if (!match) return;
  const [, src] = match;
  if (!existsSync(src)) return;

  const piDir = join(cwd, '.pi');
  const target = join(piDir, 'mcp.json');
  mkdirSync(piDir, { recursive: true });

  if (existsSync(target)) {
    const st = lstatSync(target);
    if (st.isSymbolicLink()) unlinkSync(target);
    else return;
  }
  symlinkSync(src, target);
}
