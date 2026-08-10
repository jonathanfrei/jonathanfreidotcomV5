# jonathanfrei.com (V5)

Personal site and blog for [jonathanfrei.com](https://jonathanfrei.com).

Built with **Jekyll 4.x**, deployed via **GitHub Actions** to **GitHub Pages**, and served behind **Cloudflare**.

## Features

- Minimalist, mobile-first design with system dark mode (`prefers-color-scheme`)
- Accessibility-focused (semantic HTML, skip link, focus styles, reduced-motion)
- Tiny custom utility CSS
- Short posts + long-form pages
- RSS feed + sitemap + basic SEO
- Obfuscated drafts folder (`_x7k9p`) excluded from build, indexes, feeds, and robots.txt
- Manual or push-triggered deploys (no scheduled rebuild)
- Masked contact email (no form)

## Development workflow

Most work happens directly on GitHub (or via Grok-assisted edits).

1. Write posts as Markdown in `_posts/` (or place drafts in `_x7k9p/`).
2. Push to `main` → Actions builds and deploys.
3. Future-dated posts publish on the next content push (or run **Deploy** via workflow_dispatch).

### Agents

AI coding agents should read **[AGENTS.md](./AGENTS.md)** first. It covers repo layout, drafts, permalinks, CSS include rules, deploy constraints, and common pitfalls for this site.

### Drafts

Place unfinished Markdown files in the obfuscated folder `_x7k9p/`.
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

## Cloudflare performance (gzip / Brotli + Expires)

GitHub Pages does **not** accept custom `Expires` / `Cache-Control` headers or compression settings from the repo. This site is served behind **Cloudflare**, so configure compression and long-lived cache there.

### Compress components (gzip / Brotli) — issue #117

Cloudflare compresses HTML, CSS, JS, SVG, JSON, and fonts at the edge by default:

1. **Speed → Optimization → Content Optimization**
2. Confirm **Brotli** is **On** (preferred; clients that do not support Brotli still get gzip)
3. Optional: enable **Auto Minify** for HTML/CSS/JS only if you accept the extra transform

No repo change is required for gzip once the orange-cloud proxy is on the production hostname.

### Expires / long TTL cache — issue #119

GitHub Pages sets short default cache lifetimes (Lighthouse often reports ~10 minutes for CSS). Use a **Cache Rule** (Cloudflare dashboard → Caching → Cache Rules) matching your production hostname:

| Match | Edge TTL | Browser TTL |
| --- | --- | --- |
| URI Path matches `*.css` OR `*.js` OR `*.png` OR `*.jpg` OR `*.webp` OR `*.svg` OR `*.ico` OR `*.woff2` OR `*.woff` | 1 month (or longer) | 1 day – 1 week |
| URI Path matches `*.xml` (feeds/sitemaps) | 2 hours | 1 hour |

Optional: “Cache Everything” for HTML with a short Edge TTL (e.g. 2 hours) if you want faster global TTFB and accept brief staleness after deploys. Purge cache after important publishes if you use that rule.

**CSS:** brand design system is **inlined** from `_includes/main.css` (Paper / Ink / Signature Blue `#0077A8`). Feature sheets (code, search, embeds, pagination) load only when the page needs them. Long-form **editorials** live under `editorial/` (Markdown `layout: editorial` or handcrafted HTML) with `_includes/editorial.css`. Tooling: `/assets/css/main.css`, `/assets/css/editorial.css`.

## Structure

```
├── .github/workflows/deploy.yml   # Build + deploy on push to main
├── _x7k9p/                        # Obfuscated drafts (excluded)
├── _includes/                     # Header, footer, head, main.css, feature CSS
├── _layouts/                      # default, post, page
├── _posts/                        # Published short posts
├── assets/css/main.html           # /assets/css/main.css (tooling)
├── _config.yml
├── Gemfile
├── _pages/                        # Site pages (about, blog, tags, …)
├── index.md
└── robots.txt
```

## License

Content © Jonathan Frei. Code in this repository may be reused with attribution.
