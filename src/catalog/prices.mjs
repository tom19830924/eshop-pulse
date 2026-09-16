const REGION_OPTIONS = {
  TW: { country: 'TW', lang: 'zh' }
};

export const PRICE_BATCH_SIZE = 50;

export function priceRequestUrl(region, nsuids) {
  const options = REGION_OPTIONS[region];
  if (!options) throw new Error(`Unsupported price region: ${region}`);
  const query = new URLSearchParams({ country: options.country, ids: nsuids.join(','), lang: options.lang });
  return `https://api.ec.nintendo.com/v1/price?${query}`;
}

export function enrichGamesWithPrices(games, priceEntries, now = new Date()) {
  const pricesByNsuid = new Map(priceEntries.map((entry) => [String(entry.title_id), entry]));
  return games.map((game) => ({ ...game, price: normalizePrice(pricesByNsuid.get(game.nsuid), now) }));
}

export function normalizePrice(entry, now = new Date()) {
  if (!entry) return { status: 'not_found', isOnSale: false, regular: null, sale: null, saleStartsAt: null, saleEndsAt: null };
  const sale = money(entry.discount_price ?? entry.sale_price);
  const saleStartsAt = dateValue(entry.discount_price?.start_datetime ?? entry.discount_price_start ?? entry.discount_price_start_at ?? entry.sale_start);
  const saleEndsAt = dateValue(entry.discount_price?.end_datetime ?? entry.discount_price_end ?? entry.discount_price_end_at ?? entry.sale_end);
  const saleWindowActive = (!saleStartsAt || new Date(saleStartsAt) <= now) && (!saleEndsAt || new Date(saleEndsAt) > now);
  return {
    status: entry.sales_status ?? 'unknown',
    isOnSale: sale !== null && saleWindowActive,
    regular: money(entry.regular_price),
    sale,
    saleStartsAt,
    saleEndsAt
  };
}

function money(value) {
  if (!value) return null;
  return {
    amount: value.amount ?? null,
    currency: value.currency ?? null,
    rawValue: value.raw_value ?? null
  };
}

function dateValue(value) {
  return typeof value === 'string' && value ? value : null;
}
