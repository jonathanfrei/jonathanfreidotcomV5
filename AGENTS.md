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
| Deploy | Push to `main` runs a single full `deploy.yml` (manual `workflow_dispatch` also available). Archive media stays on jsDelivr, not the Pages artifact. |
| Archive media | Kept in `_posts/v{2,3}-archive/media/`; production serves via **jsDelivr** (not Pages artifact). See `archive_media` in `_config.yml` and issue #68. |
| Image perf | `_plugins/optimize_content_images.rb` optimizes **all own site images** (archive media + `/assets/`): dimensions, lazy/LCP hints, responsive WebP via wsrv.nl (full-res on `data-full-src`). See issue #90. |

### Directory map

```
.github/workflows/deploy.yml              # Full build + deploy on push to main
_config.yml                    # Site config, plugins, permalinks, excludes
_includes/                     # head, header, footer, main.css, code.css, editorial.css
_layouts/                      # default, page, post, tag, editorial
_plugins/url_embeds.rb         # Standalone media URLs → embeds
_posts/                        # Published posts (YYYY-MM-DD-slug.md)
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
5. **Media is never in the Pages artifact** — production uses `ARCHIVE_MEDIA_MODE=cdn` (jsDelivr). The deploy step fails if `_site/media` appears.

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
# image: /assets/img/posts/example.jpg   # OG/Twitter when sharing
# author: Jonathan Frei                  # only override site default when needed
---
```

- **`date`** = first publication. Never auto-overwrite on edit. Prefer `YYYY-MM-DD HH:MM:SS ±ZZZZ` for new posts.
- **`last_modified_at`**: set in front matter only for intentional revisions (shows “Updated …” in the byline when **> 24h** after `date`). If omitted, `_plugins/post_metadata.rb` fills it from **git** for Schema.org `dateModified`, `jekyll-seo-tag`, and sitemap `lastmod` — not for the visible byline (avoids archive-import noise). Deploy uses `fetch-depth: 0` for full history.
- **Reading time / word count:** computed at build (`reading_time`, `word_count`); “N min read” shows when ≥ 2 minutes. No front matter required.
- **`description`:** encourage on new posts for stable SEO/social; archive posts need not be backfilled.
- Default layout is `post` (from `_config.yml`). Do not set a custom layout unless needed.
- Tags should be simple lowercase slugs where possible; archives live at `/tags/:name`.

### Drafts (`_x7k9p/`)

- Unfinished work goes in **`_x7k9p/`**, never in `_posts/` until ready to publish.
- Excluded from Jekyll build, feed, sitemap; blocked in `robots.txt`.
- CI **`paths-ignore`** includes `_x7k9p/**` so draft-only commits do not rebuild the site.
- To publish: move to `_posts/` with a proper dated filename and front matter.

### Pages

