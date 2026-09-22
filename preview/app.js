/**
 * CaptureX — Classic Camera Lenses Engine
 * Implements physical lens optical characteristics, depth-of-field bokeh synthesis,
 * swirly petzval vortex simulation, and automatic 'Shot with CaptureX' watermarking.
 */

// Classic Camera Lenses Database
const CLASSIC_LENSES = [
  {
    id: 'noctilux_50',
    name: 'Noctilux 50mm',
    focal: '50mm',
    defaultAperture: '0.95',
    opticalFormula: 'Spherical Ultra-Speed',
    desc: 'Ultra-shallow depth of field, creamy circular bokeh discs, glowing center sharpness.',
    bokehType: 'creamy_disc',
    swirl: 0.0,
    colorCast: { r: 1.02, g: 0.98, b: 0.95 }, // Warm amber glow
    vignette: 0.35,
    glow: 0.25
  },
  {
    id: 'helios_44_2',
    name: 'Helios 44-2',
    focal: '58mm',
    defaultAperture: '2.0',
    opticalFormula: 'Biotar 6-Elements',
    desc: 'Legendary USSR vintage lens known for dramatic swirly vortex background bokeh.',
    bokehType: 'swirly_vortex',
    swirl: 0.75,
    colorCast: { r: 0.96, g: 1.02, b: 0.98 }, // Emerald vintage tint
    vignette: 0.45,
    glow: 0.15
  },
  {
    id: 'summicron_35',
    name: 'Summicron 35mm',
    focal: '35mm',
    defaultAperture: '2.0',
    opticalFormula: 'Double-Gauss 8-Elements',
    desc: 'King of 35mm documentary street photography with punchy micro-contrast.',
    bokehType: 'crisp_gaussian',
    swirl: 0.1,
    colorCast: { r: 1.0, g: 1.0, b: 1.0 }, // Neutral true color
    vignette: 0.2,
    glow: 0.0
  },
  {
    id: 'biotar_75',
    name: 'Biotar 75mm',
    focal: '75mm',
    defaultAperture: '1.5',
    opticalFormula: 'Carl Zeiss Jena',
    desc: 'Painterly portrait lens with cat-eye peripheral bokeh and soft highlight halo.',
    bokehType: 'swirly_cateye',
    swirl: 0.55,
    colorCast: { r: 1.04, g: 0.97, b: 0.92 }, // Golden hour warmth
    vignette: 0.38,
    glow: 0.3
  },
  {
    id: 'anamorphic_50',
    name: 'Anamorphic 1.33x',
    focal: '50mm',
    defaultAperture: '1.8',
    opticalFormula: 'Cylindrical Squeeze',
    desc: 'Hollywood widescreen aesthetic with horizontal streak flare and oval bokeh.',
    bokehType: 'oval_anamorphic',
    swirl: 0.0,
    colorCast: { r: 0.94, g: 1.02, b: 1.08 }, // Cyan sci-fi streak
    vignette: 0.28,
    glow: 0.4
  },
  {
    id: 'macro_100',
    name: 'Macro 100mm',
    focal: '100mm',
    defaultAperture: '2.8',
    opticalFormula: 'Apochromatic 1:1',
    desc: 'Extreme macro subject isolation with buttery smooth background obliteration.',
    bokehType: 'smooth_melt',
    swirl: 0.0,
    colorCast: { r: 1.0, g: 1.0, b: 1.0 },
    vignette: 0.15,
    glow: 0.05
  },
  {
    id: 'pancake_28',
    name: 'Pancake 28mm',
    focal: '28mm',
    defaultAperture: '2.8',
    opticalFormula: 'Tessar Compact',
    desc: 'Ultra-wide documentary angle with analog corner falloff and rich shadow depth.',
    bokehType: 'wide_natural',
    swirl: 0.15,
    colorCast: { r: 0.98, g: 0.99, b: 1.01 },
    vignette: 0.42,
    glow: 0.0
  }
];

