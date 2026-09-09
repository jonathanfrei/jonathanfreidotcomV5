function hash(n) {
  const x = Math.sin(n * 127.1) * 43758.5453;
  return x - Math.floor(x);
}

function noise2(x, y) {
  const xi = Math.floor(x);
  const yi = Math.floor(y);
  const xf = x - xi;
  const yf = y - yi;
  const u = xf * xf * (3 - 2 * xf);
  const v = yf * yf * (3 - 2 * yf);
  const a = hash(xi * 13.1 + yi * 7.7);
  const b = hash((xi + 1) * 13.1 + yi * 7.7);
  const c = hash(xi * 13.1 + (yi + 1) * 7.7);
  const d = hash((xi + 1) * 13.1 + (yi + 1) * 7.7);
  return a * (1 - u) * (1 - v) + b * u * (1 - v) + c * (1 - u) * v + d * u * v;
}

function fbm(x, y, octaves = 5) {
  let v = 0;
  let a = 0.5;
  let f = 1;
  for (let i = 0; i < octaves; i++) {
    v += a * noise2(x * f, y * f);
    a *= 0.5;
    f *= 2;
  }
  return v;
}

function mix(a, b, t) {
  return a + (b - a) * t;
}

function rgb(r, g, b) {
  return [r, g, b];
}

function parseHex(hex) {
  const h = hex.replace("#", "");
  return [
    parseInt(h.slice(0, 2), 16),
    parseInt(h.slice(2, 4), 16),
    parseInt(h.slice(4, 6), 16),
  ];
}

export function makeBodyTexture(body, size = 512) {
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext("2d");
  const img = ctx.createImageData(size, size);
  const data = img.data;
  const base = parseHex(body.color);
  const kind = body.texture || (body.kind === "star" ? "star" : "rocky");
  const seed = body.id.split("").reduce((s, ch) => s + ch.charCodeAt(0), 1);

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const u = x / size;
      const v = y / size;
      const n = fbm(u * 8 + seed, v * 8 + seed * 0.3);
      let r = base[0];
      let g = base[1];
      let b = base[2];

      if (kind === "star") {
        const cells = fbm(u * 28 + seed, v * 28, 4);
        const spots = fbm(u * 5 + 9, v * 5 + 3, 3);
        const belt = 0.12 * Math.sin(v * Math.PI * 6 + n * 2);
        const limb = Math.pow(Math.sin(v * Math.PI), 0.35);
        const hot = 0.55 + cells * 0.45 + belt;
        r = mix(255, 255, hot);
        g = mix(90, 210, hot * limb);
        b = mix(12, 70, cells * 0.5);
        if (spots < 0.32 && cells < 0.42) {
          const dark = (0.32 - spots) * 2.2;
          r = mix(r, 70, dark);
          g = mix(g, 28, dark);
          b = mix(b, 8, dark);
        } else if (cells > 0.72) {
          r = 255;
          g = mix(g, 245, 0.55);
          b = mix(b, 160, 0.35);
        }
      } else if (kind === "earth") {
        const land = fbm(u * 6 + 2, v * 4 + 4);
        const polar = Math.abs(v - 0.5) > 0.42 + n * 0.04;
        if (polar) {
          r = mix(230, 255, n);
          g = mix(236, 255, n);
          b = mix(242, 255, n);
        } else if (land > 0.52) {
          r = mix(46, 90, land);
          g = mix(92, 140, land);
          b = mix(42, 70, n);
        } else {
          r = mix(20, 50, n);
          g = mix(70, 120, n);
          b = mix(140, 200, n);
        }
        if (n > 0.72 && !polar) {
          r = mix(r, 245, 0.55);
          g = mix(g, 248, 0.55);
          b = mix(b, 252, 0.55);
        }
      } else if (kind === "cloud") {
        const swirl = fbm(u * 10, v * 6);
        r = mix(base[0], 255, swirl * 0.45);
        g = mix(base[1], 230, swirl * 0.35);
        b = mix(base[2], 180, swirl * 0.2);
      } else if (kind === "gas") {
        const bands = body.bands || ["#d9b48a", "#c49a6c", "#efe0c4"];
        const bandIndex = Math.floor((v * bands.length * 3 + n * 0.4) % bands.length);
        const c = parseHex(bands[bandIndex]);
        const w = 0.15 + n * 0.25;
        r = mix(c[0], 255, w * 0.15);
        g = mix(c[1], 230, w * 0.1);
        b = mix(c[2], 200, w * 0.05);
      } else if (kind === "ice") {
        const streak = fbm(u * 12, v * 3);
        r = mix(base[0], 220, streak * 0.25);
        g = mix(base[1], 240, streak * 0.2);
        b = mix(base[2], 255, streak * 0.15);
      } else {
        const crater = fbm(u * 14 + seed, v * 14);
        const shade = 0.65 + crater * 0.45;
        r = Math.min(255, base[0] * shade);
        g = Math.min(255, base[1] * shade);
        b = Math.min(255, base[2] * shade);
        if (crater < 0.28) {
          r *= 0.55;
          g *= 0.55;
          b *= 0.55;
        }
      }

      const i = (y * size + x) * 4;
      data[i] = r;
      data[i + 1] = g;
      data[i + 2] = b;
      data[i + 3] = 255;
    }
  }

  ctx.putImageData(img, 0, 0);
  return canvas;
}

export function makeRingTexture(color = "#d9c9a0", opacity = 0.72) {
  const size = 1024;
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = 8;
  const ctx = canvas.getContext("2d");
  const c = parseHex(color);
  const img = ctx.createImageData(size, 8);
  for (let x = 0; x < size; x++) {
    const u = x / size;
    const gap = Math.abs(u - 0.62) < 0.03 || Math.abs(u - 0.38) < 0.012;
    const a = gap ? 0 : (0.15 + noise2(u * 80, 0.2) * 0.85) * opacity * 255;
    const shade = 0.75 + noise2(u * 40, 1.4) * 0.35;
    for (let y = 0; y < 8; y++) {
      const i = (y * size + x) * 4;
      img.data[i] = c[0] * shade;
      img.data[i + 1] = c[1] * shade;
      img.data[i + 2] = c[2] * shade;
      img.data[i + 3] = a;
    }
  }
  ctx.putImageData(img, 0, 0);
  return canvas;
}

export { rgb, mix };
