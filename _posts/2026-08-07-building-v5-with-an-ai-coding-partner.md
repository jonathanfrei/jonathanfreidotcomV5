---
title: "Building V5 with an AI coding partner"
date: "2026-08-05"
tags: [meta, site, jekyll, ai]
excerpt: "How I planned, built, and fixed jonathanfrei.com V5 with Grok—planning questions, a fresh GitHub repo, embeds, typography, a broken search box, and the small issues that pile up after launch."
---

I decided to rebuild the personal site again. Version 5. The previous stack had done its job; I wanted a clean Jekyll site on GitHub Pages, Markdown-first writing, a custom domain still sitting behind Cloudflare, and enough structure that I could keep shipping posts without wrestling the tooling every time.

I did most of the work in conversation with [Grok](https://x.ai/grok). Not as a one-shot “make me a website” prompt. More like a multi-day build log: plan first, execute against a named repo, then chase open issues and a few features that only made sense once the skeleton was live.

## Planning before a single file

The first message was deliberate: *don’t build anything yet*. I asked for a plan and a set of questions that would lock configuration choices. Grok returned a structured questionnaire covering audience, repo naming, content types, language, deployment path, design constraints, plugins, domain, drafts, SEO, and who would contribute.

I answered in a dense block:

- Personal home page plus short posts and longer articles; portfolio pages maybe later.
- English only.
- Modern GitHub Actions deployment, not the classic `github-pages` gem path.
- I can follow CLI directions but I’m not deep in the toolchain day to day.
- Development mostly through Grok and the GitHub UI, so the workflow had to build and deploy on push.
- Minimalist look with room for fully custom article pages.
- Start custom with little code, grow later.
- System dark mode, accessibility by default, mobile-first.
- No comments. Newsletter and analytics nice-to-have only.
- No non-standard plugins.
- Domain: jonathanfrei.com. Keep Cloudflare.
- Plain Markdown, with a path for drafting, preview, and publishing.
- Solo contributor.
- Drafts and scheduling; private preview of drafts.
- Basic SEO is enough.
- No branding package yet.

A later pass pinned the rest: repo name `jonathanfreidotcomV5`, skip the contact form and use a masked email, keep drafts in a public repo but under an obfuscated folder name blocked from robots and feeds, and use a tiny utility CSS set instead of a heavy framework.

That sequence mattered. The AI didn’t invent requirements in the dark. The plan was a contract.

## Standing up the repo

When I said to execute, Grok created the repository and filled it: Gemfile pinned to Jekyll 4.x plus a short plugin list (`jekyll-feed`, `jekyll-seo-tag`, `jekyll-sitemap`, `jekyll-archives`), a GitHub Actions workflow for build and Pages deploy, layouts, the utility CSS, sample content, `search.json`, and the draft folder under a nonsense name so casual path guessing wouldn’t surface half-finished work.

The Actions path was intentional. Classic GitHub Pages still limits which plugins run. Building in CI with the full Jekyll stack avoids that trap and matches how I actually want to publish.

I also got a concrete checklist for pointing the custom domain: GitHub Pages custom domain settings, Cloudflare DNS (A/CNAME), proxy behavior, and the usual SSL wait. The domain still pointed at an older repo at that point; the cutover steps were written so I could do them when ready rather than mid-build.

## Open issues as the real work queue

After the first deploy, the repo accumulated issues the way any live site does. I asked Grok to review open issues, decide which ones it could fix, and open pull requests.

That produced a useful split. Some items were pure code: tag page headings, favicon paths that ignored `baseurl`, workflow action versions throwing Node 20 deprecation warnings, path filters so commits under the drafts folder wouldn’t kick a full site rebuild. Others were Lighthouse noise about cache lifetimes and expires headers—things GitHub Pages doesn’t fully control, especially before Cloudflare sits in front. Those got honest “configure this at the CDN” notes instead of fake fixes in the repo.

Batching small fixes into one PR kept review sane. I still had to merge and watch Actions, but I wasn’t drowning in one-line branches.

## Features that arrived after the skeleton

Three pieces defined the next stretch of work: media embeds, a typography redesign, and search that actually worked.

### Paste a URL, get an embed

I wanted to drop a raw YouTube, X, Instagram, Vimeo, TikTok, Spotify, or CodePen URL on its own line in Markdown and have the build turn it into a responsive embed. No shortcodes if I could help it.

The solution landed as a small Jekyll plugin that rewrites standalone URLs at build time, plus CSS wrappers and optional platform scripts loaded only when those embeds appear. YouTube goes through the nocookie host. Social embeds use the official blockquote pattern. Opt-out is a single front-matter flag. A sample post demonstrated the pattern so I wouldn’t have to reverse-engineer it later.

It’s the kind of feature that sounds trivial until you’ve hand-pasted iframe markup for the third time in a week.

### Typography as a system, not a skin

The first CSS was a utility set: variables, spacing, system fonts, light and dark via `prefers-color-scheme`. Functional, thin, easy to extend. Then I opened an issue aimed at [Practical Typography](https://practicaltypography.com/summary-of-key-rules.html)—measure, leading, hierarchy, rhythm—without copying that site’s layout or assets.

The follow-up PR introduced a real type system: fluid base size with `clamp()`, modular scale, a reading measure around the classic 45–75 character band, serif body stack for long form, system sans for chrome, vertical rhythm derived from base line height, and a quieter header so navigation doesn’t compete with the article. Post and page layouts got clearer headers and metadata treatment. The home page picked up a proper section label for recent posts.

I can still change accent color or scale ratio in one place. That was the point of the token work.

### Search: two bugs, one page

Search looked simple—client-side filter over a generated JSON index—and failed twice in public.

First, Kramdown ate the search `<input>`. Smart quotes and Markdown processing turned the form into literal escaped text on the page. There was no input element for the script to bind. Moving the UI into a Liquid include fixed that.

Second, the JavaScript itself had a syntax error. An `escapeHtml` helper had been written with HTML entities that got stripped when the file was saved through the API, leaving broken string literals. The browser refused to parse the file. Rewriting the helper to use the DOM for escaping removed the entity problem and made the script valid again.

Both failures were easy to miss if you only looked at the repo source and not the rendered HTML. The lesson was boring and useful: verify the live artifact, not just the commit.

## Process notes worth keeping

A few habits from this collaboration stuck.

Answer configuration questions in one pass when you can. Partial answers produce partial scaffolds and rework.

Prefer Actions over restricted platform builds when you care about plugins and scheduling. The six-hour cron rebuild for future-dated posts is a small example of why.

Treat the issue tracker as the backlog even when an AI is writing the patches. Titles like “favicon path ignores baseurl” are more durable than chat scrollback.

Expect friction at the boundary between Markdown, Liquid, and static assets. Most of the painful bugs sat on that boundary—escaped HTML, wrong `baseurl`, scripts that never ran.

Don’t pretend CDN concerns live in the Jekyll repo. Cache headers for github.io are a Cloudflare (or similar) job once the domain is fronted. Document that and move on.

## Where it sits now

V5 is a small Jekyll site with a custom type system, URL embeds, client search, tag archives, an obfuscated drafts folder, and a deploy pipeline that doesn’t depend on the classic Pages gem whitelist. Earlier versions of the site still exist as historical layers. This one is meant to stay thin enough that writing is the main activity again.

Working with Grok on it was less “generate a theme” and more “pair on a constrained engineering project.” The plan held. The issues list told us what was still wrong. The features that shipped were the ones I actually asked for, in the order the site needed them.
