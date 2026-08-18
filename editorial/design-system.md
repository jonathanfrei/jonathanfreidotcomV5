---
permalink: /editorial/design-system
layout: editorial
title: Editorial Design System
description: Navigable library of editorial components with live examples and copyable shells.
---

<div class="editorial-header" markdown="1">

<span class="eyebrow">Editorial Design System</span>

# Component library

A navigable reference for the semantic components used on long-form editorial pages. Each entry has a short description, a live example, and a copyable shell you can paste into a new article.

</div>

<div class="metadata" markdown="1">

**Updated:** August 10, 2026  
**Category:** Design System  
**Use:** Copy shells into `editorial/*.md` pages with `layout: editorial`

</div>

^

**Updated:** August 18, 2026

**Category:** Kramdown block extension parsing test

**Use:** Copy shells into `editorial/*.md` pages with `layout: editorial`

^
{: .metadata} 


Trying to add a meta data element alone as the block might have hidden what I was doing. {: .metadata} 

^

Testing one line block

^ 
{: .metadata} 

Another eyebrow
{: .eyebrow}

# Title 2
{: .editorial-header}

<div class="lead" markdown="1">

This page is the working library for composition: jump to a component, preview it, copy the shell, and fill in real content. Multi-block components use HTML wrappers with `markdown="1"` so headings, lists, and paragraphs stay inside the component. Visual treatment lives in CSS (`_includes/editorial.css`).

</div>

<div class="authoring-note" markdown="1">

**How to use these shells**

1. Create `editorial/your-slug.md` with `layout: editorial` and `permalink: /editorial/your-slug`.
2. Paste shells from this page. Keep `markdown="1"` on multi-block wrappers.
3. Prefer semantic class names (what the content *is*) over presentation names.
4. Kramdown `{: .class}` alone only styles the **next single block** — use a wrapping `<div class="…" markdown="1">` when a component holds more than one block.

</div>

<div class="component-index" markdown="1">

## On this page

### Tier 1 — Core

