# AGENTS.md

Guidance for AI coding agents working on **jonathanfrei.com (V5)**.

This is a personal site and blog: **Jekyll 4.x → GitHub Actions → GitHub Pages → Cloudflare**. Prefer small, focused changes. Match existing style. Do not invent a framework or redesign the design system unless asked.

## Project overview

| Item | Detail |
| --- | --- |
| Site | [jonathanfrei.com](https://jonathanfrei.com) |
| Repo | Static Jekyll site (no app server, no database) |
| Content | Markdown posts/pages; HTML layouts/includes |
| Design | Brand tokens in `_includes/main.css` (Paper/Ink/Signature Blue #145); `editorial.css` for long-form (#144) |
| Deploy | Push to `main` runs a single full `deploy.yml` (manual `workflow_dispatch` also available). Archive media stays on **S3**, not the Pages artifact. |
| Archive media | Served from **S3** (`media.jonathanfrei.com/v{2,3}-archive/media/…`). See `archive_media` in `_config.yml` and issues #68 / #170. In-repo media trees may be removed after migration. |
| New post photos | S3 `https://media.jonathanfrei.com/assets/img/…` via the factory upload worker. Absolute CDN URLs in Markdown. Do **not** commit binaries or use site-relative `/assets/img/` for new photos (that path is favicon/profile on Pages). |
| Image perf | `_plugins/optimize_content_images.rb` optimizes **all own site images** (archive media + S3 `/assets/img/` + in-repo `/assets/`): dimensions, lazy/LCP hints, responsive WebP via wsrv.nl (full-res on `data-full-src`). See issue #90. |

### Directory map

```
.github/workflows/deploy.yml              # Full build + deploy on push to main
_config.yml                    # Site config, plugins, permalinks, excludes
_includes/                     # head, header, footer, main.css, code.css, editorial.css
_layouts/                      # default, page, post, tag, editorial, book
_plugins/url_embeds.rb         # Standalone media URLs → embeds
_plugins/books.rb              # Book collection: slugs, TOC, prev/next, noindex
_books/<book-slug>/            # Nested markdown books → /books/<book-slug>/…
_posts/                        # Published posts and link posts (YYYY-MM-DD-slug.md)
_posts/v1-archive/             # Historical imported posts (treat carefully)
_x7k9p/                        # Obfuscated drafts (excluded from build & CI paths)
assets/                        # Images, JS; CSS tooling at assets/css/*.html
editorial/                     # Handcrafted HTML drop-ins (slug.html → /editorial/slug)
editorial/                     # HTML drop-ins + Markdown editorials (layout: editorial)
index.md                         # Home (stays at repo root)
_pages/                          # Site pages → root URLs (/about, /blog, …)
_pages/**/*.md                   # Nested files → /section/page (#161)
```




## Setup (local, optional)

```bash
bundle install
bundle exec jekyll serve
```

Ruby **3.3** matches CI. There may be no Ruby on the agent host; still prefer valid Jekyll/Liquid that would pass `bundle exec jekyll build`.

Production build (CI):

```bash
bundle exec jekyll build --baseurl "${{ steps.pages.outputs.base_path }}"
```

## How work usually lands

1. Prefer a branch + PR for multi-file or behavior changes; direct `main` is fine for urgent build/content fixes when the owner asks.
2. Push to `main` deploys via a **single** full `deploy.yml` (except pure draft/doc paths — see CI `paths-ignore`).
3. Future-dated posts publish on the **next content push** (or manual **workflow_dispatch**). There is no scheduled rebuild (#142).
4. After deploy, confirm the Actions run is green when you changed build-related files.
5. **Media is never in the Pages artifact** — production uses `ARCHIVE_MEDIA_MODE=cdn` (S3 / `media.jonathanfrei.com`). The deploy step fails if `_site/media` appears.

## Content rules

### Posts

- Path: `_posts/YYYY-MM-DD-slug.md`
- Front matter contract (issue #75) — keep it small; optional fields stay optional:

```yaml
---
title: "Post title"
date: 2026-08-04 16:00:00 -0400   # first published (canonical); prefer datetime + TZ
# last_modified_at: 2026-08-10 09:00:00 -0400  # optional intentional revision stamp
tags: [tag-one, tag-two]
# categories: [notes]
description: "One or two sentences for SEO/social (preferred over raw excerpt)."
# excerpt: "Optional list blurb; falls back to auto-excerpt."
# image: https://media.jonathanfrei.com/assets/img/2026/2026-08-15-093000-example.jpg
# author: Jonathan Frei                  # only override site default when needed
---
```

- **`date`** = first publication. Never auto-overwrite on edit. Prefer `YYYY-MM-DD HH:MM:SS ±ZZZZ` for new posts. Site timezone is **`America/New_York`** (`_config.yml`, issue #180) so evening Eastern dates do not roll to the next UTC day in bylines or `/:year/:month/:day/` permalinks. There is no plugin generating HTML redirects from old UTC paths; add those later only if a real link needs one.
- **`drop_cap`:** optional override. If omitted, longer posts get a drop cap when the **file is > 5 KB** and the **first non-empty body line is prose > 100 characters** (issue #123). Set `drop_cap: false` to opt out or `drop_cap: true` to force one. Headings, images, HTML, quotes, and lists never qualify. When on, drop caps apply to the opening paragraph (after the H1), sized to two lines (`initial-letter: 2`).
- **`last_modified_at`**: set in front matter only for intentional revisions (shows “Updated …” in the byline when **> 24h** after `date`). If omitted, `_plugins/post_metadata.rb` fills it from **git** for Schema.org `dateModified`, `jekyll-seo-tag`, and sitemap `lastmod` — not for the visible byline (avoids archive-import noise). Deploy uses `fetch-depth: 0` for full history.
- **Reading time / word count:** computed at build (`reading_time`, `word_count`); “N min read” shows when ≥ 2 minutes. No front matter required.
- **`description`:** encourage on new posts for stable SEO/social; archive posts need not be backfilled.
- Default layout is `post` (from `_config.yml`). Do not set a custom layout unless needed.
- Tags should be simple lowercase slugs where possible; chips link to `/tags?tag=name`.
- A malformed post or link is skipped (site still builds). Check `_site/build-errors.log` and the Actions log before the next publish (#186).

### Drafts (`_x7k9p/`)

- Unfinished work goes in **`_x7k9p/`**, never in `_posts/` until ready to publish.
- Excluded from Jekyll build, feed, sitemap; blocked in `robots.txt`.
- CI **`paths-ignore`** includes `_x7k9p/**` so draft-only commits do not rebuild the site.
- To publish: move to `_posts/` with a proper dated filename and front matter.

### Link posts (`layout: link`)

- A link is a normal post in `_posts/YYYY-MM-DD-slug.md` with `layout: link`
  and a public `http(s)` `url:`. Permalink is the same as every other post:
  `/:year/:month/:day/:title`.
- Required front matter: `title`, `url`, `date`, `layout: link`. Optional:
  `excerpt`, `tags`, Markdown body, `card`. Category defaults to `links`.
- Permalink pages are minimal: date (linked to the permalink), then an
  outbound `→` on the first line of the body, then tags and an on-site URL
  card. No visible title/`h1`. `title` is still used for RSS and document
  `<title>` / SEO. The ending matches essays: Comment · Edit · Random · Blog
  (#221). Random draws from every `search.json` entry, including link posts.
  List pages hide the title and keep `→` on the first line of the body. The
  date is the on-site permalink; `#` appears only in RSS.
- URL cards are **site-only** (never in RSS). Default is a build-time Open
  Graph fetch (fail-soft, cached under `.jekyll-cache/link-cards/`).
  `card: false` hides the card and skips the fetch. A `card:` mapping
  (`title`, `description`, `image`, `image_alt`, `site_name`) supplies the
  preview and skips the fetch. Card images are proxied through wsrv.nl like
  other hotlinked assets.
- A bad `url:` is skipped for the card and logged to `_site/build-errors.log`.
  The rest of the site still builds.
- The main feed is `/blog` (essays and links mixed, 50 per page). There is
  no separate `/posts` or `/links` index; those URLs redirect to `/blog`.
  Essays on `/blog` show title, date, tags, reading time, a 2–3 paragraph
  excerpt, and Read more. Link entries hide the title and keep `→` on the
  first line. Link tags are ordinary post tags; chips go to `/tags?tag=name`.
- **List views match `/blog`** (`_includes/stream-list.html`, #201): month
  archives (`/archive/YYYY/MM/`) use the same post-entry / link-entry stream.
  Tag results are `/tags?tag=name`; category results are
  `/categories?category=name`. Those query views (and `/search?q=`) render
  from `search.json` with the same stream elements that exist in the index:
  title, long date, tags, excerpt, first image, Read more (#219). No
  generated `/tags/:name` or `/categories/:name` pages. Do not regress
  remaining list pages to title+date-only rows.
- Feed: `/feed.xml` (mixed; link items `<link>`/`<guid>` the external URL;
  full content). Link items use `#` for the on-site permalink in RSS only.
- Example:

  ```yaml
  ---
  layout: link
  title: "A useful essay"
  url: "https://example.com/essay"
  date: 2026-08-13 14:30:00 -0400
  excerpt: "Optional list blurb."
  tags: [reading]
  # card: false
  ---

  Optional Markdown body.
  ```

### Books (`_books/`)

Long-form books are a Jekyll collection. One folder per book; nested folders are chapters.

```
_books/
  my-book/                         # stable book slug (no numeric prefix)
    001-my-book.md                 # book home → /books/my-book
    002-first-chapter/
      001-first-chapter.md         # → /books/my-book/first-chapter
      002-a-section.md             # → /books/my-book/first-chapter/a-section
    003-appendix.md                # leaf chapter → /books/my-book/appendix
```

- **`001-` prefixes (and `002a-` insertions) are sort keys only.** Permalinks use slugs. Renaming prefixes does not change URLs.
- Insert a chapter between `002` and `003` as `002a-new-chapter/` (or `order:` in front matter). Display numbers (`1`, `1.1`) are computed at build; existing permalinks stay put.
- `slug:` front matter is the permalink segment; if omitted, the filename minus the numeric prefix is used.
- Titles should be **number-free**. The layout prints computed numbers in the TOC and pager.
- Book-home front matter: `index: false` blocks crawlers (robots.txt Disallow, `noindex,nofollow`, omit from sitemap/search). `listed: false` hides the book from `/books`. Defaults: `index` true; `listed` follows `index`.
- Optional `eyebrow` and `deck` in front matter render above/below the title, same as posts and pages (#278).
- Optional `author` on the book home is copied to every chapter and shown with `source` **below** `articleBody` (#277). There is no collection default; a book without `author` in page-one front matter does not display “Jonathan Frei”.
- Layout is `book` (sticky hamburger + wrapping breadcrumbs, contents overlay, prev/next). Book chrome CSS is `/assets/css/book.css`, not inlined. Hash links use `scroll-padding-top` so H2/H3 are not hidden behind the sticky toolbar (#275). The hamburger TOC is loaded from `/books/<slug>/toc.json` (same idea as `search.json`) so chapter HTML does not embed the full tree. The title page still renders an in-article HTML TOC. The overlay starts closed on every page. Do not add a header “Books” link unless asked.
- Demo: `_books/dispelling-beauty-lies/` is borrowed content (`index: false`, `listed: false`).
- Optional `scripts/import_beauty_book.py` rebuilds that demo tree from the Downloads conversion.

### Pages

- Site pages live under **`_pages/`** (issue #161), not the repo root.
- Root-level URLs: `_pages/about.md` → `/about` (front-matter `permalink` or auto via `_plugins/pages_dir.rb`).
- Nested pages: `_pages/services/service1.md` → `/services/service1`.
- `index.md` stays at the repo root (homepage).
- Use **no trailing slash** in permalinks (see below).
- Long-form specimen / design reference: `_pages/typography.md` → `/typography` (includes `#223` aside / pull-quote / caption / figure-wide).
- Tags: `/tags` lists multi-post tags (#140). Every chip (including singletons) links to `/tags?tag=name`. Individual `/tags/:name` pages are not generated (#209). Old `/tags/:name` URLs 404-redirect to the search URL.
- Categories: `/categories` lists categories. Chips link to `/categories?category=name`. Individual `/categories/:name` pages are not generated. Old `/categories/:name` URLs 404-redirect to the search URL.

### Media embeds

- A **supported raw URL alone on a line** (blank lines around it) becomes an embed via `_plugins/url_embeds.rb`.
- Supported: YouTube, Vimeo, X/Twitter, Instagram, TikTok, Spotify, CodePen, Imgur, Flickr.
- Opt out per document: `url_embeds: false` in front matter.
- Inline links inside paragraphs are **not** transformed.
- Embed HTML uses `markdown="0"` and no inner indentation so Kramdown `parse_block_html` does not turn iframes into highlighter blocks (#156).
- Imgur gallery SEO slugs (`/gallery/title-hash`) resolve to the trailing image hash (#157).
- Hotlinked third-party images are rewritten through wsrv.nl in production (`archive_media.optimize.hotlink`, #116). HTTPS-only hosts such as Springer need `ssl:` in the wsrv `url` param (wsrv defaults to http and 404s). If the proxy still fails, `data-full-src` plus a capture-phase error listener falls back to the original (#203). Kramdown leaves `\( \)` in destinations (cmark/GitHub unescapes them); the optimizer strips those backslashes before proxying. For new markup, wrap URLs that contain parentheses in `<>`.
- **GIFs** are never sent through wsrv. Every `<img src="…gif">` gets `loading="lazy"` and is never the LCP/eager candidate. GIF-only paragraphs are omitted from list excerpts (`list_excerpt`) so `/blog` does not download a multi-megabyte animation in the stream. The GIF still renders on the permalink.
- Standalone article images fill the measure; on viewports ≤40em they full-bleed past `.container` padding (#202, #203). Do not apply `width: 100%` to every `.prose img` (the typography favicon specimen must stay small).

### Static HTML pages (`editorial/`, extensible)

Handcrafted full HTML pages (not Jekyll layouts). Drop a file at the root of a configured directory; it publishes at a **clean permalink** (no trailing slash).

```
editorial/
  spacex-earnings.html     # → /editorial/spacex-earnings
  spacex-earnings/         # optional assets for that piece
    chart.png
  media/                   # optional shared assets under the root
  assets/
```

- **Do:** `editorial/<slug>.html` (and optional sibling asset folders)
- **Do not:** put `index.html` inside an asset folder if that would steal the slug URL
- **No YAML front matter** — HTML is not Liquid-rendered (safe to use `{{` in the page)
- Relative image paths are absolutized and optimized via wsrv.nl in production (#88, #90)
- Roots are listed under `static_html.roots` in `_config.yml` (add `articles`, etc. later)
- Does not use site chrome (`_layouts`, header/footer) unless you hardcode it into the HTML

## Critical constraints (do not regress)

### 1. Permalinks must not use a trailing slash

Desired URLs: `/about`, `/blog`, `/2026/08/05/slug`, `/tags` — **not** `/about/`, etc. (issue #63).

- **Do:** `permalink: /about`, post pattern `/:year/:month/:day/:title`, tag search `/tags?tag=name`
- Post `:year/:month/:day` uses **`timezone: America/New_York`** (issue #180), not the Actions runner’s UTC clock.
- Jekyll then writes **`.html` files** (`about.html`). GitHub Pages serves those at the clean path.
- **Do not** write extensionless files (no `.html`) — GH Pages may download them as `application/octet-stream`.
- Keep internal links consistent (`/blog`, `/tags?tag=foo`, etc.).
- After deploy, Cloudflare should 301 `/path/` → `/path` so old bookmarks still work (issue #82). Exclude `/`, `/archive/YYYY/MM/`, and `/…/page/N/`. See README “Cloudflare performance”.
- Month archives (`/archive/YYYY/MM/`) **must** keep the trailing slash (directory + `index.html`).

### 1b. Cloudflare edge

Dashboard rules live in README (redirects before cache). Do not regress:

- SSL/TLS mode is **Full**, not Full (strict). GitHub Pages has no apex certificate for `jonathanfrei.com`; Full (strict) returns 526. Do not switch back to Flexible (that emits `http://` origin redirects).
- HTML must be Cache Everything at the edge. `cf-cache-status: DYNAMIC` on documents means the rule is off; TTFB will stay a full Cloudflare → GitHub Pages hop.
- `deploy.yml` purges Cloudflare after Pages deploy when `CLOUDFLARE_ZONE_ID` and `CLOUDFLARE_API_TOKEN` are set. Do not remove that step if HTML stays cached.
- `_includes/head.html` always `preconnect`s `cdn.jsdelivr.net`. `wsrv.nl` and `media.jonathanfrei.com` only when the page will fetch them (`<img>` / those hosts in `content`). `optimize_content_images.rb` injects a missing host hint after image rewrite. Do not restore unconditional preconnects or redundant `dns-prefetch` for the same hosts.
- Speculation Rules in `head.html` prefetch `/`, `/about`, `/blog`, `/archive` on moderate eagerness. Prefetch only — do not prerender, and do not add `<link rel="preload" as="document">` for the current page.
- Free-plan Redirect Rules cannot use `regex_replace` or `matches`. Use `wildcard` / `wildcard_replace` / `ends_with`. Do not put the SHA-pinned jsDelivr `main.css` URL in a Cloudflare `Link` / Early Hints rule; it changes every commit.

### 2. CSS — brand system + optional sheets

- **Brand (#145):** `_includes/main.css` — Paper `#FAF9F6`, Ink `#111C24`, Signature Blue `#0077A8` (use blue sparingly). Full token table in that file (blue scale + editorial accents + UI semantics).
- **Feature sheets (#165):** gated by `_includes/optional-css.html` (content probes; no PurgeCSS/Node build):
  - `_includes/code.css` — fenced code / Rouge (`<pre`); wrap by default, line numbers follow wrapped lines (#222)
  - `_includes/search.css` — search box (`search-ui` / `search-input`)
  - `_includes/embeds.css` — media embeds (`class="embed` / `data-embed=`)
  - `_includes/pagination.css` — paginated lists (`pagination-list`)
- **Editorial (#144):** `_includes/editorial.css` + `layout: editorial` — Kramdown semantic components (`.lead`, `.figure`, `.stat-grid`, …). Linked as `/assets/css/editorial.css` after `core.css`.
- **Books:** `_includes/book.css` + `layout: book` — linked as `/assets/css/book.css` after `core.css` (same pattern as editorial). Do **not** inline it in `optional-css.html`; that would copy the sheet into every chapter HTML.
- **Prose marks (#223):** `{: .aside}`, `{: .pull-quote}`, `{: .caption}`, `{: .figure-wide}` live in `main.css` for ordinary posts/pages. Do not reuse editorial-grid `.aside` for blog sidenotes. `.figure-wide` must not use `100vw` and must not restyle the page via `.container:has(.figure-wide)` — that indented every `.prose` child on `/blog` and `/archive` (the Blog page is itself `article.prose`). Only the figure breaks out, using `100cqi` of `.site-main` (fallback: container padding-cancel). Images keep intrinsic size (`width: auto; max-width: 100%`); on small screens the img fills the bleed slot. Kramdown IALs (`{: .figure-wide}`) are stripped from `search.json` excerpts in `_plugins/site_index.rb`. Never `margin-inline: auto` on every prose child to fake a measure — headings shrink-wrap and the column falls apart.
- **iOS Safari (#231):** the “desktop layout” was a locked page zoom on the site, not a CSS viewport bug. Do not restore `html.is-narrow` or a head script that rewrites the viewport meta. Do not set `overflow-x` on `html`. Hang asides only at `70em`.
- **Delivery:** every page links the design system via `asset_url` (`_includes/site-css.html`). Production uses jsDelivr (`cdn.jsdelivr.net/gh/…@SHA/_includes/main.css`); local serve stays on `/assets/css/core.css`. Do not inline `main.css` or restore the front-of-house vs archive split from PR #197.
- Tooling: `/assets/css/core.css` (design system), `/assets/css/main.css` (full combined), `/assets/css/editorial.css` (editorial components only), `/assets/css/book.css` (book chrome only)
- **Never** use `{% include_relative ../... %}` — Jekyll rejects `../`
- Prefer semantic classes over utility soup
- Kramdown: `parse_block_html: true` (Markdown inside HTML blocks for editorial components)

### 2b. Editorial content (`editorial/`)

- **One directory** for both formats:
  - Handcrafted HTML: `editorial/<slug>.html` → `/editorial/<slug>` (`static_html` plugin)
  - Markdown design system: `editorial/<slug>.md` + `layout: editorial` + `permalink: /editorial/<slug>`
- Authoring (MD): multi-block components **must** use HTML wrappers so lists/paragraphs stay inside the component:
  ```html
  <div class="takeaways" markdown="1">

  ### Key Takeaways

  - Bullet stays in the component

  </div>
  ```
  Kramdown `{: .class}` alone only styles the **next single block** (not following lists).
- Requires `kramdown.parse_block_html: true` (already set).
- **Layout:** CSS Grid (not multi-column fragmentation). Prose spans full width with `max-width: ~38rem` measure. Compact cards (definition, callouts, event/entity) sit 1–3 across on wide screens; wide components (header, figures, tables, composition grids) always span full width.
- **Dark mode:** brand tokens remap in `main.css` so `--ed-deep` / `--ed-ice` stay readable on dark surfaces.
- Component reference: `/editorial/design-system`
- Sample article: `/editorial/invisible-engine`
- Plugin only manages top-level `.html` files; `.md` pages are normal Jekyll pages

### 3. Tag / list CSS specificity

- Post titles in lists: `.post-list > li > a` (not `.post-list a`)
- Tag chips use `.tag`; they must not inherit large title-link styles inside `.post-list`

### 4. Jekyll excludes

Keep these out of the site build (see `_config.yml` `exclude`):

- `Gemfile`, `Gemfile.lock`, `vendor`, `node_modules`, `.github`, `README.md`, `AGENTS.md`, `_x7k9p`, `.gitignore`

### 5. Actions / Node runtime

Deploy workflow pins current major Pages actions (Node 24-capable majors):

- `actions/checkout@v5`
- `actions/configure-pages@v6`
- `actions/upload-pages-artifact@v5`
- `actions/deploy-pages@v5`

Do not downgrade these without checking Node deprecation warnings on GH Actions.

Dependabot and scheduled deploys were removed (#142). Bump Actions majors and gems intentionally in PRs when needed.

### 6. Third-party image / CDN trust boundary

Production depends on external services for media (configured in `_config.yml` `archive_media`):

| Service | Role | Config key |
| --- | --- | --- |
| **S3 / media.jonathanfrei.com** | Archive binaries (`v{2,3}-archive/media/…`) and new post photos (`assets/img/…`) — not in the Pages artifact (#170) | `archive_media.cdn_base` |
| **wsrv.nl** | On-the-fly resize + WebP for own-site images (archive + S3 `/assets/img/` + in-repo `/assets/`); full-res on `data-full-src` | `archive_media.optimize.proxy` |
| **jsDelivr** | Fontsource fonts, plus production `/assets` (CSS/JS/favicons) pinned to the build commit | `assets_cdn` in `_config.yml`; `@font-face` in `main.css` |

- Production CSS/JS/favicons load from jsDelivr and fall back to origin `/assets` if the CDN cannot fetch the commit (GitHub blip). S3/wsrv still have no chrome fallback: images break or revert to the original `src`.
- Do **not** point `cdn_base` or the proxy at untrusted hosts or arbitrary user content.
- Changing `cdn_base` or the proxy host is a production-facing decision; prefer a PR and a smoke check of a few archive posts + `/assets/` images.
- Local `jekyll serve` uses S3 in CDN mode (default once in-repo media trees are gone). `ARCHIVE_MEDIA_MODE=local` only helps while `_posts/v*-archive/media/` still exists on disk.

## Design system (short)

- Tokens/components: `_includes/main.css` (see §2); feature sheets via `optional-css.html`
- Principles: readable measure, simple type scale, two custom faces, restrained accent, light default + dark
- Prefer semantic classes (`.prose`, `.post-meta`, `.tag`, `.post-list`, `.post-header`) over one-off or utility CSS
- Accessibility: keep skip link, focus styles, semantic HTML, sensible contrast
- Specimen page: `/typography` (`typography.md`) — use when adding HTML patterns or checking type

## Git & PR preferences

- Commit messages: complete sentences; mention issue numbers when relevant (`#21`)
- PR body: what changed, why, how to verify; use `Closes #N` when fully resolving an issue
- Do not commit secrets, local `_site/`, or `vendor/`
- Do not force-push `main`
- Avoid rewriting historical posts under `_posts/v1-archive/` unless explicitly asked

## Common tasks

| Task | Where |
| --- | --- |
| New post | `_posts/YYYY-MM-DD-slug.md` |
| New post photo | Upload via factory `tools/upload-worker/`; paste `![alt](https://media.jonathanfrei.com/assets/img/…)` — never commit the file |
| New link post | `_posts/YYYY-MM-DD-slug.md` with `layout: link` and `url:` |
| Draft | `_x7k9p/` |
| Nav / header | `_includes/header.html` |
| Footer / disclaimer | `_includes/footer.html` |
| `<head>`, favicon, meta | `_includes/head.html` |
| Site-wide layout | `_layouts/default.html` |
| Post chrome (tags, comment mailto, random post) | `_layouts/post.html` tags; `_includes/post-actions.html` (Comment · Edit · Random · Blog on essays and links; random fetches `search.json`, including link posts — #221) |
| Post metadata (last_modified, reading time) | `_plugins/post_metadata.rb` + `post_metadata` in `_config.yml` (#75) |
| Search / tag / archive indexes | `_plugins/site_index.rb` + `site_index` in `_config.yml` (#195). `search.json` includes `date_label` and first-image `img` (`src` + `alt`) for stream results (#219). |
| Date timezone | `_config.yml` `timezone: America/New_York` (#180) |
| Drop caps on long posts | `_plugins/drop_cap.rb` + `.prose--drop-cap` in `main.css` (#123) |
| Tag archive title | unused `_layouts/tag.html` (tag pages not generated, #209) |
| Search UI / index | `_includes/search-ui.html`, `assets/js/search.js`, `search.json` (thin dump of `site.data.search_index`). URLs: `?q=`, `?tag=`, `?category=`, `?title=`; `?=text` aliases `?q=`. The query string is the source of truth until the user types; an inline seed fills the box on first paint (#211). `search.js` is deferred; `/search` and query URLs reserve result space so the footer does not shift (#212). Result cards reuse the `/blog` stream markup (title, long date, tag chips, excerpt, first image, Read more; link entries hide the title) (#219). Tag, category, and archive lists stay visible below results. |
| Random-post URL list | `search.json` (`url` + `kind`; essays and link posts; `posts.json` removed — #130, #221) |
| Theme toggle | Boot in `_includes/head.html`; full `assets/js/theme.js` loads on first click (footer stub) |
| Asset CDN | `_plugins/asset_cdn.rb` + `assets_cdn` in `_config.yml`. Production: jsDelivr `@SHA` with origin `/assets` `onerror` fallback (`asset_url` / `asset_origin_url`). Local: `/assets`. |
| Site config | `_config.yml` |
| Deploy / path filters | `.github/workflows/deploy.yml` |
| Embed providers | `_plugins/url_embeds.rb` |
| Static HTML page | `editorial/<slug>.html` → `/editorial/<slug>` (see `static_html.roots`) |
| Editorial Markdown | `editorial/<slug>.md` + `layout: editorial` → `/editorial/<slug>` (#144) |
| Brand colors | `_includes/main.css` tokens (#145) |

## Verification checklist

Before finishing a change that touches build, layouts, or CSS:

1. [ ] Permalinks have **no** trailing slash for HTML pages (`/about` not `/about/`). Link posts use the same `/:year/:month/:day/:title` shape as essays.
2. [ ] Every HTML page links the design system (jsDelivr in production, `/assets/css/core.css` locally); no inlined `main.css`; `code.css` only on code pages; no `../` includes
3. [ ] Tags on `/blog` still look like chips (not oversized title links) and point at `/tags?tag=`. Category chips point at `/categories?category=`. Month lists use the same stream entries as `/blog` (#201). No `/tags/:name` or `/categories/:name` HTML files.
4. [ ] Drafts stay out of `_posts/` until intentional publish
5. [ ] If workflow changed, confirm Actions majors and `paths-ignore` still make sense
6. [ ] Prefer a green deploy run after merge/push to `main`
7. [ ] Static HTML drop-ins use `editorial/<slug>.html` → `/editorial/<slug>` (no `index.html` in asset folders)
8. [ ] Text pages (e.g. `/about`) do not `preconnect` `wsrv.nl` or `media.jonathanfrei.com`. After a production deploy with Cache Everything on, HTML `cf-cache-status` is `HIT` (or the purge secrets are documented as still missing).

## What not to do

- Do not add heavy front-end frameworks, bundlers, or CMS layers unless requested
- Do not put secrets or personal tokens in the repo
- Do not commit new post photographs; they live on S3 under `assets/img/`
- Do not “fix” downloads by inventing client-side routers; fix output paths (`.html` under clean URLs)
- Do not expand scope into unrelated redesigns when asked for a small fix
- Do not remove the AI/content footer note or contact masking patterns without being asked

## Owner intent

Ship a calm, readable personal site. Agents should be careful with production deploys, preserve typography/accessibility choices, and keep the content workflow (drafts → posts → Actions) simple.
