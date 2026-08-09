---
title: "Designing an Editorial Page for Robot Vacuums"
date: "2026-08-08"
tags: ["design", "typography", "editorial", "web", "css"]
excerpt: "How a single-page feature on robotic vacuum cleaners was built with Source Serif 4, deliberate layout constraints, and a refusal to look like every other product roundup."
---

I've enjoyed using Grok 4.5 to generate editorial webpages on a variety of subject. The most recent one was an attempt to test out some of the fonts and typography that would go into the August redesign of this site. Below is what went into the design.

Most product pages about robot vacuums look the same. White background, floating cards, gradient buttons, and a carousel of “best overall” badges. The brief here was different: take the dense Grokipedia entry on robotic vacuum cleaners and turn it into a single-page editorial feature that could sit comfortably next to a long *New Yorker* tech essay or a well-set *Cabinet* magazine article.

The result is [a page that treats domestic robots as cultural and technical history](/editorial/robot-vacuum) rather than SKUs. Below are the concrete decisions that produced it.

## Typography as the Primary Structure

Three families from Google Fonts, all from the Source series:

- **Source Serif 4** for every heading and body paragraph  
- **Source Sans 3** for captions, kickers, labels, and interface text  
- **Source Code Pro** for the small section numbers (01, 02, 03…)

Serif for the long reading, sans for the metadata, mono for the navigation landmarks. This is not a “font pairing” exercise. It is a hierarchy rule. Once the reader’s eye learns that italic serif means pull-quote and small sans means caption, the page becomes scannable without a single hamburger menu or sticky nav.

Optical sizing is left on. Source Serif 4’s variable axes are used so the large display title (clamp between 2.8rem and 4.5rem) stays dense while body text at 1.125rem remains open. Letter-spacing on the title is tightened slightly (−0.02em). Body line-height sits at 1.65. These are the unglamorous numbers that keep a long technical piece from feeling either cramped or airy.

## Layout That Changes Character with Screen Width

On viewports wider than 1000px the body text can split into two columns. The feature grid becomes 1.4fr / 1fr for text-plus-sidebar sections and three equal columns for denser technical breakdowns. On mobile everything collapses to a single stack with generous but not wasteful padding (1.1rem sides).

This is not “responsive design” as a checklist item. It is an editorial decision: large screens get the luxury of parallel reading; small screens get the same material without horizontal scroll or microscopic type. The max-width of the entire site is 1280px. Beyond that the page simply centers and stops growing. There is no full-bleed hero image that forces the reader to scroll past marketing before reaching the first paragraph.

## The Warm Paper Field

Background is `#f8f5f0`—a slightly warm off-white that recalls uncoated book stock rather than a sterile app canvas. Text is near-black (`#1a1a1a`). The single accent color is a desaturated terracotta (`#c45c26`) used only for kickers, callout rules, and links. Rules and borders sit at `#d9d2c5`.

The palette refuses both the cold blue of SaaS dashboards and the high-chroma gradients of consumer electronics marketing. It is closer to the interior of a well-printed monograph than to a product landing page. That choice alone does most of the work of telling the reader what kind of object they are looking at.

## Editorial Devices, Not UI Components

The page uses four recurring blocks:

1. **Kicker + large title + deck**  
   Classic magazine masthead. The kicker is uppercase sans, tracking opened. The deck is a single sentence that sets the historical frame.

2. **Pull quotes**  
   Large italic serif, left border in the accent color, max-width constrained so they never stretch across the full measure. They interrupt the flow deliberately.

3. **Callout boxes**  
   Light background, solid left rule, uppercase sans label. Used for “At a Glance,” battery specs, and common failure modes. They function as sidebars that stay in the reading flow rather than floating out of it.

4. **Numbered section headers**  
   Mono numerals + serif title. The numbers act as both visual anchors and a quiet table of contents.

Captions are set in the smaller sans, muted, and always include the Wikimedia Commons attribution and license. Images are hot-linked with proper credit rather than downloaded and stripped of provenance. That is a design decision as much as an ethical one: the page treats its sources as part of the visible apparatus.

## What Was Deliberately Omitted

- No sticky header.  
- No “jump to section” pills.  
- No dark-mode toggle.  
- No cookie banner mock.  
- No “as an Amazon Associate” disclosure block pretending to be design.  
- No animated progress bars or intersection-observer tricks.

The page is a document. It does not try to become an application. Once the reader is past the hero, the only movement is vertical scrolling and the occasional column reflow. That restraint is the actual design statement.

## The Content Constraint

Everything on the page is drawn from the Grokipedia entry. The writing task was condensation and re-sequencing, not invention. History comes first, then sensors and mechanisms, then performance data, then market structure, then the privacy and safety arguments. The 2026 reviewer consensus is presented as a short list rather than a product grid. Tables are used only where numbers actually compare (surface types and debris pickup rates).

This order mirrors the logic of the source material while making it readable in one sitting. The page is long—intentionally so. It is meant to be finished, not skimmed for a purchase decision.

## Why It Matters

Robot vacuums are the first domestic robots most people have lived with. They sit in the awkward middle between appliance and autonomous agent. Treating them with the same typographic care given to a critical essay on architecture or interface history is a small act of seriousness. The design does not invent that seriousness; it simply refuses to hide it behind the visual language of e-commerce.

The fonts are free. The images are free. The layout is a few hundred lines of CSS. The only scarce resource was the decision to keep the page quiet enough that the history could be heard.
