import { mkdir, rename, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';

export async function writeJsonAtomically(path, value) {
  await writeFileAtomically(path, `${JSON.stringify(value, null, 2)}\n`);
}

// Preserve every response body exactly as received. The only generated syntax is
// the outer JSON array and the commas needed to join separate API responses.
export async function writeRawJsonArrayAtomically(path, responseBodies) {
  await writeFileAtomically(path, `[\n${responseBodies.join(',\n')}\n]\n`);
}

export async function writeFileAtomically(path, value) {
  await mkdir(dirname(path), { recursive: true });
  const temporaryPath = `${path}.tmp`;
  await writeFile(temporaryPath, value);
  await rename(temporaryPath, path);
}