// App State
const state = {
  activeTab: 'lens',
  activeLens: CLASSIC_LENSES[0],
  aperture: 0.95,
  depthBlur: 85,
  focusPoint: { x: 0.5, y: 0.65 }, // Focus on center mushroom / subject
  colorPreset: 'moody',
  frameStyle: 'watermark',
  aspectRatio: '3:4',
  audio: true,
  haptics: true,
  photos: []
};

// Canvas references
const canvas = document.getElementById('lensCanvas');
const ctx = canvas.getContext('2d', { willReadFrequently: true });
const video = document.getElementById('webcam');

// Load App Logo
const logoImg = new Image();
logoImg.src = 'CaptureX logo.png';

// Web Audio Mechanical Click Synthesizer
let audioCtx = null;
function getAudio() {
  if (!audioCtx) {
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    if (AudioContextClass) audioCtx = new AudioContextClass();
  }
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
  return audioCtx;
}

function playShutterClick() {
  const actx = getAudio();
  if (!actx) return;
  const now = actx.currentTime;

  const buf = actx.createBuffer(1, actx.sampleRate * 0.035, actx.sampleRate);
  const d = buf.getChannelData(0);
  for (let i = 0; i < buf.length; i++) {
    d[i] = (Math.random() * 2 - 1) * Math.exp(-i / (actx.sampleRate * 0.007));
  }
  const noise = actx.createBufferSource();
  noise.buffer = buf;
  const bandpass = actx.createBiquadFilter();
  bandpass.type = 'bandpass';
  bandpass.frequency.setValueAtTime(3200, now);
  const gain = actx.createGain();
  gain.gain.setValueAtTime(0.85, now);
  gain.gain.exponentialRampToValueAtTime(0.01, now + 0.032);
  noise.connect(bandpass);
  bandpass.connect(gain);
  gain.connect(actx.destination);
  noise.start(now);

  const osc = actx.createOscillator();
  const oscGain = actx.createGain();
  osc.type = 'triangle';
  osc.frequency.setValueAtTime(220, now + 0.045);
  osc.frequency.exponentialRampToValueAtTime(45, now + 0.12);
  oscGain.gain.setValueAtTime(0.9, now + 0.045);
  oscGain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
  osc.connect(oscGain);
  oscGain.connect(actx.destination);
  osc.start(now + 0.045);
  osc.stop(now + 0.15);

  if ('vibrate' in navigator) navigator.vibrate(20);
}

function playDialTick() {
  const actx = getAudio();
  if (!actx) return;
  const now = actx.currentTime;
  const osc = actx.createOscillator();
  const gain = actx.createGain();
  osc.type = 'sine';
  osc.frequency.setValueAtTime(1400, now);
  osc.frequency.exponentialRampToValueAtTime(450, now + 0.012);
  gain.gain.setValueAtTime(0.12, now);
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.012);
  osc.connect(gain);
  gain.connect(actx.destination);
  osc.start(now);
  osc.stop(now + 0.015);
  if ('vibrate' in navigator) navigator.vibrate(6);
}

