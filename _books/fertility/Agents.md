# Instructions for AI agents

This repository contains the working manuscript for *The Fertility Decline*. These instructions apply throughout the repository unless a more specific `Agents.md` file is added below this directory.

## Required context and precedence

Before drafting or materially revising manuscript prose, read these sources in order:

1. `/Outline.md` for the book's argument, chapter order, section scope, and required topics.
2. The target file, the complete chapter outline, and neighboring files in `/` for local context and boundaries between sections.
3. `Style/CORE.md` for operational editorial standards and routing to supporting resources.
4. `Style/manuscript.md` for manuscript structure, front matter, Markdown, links, citations, and custom attributes.
5. `Style/voice.md` before writing prose; it is the primary authority for how the writing should sound.
6. `Style/worldview.md` as the default lens for every section of the book. Write from it without announcing or performing it.
7. `Style/critique.md` before marking work ready for review or opening or updating a pull request.

Load files in `Style/ref/` only when their routing conditions in `Style/CORE.md` apply. Do not use any manuscript section as a general voice template.

The outline controls coverage. `Style/manuscript.md` controls manuscript format. `Style/voice.md` is the sole authority for prose sound. `Style/worldview.md` supplies the book's default analytical lens. `Style/CORE.md` controls general editorial quality and source practice. A direct user instruction for the current task takes precedence over repository guidance.

If these sources conflict or leave a consequential question unanswered, preserve established content and ask for editorial direction. Do not establish a repository-wide convention from one guess.

## Operating rules

- Begin from an up-to-date default branch and use a focused branch for requested changes.
- Inspect `git status` before editing. Preserve unrelated work and do not rewrite, move, or delete files outside the requested scope.
- Match an outline section to its existing manuscript file before drafting. Do not add, remove, reorder, or substantially redefine outline topics without approval.
- Read the complete chapter outline and adjacent sections so the new prose has a clear role and does not duplicate nearby material.
- Keep one major outlined section per numbered Markdown file and preserve the three-digit reading order.
- All names under `/` must be lowercase. New directory and file names use lowercase, hyphen-separated slugs.
- Replace outline-note placeholders only when prose for that section is requested. Outline bullets are a coverage checklist, not a completed draft.
- Keep changes focused and reviewable. Avoid opportunistic rewrites elsewhere in the manuscript.
- Do not commit, push, open a pull request, merge, publish, or otherwise modify remote state unless the user requests it.

## Research and factual standards

- Follow the source rules in `Style/CORE.md` and prefer primary or authoritative sources for statistics, projections, laws, policies, scientific findings, and country outcomes.
- Verify time-sensitive facts during drafting. Preserve the year, geography, population, and definition behind quantitative claims.
- Distinguish total fertility rate, birth rate, completed fertility, cohort fertility, period fertility, desired fertility, and replacement fertility precisely.
- Separate established findings from disputed interpretations, forecasts, and speculation. State material uncertainty and do not imply causation from correlation.
- Represent credible competing explanations fairly, especially on politically or morally contested subjects.
- State direct causal mechanisms plainly when they are inherent in the act being described; reserve qualification for the magnitude, net effect, interaction, or interpretation that is actually uncertain.
- Never invent facts, quotations, citations, links, publication details, page numbers, biographical details, scenes, or experiences.
- Integrate descriptive links at the claims they support. Do not leave tool-specific citation syntax in manuscript files.
- Maintain an ordered citation list at the end of drafted sections. The detailed citation system is evolving, so follow the latest established pattern and flag cases it does not resolve.

## Drafting and revision

- Write for an intelligent reader who is interested but may not know the subject. Define technical demographic terms when they become necessary.
- Preserve the book's distinctions among individual freedom, family aspirations, institutional constraints, adaptation to low fertility, and civilizational consequences.
- Build a continuous argument rather than mechanically expanding each outline bullet into a separate paragraph.
- Use concrete examples, human consequences, and clear transitions. Avoid repeating background covered elsewhere.
- Preserve nuance around voluntary childlessness, delayed childbearing, unintended childlessness, infertility, and desired versus achieved family size.
- Follow the first-person guidance in `Style/voice.md`. Use first person for the author's analysis and opinions, but never invent personal experiences, memories, feelings, or biographical details.
- Apply `Style/worldview.md` to every section by shaping what the prose notices, values, questions, and concludes. Keep that worldview implicit unless the tradition itself is relevant to the argument.
- Where relevant, move among generational, centennial, and millennial horizons. Treat very long-range calculations as illustrations, not forecasts, and connect the millennium horizon to civilizational continuity and expansion beyond Earth only where it advances the argument.
- Preserve occasional natural roughness as described in `Style/voice.md` and `Style/CORE.md`; do not manufacture errors or incoherence as an anti-AI tell.
- Run the layered revision principles in `Style/CORE.md` and the relevant on-demand references. Remove filler, duplication, unsupported authority, generic AI phrasing, and manufactured rhetorical emphasis.
- Draft each chapter's `000-introduction.md` only after its substantive sections are complete. Chapter introductions follow the same front-matter, prose, citation, and review conventions as other manuscript sections.

## Manuscript format

- Shell files may omit `deck` and `eyebrow`. During drafting, complete the `title`, `deck`, and `eyebrow` front matter required by `Style/manuscript.md`.
- Do not add an H1 to the body; front matter supplies the section title.
- Put `{: .lede}` on the line immediately after the opening body paragraph.
- Use `##` and `###` headings as a rough expression of the outline hierarchy. Omit a heading when no meaningful subdivision exists or uninterrupted prose reads better.
- An aside must consist of exactly one paragraph placed immediately after the regular paragraph it supplements. The CMS automatically pairs the aside with that preceding regular paragraph. The aside may begin with bold text as a short title. Put `{: .aside}` on its own line immediately after the aside paragraph, and use asides sparingly.
- Keep custom attributes on their own line immediately after the element they modify.
- Use American English throughout. Use standard Markdown elsewhere, descriptive inline links, and an ordered citation list introduced by `**Citations**` at the bottom of each drafted section.

## Validation and handoff

Before presenting work for review:

1. Confirm that the section covers its outline points without drifting beyond its assigned scope.
2. Check lowercase paths, sequence numbers, completed front matter, lede placement, heading levels, asides, links, and citations.
3. Verify every factual claim and confirm that each cited source supports the nearby statement.
4. Run every item in `Style/critique.md` as pass, fail with evidence, or not applicable; fix failures or disclose why they remain.
5. Review the diff for accidental changes, repeated material, shell placeholders, formatting errors, and unsupported claims.
6. Report what changed, what was verified, and any unresolved editorial or source questions.
