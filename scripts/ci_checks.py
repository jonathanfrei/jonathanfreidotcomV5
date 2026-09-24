#!/usr/bin/env python3
"""Single-pass CI guard for the built Jekyll site (_site).

Replaces the ~20 full-tree `grep -R` scans in the "Report artifact size"
and "Check permalink convention" steps of .github/workflows/deploy.yml
with one walk of _site: each file is read at most once, and all
assertions are evaluated from the in-memory contents.

Failure semantics match the bash guards they replace: every condition
that failed the build before still fails (equivalent ::error:: text).
OK lines are condensed. Warnings never fail.

Scope: checks only. Does not change what is built or deployed.

Usage: python3 scripts/ci_checks.py  (run from the repo root)
"""

import json
import os
import re
import sys
from pathlib import Path

SITE = Path("_site")

errors = 0
warnings = 0


def fail(msg):
    global errors
    print(msg)
    errors += 1


def ok(msg):
    print(msg)


def warn(msg):
    global warnings
    print(msg)
    warnings += 1


def read_text(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except OSError as exc:
        fail(f"::error::Cannot read {path}: {exc}")
        return ""


def main():
    # Single walk: read each relevant file once.
    html = {}  # rel posix -> text
    css = {}
    json_files = {}
    feed_xml = None
    feed_xml_rel = "feed.xml"
    search_js = None
    search_js_rel = "assets/js/search.js"
    search_json_text = None
    sample_posts = []  # rel paths with exactly 4 parts ending .html

    if not SITE.is_dir():
        fail("::error::Missing _site directory (build did not run?)")
        sys.exit(1)

    for root, _dirs, files in os.walk(SITE):
        for name in files:
            full = Path(root) / name
            try:
                rel = full.relative_to(SITE).as_posix()
            except ValueError:
                continue
            low = name.lower()
            if low.endswith(".html"):
                text = read_text(full)
                html[rel] = text
                if len(Path(rel).parts) == 4:
                    sample_posts.append(rel)
            elif low.endswith(".css"):
                css[rel] = read_text(full)
            elif rel == search_js_rel:
                search_js = read_text(full)
            elif rel == "search.json":
                search_json_text = read_text(full)
                json_files[rel] = search_json_text
            elif low.endswith(".json"):
                # Only search.json matters, but the legacy wsrv guard
                # scanned every *.json, so keep any extra JSON for it.
                json_files[rel] = read_text(full)
            elif rel == feed_xml_rel:
                feed_xml = read_text(full)

    all_json_texts = list(json_files.values())

    def any_html(sub):
        return any(sub in t for t in html.values())

    def any_html_re(pattern):
        rx = re.compile(pattern)
        return any(rx.search(t) for t in html.values())

    def any_css(sub):
        return any(sub in t for t in css.values())

    def any_json(sub):
        return any(sub in t for t in all_json_texts)

    # ---- Report artifact size ----
    if (SITE / "media").is_dir():
        fail("::error::_site/media should not exist in CDN mode (would bloat Pages deploy)")
    for p in (
        "_posts/v1-archive/media",
        "_posts/v2-archive/media",
        "_posts/v3-archive/media",
    ):
        if (SITE / p).is_dir():
            fail(f"::error::Unexpected archive media tree in artifact: _site/{p}")
    if any_html_re(r"media\.jonathanfrei\.com/v[23]-archive/media/"):
        ok("OK: S3 archive media URLs present in HTML")
    else:
        fail("::error::Expected S3 archive media URLs (media.jonathanfrei.com) in built HTML")
    if any_html_re(r"cdn\.jsdelivr\.net/gh/.*/_posts/v[123]-archive/media/"):
        fail("::error::Legacy jsDelivr archive media URLs still present in HTML")
    if errors == 0:
        ok("OK: archive media not bundled; artifact is HTML/CSS/JS only")

    # ---- Permalink convention ----
    for f in ("index.html", "about.html", "tags.html", "search.html", "search.json"):
        if not (SITE / f).is_file():
            fail(f"::error::Missing expected page: _site/{f} (permalink regression?)")
        else:
            ok(f"OK: _site/{f}")

    typo = html.get("typography.html")
    if typo is not None:
        if "highlighter-rouge" in typo:
            ok("OK: Rouge highlighting on typography page")
        else:
            fail("::error::typography page should contain Rouge markup (highlighter-rouge)")
        if 'class="CodeRay"' in typo:
            fail("::error::CodeRay markup still present on typography page")

    if (SITE / "blog.html").is_file():
        ok("OK: _site/blog.html")
    else:
        fail("::error::Missing _site/blog.html (permalink must be /blog, not /blog/)")
    if (SITE / "blog/index.html").is_file():
        fail("::error::_site/blog/index.html should not exist (trailing-slash /blog/)")

    if (SITE / "2026/07/01/example-domain.html").is_file():
        ok("OK: _site/2026/07/01/example-domain.html")
    else:
        fail("::error::Missing sample link permalink _site/2026/07/01/example-domain.html")

    if not (SITE / "assets/css/core.css").is_file():
        fail("::error::Missing _site/assets/css/core.css")
    else:
        ok("OK: _site/assets/css/core.css")

    if any_html("cdn.jsdelivr.net/gh/jonathanfrei/jonathanfreidotcomV5"):
        fail("::error::jsDelivr gh/ URLs for this repo still present in HTML")
    else:
        ok("OK: no jsDelivr gh/ URLs for this repo in HTML")
    if any_html("cdn.jsdelivr.net/fontsource/") or any_css("cdn.jsdelivr.net/fontsource/"):
        fail("::error::Fontsource jsDelivr URLs still present in HTML/CSS")
    else:
        ok("OK: no Fontsource jsDelivr URLs in HTML/CSS")
    if any_html("assetFallback"):
        fail("::error::assetFallback leftover in HTML")
    else:
        ok("OK: no assetFallback helper")

    for f in (
        "source-serif-4-5.2.5-latin-wght-normal.woff2",
        "source-serif-4-5.2.5-latin-wght-italic.woff2",
        "source-code-pro-5.2.5-latin-wght-normal.woff2",
        "source-code-pro-5.2.5-latin-wght-italic.woff2",
        "source-sans-3-5.3.0-latin-wght-normal.woff2",
        "source-sans-3-5.3.0-latin-wght-italic.woff2",
    ):
        if not (SITE / "assets/fonts" / f).is_file():
            fail(f"::error::Missing _site/assets/fonts/{f}")
    ok("OK: self-hosted latin WOFF2 files in _site/assets/fonts")

    for sample in (
        "blog.html",
        "index.html",
        "about.html",
        "2009/08/29/getting-started.html",
        "blog/page/2/index.html",
    ):
        text = html.get(sample)
        if text is None:
            continue
        if "/assets/css/core.css?v=" in text:
            ok(f"OK: _site/{sample} links fingerprinted /assets/css/core.css")
        else:
            fail(f"::error::_site/{sample} should link /assets/css/core.css?v=")
        if "--brand-paper:" in text:
            fail(f"::error::_site/{sample} should not inline main.css")

    editorial = html.get("editorial/design-system.html")
    if editorial is not None:
        if "/assets/css/editorial.css?v=" in editorial:
            ok("OK: editorial page links fingerprinted editorial.css")
        else:
            fail("::error::_site/editorial/design-system.html should link /assets/css/editorial.css?v=")

    if (SITE / "blog/page/50").is_dir():
        fail("::error::blog pagination should use 50 per page (no /blog/page/50)")
    else:
        ok("OK: no /blog/page/50 (50 per page)")
    if (SITE / "tags").is_dir():
        fail("::error::_site/tags/ should not exist; tag archives are search URLs (#209)")
    else:
        ok("OK: no individual tag archive pages")

    tags = html.get("tags.html")
    if tags is not None:
        if "search-ui" in tags and "?tag=" in tags:
            ok("OK: /tags uses search UI and ?tag= chip links")
        else:
            fail("::error::_site/tags.html should include search UI and ?tag= chip links")

    if search_js is not None:
        if (
            'params.get("tag")' in search_js
            and 'params.get("q")' in search_js
            and 'params.get("category")' in search_js
        ):
            ok("OK: search.js reads q/tag/category URL params")
        else:
            fail("::error::search.js should read ?q=, ?tag=, and ?category= URL params")
        if "search.json?v=" in search_js or "searchIndexRev" in search_js:
            ok("OK: search.js cache-busts search.json")
        else:
            fail("::error::search.js should fetch /search.json?v= so edge cache cannot keep a stale index")
        if "userTyped" in search_js:
            ok("OK: search.js keeps URL params until the user types")
        else:
            fail("::error::search.js should treat the query string as source of truth until input")

    search_page = html.get("search.html")
    if search_page is not None:
        if "search-landing" in search_page and "min-height: 55vh" in search_page:
            ok("OK: /search reserves result space to limit CLS")
        else:
            fail("::error::_site/search.html should reserve min-height for search results")
        if "#tags-list" in search_page and "display: none" in search_page:
            fail("::error::search CSS should not hide the tag or archive lists")
        else:
            ok("OK: search does not hide tag/archive lists")

    if tags is not None:
        if "URLSearchParams" in tags and "search.js" in tags and "defer" in tags:
            ok("OK: /tags inlines URL seed and defers search.js")
        else:
            fail("::error::_site/tags.html should inline a URL seed and defer search.js")

    blog_page = html.get("blog.html")
    if blog_page is not None:
        if "?tag=" in blog_page:
            ok("OK: _site/blog.html tag chips use search URLs")
        else:
            fail("::error::_site/blog.html tag chips should link to /tags?tag=")
        if 'class="stream-post__body"' in blog_page:
            fail("::error::_site/blog.html should excerpt posts, not render full bodies")
        if 'class="read-more"' not in blog_page:
            fail("::error::_site/blog.html should include Read more links on post entries")
        if "feed-filter" in blog_page:
            fail("::error::_site/blog.html should not include the All/Posts/Links filter")

    for stale in ("posts.xml", "links.xml", "posts/index.html", "links/index.html"):
        if (SITE / stale).is_file():
            fail(f"::error::Stale feed or index should be gone: _site/{stale}")

    if not (SITE / "feed.xml").is_file():
        fail("::error::Missing feed: _site/feed.xml")
    else:
        ok("OK: _site/feed.xml")
        feed_text = feed_xml if feed_xml is not None else read_text(SITE / "feed.xml")
        if "link-card" in feed_text:
            fail("::error::feed.xml must not include URL card markup")
        if ">Permalink</a>" in feed_text:
            fail("::error::RSS should use a permalink glyph, not the word Permalink")

    if any_html("https://wsrv.nl/?url=") or any_json("https://wsrv.nl/?url="):
        fail("::error::wsrv.nl transform URLs still present in HTML/JSON")
    else:
        ok("OK: no wsrv.nl transform URLs in HTML/JSON")

    if search_json_text is not None:
        if "jonathanfrei.com/img?url=" in search_json_text and "&s=" in search_json_text:
            ok("OK: search.json uses signed /img URLs")
        else:
            fail("::error::search.json should contain signed jonathanfrei.com/img?url= URLs")
        if "https://wsrv.nl/" in search_json_text:
            fail("::error::search.json still points at wsrv.nl")
    else:
        fail("::error::search.json should contain signed jonathanfrei.com/img?url= URLs")

    about = html.get("about.html")
    if about is not None:
        if "cdn.jsdelivr.net" in about:
            fail("::error::_site/about.html should not mention cdn.jsdelivr.net")
        else:
            ok("OK: /about does not use jsDelivr")
        if (
            "source-serif-4-5.2.5-latin-wght-normal.woff2" in about
            and "source-code-pro-5.2.5-latin-wght-normal.woff2" in about
        ):
            ok("OK: /about preloads the two first-paint faces")
        else:
            fail("::error::_site/about.html should preload Source Serif 4 and Source Code Pro normal")
        if "source-sans-3" in about:
            fail("::error::_site/about.html should not preload unused Source Sans 3")
        else:
            ok("OK: /about does not preload Source Sans 3")
        if "wsrv.nl" in about:
            fail("::error::_site/about.html should not mention wsrv.nl")
        else:
            ok("OK: /about does not mention wsrv.nl")
        if "/img?url=" in about or "/img/?url=" in about:
            fail("::error::_site/about.html should not load /img transforms")
        else:
            ok("OK: /about does not use /img")
        if 'href="https://media.jonathanfrei.com"' in about:
            fail("::error::_site/about.html should not hint media.jonathanfrei.com")
        else:
            ok("OK: /about does not hint media.jonathanfrei.com")
        if 'rel="dns-prefetch"' in about:
            fail("::error::_site/about.html should not emit redundant dns-prefetch")
        else:
            ok("OK: /about has no dns-prefetch")
        if 'type="speculationrules"' in about:
            ok("OK: /about includes speculation rules")
        else:
            fail("::error::_site/about.html should include speculation rules")

    posts_page = html.get("posts.html")
    if posts_page is not None:
        if "Redirecting" in posts_page and "/blog" in posts_page:
            ok("OK: _site/posts.html redirects to /blog")
        else:
            fail("::error::_site/posts.html should redirect to /blog")
    links_page = html.get("links.html")
    if links_page is not None:
        if "Redirecting" in links_page and "/blog" in links_page:
            ok("OK: _site/links.html redirects to /blog")
        else:
            fail("::error::_site/links.html should redirect to /blog")

    if (SITE / "categories").is_dir():
        fail("::error::_site/categories/ should not exist; category archives are search URLs")
    else:
        ok("OK: no individual category archive pages")
    cats = html.get("categories.html")
    if cats is not None:
        if (
            "search-ui" in cats
            and "?category=" in cats
            and "searchIndexRev" in cats
            and 'params.get("category")' in cats
        ):
            ok("OK: /categories uses search UI, ?category= chips, and a busted index URL")
        else:
            fail("::error::_site/categories.html should include search UI, ?category= chips, and searchIndexRev")

    if search_json_text is not None:
        try:
            data = json.loads(search_json_text)
            first_ok = (
                isinstance(data, list) and bool(data) and isinstance(data[0], dict) and "categories" in data[0]
            )
        except (ValueError, OSError):
            first_ok = False
        if first_ok:
            ok("OK: search.json includes categories")
        else:
            fail("::error::search.json entries should include a categories field")

    log_path = SITE / "build-errors.log"
    if log_path.is_file():
        print("---- build-errors.log ----")
        log_text = read_text(log_path)
        print(log_text, end="" if log_text.endswith("\n") else "\n")

    if errors:
        sys.exit(1)

    if not sample_posts:
        warn("::warning::No sample post HTML found under _site/YYYY/MM/DD/ (may be empty site)")
    else:
        ok(f"OK: sample post HTML _site/{sorted(sample_posts)[0]}")


if __name__ == "__main__":
    main()
