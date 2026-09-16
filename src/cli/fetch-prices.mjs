import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { PRICE_BATCH_SIZE, priceRequestUrl } from '../catalog/prices.mjs';
import { normalizeSnapshot, taiwanSnapshotFromRawResponses } from '../catalog/normalize.mjs';
import { writeRawJsonArrayAtomically } from '../lib/files.mjs';
import { fetchTextWithRetry } from '../lib/http.mjs';

const rawCatalogPath = resolve(process.cwd(), 'data/raw/tw-catalog.json');
const rawPricesPath = resolve(process.cwd(), 'data/raw/tw-prices.json');
const BATCH_DELAY_MS = 1_000;
const rawCatalogResponses = JSON.parse(await readFile(rawCatalogPath, 'utf8'));
const catalog = normalizeSnapshot(taiwanSnapshotFromRawResponses(rawCatalogResponses));
const priceResponses = [];

for (const [region, games] of Object.entries(groupByRegion(catalog.games))) {
  const nsuids = games.map((game) => game.nsuid).filter((nsuid) => typeof nsuid === 'string');
  priceResponses.push(...await fetchRegionPrices(region, nsuids));
  console.log(`${region}: fetched prices for ${nsuids.length} of ${games.length} games`);
}

await writeRawJsonArrayAtomically(rawPricesPath, priceResponses);
console.log(`Wrote ${priceResponses.length} Taiwan price response batches`);

function groupByRegion(games) {
  return Object.groupBy(games, (game) => game.region);
}

function chunks(items, size) {
  return Array.from({ length: Math.ceil(items.length / size) }, (_, index) => items.slice(index * size, (index + 1) * size));
}

async function fetchRegionPrices(region, ids) {
  if (ids.length === 0) return [];
  const batches = chunks(ids, PRICE_BATCH_SIZE);
  const responses = [];
  for (const batch of batches) {
    if (responses.length > 0) await sleep(BATCH_DELAY_MS);
    responses.push(await fetchTextWithRetry(priceRequestUrl(region, batch)));
  }
  return responses;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
