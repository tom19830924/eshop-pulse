import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { writeJsonSnapshot } from '../lib/files.mjs';
import { combineCatalogs, normalizeSnapshot, taiwanSnapshotFromRawResponses } from '../catalog/normalize.mjs';
import { enrichGamesWithPrices } from '../catalog/prices.mjs';

const rawDirectory = resolve(process.cwd(), 'data/raw');
const jsonFilenames = ['tw-catalog.json'];
const rawResponseLists = await Promise.all(jsonFilenames.map(async (filename) => JSON.parse(await readFile(resolve(rawDirectory, filename), 'utf8'))));
const catalogs = rawResponseLists.map((responses) => normalizeSnapshot(taiwanSnapshotFromRawResponses(responses)));
const combined = combineCatalogs(catalogs);
const priceResponses = JSON.parse(await readFile(resolve(rawDirectory, 'tw-prices.json'), 'utf8'));
const prices = priceResponses.flatMap((response) => response.prices ?? []);
const normalized = { ...combined, generatedAt: new Date().toISOString(), games: enrichGamesWithPrices(combined.games, prices) };

await writeJsonSnapshot(
  resolve(process.cwd(), 'data/normalized/games.json'),
  resolve(process.cwd(), 'data/normalized/games.meta.json'),
  normalized
);
for (const catalog of catalogs) {
  console.log(`${catalog.region}: ${catalog.games.length} normalized games; ${catalog.diagnostics.missingNsuid} without NSUID`);
}
