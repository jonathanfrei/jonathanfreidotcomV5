---
title: Getting Better vs. Getting Better at Getting Better
---

A recurring bug is a small test of a software team's honesty. The quickest response is to patch it again. A better response adds a regression test. A deeper response asks why escaped defects don't reliably strengthen the test suite, then changes the incident process so each suitable failure leaves behind a new check. The team has moved from repairing an output to changing how it learns from repair.

The difference between getting better and getting better at getting better isn't repetition. It is whether an improvement alters the mechanism that finds, evaluates, or applies later improvements.
{: .lede}

![Computer code on a laptop screen](https://images.unsplash.com/photo-1515879218367-8466d910aaa4?ixlib=rb-4.1.0&q=85&fm=jpg&crop=entropy&cs=srgb&w=1600)
{: .figure-wide}

**Code can preserve a lesson.** A fix changes today's behavior; a test can change tomorrow's development process. *[Photo by Chris Ried on Unsplash](https://unsplash.com/photos/ieic5Tq8YMk?utm_source=jonathanfrei.com&utm_medium=referral)*
{: .caption}

## Three kinds of better

Start with the result. A pianist plays a passage correctly, a factory produces a sound part, or a model answers a question accurately. Each is a better output. If the pianist changes her fingering, the factory recalibrates a machine, or the model updates its parameters, the behavior producing the output has changed too.

The third level concerns how those behavioral changes are found. The pianist records practice sessions and uses recurring errors to choose exercises. The factory redesigns quality control so defects identify which calibration procedure needs attention. The learning system changes the way it selects examples or updates itself. The mechanism of improvement has entered the improvement process.

Researchers use **meta-learning** for one technical family of this idea. In [Chelsea Finn, Pieter Abbeel, and Sergey Levine's MAML paper](https://proceedings.mlr.press/v70/finn17a.html), a model is trained across tasks so it can adapt to a new task with only a small amount of new data. It isn't simply learning one classification. Its earlier training shapes how readily it can learn later ones. Meta-learning and recursive self-improvement aren't synonyms, but the research makes the distinction between performance and the capacity to improve unusually clear.

## Repetition is cheap

A process can run thousands of times without changing itself. A thermostat cycles. A test suite runs on every commit. A person repeats the same workout every Monday. Feedback arrives in all three cases, but the governing method may remain fixed.

> Better result → better behavior → better improvement process
>
> The arrows represent changes that must actually occur, not an automatic ladder.
{: .pull-quote}

Feedback becomes learning when it changes later behavior. Learning approaches recursive improvement when it changes how later learning happens. This is why a larger score alone tells us so little. Performance may rise because the task became easier, because more resources were spent, or because the system memorized a narrow case. None of those outcomes necessarily makes it a better optimizer elsewhere.

## The human and organizational versions

A student can correct a missed problem and move on. She can also sort errors by type, discover that rereading creates false confidence, and replace it with retrieval practice. The second response changes knowledge; the third changes how knowledge is acquired. The person remains a noisy evaluator—fatigue, pride, and anxiety still distort the signal—but the structure is recognizably recursive.

Organizations face the same choice at larger scale. Chris Argyris called ordinary correction within existing assumptions **single-loop learning** and the questioning of governing assumptions **double-loop learning** in his classic essay on [learning in organizations](https://hbr.org/1977/09/double-loop-learning-in-organizations). A sales team can work harder to hit a target, or ask whether the target rewards the wrong customers. A postmortem can assign an action item, or change how the company notices and discusses risk.

There is no guarantee that the deeper loop is better. Retrospectives can become meetings that protect the process from criticism. Metrics for learning can reward visible activity instead of insight. A method that constantly revises itself may lose the stability needed to tell whether any revision worked.

A practical test helps: after the improvement, what part of the system will behave differently the next time it tries to improve? If only the current result changed, it got better. If its way of finding or judging changes also changed, it may have become better at getting better. The final judgment still depends on who defines “better,” and whether the evidence arrives soon enough to correct a mistake.
