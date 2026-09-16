import { fetchTextWithRetry } from '../lib/http.mjs';

const PAGE_DELAY_MS = 1_000;
const BASE_URL = 'https://www.nintendo.com/tw/api/software?sftab=all';

export async function fetchTaiwanCatalog() {
  const firstPageText = await fetchPage(1);
  const firstPage = JSON.parse(firstPageText);
  const expectedTotal = numberOrNull(firstPage.total ?? firstPage.totalCount);
  const pageSize = Array.isArray(firstPage.items) ? firstPage.items.length : 0;
  const pageCount = expectedTotal && pageSize ? Math.ceil(expectedTotal / pageSize) : 1;
  const responseBodies = [firstPageText];

  for (let page = 2; page <= pageCount; page += 1) {
    await sleep(PAGE_DELAY_MS);
    responseBodies.push(await fetchPage(page));
  }

  return responseBodies;
}

function fetchPage(page) {
  return fetchTextWithRetry(`${BASE_URL}&spage=${page}`);
}

function numberOrNull(value) {
  return Number.isFinite(Number(value)) ? Number(value) : null;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
