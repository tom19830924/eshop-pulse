const FIELD_NAMES = {
  title: ['title'],
  publisher: ['publisher'],
  developer: ['developer'],
  releaseDate: ['releaseDate'],
  productType: ['category', 'hardwareCategory'],
  sourceUrl: ['pageLink']
};

export function normalizeSnapshot(snapshot) {
  if (!Array.isArray(snapshot.items)) {
    throw new Error(`${snapshot.region} snapshot does not contain a readable item list`);
  }

  const normalizedGames = snapshot.items.map((item) => normalizeGame(snapshot, item)).filter((game) => game !== null);
  const games = deduplicateGamesByNsuid(normalizedGames);
  return {
    schemaVersion: 1,
    generatedAt: new Date().toISOString(),
    region: snapshot.region,
    sourceSnapshot: {
      sourceUrl: snapshot.sourceUrl,
      fetchedAt: snapshot.fetchedAt,
      expectedTotal: snapshot.expectedTotal ?? null,
      rawItemCount: snapshot.items.length
    },
    games,
    diagnostics: {
      missingNsuid: games.filter((game) => game.nsuid === null).length,
      missingPublisher: games.filter((game) => game.publisher === null).length
    }
  };
}

export function combineCatalogs(catalogs) {
  return {
    schemaVersion: 1,
    generatedAt: new Date().toISOString(),
    games: catalogs.flatMap((catalog) => catalog.games),
    regions: Object.fromEntries(catalogs.map((catalog) => [catalog.region, catalog.sourceSnapshot]))
  };
}

export function taiwanSnapshotFromRawResponses(responses, fetchedAt = new Date().toISOString()) {
  if (!Array.isArray(responses) || responses.length === 0) {
    throw new Error('Taiwan raw catalog does not contain any API responses');
  }
  const firstPage = responses[0];
  return {
    region: 'TW',
    sourceUrl: 'https://www.nintendo.com/tw/api/software?sftab=all',
    fetchedAt,
    expectedTotal: firstPage.total ?? firstPage.totalCount ?? null,
    items: responses.flatMap((response) => response.items ?? [])
  };
}

function normalizeGame(snapshot, item) {
  const title = stringField(item, FIELD_NAMES.title);
  if (title === null) return null;
  const nsuid = findNsuid(item);
  const sourceUrl = absoluteUrl(stringField(item, FIELD_NAMES.sourceUrl), snapshot.sourceUrl);
  const imageUrl = absoluteUrl(nestedStringField(item, ['imageHero', 'url']), snapshot.sourceUrl);
  return {
    id: nsuid ? `${snapshot.region}:${nsuid}` : `${snapshot.region}:source:${stableSourceKey(item, title)}`,
    region: snapshot.region,
    nsuid,
    title,
    publisher: stringField(item, FIELD_NAMES.publisher),
    developer: stringField(item, FIELD_NAMES.developer),
    releaseDate: stringField(item, FIELD_NAMES.releaseDate),
    productType: normalizeProductType(valueField(item, FIELD_NAMES.productType)),
    imageUrl,
    sourceUrl,
    sourceUpdatedAt: snapshot.fetchedAt
  };
}

function deduplicateGamesByNsuid(games) {
  const uniqueGames = [];
  const indexByIdentity = new Map();

  for (const game of games) {
    if (game.nsuid === null) {
      uniqueGames.push(game);
      continue;
    }

    const identity = `${game.region}:${game.nsuid}`;
    const existingIndex = indexByIdentity.get(identity);
    if (existingIndex === undefined) {
      indexByIdentity.set(identity, uniqueGames.length);
      uniqueGames.push(game);
      continue;
    }

    uniqueGames[existingIndex] = fillMissingFields(uniqueGames[existingIndex], game);
  }

  return uniqueGames;
}

function fillMissingFields(first, later) {
  const merged = { ...first };
  for (const [field, value] of Object.entries(later)) {
    if (field === 'id' || field === 'region' || field === 'nsuid') continue;
    if (isMissing(merged[field]) && !isMissing(value)) merged[field] = value;
  }
  return merged;
}

function isMissing(value) {
  return value === null || value === undefined || value === '';
}

function nestedStringField(item, path) {
  let value = item;
  for (const key of path) {
    value = value?.[key];
  }
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

function valueField(item, names) {
  for (const name of names) {
    if (item[name] !== undefined && item[name] !== null) return item[name];
  }
  return null;
}

function stringField(item, names) {
  const value = valueField(item, names);
  if (Array.isArray(value)) return value.join(', ');
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

function findNsuid(item) {
  for (const value of Object.values(item)) {
    const text = Array.isArray(value) ? value.join(' ') : String(value ?? '');
    const match = text.match(/\b7\d{13}\b/);
    if (match) return match[0];
  }
  return null;
}

function normalizeProductType(value) {
  if (Array.isArray(value)) return value.join(', ');
  return value === null || value === undefined ? null : String(value);
}

function absoluteUrl(value, baseUrl) {
  if (!value || value === 'リンクなし') return null;
  try {
    return new URL(value, baseUrl).toString();
  } catch {
    return null;
  }
}

function stableSourceKey(item, title) {
  return encodeURIComponent(String(item.sys?.id ?? title));
}