// Procedural Photographic Scene Rendering with Realistic Macro Forest & Depth Bokeh
let timeTick = 0;
function renderPhotographicScene(targetCtx, w, h) {
  timeTick += 0.01;

  // 1. Forest Background with Soft Out-of-Focus Foliage & Golden Sun Flares
  const bgGrad = targetCtx.createLinearGradient(0, 0, 0, h);
  bgGrad.addColorStop(0, '#2d3a2a');
  bgGrad.addColorStop(0.4, '#4a5b3f');
  bgGrad.addColorStop(0.7, '#2f271f');
  bgGrad.addColorStop(1, '#1c1612');
  targetCtx.fillStyle = bgGrad;
  targetCtx.fillRect(0, 0, w, h);

  // 2. Optical Bokeh Discs in Background (Simulating chosen lens aperture)
  const lens = state.activeLens;
  const bokehCount = 18;
  const maxBokehRadius = (1.0 / state.aperture) * (state.depthBlur / 100.0) * (w * 0.09);

  for (let i = 0; i < bokehCount; i++) {
    const bx = (Math.sin(i * 1.7 + timeTick * 0.2) * 0.4 + 0.5) * w;
    const by = (Math.cos(i * 1.3) * 0.25 + 0.3) * h;
    const r = Math.max(12, ((i % 5) + 3) * (maxBokehRadius * 0.3));

    targetCtx.save();
    targetCtx.translate(bx, by);

    // If Helios swirly bokeh, distort discs along tangent
    if (lens.swirl > 0) {
      const angleFromCenter = Math.atan2(by - h * 0.5, bx - w * 0.5);
      targetCtx.rotate(angleFromCenter + Math.PI / 2);
      targetCtx.scale(1.0 + lens.swirl * 0.8, 1.0 - lens.swirl * 0.35);
    } else if (lens.bokehType === 'oval_anamorphic') {
      targetCtx.scale(0.7, 1.35); // Anamorphic oval stretch
    }

    // Glowing Bokeh Disc
    const bGrad = targetCtx.createRadialGradient(0, 0, r * 0.2, 0, 0, r);
    bGrad.addColorStop(0, 'rgba(255, 245, 210, 0.45)');
    bGrad.addColorStop(0.7, 'rgba(255, 220, 150, 0.25)');
    bGrad.addColorStop(0.92, 'rgba(255, 255, 255, 0.45)'); // Sharp spherical aberration ring
    bGrad.addColorStop(1, 'rgba(255, 200, 120, 0.0)');

    targetCtx.fillStyle = bGrad;
    targetCtx.beginPath();
    targetCtx.arc(0, 0, r, 0, Math.PI * 2);
    targetCtx.fill();
    targetCtx.restore();
  }

  // 3. Ground Litter & Mossy Earth (Subtle Texture)
  targetCtx.fillStyle = '#1c1612';
  targetCtx.beginPath();
  targetCtx.moveTo(0, h * 0.72);
  targetCtx.bezierCurveTo(w * 0.3, h * 0.68, w * 0.7, h * 0.76, w, h * 0.7);
  targetCtx.lineTo(w, h);
  targetCtx.lineTo(0, h);
  targetCtx.fill();

  // 4. Sharp In-Focus Hero Macro Subject: Forest Mushroom & Micro Droplets
  const mx = w * state.focusPoint.x;
  const my = h * state.focusPoint.y;
  const mSize = w * 0.28;

  targetCtx.save();
  targetCtx.translate(mx, my);

  // Mushroom Stem
  targetCtx.fillStyle = '#f5eedb';
  targetCtx.beginPath();
  targetCtx.moveTo(-mSize * 0.1, mSize * 0.45);
  targetCtx.quadraticCurveTo(-mSize * 0.05, 0, -mSize * 0.08, -mSize * 0.2);
  targetCtx.lineTo(mSize * 0.08, -mSize * 0.2);
  targetCtx.quadraticCurveTo(mSize * 0.05, 0, mSize * 0.1, mSize * 0.45);
  targetCtx.fill();

  // Stem Gills & Shadow
  targetCtx.fillStyle = '#dfd3be';
  targetCtx.beginPath();
  targetCtx.ellipse(0, -mSize * 0.2, mSize * 0.35, mSize * 0.1, 0, 0, Math.PI * 2);
  targetCtx.fill();

  // Mushroom Cap
  const capGrad = targetCtx.createLinearGradient(0, -mSize * 0.7, 0, -mSize * 0.2);
  capGrad.addColorStop(0, '#c79d6e');
  capGrad.addColorStop(0.5, '#ad7f50');
  capGrad.addColorStop(1, '#7a5433');
  targetCtx.fillStyle = capGrad;
  targetCtx.beginPath();
  targetCtx.moveTo(-mSize * 0.48, -mSize * 0.2);
  targetCtx.quadraticCurveTo(0, -mSize * 0.75, mSize * 0.48, -mSize * 0.2);
  targetCtx.quadraticCurveTo(0, -mSize * 0.15, -mSize * 0.48, -mSize * 0.2);
  targetCtx.fill();

  // Glowing Highlight on Cap
  targetCtx.fillStyle = 'rgba(255, 255, 255, 0.45)';
  targetCtx.beginPath();
  targetCtx.ellipse(-mSize * 0.12, -mSize * 0.45, mSize * 0.18, mSize * 0.08, -0.2, 0, Math.PI * 2);
  targetCtx.fill();

  targetCtx.restore();

  // 5. Lens Glow / Anamorphic Streak
  if (lens.glow > 0) {
    if (lens.bokehType === 'oval_anamorphic') {
      // Horizontal Cyan Streak
      const streak = targetCtx.createLinearGradient(0, h * 0.4, w, h * 0.4);
      streak.addColorStop(0, 'rgba(56, 189, 248, 0)');
      streak.addColorStop(0.5, 'rgba(56, 189, 248, 0.38)');
      streak.addColorStop(1, 'rgba(56, 189, 248, 0)');
      targetCtx.fillStyle = streak;
      targetCtx.fillRect(0, h * 0.38, w, 6);
    }
  }

  // 6. Natural Lens Vignette
  const cx = w / 2;
  const cy = h / 2;
  const maxR = Math.sqrt(cx * cx + cy * cy);
  const vigGrad = targetCtx.createRadialGradient(cx, cy, maxR * 0.45, cx, cy, maxR);
  vigGrad.addColorStop(0, 'rgba(0,0,0,0)');
  vigGrad.addColorStop(1, `rgba(0,0,0,${lens.vignette})`);
  targetCtx.fillStyle = vigGrad;
  targetCtx.fillRect(0, 0, w, h);
}

