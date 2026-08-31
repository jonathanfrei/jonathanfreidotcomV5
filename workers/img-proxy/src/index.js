// Same-origin mask for wsrv.nl: GET /img?url=…&w=…&output=webp&q=…&we&s=…
// HMAC must match Jekyll OptimizeContentImages.canonical_message.

const UPSTREAM = "https://wsrv.nl/";
const MAX_QUERY = 4096;
const SIGNED_KEYS = ["output", "q", "url", "w"];
const MARKET_SYMBOLS = new Set(["BTC-USD", "0992.HK", "VOO", "VTI", "IAU", "VGT", "SPCX", "IBIT"]);
const MARKET_RANGES = new Map([
  ["1d", "5m"], ["5d", "30m"], ["1mo", "1d"], ["3mo", "1d"],
  ["6mo", "1d"], ["1y", "1d"], ["5y", "1wk"],
]);

export default {
  async fetch(request, env) {
    const incoming = new URL(request.url);
    if (incoming.pathname === "/market-data") {
      return marketDataResponse(request, env, incoming);
    }

    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("method not allowed", { status: 405 });
    }

    if (incoming.search.length > MAX_QUERY) {
      return new Response("query too long", { status: 414 });
    }

    const params = incoming.searchParams;
    const inner = params.get("url") || "";
    const width = params.get("w") || "";
    const output = params.get("output") || "";
    const quality = params.get("q") || "";
    const signature = params.get("s") || "";
    const hasWe = params.has("we");

    if (!inner || !width || !output || !quality || !hasWe) {
      return new Response("missing transform params", { status: 400 });
    }
    if (forbiddenInner(inner)) {
      return new Response("forbidden origin", { status: 403 });
    }

    const secret = (env && env.IMG_HMAC) || "";
    if (!secret) {
      return new Response("proxy unconfigured", { status: 500 });
    }
    const expected = await hmacHex(secret, canonicalMessage(inner, width, output, quality));
    if (!timingSafeEqual(signature, expected)) {
      return new Response("invalid signature", { status: 403 });
    }

    if (!refererAllowed(request)) {
      return new Response("forbidden referer", { status: 403 });
    }

    const upstream = new URL(UPSTREAM);
    for (const key of SIGNED_KEYS) {
      upstream.searchParams.set(key, params.get(key) || "");
    }
    upstream.searchParams.append("we", "");

    const upstreamReq = new Request(upstream.toString(), {
      method: request.method,
      headers: {
        Accept: request.headers.get("Accept") || "image/webp,image/*;q=0.8,*/*;q=0.5",
        "User-Agent": "jonathanfrei-img-proxy",
      },
      redirect: "follow",
    });

    const response = await fetch(upstreamReq, {
      cf: {
        cacheEverything: true,
        cacheTtlByStatus: {
          "200-299": 2592000,
          "400-599": 0,
        },
      },
    });

    const headers = new Headers(response.headers);
    headers.delete("set-cookie");
    if (response.ok) {
      headers.set("Cache-Control", "public, max-age=2592000");
    } else {
      // Wikimedia 429s (and similar) come back as wsrv 404 JSON. Do not
      // pin that in cache for a month — next request can recover.
      headers.set("Cache-Control", "no-store");
    }
    headers.set("X-Content-Type-Options", "nosniff");

    return new Response(request.method === "HEAD" ? null : response.body, {
      status: response.status,
      headers,
    });
  },
};

async function marketDataResponse(request, env, incoming) {
  const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
    "Access-Control-Allow-Headers": "Accept",
    "Access-Control-Expose-Headers": "X-Market-Source, X-Market-Time",
    "Vary": "Origin",
  };
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (request.method !== "GET" && request.method !== "HEAD") {
    return new Response("method not allowed", { status: 405, headers: cors });
  }

  const symbol = (incoming.searchParams.get("symbol") || "").toUpperCase();
  const range = incoming.searchParams.get("range") || "1y";
  const interval = incoming.searchParams.get("interval") || MARKET_RANGES.get(range);
  if (!MARKET_SYMBOLS.has(symbol) || !MARKET_RANGES.has(range) || interval !== MARKET_RANGES.get(range)) {
    return new Response("unsupported market query", { status: 400, headers: cors });
  }

  const yahoo = new URL(`https://query2.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(symbol)}`);
  yahoo.search = new URLSearchParams({ range, interval, includePrePost: "false", events: "div,splits" });
  let response = await fetch(yahoo, {
    headers: { Accept: "application/json", "User-Agent": "Mozilla/5.0 market-watchlist/1.0" },
    cf: { cacheEverything: true, cacheTtl: 300 },
  });
  let body = await response.text();
  let source = "Yahoo Finance";

  if (!validYahoo(body)) {
    const publicFallback = await fallbackMarketData(symbol, range, interval);
    const fallback = publicFallback || (env && env.TWELVE_DATA_API_KEY
      ? await twelveData(symbol, range, interval, env.TWELVE_DATA_API_KEY)
      : null);
    if (fallback) {
      body = JSON.stringify(fallback.data);
      response = new Response(body, { status: 200, headers: { "Content-Type": "application/json" } });
      source = fallback.source || "Twelve Data";
    }
  }

  const headers = new Headers(response.headers);
  headers.delete("set-cookie");
  Object.entries(cors).forEach(([key, value]) => headers.set(key, value));
  headers.set("Cache-Control", response.ok ? "public, max-age=300" : "no-store");
  headers.set("X-Content-Type-Options", "nosniff");
  headers.set("X-Market-Source", source);
  headers.set("X-Market-Time", new Date().toISOString());
  return new Response(request.method === "HEAD" ? null : body, { status: response.status, headers });
}

