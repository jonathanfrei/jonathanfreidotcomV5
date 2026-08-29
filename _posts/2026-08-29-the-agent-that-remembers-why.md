---
title: "The Agent That Remembers Why"
date: 2026-08-29 09:17:00 -0400
tags: [ai, agents, skills, memory]
categories: [technology]
description: "Google's WikiSkill separates agent experience, accumulated knowledge, and executable skills. The result suggests that the next useful upgrade to an agent may be less about a larger model than a better way to remember what its work has taught it."
---
If you maintain a library of skills for AI agents, there is a fairly mundane problem hiding inside it. The skill files can tell an agent what to do, and Git can tell you how those files changed. Neither necessarily tells the next agent *why* a particular instruction ended up there.

That history tends to be scattered through execution traces, failed attempts, optimizer logs, benchmark results, and conversations. A useful lesson gets discovered, turned into a skill edit, and then partly disappears into the edit itself. If the edit doesn't work and gets rolled back, the lesson can disappear almost completely.

A new paper from Google Research and Virginia Tech, [*WikiSkill: Compiling Agent Experience into Persistent Knowledge for Skill Evolution*](https://arxiv.org/abs/2608.27454), proposes a surprisingly straightforward fix: give the agents a wiki.

Not Wikipedia, obviously. WikiSkill adds a persistent layer of structured knowledge between an agent's raw experience and the executable skills it uses to do work. That extra layer turns out to do quite a lot.

## Three kinds of memory

Most skill-evolution systems follow roughly the same loop. An agent attempts tasks, the system inspects what went right and wrong, proposes changes to its skills, tests those changes, and keeps the ones that improve performance. The researchers argue that this process tends to blur together three different artifacts that should remain separate.

The first is **raw experience**: the actual execution traces containing the agent's reasoning, tool calls, outputs, failures, and successes. WikiSkill keeps these immutable. They are the record of what happened.

The second is **accumulated knowledge**. This is the wiki. A maintainer agent studies the traces and turns them into structured Markdown pages describing recurring failure modes, successful strategies, workarounds, prior skill proposals, and whether those proposals actually helped. The wiki persists across iterations and is continuously revised as more evidence arrives.

The third is **executable skill**: the concise procedural instructions the working agent actually receives. Each skill also carries a link back to the wiki patterns that motivated it.

That separation feels obvious once you see it. A log is not knowledge, and knowledge is not an instruction. We already make similar distinctions when humans build complicated systems. There are telemetry and incident logs, documentation explaining what the team has learned, and production code that embodies some subset of those lessons. Trying to make one artifact perform all three jobs usually leaves each job a little worse.

WikiSkill gives each layer a different lifecycle. Raw traces are preserved. Knowledge accumulates. Skills can change or even be rolled back.

The last part is especially clever. A proposed skill update is tested on a validation set. If it makes the agent worse, the skill change is discarded. The wiki is not. It keeps a record of the proposal, the evidence behind it, and the fact that it failed. A later agent can therefore learn from an unsuccessful intervention without having to keep executing the unsuccessful instruction.

Failure becomes part of the institutional memory rather than clutter in an optimization log.

## The wiki seems to be doing real work

The researchers tested WikiSkill across five rather different benchmarks: mathematical reasoning, web search, spreadsheet manipulation, long-document question answering, and interactive embodied tasks. They used models from the Qwen, Gemma, and Gemini families and compared WikiSkill with several other approaches to automatically evolving skills.

Across the five models, WikiSkill produced the best average performance. But the cleaner result comes from the ablation study, where the researchers removed the persistent knowledge layer while leaving the general skill-evolution process intact.

With Gemini 3.5 Flash, allowing the skill proposer to use the accumulated wiki raised average performance across four benchmarks from **48.7% to 63.7%**. On LiveMath it went from 51.3% to 72.6%; on SpreadsheetBench, from 49.9% to 76.6%. The system was not merely getting better because it had another round of prompt editing. Much of the improvement came from giving the editor an organized memory of what previous rounds had discovered.

There is an amusing wrinkle here. Giving the *working* agent access to the wiki during training actually made the final skills worse. The researchers think the agent could solve some problems by consulting the wiki directly, which produced less informative failures and therefore poorer training material. The better arrangement was asymmetric: let the agent work from its skills, let it fail naturally, and let the agents responsible for learning study the larger body of accumulated knowledge.

The wiki is a workshop manual, not something that needs to be stuffed into every worker's head.

## Skills can substitute for a surprising amount of scale

The model-scaling results are probably the easiest part of the paper to notice. Within the Qwen family, larger models got *more* benefit from evolved skills, not less. WikiSkill improved average performance by 12.3 points for the 4B model, 17.5 points for the 9B model, and 23.9 points for the 27B model. Better models appear to be better at making use of good procedural knowledge.

But good procedural knowledge can also compensate for a lot of model size. Qwen 3.5 9B with WikiSkill averaged **47.4%**, while the much larger Qwen 3.6 27B without skills averaged **39.4%**.

That is a useful result for anyone building agents because model choice is only one place capability can live. Some of it can live in the model. Some can live in tools. Some can live in the surrounding workflow. And some can apparently live in a collection of well-evolved Markdown files.

The practical comparison is therefore not always "which model is smartest?" It may be "which system knows how to do this job?" A smaller model arriving with a good operating manual can beat a larger model arriving on its first day.

This also changes the economics a little. If procedural knowledge can be accumulated outside model weights, organizations don't have to repurchase all of their learned competence every time they change models. The expensive part of an agent system may gradually become less like buying intelligence and more like building institutional knowledge around intelligence.

## The skills don't belong to the model

The cross-model experiments push that idea further. Skills evolved by one model often worked when handed to another model, including models from different families. Sometimes the imported skill worked better than the skill the receiving model had evolved for itself.

On ALFWorld, for example, Qwen 3.5 9B scored 63.4% using its own evolved skill but **70.2%** using a skill evolved by Qwen 3.6 27B. On LiveMath, skills evolved by the small Qwen 3.5 4B model raised Gemma 4 31B from 33.9% without skills to **73.1%**, beating Gemma's 56.7% with its own evolved skills.

The transfers aren't universally good. A spreadsheet skill evolved by Qwen 3.5 4B badly hurt Gemini 3.5 Flash because it contained low-level workarounds useful to the smaller model but restrictive for the stronger one. That failure is almost as informative as the successes. A skill can contain general knowledge about a task, or it can contain a workaround for the peculiar weaknesses of the agent that wrote it.

Still, the successful transfers suggest a useful separation between *discovering* a good procedure and *executing* it. The model that figures out how to do something doesn't necessarily have to be the model that later does it.

That makes a shared skill library start to look less like a folder of prompts and more like a portable layer of organizational capability. A strong model could be used to discover and refine procedures, while cheaper models execute them at scale. Or several different models could contribute lessons to the same body of knowledge and inherit procedures discovered by the others.

## A skill library needs more than skills

I've tended to think about agent improvement in terms of the executable artifact: make a `SKILL.md`, use it, notice a problem, edit it, repeat. WikiSkill makes me think that this leaves out the most valuable artifact created by the process.

Every time an agent fails, someone learns something. Every time a workaround succeeds, there is a reason it succeeded. Every rejected skill edit contains information about what *didn't* generalize. If all of that gets compressed immediately into the current version of the skill, the system remembers the answer while gradually forgetting the argument that produced it.

Humans have run into this problem before. Mature organizations accumulate more than procedures. They accumulate design documents, incident reports, case law, laboratory notebooks, maintenance records, recipes with scribbled corrections, and old hands who remember why the strange rule exists. The procedure is useful because a much larger body of experience sits behind it.

WikiSkill is an early research system, tested on benchmarks rather than a years-old production agent fleet. Its wiki is maintained by models, and long-running knowledge bases will eventually face the familiar human problems of stale documentation, contradictory lessons, bad abstractions, and accumulated junk. The paper doesn't make those problems disappear.

But I like the architecture because it gives those problems somewhere sensible to live. Keep the traces as evidence. Compile repeated experience into knowledge. Compile the best current knowledge into skills. Test the skills. Keep learning even when a particular edit fails.

If agent skills become as common as they currently appear likely to, I suspect the most useful skill libraries won't just be libraries. They'll have a memory behind them.