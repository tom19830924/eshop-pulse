# eshop-pulse

Daily Taiwan Nintendo eShop catalog snapshots and price data.

## Repository layout

```text
apps/
  ios/                 Future iOS App (no Xcode project yet)
config/                Data-pipeline configuration
data/                  Local generated snapshots; not committed
docs/                  eShop API research notes
src/                   Catalog and price pipeline source code
test/                  Pipeline tests
.github/workflows/     Daily GitHub Actions pipeline
```

The future iOS App will download `normalized/games.json` from GitHub Pages.
It does not read the raw files directly.

## Commands

```sh
npm run fetch:catalog
npm run fetch:prices
npm run normalize:catalog
```

`fetch:catalog` stores every Taiwan software-list page, in request order, at
`data/raw/tw-catalog.json`. The file is a JSON array: aside from that outer
array and its separators, each API response body is kept unchanged.

`normalize:catalog` creates the single app DTO at
`data/normalized/games.json`.

`fetch:prices` reads the raw catalog, requests prices for every game in the
Taiwan catalog 50 games at a time and sequentially, then preserves each
official price response at `data/raw/tw-prices.json`.

Run `normalize:catalog` last: it merges the two raw files into the App DTO,
including current price and sale information. The App can filter by publisher
or `price.isOnSale` itself.

## Verification

```sh
npm test
```

## Free deployment

GitHub Actions runs daily at 02:23 Asia/Taipei and publishes all three files to
GitHub Pages:

```text
https://<github-user>.github.io/eshop-pulse/raw/tw-catalog.json
https://<github-user>.github.io/eshop-pulse/raw/tw-prices.json
https://<github-user>.github.io/eshop-pulse/normalized/games.json
```

The repository and Pages site must be public when using GitHub Free. Enable
**Settings → Pages → Build and deployment → GitHub Actions** once.