async function fallbackMarketData(symbol, range, interval) {
  if (symbol === "BTC-USD") return coinGeckoData(range);
  if (!symbol.endsWith(".HK")) return nasdaqData(symbol, range, interval);
  return null;
}

async function coinGeckoData(range) {
  const days = { "1d": 1, "5d": 5, "1mo": 30, "3mo": 90, "6mo": 180, "1y": 365, "5y": 1825 }[range];
  const url = new URL("https://api.coingecko.com/api/v3/coins/bitcoin/market_chart");
  url.search = new URLSearchParams({ vs_currency: "usd", days: String(days), precision: "full" });
  const response = await fetch(url, { headers: { Accept: "application/json" }, cf: { cacheEverything: true, cacheTtl: 300 } });
  if (!response.ok) return null;
  const json = await response.json();
  if (!Array.isArray(json.prices) || json.prices.length < 2) return null;
  const timestamps = json.prices.map((point) => Math.floor(point[0] / 1000));
  const close = json.prices.map((point) => point[1]);
  const volume = json.total_volumes.map((point) => point[1]);
  const marketCap = json.market_caps.at(-1)?.[1] || null;
  return { source: "CoinGecko", data: yahooShape("BTC-USD", "USD", "Crypto", timestamps, close, close, close, close, volume, marketCap) };
}

async function nasdaqData(symbol, range, interval) {
  const headers = { Accept: "application/json, text/plain, */*", "User-Agent": "Mozilla/5.0 market-watchlist/1.0", Origin: "https://www.nasdaq.com", Referer: "https://www.nasdaq.com/" };
  const end = new Date(), starts = { "5d": 10, "1mo": 40, "3mo": 110, "6mo": 210, "1y": 380, "5y": 1900 };
  if (range === "1d") {
    const url = `https://api.nasdaq.com/api/quote/${encodeURIComponent(symbol)}/chart?assetclass=etf`;
    const response = await fetch(url, { headers, cf: { cacheEverything: true, cacheTtl: 300 } });
    if (!response.ok) return null;
    const json = await response.json(), chart = json.data && json.data.chart;
    if (!Array.isArray(chart) || chart.length < 2) return null;
    const timestamps = chart.map((point) => Math.floor(point.x / 1000)), close = chart.map((point) => Number(point.y)), volume = close.map(() => null);
    return { source: "Nasdaq", data: yahooShape(symbol, "USD", json.data.exchange || "US Market", timestamps, close, close, close, close, volume) };
  }
  const start = new Date(end.getTime() - starts[range] * 864e5).toISOString().slice(0, 10);
  const url = new URL(`https://api.nasdaq.com/api/quote/${encodeURIComponent(symbol)}/historical`);
  url.search = new URLSearchParams({ assetclass: "etf", fromdate: start, todate: end.toISOString().slice(0, 10), limit: range === "5y" ? "1400" : "500" });
  const response = await fetch(url, { headers, cf: { cacheEverything: true, cacheTtl: 300 } });
  if (!response.ok) return null;
  const json = await response.json();
  let rows = json.data && json.data.tradesTable && json.data.tradesTable.rows;
  if (!Array.isArray(rows) || rows.length < 2) return null;
  rows = rows.slice().reverse();
  if (interval === "1wk") rows = rows.filter((_, index) => index % 5 === 0 || index === rows.length - 1);
  const number = (value) => Number(String(value || "").replace(/[$,]/g, ""));
  const timestamps = rows.map((row) => Math.floor(new Date(`${row.date} 16:00:00 -0400`).getTime() / 1000));
  return { source: "Nasdaq", data: yahooShape(symbol, "USD", "US Market", timestamps, rows.map((r) => number(r.close)), rows.map((r) => number(r.open)), rows.map((r) => number(r.high)), rows.map((r) => number(r.low)), rows.map((r) => number(r.volume))) };
}

