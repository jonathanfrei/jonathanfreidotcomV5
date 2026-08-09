---
permalink: /editorial/design-system
layout: editorial
title: Editorial Design System Template
description: Component reference for the Jekyll editorial design system.
---

{: .editorial-header}

<span class="eyebrow">Editorial Design System</span>

# Editorial Design System

A reference page demonstrating the available editorial components.

{: .metadata}

**Published:** August 9, 2026  
**Category:** Design System  
**Reading time:** 10 minutes

{: .lead}

This template demonstrates the semantic components available to editorial pages. The visual treatment is controlled by CSS while the Markdown remains focused on content.

{: #tier-1 .section-header}

## Tier 1 — Core Editorial Components

{: .subsection-header}

### Lead

The lead introduces the central idea of an article and establishes its narrative or explanatory direction.

{: .figure}

![Placeholder editorial image](https://placehold.co/1600x900)

**Figure 1.** A representative editorial image.

*Image: Placeholder image for the design-system template.*

{: .quote}

> A strong editorial design system should make the content easier to understand without becoming the content itself.

— Editorial Design Principle

{: .stat-grid}

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

{: .data-table}

| Component | Purpose | Tier |
|---|---|---:|
| Editorial Header | Establish article identity | 1 |
| Figure | Present visual evidence | 1 |
| Stat Grid | Present important numbers | 1 |
| Timeline | Present chronology | 1 |

{: .timeline}

<div class="timeline-item">

<span class="timeline-date">1944</span>

### Harvard Mark I

An example milestone in the history of computing.

</div>

<div class="timeline-item">

<span class="timeline-date">1964</span>

### IBM System/360

A major architectural milestone in enterprise computing.

</div>

<div class="timeline-item">

<span class="timeline-date">2026</span>

### Editorial Design System

A reusable component vocabulary for long-form editorial content.

</div>

{: .info-callout}

**Note**

This is an informational callout. It can be used for methodology, context, source notes, warnings, or editorial disclaimers.

{: #tier-2 .section-header}

## Tier 2 — Composition Components

{: .content-container}

This content container demonstrates the normal readable measure used by the editorial system.

{: .content-grid}

<div>

### Column One

Content grids allow related content to be arranged together while remaining responsive.

</div>

<div>

### Column Two

The grid should collapse naturally at smaller viewport widths.

</div>

{: .two-column}

<div>

### Bull Case

- Clear component vocabulary
- Consistent typography
- Reusable layouts

</div>

<div>

### Bear Case

- More CSS to maintain
- Some complex components need custom markup
- Real articles may expose new patterns

</div>

{: .comparison}

<div>

### Before

A page-specific collection of styles and markup.

</div>

<div>

### After

A shared semantic component system.

</div>

{: .editorial-list}

- **Semantic:** classes describe what content is.
- **Reusable:** components can appear across different article types.
- **Responsive:** layout is controlled by the design system.
- **Extensible:** new patterns can be added when real content requires them.

{: .full-bleed}

{: .figure}

![Full-width placeholder image](https://placehold.co/2000x800)

**Figure 2.** A full-bleed figure can escape the normal reading measure.

{: #tier-3 .section-header}

## Tier 3 — Specialized Editorial Components

{: .fact-box}

**The Battle of Lepanto**

**Date:** 7 October 1571  
**Location:** Gulf of Patras  
**Participants:** Holy League · Ottoman Empire  
**Outcome:** Holy League victory

{: .takeaways}

### Key Takeaways

- Components should describe content rather than visual appearance.
- Layout should remain responsive without changing article markup.
- Specialized components should be introduced when recurring editorial patterns emerge.

{: .definition}

**Mainframe**

A high-performance computer designed to process large volumes of data and support many concurrent users and applications.

{: .glossary}

**CDP**  
Customer Data Platform.

**CMS**  
Content Management System.

**DAM**  
Digital Asset Management.

{: .pros-cons}

<div>

### Advantages

- Simple authoring
- Consistent presentation
- Reusable patterns

</div>

<div>

### Limitations

- Complex data may require structured includes
- New editorial patterns may require new components

</div>

{: .recommendation}

### Recommendation

Start with the core components and allow the design system to evolve from real articles rather than attempting to anticipate every possible layout.

{: .scorecard}

| Criterion | Rating | Notes |
|---|---:|---|
| Authoring simplicity | 9/10 | Mostly ordinary Markdown |
| Reusability | 9/10 | Semantic component vocabulary |
| Responsiveness | 9/10 | CSS-driven |
| Complexity | 3/10 | Low initial implementation overhead |

{: .forecast}

### What Happens Next

**Near term**  
Implement the core components and migrate one representative article.

**Medium term**  
Compare the migrated article against the existing pages and refine spacing, typography, and responsive behavior.

**Long term**  
Add components only when recurring editorial patterns justify them.

{: .event-card}

<span class="event-date">7 October 1571</span>

### Battle of Lepanto

A dedicated event card can present a date, event title, and concise description.

{: .entity-card}

### Don John of Austria

**Role:** Commander of the Holy League  
**Period:** 1547–1578  
**Known for:** Commanding the Christian fleet at Lepanto.

{: .source-list}

### Sources

1. Primary historical accounts
2. Wikimedia Commons
3. Manufacturer specifications
4. Independent testing

{: .source-note}

**Source:** Example source note for a specific claim or figure.

{: .gallery}

![Gallery image one](https://placehold.co/800x600)
![Gallery image two](https://placehold.co/800x600)
![Gallery image three](https://placehold.co/800x600)

{: .figure-pair}

<div>

![Then](https://placehold.co/900x600)

**Then**  
The original configuration.

</div>

<div>

![Now](https://placehold.co/900x600)

**Now**  
The modern configuration.

</div>

{: .aside}

**Why it matters**

An aside contains useful supporting context that should not interrupt the main narrative.

{: .related-reading}

### Related Reading

- [The Mainframe](#)
- [The History of Enterprise Computing](#)
- [Virtualization Explained](#)

{: .editorial-break}

{: .section-header}

## End of Component Reference

The page itself is intentionally ordinary Markdown plus semantic Kramdown attributes. That is the authoring model the design system is intended to support.
