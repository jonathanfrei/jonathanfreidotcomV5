# jonathanfrei.com (V5)

Personal site and blog for [jonathanfrei.com](https://jonathanfrei.com).

Built with **Jekyll 4.x**, deployed via **GitHub Actions** to **GitHub Pages**, and served behind **Cloudflare**.

## Features

- Minimalist, mobile-first design with system dark mode (`prefers-color-scheme`)
- Accessibility-focused (semantic HTML, skip link, focus styles, reduced-motion)
- Tiny custom utility CSS
- Short posts + long-form pages + nested markdown **books** (`_books/`)
- RSS feed + sitemap + basic SEO
- Source-only deprecated-code archive under `assets/deprecated` (excluded from builds)
- Per-book `index: false` (demo: Dispelling Beauty Lies) is noindex and Disallow’d in generated `robots.txt`
- Manual or push-triggered deploys (no scheduled rebuild)
- Masked contact email (no form)

## Development workflow

Most work happens directly on GitHub (or via Grok-assisted edits).

1. Write publishable posts as Markdown in `_posts/`; keep unfinished drafts outside this repository.
2. Push to `main` → Actions builds and deploys.
3. Future-dated posts publish on the next content push (or run **Deploy** via workflow_dispatch).

### Agents

AI coding agents should read **[AGENTS.md](./AGENTS.md)** first. It covers repo layout, permalinks, CSS include rules, deploy constraints, and common pitfalls for this site.
They are never included in the public site build, never appear in the RSS feed or sitemap, and are blocked in `robots.txt`.
When ready, move the file to `_posts/` with a proper `YYYY-MM-DD-title.md` name and front matter.

### Local preview (optional)

If you want a local server:

```bash
bundle install
bundle exec jekyll serve
```

## Enabling GitHub Pages

After the first successful Actions run:

1. Go to the repository **Settings → Pages**.
2. Under **Build and deployment**, set **Source** to **GitHub Actions**.

## Custom domain

Point `jonathanfrei.com` (and `www` if desired) at GitHub Pages via Cloudflare DNS, then add the custom domain in the Pages settings. Cloudflare proxy can remain enabled for caching and protection.

## Cloudflare performance

GitHub Pages does **not** accept custom `Expires` / `Cache-Control` headers from the repo. This site is served behind **Cloudflare**. Apply dashboard rules **in this order** (redirects before cache) or you will cache a `www` → `http://` 301 and the `/about/` 404.

HTML is not a default Cloudflare cache extension. Without a Cache Everything rule, every document is `cf-cache-status: DYNAMIC` and still pays the hop to GitHub Pages Fastly.

This zone is on the **Free** plan. Redirect **Then** expressions cannot use `regex_replace` (Business / WAF Advanced). Filter expressions cannot use `matches`. Use `wildcard`, `wildcard_replace`, `ends_with`, and `concat`.

### SSL / TLS

- Mode: **Full** (HTTPS to GitHub Pages, no origin-cert hostname check).
- **Always Use HTTPS**: on.
- Do **not** use **Full (strict)**: GitHub Pages has a Let’s Encrypt cert for `www.jonathanfrei.com` only. Apex SNI `jonathanfrei.com` fails validation and Cloudflare returns **526**.
- Do **not** use **Flexible**: origin redirects become `http://jonathanfrei.com/` and the `www` chain grows to three hops.

### Redirects (do these first)

1. **www → apex**, Redirect Rule, 301, Preserve query string on.

   - When: `http.host eq "www.jonathanfrei.com"`
   - Then (Dynamic): `concat("https://jonathanfrei.com", http.request.uri.path)`

2. **Trailing slash** (issue #82). Redirect Rule, 301, Preserve query string on. Strip a final `/` except `/`, month archives, and paginated indexes.

   When (Edit expression):

   ```txt
   ends_with(http.request.uri.path, "/")
   and http.request.uri.path ne "/"
   and not http.request.uri.path wildcard "/archive/*/*/"
   and not http.request.uri.path wildcard "*/page/*/"
   ```

   Then (Dynamic):

   ```txt
   concat("https://jonathanfrei.com", wildcard_replace(http.request.uri.path, "/*/", "/${1}"))
   ```

   `/about/` → `/about`. Leave `/archive/2016/01/` and `/blog/page/2/` alone.

3. **HSTS** (SSL/TLS → Edge Certificates): on, 6 months. Include subdomains only if `v1` / `v2` / `media` are all HTTPS.

### Cache HTML (TTFB)

**Cache Rule** so HTML is stored at the nearest Cloudflare PoP. Exclude static extensions so the existing long-TTL asset rule (issue #119) is not shortened to 2 hours.

When: Hostname equals `jonathanfrei.com`, and file extension is not `css` / `js` / `png` / `jpg` / `webp` / `svg` / `ico` / `woff` / `woff2` / `xml` / `json`.

Exclude **`.json`**. `/search.json` changes every publish; if Cache Everything holds it for 2 hours, `/categories?category=` and `/tags?tag=` show “No matching posts” until the edge expires or you purge.

| Setting | Value |
| --- | --- |
| Eligible for cache | On |
| Edge TTL | Ignore cache-control header and use this TTL → **2 hours** |
| Browser TTL | Respect origin (`max-age=600` from GitHub Pages) |

After the first request, `curl -sI https://jonathanfrei.com/about` must show `cf-cache-status: HIT`, not `DYNAMIC`.

**Purge on every deploy.** Add repo secrets `CLOUDFLARE_ZONE_ID` and `CLOUDFLARE_API_TOKEN` (permission: Zone → Cache Purge → Purge, scoped to this zone). `deploy.yml` then purges the zone after Pages goes live. If the secrets are missing, the step skips. Manual fallback: Caching → Configuration → Purge Everything.

Static assets (issue #119) keep their own rule:

| Match | Edge TTL | Browser TTL |
| --- | --- | --- |
| URI Path matches `*.css` OR `*.js` OR `*.png` OR `*.jpg` OR `*.webp` OR `*.svg` OR `*.ico` OR `*.woff2` OR `*.woff` | 1 month (or longer) | 1 day – 1 week |
| URI Path matches `*.xml` (feeds/sitemaps) | 2 hours | 1 hour |

### Early Hints and compression

1. Speed → Settings → Content Optimization → **Early Hints: On**. Cloudflare 103s come from HTTP `Link` headers, not `<link>` tags. GitHub Pages cannot set headers, so add a **Response Header Transform Rule** with **stable** font URLs only (not the fingerprinted `core.css?v=` URL — it changes when CSS changes). Do **not** Early-Hint Source Sans 3 (vendored, unused).

   ```http
   Link: </assets/fonts/source-serif-4-5.2.5-latin-wght-normal.woff2>; rel=preload; as=font; type=font/woff2
   Link: </assets/fonts/source-code-pro-5.2.5-latin-wght-normal.woff2>; rel=preload; as=font; type=font/woff2
   ```

2. Confirm **Brotli** is On (issue #117). Leave Rocket Loader **off**. Auto Minify is optional.

### How to re-measure

Uncheck Chrome DevTools **Disable cache**. That checkbox is what sends request `cache-control: no-cache` / `pragma: no-cache` — the site response is `max-age=600`. Do not add `<link rel="preload" as="document">` for the current page. HTTP/3 is already advertised (`alt-svc: h3=":443"`).

**CSS:** brand design system is `_includes/main.css` (Paper / Ink / Signature Blue `#0077A8`). Pages load it (and `/assets` JS/favicons) from origin with a content-hash `?v=` so Cloudflare’s long browser TTL cannot keep a stale sheet. Fonts are self-hosted under `/assets/fonts/` (version in the filename). Feature sheets (code, search, embeds, pagination) load only when the page needs them. Long-form **editorials** live under `editorial/` (Markdown `layout: editorial` or handcrafted HTML) and add the editorial sheet. **Books** (`layout: book`) add `/assets/css/book.css`. Tooling: `/assets/css/main.css`, `/assets/css/editorial.css`, `/assets/css/book.css`.

## Structure

```
├── .github/workflows/deploy.yml   # Build + deploy on push to main
├── assets/deprecated/             # Archived unused source (excluded)
├── _includes/                     # Header, footer, head, main.css, feature CSS
├── _layouts/                      # default, post, page, book
├── _books/                        # Nested books → /books/<slug>/…
├── _posts/                        # Published short posts
├── assets/css/main.html           # /assets/css/main.css (tooling)
├── _config.yml
├── Gemfile
├── _pages/                        # Site pages (about, blog, books, robots.txt, …)
├── index.md
└── (robots.txt generated from _pages/robots.html)
```

## License

Content © Jonathan Frei. Code in this repository may be reused with attribution.