function yahooShape(symbol, currency, exchange, timestamp, close, open, high, low, volume, marketCap = null) {
  const last = close.length - 1;
  return { chart: { result: [{ meta: { currency, symbol, fullExchangeName: exchange, regularMarketPrice: close[last], chartPreviousClose: close[last - 1], regularMarketOpen: open[last], regularMarketDayHigh: high[last], regularMarketDayLow: low[last], regularMarketVolume: volume[last], marketCap }, timestamp, indicators: { quote: [{ open, high, low, close, volume }], adjclose: [{ adjclose: close }] } }], error: null } };
}

function validYahoo(body) {
  try {
    const parsed = JSON.parse(body);
    return Boolean(parsed.chart && parsed.chart.result && parsed.chart.result[0]);
  } catch {
    return false;
  }
}

async function twelveData(symbol, range, interval, apiKey) {
  const outputs = { "1d": 96, "5d": 240, "1mo": 31, "3mo": 93, "6mo": 186, "1y": 366, "5y": 262 };
  const intervals = { "5m": "5min", "30m": "30min", "1d": "1day", "1wk": "1week" };
  const twelveSymbol = symbol === "BTC-USD" ? "BTC/USD" : symbol;
  const url = new URL("https://api.twelvedata.com/time_series");
  url.search = new URLSearchParams({ symbol: twelveSymbol, interval: intervals[interval], outputsize: String(outputs[range]), order: "asc", timezone: "UTC", apikey: apiKey });
  const response = await fetch(url, { headers: { Accept: "application/json" }, cf: { cacheEverything: true, cacheTtl: 300 } });
  if (!response.ok) return null;
  const json = await response.json();
  if (!Array.isArray(json.values) || json.values.length < 2) return null;
  const timestamps = [], open = [], high = [], low = [], close = [], volume = [];
  for (const value of json.values) {
    timestamps.push(Math.floor(new Date(`${value.datetime.replace(" ", "T")}Z`).getTime() / 1000));
    open.push(Number(value.open)); high.push(Number(value.high)); low.push(Number(value.low)); close.push(Number(value.close)); volume.push(Number(value.volume) || null);
  }
  const last = close.length - 1, currency = symbol.endsWith(".HK") ? "HKD" : "USD";
  return { source: "Twelve Data", data: { chart: { result: [{ meta: { currency, symbol, exchangeName: json.meta.exchange || "", fullExchangeName: json.meta.exchange || "", regularMarketPrice: close[last], chartPreviousClose: close[last - 1], regularMarketOpen: open[last], regularMarketDayHigh: high[last], regularMarketDayLow: low[last], regularMarketVolume: volume[last] }, timestamp: timestamps, indicators: { quote: [{ open, high, low, close, volume }], adjclose: [{ adjclose: close }] } }], error: null } } };
}

function canonicalMessage(url, width, output, quality) {
  return `output=${output}&q=${quality}&url=${url}&w=${width}&we`;
}

function forbiddenInner(raw) {
  try {
    let candidate = raw;
    if (/^ssl:/i.test(candidate)) {
      candidate = `https://${candidate.slice(4)}`;
    } else if (!/^https?:/i.test(candidate)) {
      candidate = `https://${candidate}`;
    }
    const u = new URL(candidate);
    const host = u.hostname.toLowerCase();
    if (host === "wsrv.nl" || host === "images.weserv.nl") return true;
    if (
      (host === "jonathanfrei.com" || host === "www.jonathanfrei.com") &&
      u.pathname.startsWith("/img")
    ) {
      return true;
    }
    return false;
  } catch {
    return true;
  }
}

function refererAllowed(request) {
  const referer = request.headers.get("Referer") || request.headers.get("Origin") || "";
  if (!referer) return true;
  try {
    const host = new URL(referer).hostname.toLowerCase();
    return host === "jonathanfrei.com" || host === "www.jonathanfrei.com";
  } catch {
    return false;
  }
}

async function hmacHex(secret, message) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function timingSafeEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string" || a.length !== b.length) {
    return false;
  }
  let out = 0;
  for (let i = 0; i < a.length; i += 1) {
    out |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return out === 0;
}
