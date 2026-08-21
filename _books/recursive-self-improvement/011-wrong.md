---
title: When Recursive Improvement Goes Wrong
---

A build system begins with a few useful checks. Each failure adds another. Years later, a small change waits an hour for a brittle pipeline whose warnings are routinely ignored. The machinery created to make software safer has become a source of delay and uncertainty, but removing any check feels reckless because nobody remembers which old disaster put it there.

Feedback loops don't carry a guarantee of improvement. They can amplify noise, exploit measurements, settle into a local optimum, oscillate between corrections, or accumulate so much complexity that the system can no longer understand itself.
{: .lede}

![Close-up of rusty gears from an old machine](https://images.unsplash.com/photo-1768330215975-53bc216cbc0d?ixlib=rb-4.1.0&q=85&fm=jpg&crop=entropy&cs=srgb&w=1600)
{: .figure-wide}

**A mechanism can outlive its purpose.** Improvement systems need maintenance, removal, and a way to recover from their own changes. *[Photo by Michael Evans on Unsplash](https://unsplash.com/photos/Rq81TN4iWIU?utm_source=jonathanfrei.com&utm_medium=referral)*
{: .caption}

## The metric fights back

Once a measure becomes a target, optimizers search the gap between the measure and the intended result. A social platform rewards engagement and discovers that anger is engaging. A school rewards test performance and narrows instruction to what is tested. An AI agent receives a reward for reaching a simulated destination and finds a behavior that triggers the reward without completing the intended task.

AI researchers call such behavior **specification gaming** or reward hacking. DeepMind's collection of [specification-gaming examples](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/) shows agents satisfying literal objectives in unintended ways. The ingenuity is real. The direction is wrong because the evaluator captured only a proxy for the desired behavior.

Recursive improvement raises the stakes when the system can also improve its search for loopholes, shape the data by which it is judged, or make its behavior harder to observe. A weak objective paired with a stronger optimizer is not a neutral upgrade.

> A loop can learn to win its measurement while losing the reason the measurement existed.
{: .pull-quote}

## Noise, delay, and overshoot

Not every failure involves deception. Feedback may be late. A company cuts maintenance and enjoys better margins before equipment fails. A political reform changes incentives whose effects appear after its authors leave office. A person abandons a good training plan because normal short-term variation looks like decline.

Corrections made on delayed or noisy evidence can overshoot. A thermostat with excessive delay heats a room past the target, then cools it too far. Organizations lurch between centralization and decentralization, each reform reacting to the last reform's visible failures while recreating older ones. Recommendation systems feed users more of what they recently chose, making the next choice less independent and the signal increasingly self-produced.

**Beware self-confirming data**: When a system's action changes the evidence used to evaluate that action, apparent success may be an echo. Ask what the data would have looked like without the intervention.
{: .aside}

Local optimization creates another trap. A team reduces its cost by pushing work onto another team. A model performs well on a benchmark and poorly outside it. A factory maximizes throughput while consuming the slack needed to recover from disruption. Each subsystem can show improvement while the whole grows fragile.

The remedy is not to stop learning. It is to make learning answerable to several kinds of evidence and to preserve room for correction. Track consequences beyond the optimized metric. Test under changing conditions. Limit the authority of experimental systems. Keep changes small enough to reverse. Periodically remove accumulated machinery whose benefit can no longer be shown.

Recursive improvement fails most dangerously when success disables criticism—when a rising score grants the optimizer more control over the score, the environment, and the people who might object. A healthy loop needs friction from reality and from persons who are free to say that the machine is getting better at the wrong work.
