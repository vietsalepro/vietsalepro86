// Audit that admin-dashboard RPC contracts stay in sync with the service code.
// Run: npx tsx scripts/audit-rpc-contracts.ts

import fs from 'fs';
import path from 'path';

const CONTRACT_PATH = path.resolve('docs/admin-dashboard/RPC_CONTRACTS.md');
const CODE_DIRS = ['services', 'lib'];
const EXCLUDED_FILES = ['services/supabaseService.ts'];

function walk(dir: string): string[] {
  const out: string[] = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...walk(p));
    } else if (entry.name.endsWith('.ts')) {
      out.push(p);
    }
  }
  return out;
}

function extractContractRpcs(markdown: string): Set<string> {
  const names = new Set<string>();
  for (const line of markdown.split(/\r?\n/)) {
    if (!line.trim().startsWith('|')) continue;
    // Match the first back-ticked value in a table row: | `rpc_name` | ...
    const match = /^\|\s*`([^`\s]+)`/.exec(line);
    if (!match) continue;
    const name = match[1].trim();
    // Skip markdown table headers/separators and non-identifier text.
    if (/^[a-z_][a-z_0-9]*$/.test(name)) {
      names.add(name);
    }
  }
  return names;
}

function extractCodeRpcs(filePaths: string[]): { names: Set<string>; byFile: Map<string, string[]> } {
  const names = new Set<string>();
  const byFile = new Map<string, string[]>();
  const rx = /supabase\.rpc\('([a-z_0-9]+)'/g;

  for (const p of filePaths) {
    const text = fs.readFileSync(p, 'utf-8');
    const fileNames: string[] = [];
    for (const m of text.matchAll(rx)) {
      names.add(m[1]);
      fileNames.push(m[1]);
    }
    if (fileNames.length) byFile.set(p, fileNames);
  }
  return { names, byFile };
}

function main(): number {
  if (!fs.existsSync(CONTRACT_PATH)) {
    console.error(`Contract file not found: ${CONTRACT_PATH}`);
    return 1;
  }

  const contractMarkdown = fs.readFileSync(CONTRACT_PATH, 'utf-8');
  const contractNames = extractContractRpcs(contractMarkdown);

  const codeFiles = CODE_DIRS
    .flatMap(walk)
    .filter((p) => !EXCLUDED_FILES.includes(p.replace(/\\/g, '/')));

  const { names: codeNames, byFile } = extractCodeRpcs(codeFiles);

  const missingFromContract = [...codeNames].filter((n) => !contractNames.has(n)).sort();
  const staleInContract = [...contractNames].filter((n) => !codeNames.has(n)).sort();

  console.log(`Contract RPCs : ${contractNames.size}`);
  console.log(`Code RPCs     : ${codeNames.size}`);
  console.log('');

  if (missingFromContract.length === 0 && staleInContract.length === 0) {
    console.log('RPC contracts and service code are in sync.');
    return 0;
  }

  if (missingFromContract.length) {
    console.error(`RPCs found in code but missing from contract (${missingFromContract.length}):`);
    for (const name of missingFromContract) {
      const files = [...byFile.entries()]
        .filter(([, list]) => list.includes(name))
        .map(([f]) => f.replace(/\\/g, '/'));
      console.error(`  - ${name}  (${files.join(', ')})`);
    }
  }

  if (staleInContract.length) {
    console.error(`RPCs listed in contract but not found in code (${staleInContract.length}):`);
    for (const name of staleInContract) {
      console.error(`  - ${name}`);
    }
  }

  return 1;
}

process.exit(main());
