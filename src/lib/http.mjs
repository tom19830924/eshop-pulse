const DEFAULT_TIMEOUT_MS = 30_000;

export async function fetchJson(url, options = {}) {
  const response = await fetchWithTimeout(url, options);
  return response.json();
}

export async function fetchText(url, options = {}) {
  const response = await fetchWithTimeout(url, options);
  return response.text();
}

export async function fetchBytes(url, options = {}) {
  const response = await fetchWithTimeout(url, options);
  return new Uint8Array(await response.arrayBuffer());
}

export async function fetchTextWithRetry(url, { retries = 2 } = {}) {
  let lastError;
  for (let attempt = 0; attempt <= retries; attempt += 1) {
    try {
      const response = await requestWithTimeout(url, {});
      if (response.ok) return response.text();

      const retryAfterSeconds = Number(response.headers.get('retry-after'));
      const delayMs = Number.isFinite(retryAfterSeconds)
        ? retryAfterSeconds * 1_000
        : (attempt + 1) * 5_000;
      lastError = new Error(`Request failed (${response.status}) for ${url}`);
      if (attempt < retries) await sleep(delayMs);
    } catch (error) {
      lastError = error;
      if (attempt < retries) await sleep((attempt + 1) * 5_000);
    }
  }
  throw lastError;
}

async function fetchWithTimeout(url, options) {
  const response = await requestWithTimeout(url, options);
  if (!response.ok) {
    throw new Error(`Request failed (${response.status}) for ${url}`);
  }
  return response;
}

async function requestWithTimeout(url, options) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS);

  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
