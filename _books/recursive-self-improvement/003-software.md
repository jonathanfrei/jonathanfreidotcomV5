---
title: "Lessons That Execute"
deck: "How software turns past failures into safeguards for future changes"
eyebrow: "Software"
---

A developer changes six lines of code and opens a pull request. Before another person reads it, software formats the change, compiles it, runs thousands of tests, checks for familiar security mistakes, and builds a disposable copy of the application. The proposed future has already been compared with a long record of what the team learned to fear.

Software makes recursive improvement unusually visible because its feedback loops can be written down. Code produces behavior; tests evaluate it; review and telemetry reveal defects; new code and new checks preserve the lesson. When a failure changes the machinery that catches future failures, the loop has turned inward.
{: .lede}

![Green and blue source code displayed on a monitor](https://images.unsplash.com/photo-1753998943413-8cba1b923c0e?ixlib=rb-4.1.0&q=85&fm=jpg&crop=entropy&cs=srgb&w=1600)
{: .figure-wide}

**The engineered loop.** Software can encode both behavior and the rules used to judge changes in behavior. *[Photo by Rob Wingate on Unsplash](https://unsplash.com/photos/4s6QFMyHKa0?utm_source=jonathanfrei.com&utm_medium=referral)*
{: .caption}

## Lessons that execute

An automated test is a peculiar kind of institutional memory. It doesn't merely record that a payment calculation once failed at midnight on leap day. It recreates the condition and refuses future code that brings the failure back. A linter preserves a style or safety decision. A deployment check preserves an operational lesson. Observability turns production behavior into evidence that can inform the next change.

Continuous integration shortens the distance between action and evaluation. Martin Fowler's account of [continuous integration](https://martinfowler.com/articles/continuousIntegration.html) describes frequent integration, automated builds, self-testing code, and rapid feedback. The speed matters because delayed feedback is easier to ignore and harder to connect with its cause. Yet speed alone isn't recursive. The system becomes more capable of improvement when escaped defects add tests, flaky tests provoke better test design, and deployment failures strengthen the delivery process.

> A good software process doesn't merely remember what happened. Some of its memories can run.
{: .pull-quote}

The layers form a ladder. A developer fixes code. The team improves tests and review. It then improves how tests are selected, how risky changes are identified, or how production evidence becomes a new experiment. Tools can even propose repairs. Each layer turns part of the previous improvement mechanism into an object that can be inspected and changed.

## When memory becomes machinery

This apparent cleanliness is deceptive. Tests encode expectations, not truth. A passing suite proves only that the checked behaviors matched their specified results. Important cases may be absent, and a mistaken expectation can be preserved with impressive consistency. Static analysis can produce enough noise that developers learn to dismiss it. Telemetry can optimize what is easy to count while overlooking what users actually experience.

Automation also adds machinery. A test suite can become slow and brittle. A delivery pipeline can accumulate checks whose original purpose nobody remembers. Engineers then spend their time satisfying the improvement system rather than improving the product. The recursive loop has created a new surface that needs maintenance, evaluation, and sometimes removal.

**The deletion test**: An improvement mechanism should be able to lose obsolete parts. A process that only accumulates checks and never retires them is learning without forgetting, which eventually looks a lot like bureaucracy.
{: .aside}

The most reliable software loops therefore preserve human judgment and reversibility. Small changes are easier to review. Version control keeps history. Feature flags and staged deployments limit the cost of a mistaken assumption. Monitoring makes consequences visible, while rollback keeps one bad iteration from becoming permanent.

Software gives us the most legible version of the loop. We can inspect the test, trace the build, compare versions, and undo a commit. That visibility is easy to take for granted. People carry their rules in habits, memories, loyalties, and fears that cannot be opened in a text editor. The next step is therefore less tidy: a person can change the way she learns, but she is also the observer deciding whether the change worked.
