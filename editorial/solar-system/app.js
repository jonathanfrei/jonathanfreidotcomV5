import { World } from "./world.js";

const DATA_URL = "/editorial/solar-system/solar-system.json";

const canvas = document.querySelector("#scene");
const labelLayer = document.querySelector("#labels");
const lesson = document.querySelector("#lesson");
const roster = document.querySelector("#roster");
const playBtn = document.querySelector("#play");
const speed = document.querySelector("#speed");
const speedValue = document.querySelector("#speed-value");
const labelsToggle = document.querySelector("#labels-toggle");
const resetBtn = document.querySelector("#reset");
const note = document.querySelector("#scale-note");
const titleEl = document.querySelector("#title");
const subtitleEl = document.querySelector("#subtitle");

function kindLabel(kind) {
  if (kind === "star") return "Star";
  if (kind === "moon") return "Moon";
  if (kind === "dwarf-planet") return "Dwarf planet";
  if (kind === "planet") return "Planet";
  return "Region";
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text) node.textContent = text;
  return node;
}

function emptyLesson() {
  lesson.replaceChildren(
    el("p", "kicker", "Start here"),
    el("h2", null, "Pick a world"),
    el("p", "lede", "Tap a planet in the sky, or use the list below. Each world has a short lesson."),
    el("p", "hint", "Drag to look around. Scroll to zoom. Spacebar pauses.")
  );
}

function showLesson(def) {
  document.querySelectorAll(".world-chip").forEach((node) => {
    node.classList.toggle("is-active", Boolean(def) && node.dataset.id === def.id);
  });
  if (!def) {
    emptyLesson();
    return;
  }
  const kicker = kindLabel(def.kind) + (def.pronounce ? ` · ${def.pronounce}` : "");
  const facts = el("ol", "facts");
  for (const fact of def.facts || []) {
    facts.append(el("li", null, fact));
  }
  lesson.replaceChildren(
    el("p", "kicker", kicker),
    el("h2", null, def.name),
    el("p", "lede", def.headline || ""),
    facts
  );
}

function renderRoster(scene, world) {
  const items = [
    ...scene.bodies.map((b) => ({ id: b.id, name: b.name, color: b.color, kind: b.kind })),
    ...(scene.belts || []).map((b) => ({ id: b.id, name: b.name, color: b.color, kind: "region" })),
  ];
  roster.replaceChildren(
    ...items.map((item) => {
      const btn = el("button", "world-chip");
      btn.type = "button";
      btn.dataset.id = item.id;
      const swatch = el("span", "swatch");
      swatch.style.background = item.color;
      btn.append(swatch, el("span", "chip-name", item.name));
      btn.addEventListener("click", () => world.select(item.id, { focus: item.kind !== "region" }));
      return btn;
    })
  );
}

const scene = await fetch(DATA_URL).then((res) => {
  if (!res.ok) throw new Error(`Could not load scene (${res.status})`);
  return res.json();
});

const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const world = new World(canvas, labelLayer);

titleEl.textContent = scene.title;
subtitleEl.textContent = scene.subtitle;
note.textContent = scene.note;

world.load(scene);
world.paused = reduced;
world.speed = reduced ? 0.25 : 1;
world.onSelect = showLesson;
renderRoster(scene, world);
emptyLesson();

function syncPlay() {
  playBtn.textContent = world.paused ? "Play" : "Pause";
  playBtn.setAttribute("aria-pressed", String(!world.paused));
}
syncPlay();

playBtn.addEventListener("click", () => {
  world.paused = !world.paused;
  syncPlay();
});

speed.value = String(world.speed);
speedValue.textContent = `${world.speed.toFixed(1)}×`;
speed.addEventListener("input", () => {
  world.speed = Number(speed.value);
  speedValue.textContent = `${world.speed.toFixed(1)}×`;
});

function setImmersed(immersed) {
  world.setLabelsVisible(!immersed);
  document.body.classList.toggle("is-immersed", immersed);
  labelsToggle.textContent = immersed ? "Show names" : "Hide names";
  labelsToggle.setAttribute("aria-pressed", String(immersed));
}

labelsToggle.addEventListener("click", () => {
  setImmersed(world.showLabels);
});

resetBtn.addEventListener("click", () => {
  world.focusId = null;
  world.select(null);
  world.camera.position.fromArray(scene.camera.position);
  world.controls.target.fromArray(scene.camera.target);
});

window.addEventListener("keydown", (e) => {
  if (e.code !== "Space") return;
  if (e.target !== document.body && e.target !== canvas) return;
  e.preventDefault();
  world.paused = !world.paused;
  syncPlay();
});

function loop() {
  world.tick();
  requestAnimationFrame(loop);
}
loop();