- Site pages live under **`_pages/`** (issue #161), not the repo root.
- Root-level URLs: `_pages/about.md` → `/about` (front-matter `permalink` or auto via `_plugins/pages_dir.rb`).
- Nested pages: `_pages/services/service1.md` → `/services/service1`.
- `index.md` stays at the repo root (homepage).
- Use **no trailing slash** in permalinks (see below).
- Long-form specimen / design reference: `_pages/typography.md` → `/typography`.
- Tags: only multi-post tags get `/tags/:name` archives and appear on `/tags`; singleton tags render as non-link chips on posts (#140).

### Media embeds

- A **supported raw URL alone on a line** (blank lines around it) becomes an embed via `_plugins/url_embeds.rb`.
- Supported: YouTube, Vimeo, X/Twitter, Instagram, TikTok, Spotify, CodePen, Imgur, Flickr.
- Opt out per document: `url_embeds: false` in front matter.
- Inline links inside paragraphs are **not** transformed.
- Embed HTML uses `markdown="0"` and no inner indentation so Kramdown `parse_block_html` does not turn iframes into CodeRay blocks (#156).
- Imgur gallery SEO slugs (`/gallery/title-hash`) resolve to the trailing image hash (#157).
- Hotlinked third-party images are rewritten through wsrv.nl in production (`archive_media.optimize.hotlink`, #116).

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

Desired URLs: `/about`, `/blog`, `/2026/08/05/slug`, `/tags/foo` — **not** `/about/`, etc. (issue #63).

- **Do:** `permalink: /about`, post pattern `/:categories/:year/:month/:day/:title`, tag archives `/tags/:name`
- Jekyll then writes **`.html` files** (`about.html`). GitHub Pages serves those at the clean path.
- **Do not** write extensionless files (no `.html`) — GH Pages may download them as `application/octet-stream`.
- Keep internal links consistent (`/blog`, `/tags/foo`, etc.).
- After deploy, Cloudflare should 301 `/path/` → `/path` so old bookmarks still work (see PR for #63).
- Month archives (`/archive/YYYY/MM/`) **must** keep the trailing slash (directory + `index.html`).

### 2. CSS — brand system + optional sheets

- **Brand (#145):** `_includes/main.css` — Paper `#FAF9F6`, Ink `#111C24`, Signature Blue `#0077A8` (use blue sparingly). Full token table in that file (blue scale + editorial accents + UI semantics).
- **Code only:** `_includes/code.css` — inlined when content has `<pre` / `CodeRay`
- **Editorial (#144):** `_includes/editorial.css` + `layout: editorial` — Kramdown semantic components (`.lead`, `.figure`, `.stat-grid`, …). Inlined with main.css on editorial pages.
- **Delivery:** inlined `<style>` in layouts (no async CSS hop; avoids CLS)
- Tooling: `/assets/css/main.css`, `/assets/css/editorial.css`
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

Production depends on two external services for media (configured in `_config.yml` `archive_media`):

| Service | Role | Config key |
| --- | --- | --- |
| **jsDelivr** | Serves archive media binaries from this repo (`cdn.jsdelivr.net/gh/jonathanfrei/jonathanfreidotcomV5@main/...`) so they are not in the Pages artifact | `archive_media.cdn_base` |
| **wsrv.nl** | On-the-fly resize + WebP for all own-site images (archive + `/assets/`); full-res kept on `data-full-src` | `archive_media.optimize.proxy` |

- Both are widely used public CDNs/proxies. The site has no fallback if either is unavailable (images break or fall back to original `src` depending on browser).
- Do **not** point these at untrusted repos or arbitrary user content.
- Changing `cdn_base` or the proxy host is a production-facing decision; prefer a PR and a smoke check of a few archive posts + `/assets/` images.
- Local `jekyll serve` can use `ARCHIVE_MEDIA_MODE=local` so media is served from `_site/media` without the CDNs.

## Design system (short)

- Tokens/components: `_includes/main.css` (see §2); code styles in `code.css`
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
| Draft | `_x7k9p/` |
| Nav / header | `_includes/header.html` |
| Footer / disclaimer | `_includes/footer.html` |
| `<head>`, favicon, meta | `_includes/head.html` |
| Site-wide layout | `_layouts/default.html` |
| Post chrome (tags, comment mailto, random post) | `_layouts/post.html` (random uses on-click fetch of `search.json`) |
| Post metadata (last_modified, reading time) | `_plugins/post_metadata.rb` + `post_metadata` in `_config.yml` (#75) |
| Tag archive title | `_layouts/tag.html` |
| Search UI / index | `_includes/search-ui.html`, `assets/js/search.js`, `search.json` |
| Random-post URL list | `search.json` (`url` field; `posts.json` removed — #130) |
| Theme toggle | Boot in `_includes/head.html`; full `assets/js/theme.js` loads on first click (footer stub) |
| Site config | `_config.yml` |
| Deploy / path filters | `.github/workflows/deploy.yml` |
| Embed providers | `_plugins/url_embeds.rb` |
| Static HTML page | `editorial/<slug>.html` → `/editorial/<slug>` (see `static_html.roots`) |
| Editorial Markdown | `editorial/<slug>.md` + `layout: editorial` → `/editorial/<slug>` (#144) |
| Brand colors | `_includes/main.css` tokens (#145) |

## Verification checklist

Before finishing a change that touches build, layouts, or CSS:

1. [ ] Permalinks have **no** trailing slash for HTML pages (`/about` not `/about/`)
2. [ ] `main.css` inlined sitewide; `code.css` only on code pages; no `../` includes; no layout CLS from late CSS
3. [ ] Tags on `/blog` still look like chips (not oversized title links)
4. [ ] Drafts stay out of `_posts/` until intentional publish
5. [ ] If workflow changed, confirm Actions majors and `paths-ignore` still make sense
6. [ ] Prefer a green deploy run after merge/push to `main`
7. [ ] Static HTML drop-ins use `editorial/<slug>.html` → `/editorial/<slug>` (no `index.html` in asset folders)

## What not to do

- Do not add heavy front-end frameworks, bundlers, or CMS layers unless requested
- Do not put secrets or personal tokens in the repo
- Do not “fix” downloads by inventing client-side routers; fix output paths (`.html` under clean URLs)
- Do not expand scope into unrelated redesigns when asked for a small fix
- Do not remove the AI/content footer note or contact masking patterns without being asked

## Owner intent

Ship a calm, readable personal site. Agents should be careful with production deploys, preserve typography/accessibility choices, and keep the content workflow (drafts → posts → Actions) simple.
