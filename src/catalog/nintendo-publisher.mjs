const NINTENDO_PUBLISHERS = new Set(['nintendo', '任天堂']);

export function filterNintendoPublishedGames(games, overrides = {}) {
  const includeIds = new Set(overrides.includeIds ?? []);
  const excludeIds = new Set(overrides.excludeIds ?? []);

  return games
    .filter((game) => includeIds.has(game.id) || isNintendoPublisher(game.publisher))
    .filter((game) => !excludeIds.has(game.id));
}

export function isNintendoPublisher(publisher) {
  return typeof publisher === 'string' && NINTENDO_PUBLISHERS.has(publisher.trim().toLocaleLowerCase('en'));
}
