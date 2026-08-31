# AGENTS.md

Jekyll 4.x static site → GitHub Actions → GitHub Pages → Cloudflare. No app server, no DB. Prefer small focused changes.

## Commands

```bash
bundle install
bundle exec jekyll serve                    # local preview
bundle exec jekyll build --baseurl "${{ steps.pages.outputs.base_path }}"  # production (CI)
```

- Ruby **3.3** (CI). `TZ=America/New_York` required in CI (`_config.yml:10` `timezone`).
- Production needs `JEKYLL_ENV=production ARCHIVE_MEDIA_MODE=cdn IMG_HMAC=<same as Worker secret>` or build fails (`deploy.yml:51-54`). Full history `fetch-depth: 0` for `post_metadata.rb:79`.
- Verify after layout/CSS/build changes: check `_site/build-errors.log` and run `grep -Rql` guards from `deploy.yml:198-543` locally.

## Deploy

- Single workflow `.github/workflows/deploy.yml:1` on `push: main` (plus `workflow_dispatch`). `paths-ignore: README.md, AGENTS.md, .gitignore` — docs-only pushes skip build.
- Future-dated posts publish on next content push (no cron, `future: true` in `_config.yml:15`).
- Artifact must not contain `_site/media` or `_posts/v*-archive/media`; HTML must contain `media.jonathanfrei.com/v{2,3}-archive/media/` (`deploy.yml:158-192`).
- After push to `main`, confirm Actions green. Cloudflare purge runs when `CLOUDFLARE_ZONE_ID` + `CLOUDFLARE_API_TOKEN` set (`deploy.yml:569-585`); otherwise `HIT` vs `DYNAMIC` check needed.

## Structure

```
_config.yml              site config, permalinks, archive_media, collections
_posts/YYYY-MM-DD-*.md   published posts + link posts; v1/v2/v3-archive/ is historical
_books/<slug>/           nested book collection (001- prefix = sort key, permalink = slug)
_pages/                  site pages → root URLs via _plugins/pages_dir.rb (index.md stays at root)
_includes/               head, header, footer, main.css / editorial.css / book.css / code.css / search.css / embeds.css
_layouts/                default, post, page, book, link, editorial, archive, tag
_plugins/                books.rb, post_metadata.rb, site_index.rb, optimize_content_images.rb, url_embeds.rb, asset_cdn.rb, pages_dir.rb, static_html_pages.rb
assets/css/*.html        generates /assets/css/core.css via asset_url (_plugins/asset_cdn.rb)
editorial/               static HTML drop-ins + Markdown editorials → /editorial/<slug>
workers/img-proxy/       Cloudflare Worker /img → wsrv.nl (HMAC, wrangler.toml)
```

## Permalinks (do not regress #63)

