import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeSnapshot } from '../src/catalog/normalize.mjs';
import { filterNintendoPublishedGames } from '../src/catalog/nintendo-publisher.mjs';
import { enrichGamesWithPrices, normalizePrice, PRICE_BATCH_SIZE, priceRequestUrl } from '../src/catalog/prices.mjs';

test('normalizes a Taiwan catalog item into the shared DTO', () => {
  const catalog = normalizeSnapshot({
    region: 'TW',
    sourceUrl: 'https://www.nintendo.com/tw/api/software',
    fetchedAt: '2026-09-14T00:00:00.000Z',
    items: [{
      title: 'Super Mario Bros. Wonder',
      nsuid: '70010000068664',
      publisher: 'Nintendo',
      developer: 'Nintendo',
      releaseDate: '2023-10-20',
      category: ['下載版'],
      imageHero: { url: 'https://images.example.com/mario.jpg' },
      pageLink: '/tw/software/70010000068664'
    }]
  });

  assert.deepEqual(catalog.games[0], {
    id: 'TW:70010000068664',
    region: 'TW',
    nsuid: '70010000068664',
    title: 'Super Mario Bros. Wonder',
    publisher: 'Nintendo',
    developer: 'Nintendo',
    releaseDate: '2023-10-20',
    productType: '下載版',
    imageUrl: 'https://images.example.com/mario.jpg',
    sourceUrl: 'https://www.nintendo.com/tw/software/70010000068664',
    sourceUpdatedAt: '2026-09-14T00:00:00.000Z'
  });
});

test('selects Nintendo publisher aliases and applies explicit overrides', () => {
  const games = [
    { id: 'TW:1', publisher: 'Nintendo' },
    { id: 'TW:2', publisher: '任天堂' },
    { id: 'TW:3', publisher: 'SEGA' }
  ];
  const filtered = filterNintendoPublishedGames(games, {
    includeIds: ['TW:3'],
    excludeIds: ['TW:2']
  });
  assert.deepEqual(filtered.map((game) => game.id), ['TW:1', 'TW:3']);
});

test('normalizes price and sale data for an app-friendly DTO', () => {
  const now = new Date('2026-09-15T00:00:00.000Z');
  const price = normalizePrice({
    title_id: 70010000000001,
    sales_status: 'onsale',
    regular_price: { amount: 'NT$1,790', currency: 'TWD', raw_value: '1790' },
    discount_price: {
      amount: 'NT$1,253',
      currency: 'TWD',
      raw_value: '1253',
      start_datetime: '2026-09-01T00:00:00Z',
      end_datetime: '2026-09-20T00:00:00Z'
    }
  }, now);
  assert.equal(price.isOnSale, true);
  assert.equal(price.sale.rawValue, '1253');
  assert.equal(PRICE_BATCH_SIZE, 50);
  assert.match(priceRequestUrl('TW', ['70010000000001']), /country=TW/);

  const [game] = enrichGamesWithPrices([{ id: 'TW:70010000000001', nsuid: '70010000000001' }], [], now);
  assert.equal(game.price.status, 'not_found');
});
