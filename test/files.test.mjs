import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { writeJsonSnapshot, writeRawJsonArraySnapshot } from '../src/lib/files.mjs';

test('writes raw snapshots unchanged with independent Unix-second metadata', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'eshop-pulse-snapshot-'));
  const catalogPath = join(directory, 'tw-catalog.json');
  const catalogMetadataPath = join(directory, 'tw-catalog.meta.json');
  const pricesPath = join(directory, 'tw-prices.json');
  const pricesMetadataPath = join(directory, 'tw-price.meta.json');
  const catalogResponse = '{\n  "total": 1,\n  "items": [{"id":"game-1"}]\n}';
  const priceResponse = '{"prices":[{"title_id":"game-1"}]}';

  try {
    await writeFile(pricesMetadataPath, JSON.stringify({ timestamp: 123 }));
    const catalogTimestamp = await writeRawJsonArraySnapshot(
      catalogPath,
      catalogMetadataPath,
      [catalogResponse],
      () => 1_789_000_001_999
    );

    assert.equal(catalogTimestamp, 1_789_000_001);
    assert.equal(await readFile(catalogPath, 'utf8'), `[\n${catalogResponse}\n]\n`);
    assert.deepEqual(JSON.parse(await readFile(catalogMetadataPath, 'utf8')), {
      timestamp: 1_789_000_001
    });
    assert.deepEqual(JSON.parse(await readFile(pricesMetadataPath, 'utf8')), { timestamp: 123 });

    const priceTimestamp = await writeRawJsonArraySnapshot(
      pricesPath,
      pricesMetadataPath,
      [priceResponse],
      () => 1_789_000_009_000
    );

    assert.equal(priceTimestamp, 1_789_000_009);
    assert.equal(await readFile(pricesPath, 'utf8'), `[\n${priceResponse}\n]\n`);
    assert.deepEqual(JSON.parse(await readFile(pricesMetadataPath, 'utf8')), {
      timestamp: 1_789_000_009
    });
    assert.deepEqual(JSON.parse(await readFile(catalogMetadataPath, 'utf8')), {
      timestamp: 1_789_000_001
    });
    assert.ok(Number.isInteger(JSON.parse(await readFile(catalogMetadataPath, 'utf8')).timestamp));
    assert.ok(Number.isInteger(JSON.parse(await readFile(pricesMetadataPath, 'utf8')).timestamp));
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('writes a DTO snapshot and Unix-second metadata without changing the DTO body', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'eshop-pulse-dto-'));
  const dtoPath = join(directory, 'games.json');
  const metadataPath = join(directory, 'games.meta.json');
  const dto = {
    generatedAt: '2026-09-17T00:00:00.000Z',
    games: [{ id: 'TW:game-1' }]
  };

  try {
    const timestamp = await writeJsonSnapshot(dtoPath, metadataPath, dto, () => 1_789_000_010_999);

    assert.equal(timestamp, 1_789_000_010);
    assert.deepEqual(JSON.parse(await readFile(dtoPath, 'utf8')), dto);
    const metadata = JSON.parse(await readFile(metadataPath, 'utf8'));
    assert.deepEqual(metadata, { timestamp: 1_789_000_010 });
    assert.ok(Number.isInteger(metadata.timestamp));
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