// 32-bit Color Grading & Film Stock Shader
function applyColorGrade(imgData, w, h) {
  const d = imgData.data;
  const lens = state.activeLens;
  const color = state.colorPreset;

  let satMultiplier = 1.0;
  let contrast = 1.0;
  let tempShift = 0.0;
  let tintShift = 0.0;
  let grain = 0.0;

  if (color === 'moody') {
    contrast = 1.35;
    satMultiplier = 0.75;
    tempShift = -0.15;
    grain = 0.15;
  } else if (color === 'dreamy') {
    contrast = 0.9;
    satMultiplier = 1.15;
    tempShift = 0.25;
    grain = 0.08;
  } else if (color === 'nightcore') {
    contrast = 1.4;
    satMultiplier = 1.6;
    tempShift = -0.3;
    grain = 0.12;
  } else if (color === 'vivid') {
    contrast = 1.28;
    satMultiplier = 1.5;
    tempShift = 0.1;
  } else if (color === 'portra') {
    contrast = 1.12;
    satMultiplier = 1.1;
    tempShift = 0.18;
    grain = 0.35;
  } else if (color === 'trix') {
    contrast = 1.5;
    satMultiplier = 0.0; // Black & White
    grain = 0.45;
  }

  for (let i = 0; i < d.length; i += 4) {
    let r = d[i] / 255.0;
    let g = d[i + 1] / 255.0;
    let b = d[i + 2] / 255.0;

    // Apply Lens Optical Color Cast
    r *= lens.colorCast.r;
    g *= lens.colorCast.g;
    b *= lens.colorCast.b;

    // White Balance
    r += tempShift * 0.12;
    b -= tempShift * 0.12;

    // Contrast
    r = (r - 0.5) * contrast + 0.5;
    g = (g - 0.5) * contrast + 0.5;
    b = (b - 0.5) * contrast + 0.5;

    // Saturation
    const lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    r = lum + (r - lum) * satMultiplier;
    g = lum + (g - lum) * satMultiplier;
    b = lum + (b - lum) * satMultiplier;

    // Film Grain
    if (grain > 0) {
      const noise = (Math.random() - 0.5) * grain * 0.2;
      r += noise;
      g += noise;
      b += noise;
    }

    d[i] = Math.max(0, Math.min(255, Math.round(r * 255)));
    d[i + 1] = Math.max(0, Math.min(255, Math.round(g * 255)));
    d[i + 2] = Math.max(0, Math.min(255, Math.round(b * 255)));
  }
}

