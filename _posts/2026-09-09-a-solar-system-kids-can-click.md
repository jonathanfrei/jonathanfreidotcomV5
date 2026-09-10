---
title: "A Solar System Kids Can Click"
date: 2026-09-09 21:35:59 -0400
tags: ["education", "AI", "web", "Three.js"]
categories: technology
description: "I wanted to try Hermes and make something for my younger kids. A browser solar system gave me a way to do both, using Grok and Three.js."
---

I wanted to try [Hermes](https://hermes-agent.nousresearch.com/) and thought it would be fun to make something for my younger kids while I was at it. A small solar system seemed like a good project: they could move around the planets, tap one that looked interesting, and read a little about it. I wanted it to work in a browser, including on a phone, so they could open a page and start exploring.

The result is [Our Solar System](https://jonathanfrei.com/editorial/solar-system), a 3D model here on the site. It has the Sun, the eight planets, Earth's Moon, and Pluto. You can move the view around, zoom in, and select a world to bring up a short lesson. There's also a row of names along the bottom, which makes Mercury easier to reach when it's a small dot on a small screen.

I kept the lessons brief so there would still be room to look around. Each world has a few facts to give a child somewhere to begin, without asking them to read a whole page before choosing another planet. Hiding the names also hides the lesson card, leaving more of the screen for the model itself.

The sizes and distances are adjusted to make everything visible. A model that showed both accurately would leave very little to tap on a phone, so I enlarged the planets and brought their orbits closer together. I wanted children to be able to recognize the worlds and explore them, while being clear about what the picture leaves out.

I included Pluto as a dwarf planet. It's still a world worth learning about, and keeping it in the model gives me a place to explain the classification. It can sit alongside the eight planets without being counted as one of them.

## Building with Hermes and Grok

I used Grok as the model inside Hermes. Hermes is an open-source agent from Nous Research that connects a language model to tools for working with files, running terminal commands, and other tasks. In its [agent loop](https://hermes-agent.nousresearch.com/docs/developer-guide/architecture), it sends the conversation and available tools to the model, carries out the tool calls the model requests, and returns their results for the next step. That lets a coding session continue through edits and command output instead of ending with a block of suggested code.

[Grok](https://docs.x.ai/overview) supplied the model responses in that loop: interpreting my requests, generating code, and requesting tool actions. Hermes supplied the machinery for carrying those actions out and bringing the results back into the conversation. I described what I wanted, looked at the result, and asked for changes over several passes. The work produced the scene data, rendering code, generated textures, and page controls described below.

Three.js is the JavaScript graphics library that the resulting app uses in the browser. It provides objects for geometry, materials, lights, and cameras, along with a renderer that turns the scene into WebGL drawing operations on a canvas. Our code assembles those objects into planets and updates them as time passes. Hermes and Grok were part of making the app; opening the finished page runs JavaScript and Three.js locally, with no model call needed to move a planet or display a lesson.

The first version ran locally with Vite, which provided the development server and reloaded the page as the source changed. That gave me a browser view to judge while the files were being revised. The project itself settled into a few parts: a JSON description of the solar system, a `World` class to render and animate it, texture functions, and an application module to connect the scene to the page controls.

## Describing the scene

The project separates the description of the solar system from the code that draws it. A JSON file holds the worlds, their appearance and motion, and the text for their lessons. Each record includes a name, radius, color, and texture type, with optional fields for rings, atmosphere, tilt, and an orbit. The Moon's record names Earth as its parent; Earth's names the Sun.

I like this arrangement because the same record supplies both the planet on screen and the lesson beside it. Selecting Saturn gives the interface Saturn's name, classification, pronunciation, and facts from that file. I can revise an explanation without touching the rendering code, or adjust a displayed orbit without changing how selection works. Another model built from similar bodies could use the same renderer, though a different kind of scene would still need new code.

## Making the planets move

The renderer builds each world from a sphere and a small hierarchy of Three.js groups. One group turns around the orbital center, another places the planet at its orbital distance, and a third handles its tilt and spin. Keeping those movements separate lets a planet rotate while it travels around the Sun. The Moon's orbit attaches to Earth's position, so it comes along as Earth moves without inheriting Earth's daily spin.

The orbits are circles, and the animation calculates positions from elapsed time. There's no gravity calculation between bodies. I also compressed the differences in orbital periods so the outer planets would move visibly: the code raises each period to the power of 0.38 before using it to set the animation speed. At the default speed, Earth completes an orbit in 24 seconds, while Neptune takes roughly three minutes. Those timings belong to the illustration; they aren't a common time scale for the real solar system.

The surfaces are generated in the browser too. A texture function draws pixels into an offscreen canvas, combining colors with layers of noise to produce rocky surfaces, cloud patterns, and the bands on the gas giants. Three.js wraps the resulting image around the sphere. Saturn's rings use a separate generated texture with transparent gaps.

That keeps the planet artwork in code, but it also sets a limit on what the picture can teach. Earth's green and blue patches are generated shapes, not a map of its continents. I think of these surfaces as illustrations that help distinguish the worlds. The lesson text carries details that the model doesn't attempt to reproduce.

## Connecting the model to the page

The planets are drawn in WebGL, while the names and lessons remain HTML. Three.js's CSS2DRenderer keeps each name positioned beside its world as the view moves. The lesson panel is ordinary text and a list of facts, so it can be styled and laid out with the rest of the page. I don't need to draw text into a texture just to explain what a child has selected.

A click on the scene uses raycasting: the code projects a line from the camera through the pointer's position and checks which planet it intersects. Clicking a name or one of the buttons along the bottom reaches the same selection function. That function updates the lesson and starts a gradual camera move toward the selected world. Once the move finishes, the camera's point of interest continues to follow the world as it travels.

I wanted the controls to leave some room for looking. The page can pause the orbital and spin animation, change its speed, or return to the full view. Hiding the names also hides the lesson card. If the browser reports a preference for reduced motion, the model starts paused, though selecting a world still moves the camera.

## Fitting it into the site

My site uses Jekyll and GitHub Pages, so the finished version is a static HTML page with JavaScript modules and the JSON scene file alongside it. The browser fetches the description and builds the scene locally. Vite was useful during development, but the deployed page doesn't need a running Vite or Node server.

Three.js and its controls are included in the site's files. A small import map tells the browser where to find the library when a module imports `three`. This lets the page use modules directly while keeping that dependency on the same site. The model also uses the site's existing fonts, so the surrounding text feels familiar.

On a phone, the lesson moves toward the bottom of the screen and has a limited height, with its contents available by scrolling. The row of names provides a larger target than the planets themselves. The renderer caps its pixel ratio at two, which limits the number of pixels it draws on displays with a higher density. I had my younger kids in mind when making those choices, though I haven't established how well the model works in a classroom.

I like being able to keep working on the explanations separately from the scene. A lesson can get clearer without rebuilding a planet, and the controls can improve without rewriting the lesson. Trying Hermes has left me with a small solar system I can share with my younger kids. I'm curious to see which parts they want to spend time with.
