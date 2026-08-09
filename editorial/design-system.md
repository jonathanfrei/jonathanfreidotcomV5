---
permalink: /editorial/design-system
layout: editorial
title: Editorial Design System Template
description: Component reference for the Jekyll editorial design system.
---

<div class="editorial-header" markdown="1">

<span class="eyebrow">Editorial Design System</span>

# Editorial Design System

A reference page demonstrating the available editorial components.

</div>

<div class="metadata" markdown="1">

**Published:** August 9, 2026  
**Category:** Design System  
**Reading time:** 10 minutes

</div>

<div class="lead" markdown="1">

This template demonstrates the semantic components available to editorial pages. Multi-block components use HTML wrappers with `markdown="1"` so headings, lists, and paragraphs stay inside the component. The visual treatment is controlled by CSS.

</div>

<div id="tier-1" class="section-header" markdown="1">

## Tier 1 — Core Editorial Components

</div>

<div class="subsection-header" markdown="1">

### Lead

</div>

The lead introduces the central idea of an article and establishes its narrative or explanatory direction.

<div class="figure" markdown="1">

![Placeholder editorial image](https://placehold.co/1600x900)

**Figure 1.** A representative editorial image.

*Image: Placeholder image for the design-system template.*

</div>

<div class="quote" markdown="1">

> A strong editorial design system should make the content easier to understand without becoming the content itself.

— Editorial Design Principle

</div>

<div class="stat-grid" markdown="1">

<div class="stat">
<span class="stat-value">36</span>
<span class="stat-label">Semantic components</span>
</div>

<div class="stat">
<span class="stat-value">3</span>
<span class="stat-label">Component tiers</span>
</div>

<div class="stat">
<span class="stat-value">1</span>
<span class="stat-label">Shared visual system</span>
</div>

</div>

<div class="data-table" markdown="1">

| Component | Purpose | Tier |
|---|---|---:|
| Editorial Header | Establish article identity | 1 |
| Figure | Present visual evidence | 1 |
| Stat Grid | Present important numbers | 1 |
| Timeline | Present chronology | 1 |

</div>

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

A reusable component vocabulary for long-form editorial content.

</div>

</div>

<div class="info-callout" markdown="1">

**Note**

This is an informational callout. It can be used for methodology, context, source notes, warnings, or editorial disclaimers.

</div>

<div id="tier-2" class="section-header" markdown="1">

## Tier 2 — Composition Components

</div>

<div class="content-container" markdown="1">

This content container demonstrates the normal readable measure used by the editorial system. On wide viewports, article prose flows in multiple columns; full-width components span the full measure.

</div>

<div class="content-grid" markdown="1">

<div markdown="1">

### Column One

Content grids allow related content to be arranged together while remaining responsive.

</div>

<div markdown="1">

### Column Two

The grid should collapse naturally at smaller viewport widths.

</div>

</div>

<div class="two-column" markdown="1">

<div markdown="1">

### Bull Case

- Clear component vocabulary
- Consistent typography
- Reusable layouts

</div>

<div markdown="1">

### Bear Case

- More CSS to maintain
- Some complex components need custom markup
- Real articles may expose new patterns

</div>

</div>

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

<div class="editorial-list" markdown="1">

- **Semantic:** classes describe what content is.
- **Reusable:** components can appear across different article types.
- **Responsive:** layout is controlled by the design system.
- **Extensible:** new patterns can be added when real content requires them.

</div>

<div class="full-bleed" markdown="1">

<div class="figure" markdown="1">

![Full-width placeholder image](https://placehold.co/2000x800)

**Figure 2.** A full-bleed figure can escape the normal reading measure.

</div>

</div>

<div id="tier-3" class="section-header" markdown="1">

## Tier 3 — Specialized Editorial Components

</div>

<div class="fact-box" markdown="1">

**The Battle of Lepanto**

**Date:** 7 October 1571  
**Location:** Gulf of Patras  
**Participants:** Holy League · Ottoman Empire  
**Outcome:** Holy League victory

</div>

<div class="takeaways" markdown="1">

### Key Takeaways

- Components should describe content rather than visual appearance.
- Layout should remain responsive without changing article markup.
- Specialized components should be introduced when recurring editorial patterns emerge.

</div>

<div class="definition" markdown="1">

**Mainframe**

A high-performance computer designed to process large volumes of data and support many concurrent users and applications.

</div>

<div class="glossary" markdown="1">

**CDP**  
Customer Data Platform.

**CMS**  
Content Management System.

**DAM**  
Digital Asset Management.

</div>

<div class="pros-cons" markdown="1">

<div markdown="1">

### Advantages

- Simple authoring
- Consistent presentation
- Reusable patterns

</div>

<div markdown="1">

### Limitations

- Complex data may require structured includes
- New editorial patterns may require new components

</div>

</div>

<div class="recommendation" markdown="1">

### Recommendation

Start with the core components and allow the design system to evolve from real articles rather than attempting to anticipate every possible layout.

</div>

<div class="scorecard" markdown="1">

| Criterion | Rating | Notes |
|---|---:|---|
| Authoring simplicity | 9/10 | Mostly ordinary Markdown |
| Reusability | 9/10 | Semantic component vocabulary |
| Responsiveness | 9/10 | CSS-driven |
| Complexity | 3/10 | Low initial implementation overhead |

</div>

<div class="forecast" markdown="1">

### What Happens Next

**Near term**  
Implement the core components and migrate one representative article.

**Medium term**  
Compare the migrated article against the existing pages and refine spacing, typography, and responsive behavior.

**Long term**  
Add components only when recurring editorial patterns justify them.

</div>

<div class="event-card" markdown="1">

<span class="event-date">7 October 1571</span>

### Battle of Lepanto

A dedicated event card can present a date, event title, and concise description.

</div>

<div class="entity-card" markdown="1">

### Don John of Austria

**Role:** Commander of the Holy League  
**Period:** 1547–1578  
**Known for:** Commanding the Christian fleet at Lepanto.

</div>

<div class="source-list" markdown="1">

### Sources

1. Primary historical accounts
2. Wikimedia Commons
3. Manufacturer specifications
4. Independent testing

</div>

<div class="source-note" markdown="1">

**Source:** Example source note for a specific claim or figure.

</div>

<div class="gallery" markdown="1">

![Gallery image one](https://placehold.co/800x600)
![Gallery image two](https://placehold.co/800x600)
![Gallery image three](https://placehold.co/800x600)

</div>

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

<div class="aside" markdown="1">

**Why it matters**

An aside contains useful supporting context that should not interrupt the main narrative.

</div>

<div class="related-reading" markdown="1">

### Related Reading

- [The Mainframe](#)
- [The History of Enterprise Computing](#)
- [Virtualization Explained](#)

</div>

<div class="editorial-break"></div>

<div class="section-header" markdown="1">

## End of Component Reference

</div>

Multi-block components must use a wrapping element:

```html
<div class="takeaways" markdown="1">

### Key Takeaways

- List items stay inside the component

</div>
```

Kramdown’s `{: .class}` alone only styles the **next single block**, which is why lists and following paragraphs were falling out of components.
