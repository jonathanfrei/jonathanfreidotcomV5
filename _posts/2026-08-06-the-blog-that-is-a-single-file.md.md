---
title: "The Blog That Is a Single File"
date: "2026-08-06"
tags: ["web-design", "indieweb", "markdown", "architecture"]
excerpt: "A look at claude-blog.md and the quiet resurgence of hyper-minimal, zero-build text files as web architecture."
---

Someone built a site called [claude-blog.md](https://claude-blog.md/) that is, quite literally, just a raw Markdown file rendered directly in the browser. No static site generator, no serverless hydration layer, no build steps, and no dynamic client-side router running three separate JS workers. Just text and a clean parser.

It brings back memories of the early web's best impulse: fetching a raw document across a wire, reading it, and moving on with your day.

---

## The Build Step That Wasn't

For the last decade, personal blogging software went down a strange path. What used to be a `index.html` file on a university server somehow turned into a full-blown software project. You don't just write a post anymore; you configure Next.js, manage Node dependencies, fix broken Tailwind builds, and tweak GraphQL queries just to publish three paragraphs about a movie you saw on Tuesday.

Projects like `claude-blog.md` strip that entire apparatus away. The source document *is* the page.