- Desired: `/about`, `/blog`, `/:year/:month/:day/:title`, `/tags`, `/editorial/<slug>`, `/books/<slug>/…` — **no trailing slash**, written as `.html` files (GH Pages serves clean path). Never emit extensionless files (`application/octet-stream`).
- Exception: `jekyll-archives` month pages ` /archive/:year/:month/` must keep trailing slash (`_config.yml:97`).
- `permalink: /:year/:month/:day/:title` uses `timezone: America/New_York` (`_config.yml:10`, #180) so Eastern evening dates don't roll to UTC.
- Cloudflare must 301 `/path/` → `/path` excluding `/`, `/archive/*/*/`, `/…/page/*/` (Free plan: `wildcard` / `wildcard_replace` / `ends_with`, not `regex_replace`).

## Content contracts

**Posts** `_posts/YYYY-MM-DD-slug.md` (#75):
```yaml
---
title: "Title"
date: 2026-08-04 16:00:00 -0400   # first published, never auto-overwrite; TZ-aware
tags: [tag-one, tag-two]
description: "SEO sentence (preferred over raw excerpt)"
---
```
- `last_modified_at` only for intentional revisions (>24h shows "Updated …"); otherwise `post_metadata.rb` fills from git.
- `drop_cap` auto when file >5KB + first prose line >100 chars (#123); headings/images/HTML/lists never qualify.
- Default `layout: post`. Chips → `/tags?tag=name`.

**Link posts** `layout: link` + `url: https://…` : same `/:year/:month/:day/:title` permalink. Mixed into `/blog` (`_plugins/stream_pages.rb`, `pagination.per_page: 100` in `_config.yml:64`) and `search.json`. `card: false` skips OG fetch or `card: {title, description, image, …}` supplies it (cached `.jekyll-cache/link-cards/`). `url_embeds.rb` skipped in RSS; feed `/feed.xml` links external URL.

**Books** `_books/<book-slug>/001-book.md → /books/<slug>`; nested `002-chapter/001-section.md → /books/<slug>/chapter/section`. `001-` / `002a-` are sort keys only (`books.rb`). `slug:` overrides filename. `index: false` → `noindex` + `robots.txt` Disallow + exclude from `search.json`/`sitemap`. `listed: false` hides from `/books`. Book-home `author:` copied to all chapters (#277).

**Pages** `_pages/about.md → /about` via `pages_dir.rb:#161`; `_pages/services/x.md → /services/x`. `permalink` no trailing slash.

**Search/tags** No generated `/tags/:name` or `/categories/:name` dirs (`deploy.yml:317-321` guards). Chips use `?tag=` / `?category=` query views from `search.json` (`site_index.rb`, `stream-list.html` #201/#209/#219). `search.json` schema: `kind,title,url,date,date_label,excerpt,tags,categories,img{src,alt,full}` with signed `/img` URLs; keep budgets <600KB warn / 1.5MB fail.

**Embeds** Standalone supported URL alone on line (blank lines around) → embed via `url_embeds.rb` (YouTube, Vimeo, X, Instagram, TikTok, Spotify, CodePen, Imgur, Flickr). Opt out `url_embeds: false`. Use `markdown="0"` without indentation (#156).

**Static HTML** `editorial/<slug>.html → /editorial/<slug>` per `static_html.roots: [editorial]` (`_config.yml:138`). No front matter. Asset sibling folders OK; don't put `index.html` inside asset folder.

## Assets & images (critical)

- **Media not in artifact**: archive + new photos live on S3 `https://media.jonathanfrei.com` (`archive_media.cdn_base` #170). New post photos must be absolute CDN URLs via factory worker (`https://media.jonathanfrei.com/assets/img/...`); **don't commit binaries** or use `/assets/img/` for new photos (that's favicon/profile).
- **Image optimize** `_plugins/optimize_content_images.rb`: own images + hotlinked → same-origin `/img?url=&w=&output=webp&q=85&we&s=` (HMAC `IMG_HMAC` must match Worker). Config `archive_media.optimize: proxy, quality 85, widths [480,768,1100], sizes "(max-width: 40em) 100vw, 36em", hotlink true`. GIF/SVG never proxied (`loading=lazy` fallback); `data-full-src` keeps original. Wrap URLs with `()` in `<>`, don't fetch `wsrv` JSON at build (would be ~11min). Hotlink uses `ssl:` for Springer hosts; `\( \)` stripped before proxy (#203).
- **Worker** `workers/img-proxy/src/index.js:90` canonical `output=&q=&url=&w=&we`; route `jonathanfrei.com/img*` (not `/img/*`), 200 cache 30d, 4xx/5xx `no-store`. Redeploy Worker after `src/index.js` changes (Pages deploy doesn't).
- **CSS** Tokens in `_includes/main.css` (Paper `#FAF9F6`, Ink `#111C24`, Blue `#0077A8` #145). Feature sheets gated by `optional-css.html` via content probes: `code.css` (`<pre`), `search.css`, `embeds.css`, `pagination.css`. `editorial.css` (`layout: editorial`), `book.css` (`layout: book`) linked as `/assets/css/<name>.css?v=<hash>` via `asset_url` (`asset_cdn.rb`). Never `{% include_relative ../... %}`. Never inline `main.css` or use `cdn.jsdelivr.net` for chrome/fonts. `kramdown.parse_block_html: true` required for editorial wrappers. Prose marks `{: .aside}`, `{: .pull-quote}`, `{: .caption}`, `{: .figure-wide}` in `main.css` — `.figure-wide` uses `100cqi` of `.site-main`, not `100vw`, no `.container:has(...)` (#223). Fonts `/assets/fonts/source-*woff2` self-hosted, versioned filenames; first-paint preloads only Serif 4 + Code Pro normal (not Source Sans 3). Don't restore `html.is-narrow` viewport hack — iOS safari “desktop layout” was page-zoom lock (#231).

## Cloudflare edge (README source of truth)

- SSL/TLS **Full** (not Full-strict → 526 on apex, not Flexible → `http://` redirects) (#82).
- **Cache Everything** for HTML (2h edge, respect `max-age=600` browser); extension-excluded assets use 1 month. `/img` Worker has own rule: host=`jonathanfrei.com` + path starts `/img`, respect origin cache, include query string in key. Exclude `.json` (`search.json`) and `/img` from HTML cache.
- Redirects before cache: `www → apex` and trailing-slash strip. Free plan can't use `regex_replace`/`matches`.
- `_includes/head.html` must not preconnect `wsrv.nl` / `cdn.jsdelivr.net`; `media.jonathanfrei.com` only when page has `<img>` from that host (injected by optimizer). Speculation Rules prefetch `/,/about,/blog,/archive` only (prefetch not prerender).

## Verification before finishing build/layout/CSS changes

- Permalinks no slash (`/about` not `/about/`); `/blog.html` exists not `/blog/index.html`; month archives keep slash.
- Every page links `/assets/css/core.css?v=`; no `cdn.jsdelivr.net`, no inlined `main.css`, no `../` includes.
- Tags → `/tags?tag=` chip class `.tag` not oversized; no `_site/tags/` or `_site/categories/` dirs; search UI present.
- Only intentional `_posts/` additions; drafts stay outside repo.
- Actions majors: `checkout@v7 configure-pages@v6 upload-pages-artifact@v5 deploy-pages@v5` (`deploy.yml:27-41`) — don't downgrade without checking Node warnings.
- After `main` push, cloudflare `cf-cache-status: HIT` for HTML, signed `/img?url=` for images, `wsrv.nl` absent from HTML/`search.json`.

## Don't

- Add frameworks/bundlers/CMS, commit secrets, `_site/`, `vendor/`, or post photos; remove footer AI note or contact masking without ask; rewrite `_posts/v1-archive/` history; force-push `main`; invent client routers for downloads.

## Workflow

- Prefer branch+PR for multi-file/behavior; direct `main` only for urgent fix when owner asks. Commit: complete sentences + issue `#N`; PR: what/why/how to verify, `Closes #N`. Ensure green deploy after merge.
