import { resolve } from 'node:path';
import { writeRawJsonArrayAtomically } from '../lib/files.mjs';
import { fetchTaiwanCatalog } from '../adapters/tw.mjs';

const outputDirectory = resolve(process.cwd(), 'data/raw');
const jobs = [
  ['TW', 'tw-catalog.json', fetchTaiwanCatalog]
];

const requestedRegions = new Set(process.argv.slice(2).map((region) => region.toUpperCase()));
const selectedJobs = requestedRegions.size === 0 ? jobs : jobs.filter(([region]) => requestedRegions.has(region));
if (selectedJobs.length === 0) {
  throw new Error(`Unknown region. Use one or more of: ${jobs.map(([region]) => region).join(', ')}`);
}

for (const [region, filename, fetchCatalog] of selectedJobs) {
  console.log(`Fetching ${filename}…`);
  const responseBodies = await fetchCatalog();
  await writeRawJsonArrayAtomically(resolve(outputDirectory, filename), responseBodies);
  const items = responseBodies.flatMap((body) => JSON.parse(body).items ?? []);
  console.log(`${region}: wrote ${filename} (${responseBodies.length} pages, ${items.length} items)`);
}
