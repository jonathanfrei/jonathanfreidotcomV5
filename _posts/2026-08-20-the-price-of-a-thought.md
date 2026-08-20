---
title: "The Price of a Thought"
date: 2026-08-20 06:05:00 -0400
tags: [AI, inference, infrastructure, economics]
categories: [technology]
description: "AI models get the attention, but inference engineering is building the infrastructure that can make useful machine intelligence cheap enough to become ordinary."
---

For most of human history, if you wanted another useful thought, you needed another person or more of someone's time. A calculation needed a mathematician. A translation needed someone who knew both languages. A legal opinion needed a lawyer. A drawing needed a draftsman. Even after computers arrived, most of the judgment surrounding computation still came from people.

We now have machines that can produce a growing range of this work. I [wrote recently about what happens when intelligence becomes cheap](https://jonathanfrei.com/2026/08/15/when-intelligence-is-cheap), and especially what that might do to the excuses we make when knowledge and competent advice are no longer particularly scarce. But there is a more basic question underneath that one: what actually makes intelligence cheap?

The obvious answer is better AI models. I don't think that's quite right. Training makes a model capable. Something else has to make that capability cheap enough, fast enough, and reliable enough that we can use it casually.

Philip Kiely's *Inference Engineering* is largely about that something else.

[Inference](https://learn-inference.com/chapters/inference/two-phases) is what happens after a model has been trained, when someone actually asks it to do some work. Training is a project with a beginning and an end. Inference is an operation that can continue for as long as anyone wants to use the model. In fact, success makes the problem harder. A popular AI product creates more inference demand and therefore a larger bill.

That bill is surprisingly physical.

A large language model generates text one token at a time. During the generation phase, the limiting factor is often not how quickly the GPU can perform arithmetic but how quickly it can move the model's weights through memory. Kiely uses the example of a 70-billion-parameter model represented in 16-bit values. Its weights alone occupy roughly 140 gigabytes. At a batch size of one, generating a token can mean moving something on that order through memory so the machine can produce a tiny addition to the sentence on your screen.

The answer feels almost weightless. Underneath it are racks of accelerators moving a great deal of data, consuming electricity, producing heat, occupying data centers, and tying up some very expensive capital equipment.

This makes the phrase "the price of a thought" less metaphorical than it first sounds. A token isn't a thought, of course, and none of this requires taking a position on whether a machine thinks in the human sense. But an answer, translation, summary, classification, design, or plan now has a measurable computational cost. A growing class of cognitive work can be bought in units.

And engineers are steadily trying to make those units cheaper.

One way is batching. If the expensive part of generating a token is moving model weights through memory, it makes sense to use that movement to serve several requests at once. Another is quantization, which represents the model with fewer bits so there is simply less data to move. Caching avoids recomputing parts of a request the system has already seen. Speculative decoding lets a smaller, cheaper model guess several upcoming tokens and asks the larger model to verify them together rather than doing all the work serially.

These techniques sound like fairly obscure computer engineering, and in one sense they are. But taken together they are doing something economically familiar: getting more useful output from scarce capital.

There is no magic in it. Each optimization trades one scarce resource for another. More batching can improve throughput while making an individual request wait. Quantization can reduce memory use while risking some loss of quality. Caches consume memory of their own and are only valuable when the right requests return to the machines holding them. Speculation saves time only when the cheaper model guesses well enough to justify its own cost. *Inference Engineering* treats these as exchanges among memory, compute, latency, quality, and operational complexity. Engineers are looking for better exchange rates.

Something similar happened with electricity.

The spectacular part of early electrification was generating electricity at all. Edison opened the Pearl Street Station in Manhattan in 1882, but direct-current power could initially be delivered only a short distance from the station. By 1900 the United States had more than 3,000 central service stations, while alternating current and higher-voltage transmission were allowing power to travel much farther. In 1922, a 220-kilovolt line in California carried power more than 200 miles from the Sierra Nevada toward the San Francisco Bay Area. [The history of the early electricity industry](https://www.nber.org/papers/w22254) is partly a history of learning how to separate where power was generated from where it could economically be used.

The generator was an invention. The grid was a system.

Transmission lines, distribution networks, interconnected generating stations, spare capacity, standards, load balancing, and eventually a wall socket turned an impressive machine into an ordinary part of life. The economic effects followed the spread of the system. Research on American manufacturing from 1890 to 1940 finds [rapid and persistent productivity gains from electrification](https://www.nber.org/papers/w28076), accompanied by investment and changes in how factories were organized. Other research finds that the expansion of high-voltage transmission between 1910 and 1940 [helped drive the shift of American employment from agriculture toward manufacturing](https://www.nber.org/papers/w26477).

Factories didn't simply replace a steam engine with an electric motor and carry on as before. Electricity eventually allowed individual machines to have their own motors. Factory floors could be rearranged around the work instead of around shafts, belts, and a central source of mechanical power. The technology became more valuable as people reorganized other things around its abundance.

I think AI is beginning to acquire its own version of this surrounding machinery.

The comparison shouldn't be pushed too literally. GPUs aren't power plants and tokens aren't kilowatt-hours. But the structural problem looks familiar. We have learned how to produce a valuable resource and are now building systems for delivering it under unpredictable demand while trying to keep cost down and reliability up.

At small scale, this looks like software optimization. At larger scale it starts to look like infrastructure economics.

A company serving AI has to decide how many expensive GPUs to keep running while nobody is asking for them. Turning them off saves money, but starting a large model again can take long enough that the next user is left waiting. Keeping them running buys readiness. Autoscaling is partly the art of deciding how much readiness is worth paying for.

At still larger scales, the abstraction breaks down further. Kiely notes that once a deployment needs hundreds of GPUs, the problem can become less about whether the software knows how to scale and more about where the physical GPUs are actually available. Capacity exists in particular data centers, regions, and clouds. Network latency makes geography relevant. Suddenly the seemingly immaterial business of producing words has some of the same concerns as other infrastructure: capacity planning, utilization, redundancy, routing, and location.

This suggests another way to think about AI progress.

Most of our attention goes to the frontier: which model scores highest, has the largest context window, or can solve the hardest problem. Those advances are real. But there is another curve underneath them that may ultimately be just as consequential: how much useful cognition can a dollar buy?

Economic historians often describe electricity and information technology as general-purpose technologies because their effects spread through many industries rather than remaining confined to the business that invented them. [Research comparing the two](https://www.nber.org/papers/w11093) notes both the broad adoption of electricity and the continuing decline in the price of information technology. Neither became transformative simply because the best available machine got better. They became transformative because useful capability became cheap and available enough to put almost everywhere.

The same possibility is easy to imagine with inference. A model becoming somewhat smarter can improve the tasks we already give it. Making the same useful model ten times cheaper changes how often we are willing to call it. Software can ask for a classification that wasn't worth paying for before. An agent can inspect ten possible approaches instead of one. A small company can afford a capability that previously required a large budget. Intelligence starts appearing in products where nobody would have bothered rationing expensive model calls.

There is a catch familiar from almost every efficiency improvement: cheaper units don't necessarily mean we consume less in total. They often mean we find reasons to consume far more. Better inference could reduce the cost of a given AI workload while increasing the amount of inference civilization performs. The likely future isn't necessarily a smaller collection of GPU data centers doing today's work more efficiently. It may be much larger infrastructure doing kinds and quantities of cognitive work that aren't economical today.

That is another reason the grid analogy seems useful to me. We didn't respond to cheaper, more available electricity by deciding we had enough light bulbs. We built refrigerators, air conditioners, elevators, washing machines, factories, computers, and eventually data centers. Abundant electricity created uses for electricity.

Inference engineering is still a young discipline, and machine intelligence remains constrained by chips, memory, energy, networks, capital, geography, and the quality of the models themselves. There is no reason to assume the price falls smoothly or reaches zero.

But I suspect some of the biggest changes in AI will arrive without a dramatic new model at all. They will come from making yesterday's remarkable capability cheap enough that tomorrow nobody thinks very hard before using it again.

Electricity became part of ordinary life when most of us stopped thinking about the power plant. Machine intelligence may reach a similar point when asking for one more small piece of cognitive work feels just as unremarkable.
