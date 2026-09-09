import * as THREE from "three";
import { OrbitControls } from "./lib/OrbitControls.js";
import { CSS2DRenderer, CSS2DObject } from "./lib/CSS2DRenderer.js";
import { makeBodyTexture, makeRingTexture } from "./textures.js";

const YEAR_SECONDS = 24;
const DAY_SECONDS = 8;

export class World {
  constructor(canvas, labelLayer) {
    this.canvas = canvas;
    this.labelLayer = labelLayer;
    this.bodies = new Map();
    this.belts = [];
    this.descriptor = null;
    this.elapsed = 0;
    this.paused = false;
    this.speed = 1;
    this.selectedId = null;
    this.showLabels = true;
    this.focusId = null;
    this.focusLerp = 0;
    this._ray = new THREE.Raycaster();
    this._pointer = new THREE.Vector2();
    this._clock = new THREE.Clock();
    this._focusFrom = new THREE.Vector3();
    this._focusTo = new THREE.Vector3();
    this._targetFrom = new THREE.Vector3();
    this._targetTo = new THREE.Vector3();
    this.onSelect = () => {};

    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(42, 1, 0.1, 4000);
    this.renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: true,
      alpha: false,
      powerPreference: "high-performance",
    });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.05;

    this.labelRenderer = new CSS2DRenderer();
    this.labelRenderer.domElement.className = "label-layer";
    labelLayer.appendChild(this.labelRenderer.domElement);

    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.06;
    this.controls.minDistance = 4;
    this.controls.maxDistance = 280;
    this.controls.maxPolarAngle = Math.PI * 0.48;

    this.ambient = new THREE.AmbientLight(0xffffff, 0.07);
    this.scene.add(this.ambient);
    this.hemi = new THREE.HemisphereLight(0x9bb7ff, 0x1a120c, 0.18);
    this.scene.add(this.hemi);

    this.root = new THREE.Group();
    this.scene.add(this.root);

    this._onResize = () => this.resize();
    window.addEventListener("resize", this._onResize);
    canvas.addEventListener("pointerdown", (e) => this._onPointer(e));
    canvas.addEventListener("pointermove", (e) => this._onHover(e));
  }

  resize() {
    const wrap = this.canvas.parentElement;
    const w = wrap.clientWidth;
    const h = wrap.clientHeight;
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(w, h, false);
    this.labelRenderer.setSize(w, h);
  }

  load(descriptor) {
    this.clear();
    this.descriptor = descriptor;
    this.scene.background = new THREE.Color(descriptor.background || "#05070d");
    this.ambient.intensity = descriptor.ambient ?? 0.07;
    this.camera.fov = descriptor.camera?.fov ?? 42;
    this.camera.near = descriptor.camera?.near ?? 0.1;
    this.camera.far = descriptor.camera?.far ?? 4000;
    this.camera.position.fromArray(descriptor.camera?.position || [0, 32, 86]);
    this.controls.target.fromArray(descriptor.camera?.target || [0, 0, 0]);
    this.camera.updateProjectionMatrix();

    this._addStars(descriptor.starCount || 2500);

    for (const body of descriptor.bodies) {
      this._addBody(body);
    }
    for (const belt of descriptor.belts || []) {
      this._addBelt(belt);
    }

    this.resize();
  }

  clear() {
    this.bodies.clear();
    this.belts = [];
    this.selectedId = null;
    this.focusId = null;
    while (this.root.children.length) {
      const child = this.root.children[0];
      this.root.remove(child);
      child.traverse((obj) => {
        if (obj.geometry) obj.geometry.dispose();
        if (obj.material) {
          const mats = Array.isArray(obj.material) ? obj.material : [obj.material];
          mats.forEach((m) => {
            if (m.map) m.map.dispose();
            m.dispose();
          });
        }
      });
    }
    this.labelLayer.querySelector(".label-layer")?.replaceChildren();
  }

  _addStars(count) {
    const positions = new Float32Array(count * 3);
    const colors = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      const r = 420 + Math.random() * 900;
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.acos(2 * Math.random() - 1);
      positions[i * 3] = r * Math.sin(phi) * Math.cos(theta);
      positions[i * 3 + 1] = r * Math.cos(phi);
      positions[i * 3 + 2] = r * Math.sin(phi) * Math.sin(theta);
      const tint = 0.75 + Math.random() * 0.25;
      colors[i * 3] = tint;
      colors[i * 3 + 1] = tint * (0.92 + Math.random() * 0.08);
      colors[i * 3 + 2] = tint * (0.85 + Math.random() * 0.2);
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    geo.setAttribute("color", new THREE.BufferAttribute(colors, 3));
    const mat = new THREE.PointsMaterial({
      size: 1.15,
      sizeAttenuation: false,
      vertexColors: true,
      transparent: true,
      opacity: 0.9,
      depthWrite: false,
    });
    const stars = new THREE.Points(geo, mat);
    stars.name = "stars";
    this.root.add(stars);
  }

  _addBody(def) {
    const pivot = new THREE.Group();
    pivot.name = `${def.id}-pivot`;

    const spin = new THREE.Group();
    spin.name = `${def.id}-spin`;
    if (def.tilt) spin.rotation.z = THREE.MathUtils.degToRad(def.tilt);

    const geo = new THREE.SphereGeometry(def.radius, 64, 48);
    const map = new THREE.CanvasTexture(makeBodyTexture(def, def.kind === "star" ? 1024 : 512));
    map.colorSpace = THREE.SRGBColorSpace;
    map.anisotropy = 8;

    const mat = def.emissive
      ? new THREE.MeshBasicMaterial({ map })
      : new THREE.MeshStandardMaterial({
          map,
          roughness: def.kind === "gas" || def.kind === "ice" || def.kind === "cloud" ? 0.55 : 0.82,
          metalness: 0.02,
        });

    const mesh = new THREE.Mesh(geo, mat);
    mesh.name = def.id;
    mesh.userData.bodyId = def.id;
    spin.add(mesh);

    if (def.emissive) {
      const glowGeo = new THREE.SphereGeometry(def.radius * 1.28, 32, 24);
      const glowMat = new THREE.MeshBasicMaterial({
        color: def.emissive,
        transparent: true,
        opacity: 0.18,
        side: THREE.BackSide,
        depthWrite: false,
      });
      const glow = new THREE.Mesh(glowGeo, glowMat);
      glow.userData.ignorePick = true;
      spin.add(glow);

      const light = new THREE.PointLight(
        def.light?.color || "#fff4d6",
        def.light?.intensity ?? 4,
        def.light?.distance ?? 400,
        1.6
      );
      spin.add(light);
    }

    if (def.atmosphere) {
      const shell = new THREE.Mesh(
        new THREE.SphereGeometry(def.radius * 1.045, 32, 24),
        new THREE.MeshBasicMaterial({
          color: def.atmosphere,
          transparent: true,
          opacity: 0.14,
          side: THREE.BackSide,
          depthWrite: false,
        })
      );
      shell.userData.ignorePick = true;
      spin.add(shell);
    }

    if (def.rings) {
      const inner = def.rings.inner;
      const outer = def.rings.outer;
      const ringGeo = new THREE.RingGeometry(inner, outer, 96, 4);
      const uv = ringGeo.attributes.uv;
      for (let i = 0; i < uv.count; i++) {
        const x = ringGeo.attributes.position.getX(i);
        const y = ringGeo.attributes.position.getY(i);
        const r = Math.sqrt(x * x + y * y);
        uv.setXY(i, (r - inner) / (outer - inner), 0.5);
      }
      const ringMap = new THREE.CanvasTexture(makeRingTexture(def.rings.color, def.rings.opacity ?? 0.72));
      ringMap.colorSpace = THREE.SRGBColorSpace;
      const ringMat = new THREE.MeshBasicMaterial({
        map: ringMap,
        side: THREE.DoubleSide,
        transparent: true,
        depthWrite: false,
      });
      const ring = new THREE.Mesh(ringGeo, ringMat);
      ring.rotation.x = Math.PI / 2;
      ring.userData.ignorePick = true;
      spin.add(ring);
    }

    const labelEl = document.createElement("div");
    labelEl.className = "world-label";
    labelEl.textContent = def.name;
    const label = new CSS2DObject(labelEl);
    label.position.set(0, def.labelOffset ?? def.radius + 0.55, 0);
    spin.add(label);

    const holder = new THREE.Group();
    holder.name = `${def.id}-holder`;
    if (def.orbitRadius) holder.position.set(def.orbitRadius, 0, 0);
    holder.add(spin);

    labelEl.style.pointerEvents = "auto";
    labelEl.addEventListener("click", (event) => {
      event.stopPropagation();
      this.select(def.id);
    });

    const record = {
      def,
      pivot,
      holder,
      spin,
      mesh,
      labelEl,
      angle0:
        def.orbitPhase != null
          ? THREE.MathUtils.degToRad(def.orbitPhase)
          : Math.random() * Math.PI * 2,
    };

    const parentRecord = def.parent ? this.bodies.get(def.parent) : null;
    const attachTo = parentRecord ? parentRecord.holder : this.root;
    if (def.orbitRadius && !def.hideOrbit) {
      attachTo.add(this._orbitLine(def.orbitRadius));
    }
    attachTo.add(pivot);
    pivot.add(holder);

    this.bodies.set(def.id, record);
    if (def.kind === "moon") record.labelEl.classList.add("is-hidden");
  }

  _orbitLine(radius) {
    const pts = [];
    const n = 128;
    for (let i = 0; i <= n; i++) {
      const t = (i / n) * Math.PI * 2;
      pts.push(new THREE.Vector3(Math.cos(t) * radius, 0, Math.sin(t) * radius));
    }
    const geo = new THREE.BufferGeometry().setFromPoints(pts);
    const mat = new THREE.LineBasicMaterial({
      color: 0x8d8678,
      transparent: true,
      opacity: 0.28,
    });
    const line = new THREE.Line(geo, mat);
    line.userData.ignorePick = true;
    return line;
  }

  _addBelt(def) {
    const count = def.count || 400;
    const positions = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      const r = def.inner + Math.random() * (def.outer - def.inner);
      const a = Math.random() * Math.PI * 2;
      const y = (Math.random() - 0.5) * 0.35;
      positions[i * 3] = Math.cos(a) * r;
      positions[i * 3 + 1] = y;
      positions[i * 3 + 2] = Math.sin(a) * r;
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    const mat = new THREE.PointsMaterial({
      color: def.color || "#8a8174",
      size: def.size || 0.05,
      sizeAttenuation: true,
    });
    const points = new THREE.Points(geo, mat);
    points.userData.belt = def;
    this.root.add(points);
    this.belts.push({ def, points });
  }

  worldPosition(id) {
    const rec = this.bodies.get(id);
    if (!rec) return new THREE.Vector3();
    rec.mesh.updateWorldMatrix(true, false);
    return rec.mesh.getWorldPosition(new THREE.Vector3());
  }

  select(id, { focus = true } = {}) {
    if (id && !this.bodies.has(id) && !this.belts.find((b) => b.def.id === id)) {
      return;
    }
    this.selectedId = id;
    for (const rec of this.bodies.values()) {
      rec.labelEl.classList.toggle("is-selected", rec.def.id === id);
      const isMoon = rec.def.kind === "moon";
      const related = rec.def.id === id || rec.def.parent === id;
      rec.labelEl.classList.toggle("is-hidden", Boolean(isMoon && !related));
    }
    if (focus && id && this.bodies.has(id)) this.focus(id);
    const def =
      this.bodies.get(id)?.def || this.belts.find((b) => b.def.id === id)?.def || null;
    this.onSelect(def);
  }

  focus(id) {
    const rec = this.bodies.get(id);
    if (!rec) return;
    this.focusId = id;
    this.focusLerp = 0;
    this._focusFrom.copy(this.camera.position);
    this._targetFrom.copy(this.controls.target);
    const pos = this.worldPosition(id);
    const r = rec.def.radius;
    const dist = Math.max(8, r * 7.5);
    const offset = new THREE.Vector3(dist * 0.55, dist * 0.38, dist);
    this._focusTo.copy(pos).add(offset);
    this._targetTo.copy(pos);
  }

  setLabelsVisible(visible) {
    this.showLabels = visible;
    this.labelLayer.style.opacity = visible ? "1" : "0";
  }

  _pick(event) {
    const rect = this.canvas.getBoundingClientRect();
    this._pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    this._pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
    this._ray.setFromCamera(this._pointer, this.camera);
    const meshes = [...this.bodies.values()].map((b) => b.mesh);
    const hits = this._ray.intersectObjects(meshes, false);
    return hits[0]?.object.userData.bodyId || null;
  }

  _onPointer(event) {
    if (event.button !== 0) return;
    const id = this._pick(event);
    if (id) {
      this.select(id);
    }
  }

  _onHover(event) {
    const id = this._pick(event);
    this.canvas.style.cursor = id ? "pointer" : "grab";
  }

  tick() {
    const dt = Math.min(this._clock.getDelta(), 0.05);
    if (!this.paused) this.elapsed += dt * this.speed;

    for (const rec of this.bodies.values()) {
      const def = rec.def;
      if (def.orbitRadius && def.orbitPeriod) {
        const visualYears = Math.pow(Math.abs(def.orbitPeriod), 0.38);
        const omega = (Math.PI * 2) / (visualYears * YEAR_SECONDS);
        rec.pivot.rotation.y = rec.angle0 + this.elapsed * omega;
      }
      if (def.spinPeriod) {
        const spinOmega = (Math.PI * 2) / (Math.abs(def.spinPeriod) * DAY_SECONDS);
        rec.spin.rotation.y += (this.paused ? 0 : dt * this.speed) * spinOmega * Math.sign(def.spinPeriod);
      }
    }

    if (this.focusId && this.focusLerp < 1) {
      this.focusLerp = Math.min(1, this.focusLerp + dt * 1.6);
      const t = 1 - Math.pow(1 - this.focusLerp, 3);
      this.camera.position.lerpVectors(this._focusFrom, this._focusTo, t);
      this.controls.target.lerpVectors(this._targetFrom, this._targetTo, t);
    } else if (this.focusId) {
      const pos = this.worldPosition(this.focusId);
      this.controls.target.lerp(pos, 0.08);
    }

    this.controls.update();
    this.renderer.render(this.scene, this.camera);
    this.labelRenderer.render(this.scene, this.camera);
  }
}