// Master Render Loop
function renderFrame() {
  const rect = canvas.getBoundingClientRect();
  const dpr = window.devicePixelRatio || 1;
  const w = Math.round(rect.width * dpr);
  const h = Math.round(rect.height * dpr);

  if (canvas.width !== w || canvas.height !== h) {
    canvas.width = w;
    canvas.height = h;
  }

  renderPhotographicScene(ctx, w, h);

  try {
    const imgData = ctx.getImageData(0, 0, w, h);
    applyColorGrade(imgData, w, h);
    ctx.putImageData(imgData, 0, 0);
  } catch (e) {
    // Ignore canvas security errors
  }

  requestAnimationFrame(renderFrame);
}

// Overlay "Shot with CaptureX" Watermark & Classic Frame
function stampWatermarkAndFrame(targetCtx, w, h) {
  if (state.frameStyle === 'none') return;

  targetCtx.save();
  const scale = (Math.min(w, h) / 720);

  if (state.frameStyle === 'border') {
    // White Gallery Border
    const borderW = 28 * scale;
    targetCtx.strokeStyle = '#ffffff';
    targetCtx.lineWidth = borderW;
    targetCtx.strokeRect(borderW / 2, borderW / 2, w - borderW, h - borderW);
  }

  if (state.frameStyle === 'watermark') {
    // "Shot with CaptureX" Badge with Official Logo
    const pad = 24 * scale;
    const logoSize = 28 * scale;
    const titleText = "Shot with CaptureX";
    const exifText = `${state.activeLens.name} • ƒ/${state.aperture} • 1/250s ISO 64`;

    const titleSize = Math.round(14 * scale);
    const subSize = Math.round(10 * scale);

    targetCtx.font = `700 ${titleSize}px 'Plus Jakarta Sans', sans-serif`;
    const titleW = targetCtx.measureText(titleText).width;

    targetCtx.font = `600 ${subSize}px 'JetBrains Mono', monospace`;
    const subW = targetCtx.measureText(exifText).width;

    const badgeW = logoSize + 14 * scale + Math.max(titleW, subW) + 24 * scale;
    const badgeH = logoSize + 16 * scale;

    const x = w - badgeW - pad;
    const y = h - badgeH - pad;

    // Dark Frosted Pill
    targetCtx.fillStyle = 'rgba(10, 13, 20, 0.82)';
    targetCtx.strokeStyle = 'rgba(255, 255, 255, 0.18)';
    targetCtx.lineWidth = 1 * scale;
    targetCtx.shadowColor = 'rgba(0, 0, 0, 0.6)';
    targetCtx.shadowBlur = 14 * scale;
    targetCtx.shadowOffsetY = 4 * scale;

    const r = 14 * scale;
    targetCtx.beginPath();
    targetCtx.roundRect(x, y, badgeW, badgeH, r);
    targetCtx.fill();
    targetCtx.stroke();

    targetCtx.shadowColor = 'transparent';
    targetCtx.shadowBlur = 0;

    // Draw Logo
    const lx = x + 12 * scale;
    const ly = y + (badgeH - logoSize) / 2;
    if (logoImg.complete && logoImg.naturalWidth > 0) {
      targetCtx.drawImage(logoImg, lx, ly, logoSize, logoSize);
    } else {
      targetCtx.strokeStyle = '#ff9f0a';
      targetCtx.lineWidth = 2 * scale;
      targetCtx.beginPath();
      targetCtx.arc(lx + logoSize / 2, ly + logoSize / 2, logoSize * 0.38, 0, Math.PI * 2);
      targetCtx.stroke();
    }

    // Text
    const tx = lx + logoSize + 10 * scale;
    targetCtx.fillStyle = '#ffffff';
    targetCtx.font = `700 ${titleSize}px 'Plus Jakarta Sans', sans-serif`;
    targetCtx.fillText(titleText, tx, y + badgeH / 2 - 2 * scale);

    targetCtx.fillStyle = 'rgba(255, 255, 255, 0.65)';
    targetCtx.font = `600 ${subSize}px 'JetBrains Mono', monospace`;
    targetCtx.fillText(exifText, tx, y + badgeH / 2 + 10 * scale);
  }

  targetCtx.restore();
}

