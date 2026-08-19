---
layout: page
title: Typography
permalink: /typography
description: "Specimen page for the site’s typographic design system (Source Serif 4 / Source Code Pro) and HTML element styles."
---

This page samples the HTML elements and typographic styles used across the site. Use it when tuning tokens in `_includes/main.css` or checking dark mode and measure. Design system: **The Modern Editorial System** (#110) with Fontsource + jsDelivr fonts (#92) — two custom faces only (serif body + code UI/mono).

## Headings

# Heading 1

## Heading 2

### Heading 3

#### Heading 4

##### Heading 5

###### Heading 6

## Body copy

Body text uses **Source Serif 4** (Light) sized with a fluid modular scale. The measure is constrained so lines stay near the Practical Typography range (roughly 45–75 characters). Leading is set for comfortable long-form reading.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

A second paragraph follows with the same spacing rhythm. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.

## Inline text

This sentence has **bold**, *italic*, ***bold italic***, <u>underline</u>, ~~strikethrough~~, `inline code`, and a [text link]({{ '/about' | relative_url }}).

Superscript: E = mc<sup>2</sup>. Subscript: H<sub>2</sub>O. Abbreviation: <abbr title="HyperText Markup Language">HTML</abbr>.

## Lists

Unordered:

- First item
- Second item with a longer line so wrapping and spacing are visible
- Nested list:
  - Nested one
  - Nested two
- Final item

Ordered:

1. Step one
2. Step two
3. Step three

## Blockquote

> Typography is the craft of endowing human language with a durable visual form.  
> — adapted from Robert Bringhurst

## Horizontal rule

---

## Code

Inline: `bundle exec jekyll serve`

Fenced block (wraps by default; unwrap from the toolbar if you want a single long line):

```ruby
def hello(name)
  puts "Hello, #{name} — this line is intentionally long so wrapped text stays aligned with its line number"
end

hello("world")
```

## Table

| Token | Role | Example |
| --- | --- | --- |
| `--font-body` | Source Serif 4 | Editorial text |
| `--font-ui` | Source Code Pro | Nav / UI |
| `--font-mono` | Source Code Pro | Meta / code |
| `--type-base` | Fluid body size | `clamp(...)` |
| `--leading-body` | Body line-height | `1.65` |
| `--measure` | Reading width | `~36em` |
| `--color-accent` | Links / focus | Signature Blue `#0077A8` |
| `--brand-ink` / `--brand-paper` | Text / page ground | `#111C24` / `#FAF9F6` |

## Editorial marks

Kramdown classes on ordinary posts and pages (`{: .aside}`, `{: .pull-quote}`, `{: .caption}`, `{: .figure-wide}`).

**A sidenote** about the following paragraph. On a *wide screen* it sits in the left margin; on a narrow screen it drops below in a box. [Links look like this](xx)
{: .aside}

Typography is the craft of endowing human language with a durable visual form, and asides should not interrupt that line length when the page has room for a margin.

### Pull quote from the text

A complete sentence is still the unit of thought, even when it is pulled out of the column and boxed.
{: .pull-quote}

### Full Bleed Images

![full sized image](https://images.unsplash.com/photo-1770034568779-af19841f2aeb?q=80&w=1887&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D)
{: .figure-wide}

**Caption title** Body of the caption in the reading face. *[Credit or source](https://unsplash.com/photos/rocky-mountain-slope-in-stepantsminda-fJrVETFC1lE)*
{: .caption}

![Testing another large image but not full bleed](https://media.jonathanfrei.com/assets/img/2026-08-18-20260818101515-9080.png)
{: .figure-wide}

**large but not full bleed** Body of the caption in the reading face. *[Credit or source](https://unsplash.com/photos/rocky-mountain-slope-in-stepantsminda-fJrVETFC1lE)*
{: .caption}

## Definition list

<dl>
  <dt>Measure</dt>
  <dd>The length of a line of text; kept moderate for readability.</dd>
  <dt>Leading</dt>
  <dd>Vertical space between baselines of body text.</dd>
  <dt>Hierarchy</dt>
  <dd>Relative size and weight that signal structure without shouting.</dd>
</dl>


## Form controls (unstyled baseline)

<label for="specimen-input">Sample input</label>

<input id="specimen-input" class="search-input" type="search" placeholder="Search-style input" autocomplete="off">

## Utility samples

<p class="post-meta">`.post-meta` — UI sans / mono, muted metadata</p>

<p class="section-title">Section title</p>

<ul class="tags">
  <li><a class="tag" href="{{ '/tags' | relative_url }}?tag=tag">tag</a></li>
  <li><a class="tag" href="{{ '/tags' | relative_url }}?tag=typography">typography</a></li>
  <li><a class="tag" href="{{ '/tags' | relative_url }}?tag=specimen">specimen</a></li>
</ul>

## Embed wrapper (empty shell)

<div class="embed embed-video" aria-hidden="true">
  <div class="embed-video__inner" style="--embed-ratio: 56.25%; min-height: 8rem;"></div>
</div>

<p class="post-meta">Empty 16:9 embed shell (`.embed` / `.embed-video`) for layout checks.</p>
