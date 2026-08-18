---
title: "Styling Markdown with Kramdown Attributes"
date: 2026-08-17T21:52:00-04:00
tags: ["jekyll", "markdown", "kramdown", "design system"]
categories: technology
description: "A practical guide to using Kramdown attributes in Jekyll, and turning a small set of semantic Markdown classes into an extensible design system."
status: published
type: guide
created: 2026-08-17T21:52:00-04:00
updated: 2026-08-17T22:10:00-04:00
worldview: n/a
---

Markdown is deliberately limited at visual design. A paragraph is a paragraph, a blockquote is a blockquote, and the author generally doesn't get to decide that one particular paragraph should become a pull quote, warning box, or oversized introduction. For most writing that is a feature. It keeps content separate from presentation.

Kramdown gives Jekyll sites a useful middle ground. Its [Inline Attribute Lists](https://kramdown.gettalong.org/syntax.html#inline-attribute-lists), usually called IALs, let you add classes, IDs, and ordinary HTML attributes to Markdown elements without replacing the Markdown with raw HTML. That makes it possible to build richer editorial layouts while keeping the source readable.

For example:

```markdown
This paragraph contains a short editorial aside.
{: .aside}
```

Kramdown renders that roughly as:

```html
<p class="aside">This paragraph contains a short editorial aside.</p>
```

The same pattern works on headings, blockquotes, lists, images, code blocks, and many other block elements. Inline elements can take attributes too:

```markdown
This is *emphasized text*{:.highlight} inside a paragraph.
```

Classes use the familiar `.class-name` shorthand and IDs use `#id-name`:

```markdown
## The Second Act
{: #second-act .section-heading}
```

You can also use normal HTML-style attributes when there is a reason to:

```markdown
[External documentation](https://example.com){: rel="nofollow" target="_blank"}
```

The Kramdown syntax documentation has the full grammar, but for most site work the useful mental model is simple: put a block attribute list immediately after the block it belongs to, and put an inline attribute list immediately after the inline element. Kramdown also supports reusable [Attribute List Definitions](https://kramdown.gettalong.org/syntax.html#attribute-list-definitions), although I tend to prefer explicit semantic classes in content because they are easier to find and understand later.

## Treat classes as content roles

The tempting way to use this feature is to put presentation directly into Markdown:

```markdown
A big sentence.
{: .large-blue-text}
```

That works, but it creates the same problem inline styles create in HTML. The content now knows too much about its current appearance. A redesign either leaves old class names lying around or requires editing hundreds of posts.

A better approach is to name what the element *is*:

```markdown
A big sentence.
{: .pull-quote}
```

Then the stylesheet decides what a pull quote looks like:

```css
.pull-quote {
  font-size: var(--type-scale-4);
  line-height: 1.25;
  max-width: 28ch;
  margin-block: var(--space-8);
}
```

That small distinction is the foundation of a reusable content design system. Markdown becomes the author-facing API. The classes describe editorial roles such as `.lede`, `.pull-quote`, `.aside`, `.note`, `.data-block`, `.figure-wide`, or `.section-break`. CSS owns typography, spacing, color, borders, responsive behavior, and themes.

Once those roles are stable, the design can change without rewriting the article source. A `.note` can be a pale bordered box in one theme and a compact icon treatment in another. The Markdown remains the same because the meaning of the content has not changed.
{: .aside}

## Start with a small component vocabulary

It is easy to create too many classes. I would start with a small set that covers recurring editorial needs and add a new one only when several pieces of content genuinely need the same treatment.

For a long-form Jekyll site, that might look something like this:

```text
.lede             opening paragraph
.pull-quote       emphasized quotation or sentence
.aside            secondary editorial thought
.note             explanatory or contextual callout
.data-block       compact presentation of numbers or facts
.figure           standard editorial image treatment
.figure-wide      image that breaks beyond the text column
.caption          image or figure caption
.section-break    visual pause between major movements
.small            intentionally de-emphasized copy
```

The exact names are less important than keeping them semantic, documented, and few enough that an author can remember them.

I would avoid turning every CSS utility into a Kramdown attribute. Classes such as `.mt-32`, `.text-blue`, or `.grid-span-8` are useful inside templates, but they make prose depend on the current implementation. Editorial Markdown should normally use components; layouts and CSS can use utilities underneath them.
{: .aside}

## Build the CSS in layers

The attribute vocabulary becomes more reusable when the CSS behind it has its own structure. A simple design-system stack might have four layers:

```text
Tokens       colors, spacing, type scale, widths, radii
Base         headings, paragraphs, links, lists, figures
Components   .lede, .pull-quote, .note, .aside, .data-block
Utilities    layout helpers used mainly by templates/includes
```

Then a component is assembled from common tokens instead of inventing new values each time:

```css
:root {
  --content-width: 44rem;
  --wide-width: 68rem;
  --space-4: 1rem;
  --space-8: 2rem;
  --radius-2: 0.5rem;
}

.note {
  padding: var(--space-4);
  border-radius: var(--radius-2);
  background: var(--surface-secondary);
}
```

This becomes especially useful for light and dark themes. The Markdown should not need `.note-dark` and `.note-light`. The `.note` component should consume theme-aware tokens, while the theme changes those tokens.
{: .aside}

## Let Jekyll handle the larger components

Kramdown attributes are best for styling an existing Markdown element. They are less attractive once a component needs complex markup, repeated child elements, data from front matter, Liquid logic, or accessibility behavior that authors should not have to remember.

At that point, use a Jekyll include or layout instead. A useful dividing line is:

```text
One existing Markdown element + styling       -> Kramdown attribute
Several coordinated elements or logic        -> Jekyll include
Page-wide structure                           -> Jekyll layout
```

A pull quote is a good attribute component. A comparison card with a heading, icon, source link, and three data points is probably an include.

This keeps the authoring language small. Attributes extend Markdown; they do not need to become a substitute templating system.

## Jekyll considerations

Jekyll [uses Kramdown as its default Markdown renderer](https://jekyllrb.com/docs/configuration/markdown/), and its current default Kramdown input processor is GitHub Flavored Markdown. A typical `_config.yml` therefore needs no special setting just to use Kramdown:

```yaml
markdown: kramdown
```

You can explicitly select the input parser if needed:

```yaml
kramdown:
  input: GFM
```

The important part is to test the syntax against the site configuration rather than assuming that every Markdown environment behaves the same way. Kramdown attributes are an extension, not part of basic Markdown. A file that renders correctly in Jekyll may display the literal `{: .note}` text in another renderer.

That affects previews too. GitHub's own Markdown view, an editor preview, a CMS preview, and the final Jekyll build are not necessarily using the same parser. The generated site is the authoritative rendering. For a design system that depends on attributes, it is worth keeping a small fixture page containing every supported component and checking it during site changes.

Jekyll also processes pages through more than one layer: front matter and Liquid are handled as part of the site build, Markdown is converted to HTML, and the resulting content is inserted into layouts. [Jekyll's documentation describes that rendering pipeline](https://jekyllrb.com/tutorials/convert-site-to-jekyll/). That means attributes should generally describe content, while Liquid and layouts own application structure.

Raw HTML is still available when needed, but mixing Markdown inside HTML blocks has its own Kramdown parsing rules. If a design regularly needs containers with complicated nested Markdown, that is another signal to move the structure into an include rather than making authors manage parsing details in each article.
{: .aside}

## Make the design system self-documenting

The easiest design systems to maintain have one canonical page that shows every supported content component. In a Jekyll site I would keep something like `editorial-template.md` or `style-guide.md` containing the source example, the attribute syntax, and the rendered result for each component.

Alongside it, keep a short component contract in the repository documentation:

```text
.pull-quote
Purpose: emphasize a sentence worth visually separating from body copy
Allowed on: paragraph or blockquote
Do not use: simply to make ordinary prose larger

.note
Purpose: supplemental context that can be skipped without breaking the argument
Allowed on: paragraph or blockquote
Do not use: for primary argument text
```

Those rules are more valuable than a long catalog of CSS properties. They keep authors from creating slightly different components for the same job and give an AI writing or publishing agent a stable vocabulary it can apply correctly.

The result is a fairly clean separation of concerns: Markdown carries the article and a small amount of semantic intent, Kramdown turns that intent into classes and attributes, Jekyll handles reusable structure, and CSS decides how the system looks. You still get the simplicity of Markdown, but without limiting every long-form article to the same uninterrupted column of paragraphs and headings.