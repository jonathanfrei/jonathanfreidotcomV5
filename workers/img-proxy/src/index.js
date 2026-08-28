// Same-origin mask for wsrv.nl: GET /img?url=…&w=…&output=webp&q=…&we&s=…
// HMAC must match Jekyll OptimizeContentImages.canonical_message.

const UPSTREAM = "https://wsrv.nl/";
const MAX_QUERY = 4096;
const SIGNED_KEYS = ["output", "q", "url", "w"];

export default {
  async fetch(request, env) {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("method not allowed", { status: 405 });
    }

    const incoming = new URL(request.url);
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
        cacheTtl: 2592000,
      },
    });

    const headers = new Headers(response.headers);
    headers.delete("set-cookie");
    headers.set("Cache-Control", "public, max-age=2592000");
    headers.set("X-Content-Type-Options", "nosniff");

    return new Response(request.method === "HEAD" ? null : response.body, {
      status: response.status,
      headers,
    });
  },
};

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
