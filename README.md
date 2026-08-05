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
- Scheduled rebuilds so future-dated posts publish automatically
- Masked contact email (no form)

## Development workflow

Most work happens directly on GitHub (or via Grok-assisted edits).

1. Write posts as Markdown in `_posts/` (or place drafts in `_x7k9p/`).
2. Push to `main` → Actions builds and deploys.
3. Future-dated posts are picked up by the scheduled workflow (every 6 hours).

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

## Cloudflare caching (Expires / long TTL)

GitHub Pages sets short default cache lifetimes on static assets (Lighthouse often reports ~10 minutes for CSS). Because the site is served behind **Cloudflare**, set edge/browser cache there — GitHub Pages itself does not accept custom `Expires` / `Cache-Control` headers from the repo.

Recommended **Cache Rule** (Cloudflare dashboard → Caching → Cache Rules), matching your production hostname:

| Match | Edge TTL | Browser TTL |
| --- | --- | --- |
| URI Path matches `*.css` OR `*.js` OR `*.png` OR `*.jpg` OR `*.webp` OR `*.svg` OR `*.ico` OR `*.woff2` | 1 month (or longer) | 1 day – 1 week |

Optional: “Cache Everything” for HTML with a short Edge TTL (e.g. 2 hours) if you want faster global TTFB and accept brief staleness after deploys.

Critical CSS is also **inlined** in the HTML so first paint does not depend on a render-blocking stylesheet fetch; the external `assets/css/main.css` remains available for long-lived caching once Cloudflare rules are in place.

## Structure

```
├── .github/workflows/deploy.yml   # Build + deploy + scheduled rebuild
├── _x7k9p/                        # Obfuscated drafts (excluded)
├── _includes/                     # Header, footer, head
├── _layouts/                      # default, post, page
├── _posts/                        # Published short posts
├── assets/css/main.css            # Tiny utility CSS
├── _config.yml
├── Gemfile
├── index.md, about.md, blog.md
└── robots.txt
```

## License

Content © Jonathan Frei. Code in this repository may be reused with attribution.
