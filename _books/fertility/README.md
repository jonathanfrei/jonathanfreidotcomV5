# The Fertility Decline

This repository is the working source for a book about the causes, consequences, and long-term civilizational stakes of declining fertility. It contains the book outline, manuscript drafts, and the editorial resources used to research, draft, critique, and revise the book.

The manuscript is designed for incremental drafting. Each chapter has a directory, each major section has its own Markdown file, and unfinished files retain the relevant outline notes until they are replaced by prose.

## Repository organization

- `/Outline.md` is the canonical book outline. It defines the chapter sequence, section sequence, and intended coverage.
- `/000-fertility-decline.md` is the book-level entry point and cover-page placeholder.
- `/000-introduction/` contains the book introduction.
- `/001-.../` through `/010-.../` contain the numbered chapters and conclusion. Each directory begins with `000-introduction.md`; the remaining numbered files are chapter sections. Chapter 7 also holds `ref.md`, a working file for the chapter plan and research notes.
- `Style/` contains the editorial system for the project.
- `Agents.md` gives AI agents the repository-specific workflow for researching, drafting, revising, and validating manuscript sections.

## Style resources

`Style/CORE.md` is the operational baseline. Agents drafting prose also use `Style/voice.md`, `Style/worldview.md`, and `Style/manuscript.md`, then run the review in `Style/critique.md`. The longer documents in `Style/ref/` provide additional context only when their routing conditions apply. `Style/voice.md` is the sole authority for manuscript voice; there is no sample chapter to imitate.

## Manuscript conventions

Chapter directories and section files begin with three-digit sequence numbers so reading order remains visible in the filesystem. All manuscript directory and file names must be lowercase. New names use lowercase, hyphen-separated slugs.

Shell files may initially contain only the front matter needed to identify them and numbered notes copied from the outline. When a section is drafted, its front matter is completed with the fields required by `Style/manuscript.md`, and the notes are replaced by coherent prose.

Drafted sections use standard Markdown and the custom attributes described in the style resources. Sources are linked in the prose and collected in an ordered citation list. The precise citation format will be refined during drafting; agents should follow the latest established manuscript pattern and surface unresolved cases for editorial review.

Chapter introductions follow the same manuscript conventions as other sections, but they are drafted after the chapter's substantive sections are complete.

## Drafting workflow

1. Select a section from the outline and confirm its matching manuscript file.
2. Read the complete chapter outline and adjacent manuscript sections to understand scope and avoid duplication.
3. Load the required resources in `Style/` according to `Agents.md` and any routing instructions in `Style/CORE.md`.
4. Research consequential claims with reliable sources and distinguish evidence, interpretation, and uncertainty.
5. Replace the shell notes with a continuous argument in the prescribed voice and manuscript format.
6. Complete the front matter, links, citations, and custom attributes.
7. Run the critique and validation checks before requesting review.

Consequential conflicts or gaps in the editorial guidance should be raised for clarification rather than resolved by silently inventing a new convention.