- [Editorial header](#editorial-header)
- [Metadata](#metadata)
- [Lead](#lead)
- [Section header](#section-header)
- [Subsection header](#subsection-header)
- [Figure](#figure)
- [Quote](#quote)
- [Stat grid](#stat-grid)
- [Data table](#data-table)
- [Timeline](#timeline)
- [Info callout](#info-callout)

### Tier 2 — Composition

- [Content container](#content-container)
- [Content grid](#content-grid)
- [Two column](#two-column)
- [Comparison](#comparison)
- [Editorial list](#editorial-list)
- [Full bleed](#full-bleed)

### Tier 3 — Specialized

- [Fact box](#fact-box)
- [Takeaways](#takeaways)
- [Definition](#definition)
- [Glossary](#glossary)
- [Pros / cons](#pros-cons)
- [Recommendation](#recommendation)
- [Scorecard](#scorecard)
- [Forecast](#forecast)
- [Event card](#event-card)
- [Entity card](#entity-card)
- [Source list](#source-list)
- [Source note](#source-note)
- [Gallery](#gallery)
- [Figure pair](#figure-pair)
- [Aside](#aside)
- [Related reading](#related-reading)
- [Editorial break](#editorial-break)

</div>

<div id="tier-1" class="section-header" markdown="1">

## Tier 1 — Core editorial components

Identity, evidence, and the primary reading path of an article.

</div>

<!-- ========== Editorial header ========== -->
<div id="editorial-header" class="component-doc" markdown="1">

### Editorial header

<span class="component-class">`.editorial-header` · `.eyebrow` · optional `.dek`</span>

<p class="component-desc">Article identity block: eyebrow label, title, and optional deck. Place once at the top of the page.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="editorial-header" markdown="1">

<span class="eyebrow">Example series</span>

# Example article title

A short deck that orients the reader before the lead.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="editorial-header" markdown="1">

<span class="eyebrow">Series or section label</span>

# Article title

Optional deck (plain paragraph or class="dek").

</div>
```

</div>

<!-- ========== Metadata ========== -->
<div id="metadata" class="component-doc" markdown="1">

### Metadata

<span class="component-class">`.metadata`</span>

<p class="component-desc">Compact byline bar for publish date, category, reading time, or other facts. Use strong labels and short values.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="metadata" markdown="1">

**Published:** August 10, 2026  
**Category:** Design System  
**Reading time:** 12 minutes

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="metadata" markdown="1">

**Published:** Month D, YYYY  
**Category:** Topic  
**Reading time:** N minutes

</div>
```

</div>

<!-- ========== Lead ========== -->
<div id="lead" class="component-doc" markdown="1">

### Lead

<span class="component-class">`.lead`</span>

<p class="component-desc">Opening statement that establishes the article’s narrative or explanatory direction. Slightly larger type; first letter is emphasized.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="lead" markdown="1">

This lead introduces the central idea and sets the tone for everything that follows. Keep it to one or two tight paragraphs.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="lead" markdown="1">

Opening paragraph that states the thesis or stakes.

</div>
```

</div>

<!-- ========== Section header ========== -->
<div id="section-header" class="component-doc" markdown="1">

### Section header

<span class="component-class">`.section-header`</span>

<p class="component-desc">Major section break with an `h2`. Use for primary structure inside the article.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="section-header" markdown="1">

## How the system is organized

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="section-header" markdown="1">

## Section title

</div>
```

</div>

<!-- ========== Subsection header ========== -->
<div id="subsection-header" class="component-doc" markdown="1">

### Subsection header

<span class="component-class">`.subsection-header`</span>

<p class="component-desc">Secondary heading (`h3`) within a section when you need hierarchy without a full section rule.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="subsection-header" markdown="1">

### A focused subtopic

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="subsection-header" markdown="1">

### Subsection title

</div>
```

</div>

<!-- ========== Figure ========== -->
<div id="figure" class="component-doc" markdown="1">

### Figure

<span class="component-class">`.figure`</span>

<p class="component-desc">Image with caption and optional credit. Prefer meaningful alt text; caption can use bold figure label + italic credit line.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="figure" markdown="1">

![Placeholder editorial image](https://placehold.co/1600x900)

**Figure 1.** A representative editorial image.

*Image: Placeholder for the design-system library.*

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="figure" markdown="1">

![Describe the image](/path/or/url)

**Figure N.** Caption that explains what the reader should notice.

*Image: Credit or source.*

</div>
```

</div>

<!-- ========== Quote ========== -->
<div id="quote" class="component-doc" markdown="1">

### Quote

<span class="component-class">`.quote`</span>

<p class="component-desc">Pull quote or attributed statement. Use a Markdown blockquote plus a plain attribution line.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="quote" markdown="1">

> A strong editorial design system should make the content easier to understand without becoming the content itself.

— Editorial Design Principle

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="quote" markdown="1">

> Quoted text that deserves emphasis.

— Attribution

</div>
```

</div>

<!-- ========== Stat grid ========== -->
<div id="stat-grid" class="component-doc" markdown="1">

### Stat grid

<span class="component-class">`.stat-grid` · `.stat` · `.stat-value` · `.stat-label`</span>

<p class="component-desc">Row of key numbers. Each cell is a `.stat` with a large value and a short label. Best for three to five figures.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="stat-grid" markdown="1">

<div class="stat">
<span class="stat-value">32</span>
<span class="stat-label">Components</span>
</div>

<div class="stat">
<span class="stat-value">3</span>
<span class="stat-label">Tiers</span>
</div>

<div class="stat">
<span class="stat-value">1</span>
<span class="stat-label">Shared system</span>
</div>

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="stat-grid" markdown="1">

<div class="stat">
<span class="stat-value">42</span>
<span class="stat-label">Label</span>
</div>

<div class="stat">
<span class="stat-value">18%</span>
<span class="stat-label">Label</span>
</div>

</div>
```

</div>

<!-- ========== Data table ========== -->
<div id="data-table" class="component-doc" markdown="1">

### Data table

<span class="component-class">`.data-table`</span>

<p class="component-desc">Styled Markdown table for structured comparisons or reference data. Keep headers short; right-align numeric columns when useful.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="data-table" markdown="1">

| Component | Purpose | Tier |
|---|---|---:|
| Editorial Header | Establish article identity | 1 |
| Figure | Present visual evidence | 1 |
| Stat Grid | Present important numbers | 1 |

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="data-table" markdown="1">

| Column A | Column B | Column C |
|---|---|---:|
| Row | Detail | 1 |
| Row | Detail | 2 |

</div>
```

</div>

<!-- ========== Timeline ========== -->
<div id="timeline" class="component-doc" markdown="1">

### Timeline

<span class="component-class">`.timeline` · `.timeline-item` · `.timeline-date`</span>

<p class="component-desc">Chronology of milestones. Each item has a date label, heading, and short body.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="timeline" markdown="1">

<div class="timeline-item" markdown="1">

<span class="timeline-date">1944</span>

### Harvard Mark I

An example milestone in the history of computing.

</div>

<div class="timeline-item" markdown="1">

<span class="timeline-date">1964</span>

### IBM System/360

A major architectural milestone in enterprise computing.

</div>

<div class="timeline-item" markdown="1">

<span class="timeline-date">2026</span>

### Editorial Design System

A reusable component vocabulary for long-form content.

</div>

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="timeline" markdown="1">

<div class="timeline-item" markdown="1">

<span class="timeline-date">YYYY</span>

### Milestone title

One or two sentences of context.

</div>

</div>
```

</div>

<!-- ========== Info callout ========== -->
<div id="info-callout" class="component-doc" markdown="1">

### Info callout

<span class="component-class">`.info-callout`</span>

<p class="component-desc">Informational aside for methodology, warnings, disclaimers, or source context that should stand out from body prose.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="info-callout" markdown="1">

**Note**

This is an informational callout. Use it for methodology, context, source notes, warnings, or editorial disclaimers.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="info-callout" markdown="1">

**Note**

Callout body. Keep it short and specific.

</div>
```

</div>

<div id="tier-2" class="section-header" markdown="1">

## Tier 2 — Composition components

Layout and grouping patterns for arranging related content.

</div>

<!-- ========== Content container ========== -->
<div id="content-container" class="component-doc" markdown="1">

### Content container

<span class="component-class">`.content-container`</span>

<p class="component-desc">Readable measure for ordinary prose when you need an explicit wrapper (for example inside a mixed layout). On the default article grid, bare paragraphs already sit on the measure.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="content-container" markdown="1">

This content container demonstrates the normal readable measure used by the editorial system. Use it when a group of paragraphs should share an explicit shell.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="content-container" markdown="1">

Body paragraphs that should share a readable measure.

</div>
```

</div>

<!-- ========== Content grid ========== -->
<div id="content-grid" class="component-doc" markdown="1">

### Content grid

<span class="component-class">`.content-grid`</span>

<p class="component-desc">Responsive multi-column arrangement of related blocks. Children are plain wrappers; headings and prose go inside each child.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="content-grid" markdown="1">

<div markdown="1">

### Column one

Related points side by side on wide viewports.

</div>

<div markdown="1">

### Column two

Collapses to a single column on small screens.

</div>

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="content-grid" markdown="1">

<div markdown="1">

### Column title

Column body.

</div>

<div markdown="1">

### Column title

Column body.

</div>

</div>
```

</div>

<!-- ========== Two column ========== -->
<div id="two-column" class="component-doc" markdown="1">

### Two column

<span class="component-class">`.two-column`</span>

<p class="component-desc">Fixed two-up layout for paired arguments, options, or lists (for example bull case vs bear case).</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="two-column" markdown="1">

<div markdown="1">

### Bull case

- Clear component vocabulary
- Consistent typography
- Reusable layouts

</div>

<div markdown="1">

### Bear case

- More CSS to maintain
- Complex components need custom markup
- Real articles may expose new patterns

</div>

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="two-column" markdown="1">

<div markdown="1">

### Left title

- Point one
- Point two

</div>

<div markdown="1">

### Right title

- Point one
- Point two

</div>

</div>
```

</div>

<!-- ========== Comparison ========== -->
<div id="comparison" class="component-doc" markdown="1">

### Comparison

<span class="component-class">`.comparison`</span>

<p class="component-desc">Before/after or A/B framing. Same grid shell as two-column, tuned for contrast pairs.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="comparison" markdown="1">

<div markdown="1">

### Before

A page-specific collection of styles and markup.

</div>

<div markdown="1">

### After

A shared semantic component system.

</div>

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="comparison" markdown="1">

<div markdown="1">

### Before

Describe the prior state.

</div>

<div markdown="1">

### After

Describe the improved state.

</div>

</div>
```

</div>

<!-- ========== Editorial list ========== -->
<div id="editorial-list" class="component-doc" markdown="1">

### Editorial list

<span class="component-class">`.editorial-list`</span>

<p class="component-desc">Emphasized bullet list for principles, criteria, or checklist-style points. Prefer bold lead-ins on each item.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="editorial-list" markdown="1">

- **Semantic:** classes describe what content is.
- **Reusable:** components can appear across article types.
- **Responsive:** layout is controlled by the design system.
- **Extensible:** add patterns only when real content needs them.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="editorial-list" markdown="1">

- **Label:** explanation.
- **Label:** explanation.

</div>
```

</div>

<!-- ========== Full bleed ========== -->
<div id="full-bleed" class="component-doc" markdown="1">

### Full bleed

<span class="component-class">`.full-bleed`</span>

<p class="component-desc">Escapes the normal measure so a child (usually a figure) can use more horizontal space. Nest a figure or other wide media inside.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="full-bleed" markdown="1">

<div class="figure" markdown="1">

![Full-width placeholder](https://placehold.co/2000x800)

**Figure 2.** A full-bleed figure can escape the normal reading measure.

</div>

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="full-bleed" markdown="1">

<div class="figure" markdown="1">

![Describe the image](/path/or/url)

**Figure N.** Caption.

</div>

</div>
```

</div>

<div id="tier-3" class="section-header" markdown="1">

## Tier 3 — Specialized editorial components

Recurring patterns for history, product, analysis, and reference writing.

</div>

<!-- ========== Fact box ========== -->
<div id="fact-box" class="component-doc" markdown="1">

### Fact box

<span class="component-class">`.fact-box`</span>

<p class="component-desc">At-a-glance facts for an event, product, or entity (date, location, outcome, specs).</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="fact-box" markdown="1">

**The Battle of Lepanto**

**Date:** 7 October 1571  
**Location:** Gulf of Patras  
**Participants:** Holy League · Ottoman Empire  
**Outcome:** Holy League victory

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="fact-box" markdown="1">

**Title**

**Label:** value  
**Label:** value  
**Label:** value

</div>
```

</div>

<!-- ========== Takeaways ========== -->
<div id="takeaways" class="component-doc" markdown="1">

### Takeaways

<span class="component-class">`.takeaways`</span>

<p class="component-desc">Summary box of key points. Heading plus bullets; keep each bullet one idea.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="takeaways" markdown="1">

### Key takeaways

- Components should describe content rather than visual appearance.
- Layout should stay responsive without changing article markup.
- Add specialized components only when patterns recur.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="takeaways" markdown="1">

### Key takeaways

- Point one
- Point two
- Point three

</div>
```

</div>

<!-- ========== Definition ========== -->
<div id="definition" class="component-doc" markdown="1">

### Definition

<span class="component-class">`.definition`</span>

<p class="component-desc">Single term and definition for inline glossary moments without a full glossary list.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="definition" markdown="1">

**Mainframe**

A high-performance computer designed to process large volumes of data and support many concurrent users and applications.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="definition" markdown="1">

**Term**

Definition in one or two sentences.

</div>
```

</div>

<!-- ========== Glossary ========== -->
<div id="glossary" class="component-doc" markdown="1">

### Glossary

<span class="component-class">`.glossary`</span>

<p class="component-desc">Multiple term/definition pairs for a section or article. Bold the term on its own line, definition below.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="glossary" markdown="1">

**CDP**  
Customer Data Platform.

**CMS**  
Content Management System.

**DAM**  
Digital Asset Management.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="glossary" markdown="1">

**TERM**  
Definition.

**TERM**  
Definition.

</div>
```

</div>

<!-- ========== Pros / cons ========== -->
<div id="pros-cons" class="component-doc" markdown="1">

### Pros / cons

<span class="component-class">`.pros-cons`</span>

<p class="component-desc">Two-column advantages vs limitations. Same structure as two-column; use when the frame is specifically tradeoffs.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="pros-cons" markdown="1">

<div markdown="1">

### Advantages

- Simple authoring
- Consistent presentation
- Reusable patterns

</div>

<div markdown="1">

### Limitations

- Complex data may need structured includes
- New patterns may require new components

</div>

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="pros-cons" markdown="1">

<div markdown="1">

### Advantages

- Item

</div>

<div markdown="1">

### Limitations

- Item

</div>

</div>
```

</div>

<!-- ========== Recommendation ========== -->
<div id="recommendation" class="component-doc" markdown="1">

### Recommendation

<span class="component-class">`.recommendation`</span>

<p class="component-desc">Prescriptive close or guidance block. One clear heading and a short directive paragraph or list.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="recommendation" markdown="1">

### Recommendation

Start with the core components and let the system evolve from real articles rather than anticipating every layout.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="recommendation" markdown="1">

### Recommendation

What the reader should do next, in one short paragraph.

</div>
```

</div>

<!-- ========== Scorecard ========== -->
<div id="scorecard" class="component-doc" markdown="1">

### Scorecard

<span class="component-class">`.scorecard`</span>

<p class="component-desc">Criteria table with ratings and notes. Useful for reviews, evaluations, and design critiques.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="scorecard" markdown="1">

| Criterion | Rating | Notes |
|---|---:|---|
| Authoring simplicity | 9/10 | Mostly ordinary Markdown |
| Reusability | 9/10 | Semantic vocabulary |
| Responsiveness | 9/10 | CSS-driven |
| Complexity | 3/10 | Low initial overhead |

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="scorecard" markdown="1">

| Criterion | Rating | Notes |
|---|---:|---|
| Criterion | N/10 | Short note |

</div>
```

</div>

<!-- ========== Forecast ========== -->
<div id="forecast" class="component-doc" markdown="1">

### Forecast

<span class="component-class">`.forecast`</span>

<p class="component-desc">Near / medium / long-term outlook sections. Heading plus labeled time horizons.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="forecast" markdown="1">

### What happens next

**Near term**  
Implement the core components and migrate one representative article.

**Medium term**  
Compare against existing pages and refine spacing and type.

**Long term**  
Add components only when recurring patterns justify them.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="forecast" markdown="1">

### What happens next

**Near term**  
…

**Medium term**  
…

**Long term**  
…

</div>
```

</div>

<!-- ========== Event card ========== -->
<div id="event-card" class="component-doc" markdown="1">

### Event card

<span class="component-class">`.event-card` · `.event-date`</span>

<p class="component-desc">Dated event summary: date label, title, and concise description.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="event-card" markdown="1">

<span class="event-date">7 October 1571</span>

### Battle of Lepanto

A dedicated event card can present a date, event title, and concise description.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="event-card" markdown="1">

<span class="event-date">Day Month Year</span>

### Event title

One or two sentences.

</div>
```

</div>

<!-- ========== Entity card ========== -->
<div id="entity-card" class="component-doc" markdown="1">

### Entity card

<span class="component-class">`.entity-card`</span>

<p class="component-desc">Person, organization, or product card with role, period, and known-for lines.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="entity-card" markdown="1">

### Don John of Austria

**Role:** Commander of the Holy League  
**Period:** 1547–1578  
**Known for:** Commanding the Christian fleet at Lepanto.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="entity-card" markdown="1">

### Name

**Role:** …  
**Period:** …  
**Known for:** …

</div>
```

</div>

<!-- ========== Source list ========== -->
<div id="source-list" class="component-doc" markdown="1">

### Source list

<span class="component-class">`.source-list`</span>

<p class="component-desc">Numbered bibliography or reference list for the end of an article.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="source-list" markdown="1">

### Sources

1. Primary historical accounts
2. Wikimedia Commons
3. Manufacturer specifications
4. Independent testing

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="source-list" markdown="1">

### Sources

1. Source one
2. Source two

</div>
```

</div>

<!-- ========== Source note ========== -->
<div id="source-note" class="component-doc" markdown="1">

### Source note

<span class="component-class">`.source-note`</span>

<p class="component-desc">Inline footnote-style credit for a specific claim, chart, or figure.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="source-note" markdown="1">

**Source:** Example source note for a specific claim or figure.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="source-note" markdown="1">

**Source:** Citation or link for the claim above.

</div>
```

</div>

<!-- ========== Gallery ========== -->
<div id="gallery" class="component-doc" markdown="1">

### Gallery

<span class="component-class">`.gallery`</span>

<p class="component-desc">Multi-image row that wraps responsively. Use when several images share equal weight.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="gallery" markdown="1">

![Gallery image one](https://placehold.co/800x600)
![Gallery image two](https://placehold.co/800x600)
![Gallery image three](https://placehold.co/800x600)

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="gallery" markdown="1">

![Alt one](/path/one)
![Alt two](/path/two)
![Alt three](/path/three)

</div>
```

</div>

<!-- ========== Figure pair ========== -->
<div id="figure-pair" class="component-doc" markdown="1">

### Figure pair

<span class="component-class">`.figure-pair`</span>

<p class="component-desc">Two images with captions for then/now, before/after, or side-by-side comparison.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="figure-pair" markdown="1">

<div markdown="1">

![Then](https://placehold.co/900x600)

**Then**  
The original configuration.

</div>

<div markdown="1">

![Now](https://placehold.co/900x600)

**Now**  
The modern configuration.

</div>

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="figure-pair" markdown="1">

<div markdown="1">

![Left](/path/left)

**Left label**  
Caption.

</div>

<div markdown="1">

![Right](/path/right)

**Right label**  
Caption.

</div>

</div>
```

</div>

<!-- ========== Aside ========== -->
<div id="aside" class="component-doc" markdown="1">

### Aside

<span class="component-class">`.aside`</span>

<p class="component-desc">Supporting context that should not interrupt the main narrative. Compact card; can sit beside other compact components on wide screens.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="aside" markdown="1">

**Why it matters**

An aside holds useful supporting context without derailing the primary story.

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="aside" markdown="1">

**Label**

Supporting context in a short paragraph.

</div>
```

</div>

<!-- ========== Related reading ========== -->
<div id="related-reading" class="component-doc" markdown="1">

### Related reading

<span class="component-class">`.related-reading`</span>

<p class="component-desc">Outbound or internal further-reading list. Prefer real permalinks in production articles.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="related-reading" markdown="1">

### Related reading

- [The Mainframe](/editorial/invisible-engine)
- [Robot vacuum editorial](/editorial/robot-vacuum)
- [Design system (this page)](/editorial/design-system)

</div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="related-reading" markdown="1">

### Related reading

- [Title](/path)
- [Title](/path)

</div>
```

</div>

<!-- ========== Editorial break ========== -->
<div id="editorial-break" class="component-doc" markdown="1">

### Editorial break

<span class="component-class">`.editorial-break`</span>

<p class="component-desc">Visual pause between major parts of an article. Empty element — no children required.</p>

<p class="component-label">Live example</p>

<div class="component-example" markdown="1">

<div class="editorial-break"></div>

</div>

<p class="component-label">Copy shell</p>

```html
<div class="editorial-break"></div>
```

</div>

<div class="section-header" markdown="1">

## Authoring reminder

</div>

<div class="info-callout" markdown="1">

**Multi-block rule**

Kramdown’s `{: .class}` alone only styles the **next single block**. When a component holds headings, lists, or several paragraphs, wrap them:

```html
<div class="takeaways" markdown="1">

### Key takeaways

- List items stay inside the component

</div>
```

</div>
