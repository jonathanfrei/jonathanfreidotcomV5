---
title: Can a System Safely Improve Itself?
---

A team testing new flight-control software does not begin by handing it an aircraft full of passengers and hoping the feedback is educational. It uses simulation, constrained test ranges, independent checks, staged authority, and procedures for returning to a known state. The system may be designed to adapt, but the conditions of adaptation are designed too.

Safe recursive improvement is not one feature added after capability. It is a structure around objectives, evidence, authority, observation, and recovery. The faster or more autonomous the loop becomes, the less room there is to improvise those protections after a mistake.
{: .lede}

![A combination lock resting on a laptop keyboard](https://images.unsplash.com/photo-1768839720936-87ce3adf2d08?ixlib=rb-4.1.0&q=85&fm=jpg&crop=entropy&cs=srgb&w=1600)
{: .figure-wide}

**Authority should be bounded.** A system's ability to modify itself need not include permission to modify everything it can reach. *[Photo by Sasun Bughdaryan on Unsplash](https://unsplash.com/photos/WUJmdr8pNwk?utm_source=jonathanfrei.com&utm_medium=referral)*
{: .caption}

## Seven conditions

**A bounded objective.** The system needs a purpose specific enough to guide action and humble enough not to pretend that one score contains every good. Hard constraints can protect values that shouldn't be traded for marginal performance.

**Several kinds of evidence.** A single metric invites blindness and gaming. Outcome measures, process checks, qualitative reports, adversarial tests, and independent review reveal different failures. Disagreement among them is information, not merely inconvenience.

**Limited authority.** The ability to propose a change is different from the authority to deploy it. Systems can be allowed to modify a sandbox, a narrow component, or a reversible configuration without receiving control over credentials, evaluators, and production data.

**Observability.** Operators need to know what changed, why it changed, and what happened afterward. NIST's [AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework) organizes risk work around governing, mapping, measuring, and managing. The details vary by domain, but invisible improvement is hard to supervise anywhere.

**Reversibility.** Versioned rules, rollback, backups, staged deployment, and preserved baselines keep an experiment from erasing the last known good state. Some changes—constitutional, ecological, reputational—cannot be cleanly undone, so they demand slower thresholds.

**Independent correction.** The system being evaluated should not control every evaluator. Human review, separated duties, external audits, competing models, and avenues for affected people to object prevent one loop from becoming its own judge.

**A controlled rate.** Improvement must move slowly enough for consequences to appear. More speed can reduce the evidence available between iterations and allow a small mistaken assumption to compound.

> A safe system can learn, but it cannot quietly redefine success, hide the evidence, and grant itself more power in the same motion.
{: .pull-quote}

## Safety is a property of the whole

Software contributes tests and rollback. Individual practice contributes reflection and trusted correction. Organizations contribute governance and institutional memory. Markets show the value of distributed information and the danger of treating price as a moral verdict. Politics shows why rule changes need legitimacy and durable constraints. Evolution shows what powerful adaptation looks like without a final objective. Competition shows that another optimizer can turn a stable plan into an arms race.

No checklist can make every self-modifying system safe. Unknown environments produce unknown failures, and human overseers have their own blind spots and incentives. The right question is often not whether a system is “safe” in the abstract, but safe to change which component, with what evidence, under whose authority, at what speed, and with what path back.

**Keep the right to stop**: Oversight is meaningful only if someone can pause the loop before the system's next improvement removes the opportunity.
{: .aside}

Recursive improvement deserves neither automatic fear nor automatic trust. It can preserve lessons, widen human agency, and make difficult work steadily more reliable. It can also compound a bad objective or outrun the people living with its consequences. Safety begins by refusing to place every part of improvement inside one unchecked loop.
