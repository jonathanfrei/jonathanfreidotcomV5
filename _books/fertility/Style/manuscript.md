# Manuscript file format and organization

Folder structure
- Each chapter will have a folder.
- Folder naming convention is 001-chapter-one-title-slug

File structure
- Each chapter section will be a .md file within its chapter folder
- File naming conventions are 001-section-title-slug.md
- Each section file follows standard front matter

---
title: [full section title]
deck: [section sub-title]
eyebrow: [short thematic phrase]
---

[section body content]

Section formatting 

- Use standard markdown conventions for formatting 
- Use the {: .lede} tag on the line following the first paragraph of the body content
- Use semantic H2 and H3 tags to organize content
- An aside must be exactly one paragraph and should be used sparingly. Place it immediately after the regular paragraph it supplements; the CMS automatically pairs it with that preceding paragraph. The aside may begin with bold text as a short title. Put the {: .aside} tag on its own line immediately after the aside paragraph.
- Use inline links to external sources where relevant
- In prose, refer to an adjacent chapter or section relatively (for example, “the previous chapter”) instead of using production numbers such as “Chapter 001.” Use a numbered reference only when it helps readers find a nonadjacent discussion.
- Wrap the citation block in `<div class="citation">` and `</div>` so the CMS can style it separately from the prose. Inside the div, introduce the ordered list with the bold label `**Citations**`, not a heading.
- Use American English spelling throughout manuscript prose
