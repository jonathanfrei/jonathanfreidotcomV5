---
title: "A Computer with a Signature"
date: 2026-08-14 20:00:00 -0400
tags: [omarchy, linux, dhh, taste, personal-computing]
categories: [technology]
description: "Omarchy Quattro is DHH shipping a whole working environment with his name on the defaults, and leaving the files where you can still argue with them."
---

On Friday, David Heinemeier Hansson shipped [Omarchy](https://omarchy.org/) 4.0, called it Quattro, and said it was one of the greatest software releases of his professional career. That is a large sentence from a man who already wrote Ruby on Rails. The launch video is an hour and a half. He posted a forty-five-second install on a fast AMD machine and thanked a long list of other people, including the authors of [Hyprland](https://hypr.land/) and [Quickshell](https://quickshell.org/), before ending the thread the way he meant it: computers should be fun.

https://x.com/dhh/status/2088304854603047019

I have not installed it. What follows is a reading of a release, a doctrine, and the noise a signed desktop still makes in a culture that prefers its operating systems to arrive without a name on them.

## A chef's Linux

Omarchy is DHH's omakase environment on [Arch Linux](https://archlinux.org/). The name is the joke and the method: chef's choice, plus Arch. It began as a follow-on to [Omakub](https://omakub.org/), the Ubuntu setup he published in 2024 after [37signals dropped the Mac as its exclusive default](https://world.hey.com/dhh/linux-as-the-new-developer-default-at-37signals-ef0823b7). In June 2025 he [called Omarchy a love letter to Linux](https://world.hey.com/dhh/omarchy-is-out-4666dd31) and "the same setup that I now run every day." By August it had an ISO. By this week it has a shell of its own.

The [welcome page](https://omarchy.org/manual/) is unusually honest about the contents. Neovim, Chromium, Obsidian, LibreOffice, Kdenlive, OBS, a retro music player. "Zero bloat: Just everything I use." A beautiful system, he writes, is a motivating system, and productivity has always been [downstream from motivation](https://world.hey.com/dhh/beautiful-motivations-6fef7c73). He is not trying to look like Windows or macOS. He wants the Linux-ness: terminals, tiling windows, config files, a [manual](https://omarchy.org/manual/) you are expected to read.

The mouse made computers discoverable. Omarchy is willing to charge a learning tax in exchange for speed. Super replaces Command. Super-Space is Spotlight without the store. Windows tile instead of overlapping. Copy and paste use the same keys in the terminal as everywhere else, which is a small mercy if you have ever killed a process by trying to copy from one. The manual tells people coming from a Mac or a PC to give it two weeks and to memorize one hotkey, the one that shows all the others.

I cannot tell you whether two weeks is enough. I can tell you what kind of claim that is. A computer is being offered as a discipline, not as a skin.

## The garden, the parts bin, and the menu

The last fifteen years of personal computing offered two mature answers, and both have started to smell.

Apple will decide. The machine is integrated, often beautiful, and increasingly leased. You get taste with a landlord. Microsoft will also decide, more loudly, with more advertising, and with a security model designed for a company that would rather you never turned Secure Boot off. Classic Linux will refuse to decide. You own every ingredient and enjoy nothing until you have spent a weekend configuring a bar.

[Omakase computing](https://learn.omacom.io/3/omacom/76/omakase-computing), as DHH names it, is the third answer, and it is the same answer [Rails gave web developers](https://rubyonrails.org/doctrine#omakase) twenty years ago. How do you know what to order when you do not yet know what is good? Let the chef choose. Substitutions remain possible. Starting from a blank page is not required. "Most people don't actually know what they want, at least not at first." That sentence will offend people who built their identity on configuring everything. It will also sound like relief to anyone who has opened the Arch wiki at midnight and felt the paradox of choice arrive as a kind of fatigue.

The [Omacom doctrine](https://learn.omacom.io/3/omacom/81/doctrine) is the part worth sitting with, even if you never boot the ISO. Defaults over decisions: a default is a benchmark you can later beat. Tasteful, not over-the-top: beauty is a human yearning, and the old Linux piety that ugly is honest was always a superstition. Keyboard before mouse. Pragmatic commercialism: Spotify and 1Password sit next to Kdenlive and OBS, because the project is not a purity test. Newer is not better; better is better. And then the line that explains why this thing looks the way it does: let Linux be Linux. Hard corners, monospace, terminal interfaces, no Liquid Glass impersonation.

A computer trains the person who uses it. The consumer desktop of the last decade trained people to click, subscribe, and remain inside someone else's store. A keyboard-first tiling environment trains a different set of habits: attention, repetition, the slightly severe pleasure of a room arranged on purpose. That is older than Linux. Workshops look like the work they are for. Kitchens do too.

## When a daily driver becomes a system

For most of its first year, the fairest description of Omarchy was the one its skeptics used. It was Arch plus DHH's daily driver, bottled: a post-install script, a personalized desktop with a marketing site. In May 2026, [jes argued](https://abyss.fish/your_dotfiles_are_not_a_distro) that the whole thing should probably have been a few gists, and that installing it meant installing "a huge glut of DHH's personal preferences." The exhibit was specific: hotkeys that opened Grok, the HEY calendar, and the X compose box. Those are not the defaults of a nameless committee. They are a fingerprint.

The fingerprint is the point. It is also the risk. If you wanted a Linux that pretended nobody had taste, this was never going to be your distribution. If you wanted a Linux that admitted someone did, the HEY keybind is almost too perfect. You can delete it. That is the test of whether omakase is a menu or a cult.

Quattro is the first release that makes the "just dotfiles" description feel dated. The [changelog](https://github.com/basecamp/omarchy/releases/tag/v4.0.0) is enormous, and most of it does not belong in an essay. Four changes do.

The desktop shell was rewritten in Quickshell. The bar, the launcher, the menus, the notifications, the on-screen displays, the lock screen, and the polkit prompt now live in one long-running process. Waybar, Walker, Mako, and a handful of other familiar names are gone. Theme is no longer a set of files pretending seven programs are one product.

The internals moved from a git checkout in the user's home directory to system packages. DHH had already said the old arrangement was a core source of instability. Updates now go through pacman. That does not settle every security argument that followed the project onto Framework laptops last fall. It does mean the project finally accepted a distinction Linux veterans have been shouting at it: user configuration and system software are not the same kind of thing.

You can install the machine for someone else. The ISO can finish with no owner. On first boot the person who actually received the computer picks a keyboard, an account, and a password, and that password becomes the disk encryption. Later, a factory reset returns the machine to that unused state. A personal setup you can only maintain yourself is a hobby. A computer you can hand to a colleague, a student, or a family member is a different object.

Coding agents are furniture. You pick Claude Code, Codex, Grok, Gemini, Copilot, or one of several others the way you pick a browser. A hotkey launches it. A crash can raise a toast that briefs the agent. The desktop is being rearranged around a person who works with a model in the next pane. That will date faster than the tiling. It is still a tell: the author is designing for the desk he actually sits at in 2026, not the desk he remembers from 2006.

They also wrote three tiny Qt apps — a Markdown editor, a video trimmer, a calculator — rather than living forever on other people's defaults. Authors make the missing pieces.

https://www.youtube.com/watch?v=F7fe9pa8OeE

## The reaction

The tech world's response has been less about package management than about recognition. People who have spent a decade half-joking about the Year of the Linux Desktop recognized a feeling they had misplaced.

[Andrej Karpathy](https://www.threads.com/@karpathy/post/DUvoZlRFOHW), in February, called it fully owned, hackable, beautiful, keyboard-heavy, and TUI-focused, and then admitted the side quest: a Framework 13 and Omarchy on it. [Jorge Manrubia](https://x.com/jorgemanru), a principal programmer at 37signals, had resisted Omakub and did not think Omarchy was for him. After the company made it the default, he wrote that it "clicked surprisingly HARD," that he had forgotten what it was like to be hyped about an OS version, and that if you thought Apple had fantastic taste you should prepare to notice how little of that taste was in the desktop.

https://x.com/jorgemanru/status/2085371786409980026

Tobi Lütke spent the week before launch shipping a screenshot tool into the release, which is a more useful form of praise than a quote tweet.

https://x.com/tobi/status/2086997507855331434

On [Hacker News](https://news.ycombinator.com/item?id=45001434) last year, when 2.0 arrived, one longtime Linux user wrote that DHH had "tapped into an enthusiasm for Linux I haven't felt in a long time." Another said the world needs people who follow the blog post with the work. A third tried it, went back to Plasma, and still thought the project was doing something the friendly distros had failed to do: making a power-user setup look like a product.

The mockery has been just as revealing. [Jason Fried](https://x.com/jasonfried/status/1941174397752201626) needled his partner as an Apple superfan who would not listen. Framework's account, in October, posted that Omarchy was the new Windows XP product key, which is a compliment if you remember what that string meant and an irritation if you think a laptop company should not have a favorite desktop. Both jokes assume the same fact. This thing has a face.

37signals has now said the quiet part on a podcast. Omarchy is a 37signals Linux distribution the way Rails is a 37signals web framework. The operations and Ruby teams are supposed to be on it by 2028, with exceptions for people who cannot make the jump. That is a serious test. A chef's menu that a company will actually eat is different from a chef's menu that only the chef eats on stage.

## Weather

Linux has a long habit of treating a signature as a defect. A proper distribution, in that telling, is a committee, a foundation, a set of packages without a face. Omarchy has a face. DHH has spent twenty years being loud, and the last few years being louder about politics than a lot of the free-software world prefers. Hyprland's lead developer was banned from freedesktop.org after a fight over community moderation. When Framework sponsored Hyprland and kept boosting Omarchy, the company's forum opened a thread titled "Framework supporting far-right racists?" Nirav Patel said Framework runs a [big tent](https://itsfoss.com/news/framework-hyprland-sponsorship/) because it wants open source to win. The thread ran past a thousand replies.

That is the weather. It will not be argued away here, and it should not be laundered. Charismatic authors attract weather. So do compositors with abrasive maintainers. Readers who cannot separate a tiling window manager from the man who wrote it, or a Linux setup from the man who named it, will not be talked out of that in a paragraph. The honest minimum is to notice the pattern without making it the plot. The software is opinionated. The author is too. Those are related facts. They are not the same fact.

The "not a real distro" argument belongs in the same weather system, and it used to be stronger. Early Omarchy was a script on Arch. Quattro ships an ISO, a package repository, a factory snapshot, and a shell that is no longer a theme glued onto seven daemons. The taxonomic fight is less interesting than the user-facing fact. A person can download an image and be working in minutes. Ubuntu already offered that, as did Pop!_OS, elementary, Fedora, and a dozen others. What they did not offer was this particular combination: Arch's currency, Hyprland's motion, a named doctrine, and a famous person willing to look slightly ridiculous caring about backgrounds.

## The files are still there

I keep coming back to the files.

Apple's taste arrives as glass and animation, and then as a permission dialog. Classic Linux taste arrives as a wiki and a weekend. Omarchy's taste arrives as a set of defaults you can read. The Setup menu opens the actual config. Updates take a snapshot first. Encryption is on unless you interrupt the installer. If an agent makes a mess of the Hyprland config, there is a command to put the configs back. That is a modest kind of freedom, and it is the kind that matters. You inherit a tradition. You are allowed to depart from it. You can see what you are departing from.

The gift path is the domestic version of the same idea. Preparing a machine for someone else is what an author of defaults owes the next user. Most Linux setups fail that test because they assume the installer and the owner are the same obsessive. Most commercial desktops fail it the other way: the owner is a subscriber, and the machine is never quite his. A computer you can encrypt, hand over, and later wipe back to a clean first boot is closer to a tool than to either of those.

I do not know yet whether I will run this. I know what I think the release is arguing, and I think the argument is larger than Hyprland.

Someone still has to choose. The honest way to do that is to put a name on the choices, ship a whole working environment, and leave the files where the next person can argue. That is what a signature on a computer is worth. Not obedience. A starting point with an address.

Computers should be fun. Fun, here, means a desk arranged on purpose — owned, a little severe, ready for work, including the work of telling the chef he is wrong.
