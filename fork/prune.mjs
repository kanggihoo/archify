#!/usr/bin/env node
// Removes the paths in fork/prune.list from the index and working tree.
// Run it after `git merge upstream/main`: it also resolves modify/delete conflicts on those paths.
//   node fork/prune.mjs          remove listed paths that are still tracked
//   node fork/prune.mjs --check  only report them; exit 1 if any are tracked
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const git = (...args) => spawnSync('git', args, { cwd: root, encoding: 'utf8' });
const paths = fs.readFileSync(path.join(root, 'fork/prune.list'), 'utf8')
  .split(/\r?\n/).map(line => line.trim()).filter(line => line && !line.startsWith('#'));
const check = process.argv.includes('--check');
let tracked = 0;

for (const entry of paths) {
  const listed = git('ls-files', '--', entry).stdout.trim();
  if (!listed) continue;
  tracked += listed.split('\n').length;
  if (check) { console.log(`still tracked: ${entry}`); continue; }
  const result = git('rm', '-r', '-f', '--quiet', '--', entry);
  console.log(result.status === 0 ? `removed: ${entry}` : `FAILED: ${entry}\n${result.stderr}`);
}
console.log(tracked ? (check ? `${tracked} tracked file(s) remain` : 'done') : 'nothing to remove');
process.exit(check && tracked ? 1 : 0);