// Export / Capture High-Res Snapshot
function exportPhoto() {
  playShutterClick();

  // Screen Flash
  const flash = document.getElementById('flashCover');
  flash.classList.add('flashing');
  setTimeout(() => flash.classList.remove('flashing'), 100);

  // 4K Export Canvas
  const outCanvas = document.createElement('canvas');
  outCanvas.width = 1440;
  outCanvas.height = 1920;
  const outCtx = outCanvas.getContext('2d');

  renderPhotographicScene(outCtx, outCanvas.width, outCanvas.height);

  const imgData = outCtx.getImageData(0, 0, outCanvas.width, outCanvas.height);
  applyColorGrade(imgData, outCanvas.width, outCanvas.height);
  outCtx.putImageData(imgData, 0, 0);

  stampWatermarkAndFrame(outCtx, outCanvas.width, outCanvas.height);

  const dataUrl = outCanvas.toDataURL('image/jpeg', 0.95);
  document.getElementById('exportImg').src = dataUrl;
  document.getElementById('btnDownloadExport').href = dataUrl;
  document.getElementById('exportModal').classList.add('open');
}

// UI Setup & Interactions
function setupUI() {
  renderLensCarousel();

  // Top Export Button
  document.getElementById('btnExportTop').addEventListener('click', exportPhoto);
  document.getElementById('btnCloseExport').addEventListener('click', () => {
    document.getElementById('exportModal').classList.remove('open');
  });

  // Tap-to-Focus Reticle on Canvas
  canvas.addEventListener('click', (e) => {
    playDialTick();
    const rect = canvas.getBoundingClientRect();
    const nx = (e.clientX - rect.left) / rect.width;
    const ny = (e.clientY - rect.top) / rect.height;

    state.focusPoint = { x: nx, y: ny };

    const reticle = document.getElementById('depthReticle');
    reticle.style.left = `${e.offsetX}px`;
    reticle.style.top = `${e.offsetY}px`;
    reticle.style.display = 'block';

    const dist = (0.5 + ny * 2.5).toFixed(1);
    document.getElementById('reticleDist').textContent = `${dist}m`;
    setTimeout(() => { reticle.style.display = 'none'; }, 1200);
  });

  // Bottom Tabs Switching (Aperture, Lens, Depth, Color Lab, Frame, Crop)
  document.querySelectorAll('.tab-item').forEach(tab => {
    tab.addEventListener('click', () => {
      playDialTick();
      document.querySelectorAll('.tab-item').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');

      const targetView = tab.dataset.tab;
      state.activeTab = targetView;

      document.querySelectorAll('.drawer-view').forEach(v => v.classList.remove('active'));

      if (targetView === 'aperture') document.getElementById('viewAperture').classList.add('active');
      else if (targetView === 'lens') document.getElementById('viewLens').classList.add('active');
      else if (targetView === 'depth') document.getElementById('viewDepth').classList.add('active');
      else if (targetView === 'colorlab') document.getElementById('viewColorLab').classList.add('active');
      else if (targetView === 'frame') document.getElementById('viewFrame').classList.add('active');
      else if (targetView === 'crop') document.getElementById('viewCrop').classList.add('active');
    });
  });

  // Aperture F-Stop Buttons
  document.querySelectorAll('.f-stop').forEach(btn => {
    btn.addEventListener('click', () => {
      playDialTick();
      document.querySelectorAll('.f-stop').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.aperture = parseFloat(btn.dataset.f);
      document.getElementById('apertureValue').textContent = `ƒ/${state.aperture}`;
      document.getElementById('badgeAperture').textContent = `ƒ/${state.aperture}`;
    });
  });

  // Depth Slider
  const depthSlider = document.getElementById('depthSlider');
  depthSlider.addEventListener('input', (e) => {
    playDialTick();
    state.depthBlur = parseInt(e.target.value);
    document.getElementById('depthValue').textContent = `${state.depthBlur}% Blur`;
  });

  // Color Lab Pills
  document.querySelectorAll('.color-pill').forEach(pill => {
    pill.addEventListener('click', () => {
      playDialTick();
      document.querySelectorAll('.color-pill').forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      state.colorPreset = pill.dataset.color;
    });
  });

  // Frame Options
  document.querySelectorAll('.frame-opt').forEach(opt => {
    opt.addEventListener('click', () => {
      playDialTick();
      document.querySelectorAll('.frame-opt').forEach(o => o.classList.remove('active'));
      opt.classList.add('active');
      state.frameStyle = opt.dataset.frame;
    });
  });

  // Crop Options
  document.querySelectorAll('.crop-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      playDialTick();
      document.querySelectorAll('.crop-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.aspectRatio = btn.dataset.aspect;

      const card = document.getElementById('photoFrameCard');
      if (state.aspectRatio === '1:1') card.style.aspectRatio = '1/1';
      else if (state.aspectRatio === '16:9') card.style.aspectRatio = '16/9';
      else if (state.aspectRatio === '3:2') card.style.aspectRatio = '3/2';
      else card.style.aspectRatio = '3/4';
    });
  });
}

