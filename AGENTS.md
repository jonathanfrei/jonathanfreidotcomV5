# AGENTS.md

Guidance for AI coding agents working on **jonathanfrei.com (V5)**.

This is a personal site and blog: **Jekyll 4.x → GitHub Actions → GitHub Pages → Cloudflare**. Prefer small, focused changes. Match existing style. Do not invent a framework or redesign the design system unless asked.

## Project overview

| Item | Detail |
| --- | --- |
| Site | [jonathanfrei.com](https://jonathanfrei.com) |
| Repo | Static Jekyll site (no app server, no database) |
| Content | Markdown posts/pages; HTML layouts/includes |
| Design | Custom CSS design system in `_includes/main.css` (inlined at build) |
| Deploy | Push to `main` runs `.github/workflows/deploy.yml` |

### Directory map

```
.github/workflows/deploy.yml   # Build + deploy + 6-hour scheduled rebuild
_config.yml                    # Site config, plugins, permalinks, excludes
_includes/                     # head, header, footer, search UI, **main.css**
_layouts/                      # default, page, post, tag
_plugins/url_embeds.rb         # Standalone media URLs → embeds
_posts/                        # Published posts (YYYY-MM-DD-slug.md)
_posts/v1-archive/             # Historical imported posts (treat carefully)
_x7k9p/                        # Obfuscated drafts (excluded from build & CI paths)
assets/                        # Images, JS; CSS served via assets/css/main.html
editorial/                     # Handcrafted HTML pages (folder + index.html each)
index.md, about.md, blog.md, tags.md, search.md, typography.md
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
2. Push to `main` deploys (except pure draft/doc paths — see CI).
3. Future-dated posts publish on the **every-6-hours** schedule (or next push).
4. After deploy, confirm the Actions run is green when you changed build-related files.

## Content rules

### Posts

- Path: `_posts/YYYY-MM-DD-slug.md`
- Front matter typically:

```yaml
---
title: "Post title"
date: 2026-08-04 16:00:00 -0400
tags: [tag-one, tag-two]
---
```

- Default layout is `post` (from `_config.yml`). Do not set a custom layout unless needed.
- Tags should be simple lowercase slugs where possible; archives live at `/tags/:name/`.

### Drafts (`_x7k9p/`)

- Unfinished work goes in **`_x7k9p/`**, never in `_posts/` until ready to publish.
- Excluded from Jekyll build, feed, sitemap; blocked in `robots.txt`.
- CI **`paths-ignore`** includes `_x7k9p/**` so draft-only commits do not rebuild the site.
- To publish: move to `_posts/` with a proper dated filename and front matter.

### Pages

- Root Markdown with front matter, e.g. `about.md`, `blog.md`.
- Use **trailing-slash permalinks** (see below).
- Long-form specimen / design reference: `typography.md` → `/typography/`.

### Media embeds

- A **supported raw URL alone on a line** (blank lines around it) becomes an embed via `_plugins/url_embeds.rb`.
- Supported: YouTube, Vimeo, X/Twitter, Instagram, TikTok, Spotify, CodePen.
- Opt out per document: `url_embeds: false` in front matter.
- Inline links inside paragraphs are **not** transformed.

### Editorial HTML pages (`editorial/`)

Handcrafted full HTML/CSS/JS pages (not Jekyll layouts). Each page is a **folder with `index.html`** so GitHub Pages serves it at the directory URL.

```
editorial/
  spacex-earnings/
    index.html          # → /editorial/spacex-earnings/
    # optional: css/, js/, images/ with relative paths
```

- **Do:** `editorial/<slug>/index.html` (and sibling assets with relative links)
- **Do not:** put a bare `editorial/<slug>.html` if you want `/editorial/<slug>/`
- **No YAML front matter** on these files so Jekyll copies them as static files (not Liquid-processed pages)
- Relative asset paths resolve correctly under `/editorial/<slug>/`
- Does not use site chrome (`_layouts`, header/footer) unless you hardcode it into the HTML

## Critical constraints (do not regress)

### 1. Permalinks must be directory-style (trailing slash)

GitHub Pages serves **extensionless files** as downloads (`application/octet-stream`).

- **Do:** `permalink: /about/`, post pattern `/:categories/:year/:month/:day/:title/`, tag archives `/tags/:name/`
- **Do not:** drop trailing slashes on HTML routes (issue #32 conflicted with GH Pages; directory style wins)
- Keep internal links consistent (`/blog/`, `/tags/foo/`, etc.)

### 2. CSS lives in `_includes/main.css`

- Source of truth: **`_includes/main.css`**
- Inlined in `_layouts/default.html` via `{% include main.css %}` (avoids render-blocking CSS)
- Also exposed at `/assets/css/main.css` through `assets/css/main.html`
- **Never** use `{% include_relative ../... %}` — Jekyll rejects `../` path traversal and breaks the build
- When changing styles, edit `_includes/main.css` only (single source)

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

## Design system (short)

- Tokens and components: `_includes/main.css`
- Principles: readable measure, modular type scale, system fonts, restrained accent, light default + `prefers-color-scheme` dark
- Prefer existing utilities/classes (`.prose`, `.post-meta`, `.tag`, `.post-list`, layout helpers) over one-off CSS
- Accessibility: keep skip link, focus styles, semantic HTML, sensible contrast
- Specimen page: `/typography/` (`typography.md`) — use when adding HTML patterns or checking type

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
| Post chrome (tags, comment mailto) | `_layouts/post.html` |
| Tag archive title | `_layouts/tag.html` |
| Search UI / index | `_includes/search-ui.html`, `assets/js/search.js`, `search.json` |
| Site config | `_config.yml` |
| Deploy / schedule / path filters | `.github/workflows/deploy.yml` |
| Embed providers | `_plugins/url_embeds.rb` |
| Editorial HTML page | `editorial/<slug>/index.html` → `/editorial/<slug>/` |

## Verification checklist

Before finishing a change that touches build, layouts, or CSS:

1. [ ] Permalinks still use trailing slashes for HTML pages
2. [ ] CSS still inlines from `_includes/main.css` without `../` includes
3. [ ] Tags on `/blog/` still look like chips (not oversized title links)
4. [ ] Drafts stay out of `_posts/` until intentional publish
5. [ ] If workflow changed, confirm Actions majors and `paths-ignore` still make sense
6. [ ] Prefer a green deploy run after merge/push to `main`
7. [ ] Editorial pages use `editorial/<slug>/index.html` (directory URL, static copy)

## What not to do

- Do not add heavy front-end frameworks, bundlers, or CMS layers unless requested
- Do not put secrets or personal tokens in the repo
- Do not “fix” downloads by inventing client-side routers; fix output paths (`index.html` under directories)
- Do not expand scope into unrelated redesigns when asked for a small fix
- Do not remove the AI/content footer note or contact masking patterns without being asked

## Owner intent

Ship a calm, readable personal site. Agents should be careful with production deploys, preserve typography/accessibility choices, and keep the content workflow (drafts → posts → Actions) simple.