function renderLensCarousel() {
  const carousel = document.getElementById('lensCarousel');
  carousel.innerHTML = CLASSIC_LENSES.map((lens, idx) => `
    <div class="lens-item-card ${idx === 0 ? 'active' : ''}" data-id="${lens.id}">
      <div class="lens-barrel-icon">
        <svg class="lens-svg-art" viewBox="0 0 48 48" fill="none" stroke="currentColor">
          <rect x="8" y="6" width="32" height="36" rx="6" stroke="#ffffff" stroke-width="2" fill="#1e2536"/>
          <line x1="8" y1="14" x2="40" y2="14" stroke="#ff9f0a" stroke-width="1.5"/>
          <line x1="8" y1="18" x2="40" y2="18" stroke="#475569" stroke-width="1"/>
          <line x1="8" y1="22" x2="40" y2="22" stroke="#475569" stroke-width="1"/>
          <line x1="8" y1="26" x2="40" y2="26" stroke="#475569" stroke-width="1"/>
          <line x1="8" y1="34" x2="40" y2="34" stroke="#ffffff" stroke-width="1.5"/>
          <circle cx="24" cy="24" r="7" stroke="#38bdf8" stroke-width="2" fill="#0f172a"/>
        </svg>
      </div>
      <span class="lens-card-name">${lens.name}</span>
      <span class="lens-card-focal">ƒ/${lens.defaultAperture}</span>
    </div>
  `).join('');

  carousel.querySelectorAll('.lens-item-card').forEach(card => {
    card.addEventListener('click', () => {
      playDialTick();
      const id = card.dataset.id;
      state.activeLens = CLASSIC_LENSES.find(l => l.id === id);
      state.aperture = parseFloat(state.activeLens.defaultAperture);

      document.querySelectorAll('.lens-item-card').forEach(c => c.classList.remove('active'));
      card.classList.add('active');

      document.getElementById('badgeLensName').textContent = state.activeLens.name;
      document.getElementById('badgeAperture').textContent = `ƒ/${state.aperture}`;
      document.getElementById('apertureValue').textContent = `ƒ/${state.aperture}`;

      // Update aperture buttons
      document.querySelectorAll('.f-stop').forEach(b => {
        b.classList.toggle('active', parseFloat(b.dataset.f) === state.aperture);
      });
    });
  });
}

// Start
window.addEventListener('DOMContentLoaded', () => {
  setupUI();
  renderFrame();
});
