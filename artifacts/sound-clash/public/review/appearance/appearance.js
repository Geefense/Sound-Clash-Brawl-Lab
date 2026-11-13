/*
 * Isolated appearance-review preview for the Feedback 17-pose pack.
 * Reads the pack's own feedback.poses.json for canvas size, origins and anchors.
 * One display scale for every pose; no per-figure fitting. Nothing here touches
 * the game, the simulation, hitboxes or the source PNGs.
 */
(() => {
  'use strict';

  const MANIFEST_URL = '/assets/feedback/feedback.poses.json';
  const PACK_DIR = '/assets/feedback/';
  const DPR = Math.min(window.devicePixelRatio || 1, 2);
  const FLOOR_PAD = 68;

  // Four-key movement reference. Different canvas (460x620), support sole pinned
  // at y = 566, torso centred at x = 230 — one alignment for all four keys.
  const WALK = [
    { title: 'OLDER STUDY · CONTACT A', file: '01_contact_a.png' },
    { title: 'OLDER STUDY · PASS A', file: '02_pass_a.png' },
    { title: 'OLDER STUDY · CONTACT B', file: '03_contact_b.png' },
    { title: 'OLDER STUDY · PASS B', file: '04_pass_b.png' },
  ];
  const WALK_BOX = { w: 460, h: 620, ax: 230, ay: 566 };

  const SEQUENCE = [
    { type: 'pack', id: '01_idle', title: 'IDLE' },
    { type: 'walk', i: 0 },
    { type: 'walk', i: 1 },
    { type: 'walk', i: 2 },
    { type: 'walk', i: 3 },
    { type: 'pack', id: '12_backhand_windup', title: 'BOX WINDUP' },
    { type: 'pack', id: '13_box_palm', title: 'BOX CONTACT' },
    { type: 'pack', id: '14_followthrough', title: 'BOX RECOVERY' },
    { type: 'pack', id: '08_block', title: 'BLOCK' },
    { type: 'pack', id: '16_gut_punch', title: 'HURT' },
    { type: 'pack', id: '17_seated_landing', title: 'LANDING' },
    { type: 'pack', id: '02_knockout', title: 'KO' },
  ];

  const state = {
    idx: 0,
    playing: true,
    holdMs: 1200,
    scale: 0.42,
    anchors: false,
    ghost: false,
    lines: true,
  };

  const $ = (id) => document.getElementById(id);
  const els = {
    seq: $('seq'),
    ref: $('ref'),
    meta: $('meta'),
    paneLabel: $('paneLabel'),
    poseMeta: $('poseMeta'),
    badge: $('badge'),
    refMeta: $('refMeta'),
    strip: $('strip'),
    checkList: $('checkList'),
    poseNote: $('poseNote'),
    original: $('original'),
    play: $('play'),
    prev: $('prev'),
    next: $('next'),
    hold: $('hold'),
    scale: $('scale'),
    scaleOut: $('scaleOut'),
    anchors: $('anchors'),
    ghost: $('ghost'),
    lines: $('lines'),
  };

  let manifest = null;
  const images = new Map(); // key -> { img, ok, entry }
  let timer = null;

  const review = window.REVIEW || { poses: {} };

  function setupCanvas(canvas) {
    const w = Number(canvas.getAttribute('width'));
    const h = Number(canvas.getAttribute('height'));
    canvas.width = Math.round(w * DPR);
    canvas.height = Math.round(h * DPR);
    canvas.style.aspectRatio = `${w} / ${h}`;
    return { ctx: canvas.getContext('2d'), w, h };
  }

  function loadImage(key, src) {
    if (images.has(key)) return images.get(key);
    const rec = { img: new Image(), ok: false, error: null };
    rec.img.onload = () => {
      rec.ok = true;
      draw();
    };
    rec.img.onerror = () => {
      rec.error = 'missing';
      draw();
    };
    rec.img.src = src;
    images.set(key, rec);
    return rec;
  }

  function packEntry(id) {
    const pose = manifest.poses[id];
    return {
      kind: 'pack',
      id,
      pose,
      rec: loadImage(`pack:${id}`, `${PACK_DIR}${pose.file}`),
      w: manifest.canvas[0],
      h: manifest.canvas[1],
      ax: pose.anchorPx[0],
      ay: pose.anchorPx[1],
      placement: pose.placement,
      facing: pose.facing,
      bounds: pose.alphaBounds,
      src: `${PACK_DIR}${pose.file}`,
    };
  }

  function walkEntry(i) {
    const key = WALK[i];
    return {
      kind: 'walk',
      id: `walk-${i + 1}`,
      title: key.title,
      rec: loadImage(`walk:${i}`, `/review/appearance/walk/${key.file}`),
      w: WALK_BOX.w,
      h: WALK_BOX.h,
      ax: WALK_BOX.ax,
      ay: WALK_BOX.ay,
      placement: 'feet',
      facing: 'right',
      bounds: null,
      src: `/review/appearance/walk/${key.file}`,
    };
  }

  function entryFor(step) {
    return step.type === 'pack' ? packEntry(step.id) : walkEntry(step.i);
  }

  function anchorY(entry, floorY, S) {
    if (entry.kind === 'pack' && entry.placement === 'pelvis') {
      // Manifest keeps airborne poses on a pelvis anchor: hold that point 290
      // canvas px above the floor (groundBaselineY 900 minus anchor 610).
      return floorY - (manifest.groundBaselineY - entry.ay) * S;
    }
    return floorY;
  }

  function drawPose(ctx, entry, S, W, H, opts = {}) {
    const floorY = H - FLOOR_PAD;
    const tx = opts.tx ?? W / 2;
    const ty = anchorY(entry, floorY, S);
    const rec = entry.rec;

    if (opts.lines) {
      ctx.save();
      ctx.strokeStyle = 'rgba(126, 166, 255, 0.55)';
      ctx.setLineDash([6, 5]);
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(0, floorY + 0.5);
      ctx.lineTo(W, floorY + 0.5);
      ctx.stroke();

      const pelvisY = floorY - (manifest.groundBaselineY - 610) * S;
      ctx.strokeStyle = 'rgba(226, 178, 116, 0.5)';
      ctx.beginPath();
      ctx.moveTo(0, pelvisY + 0.5);
      ctx.lineTo(W, pelvisY + 0.5);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.font = '11px ui-monospace, monospace';
      ctx.fillStyle = 'rgba(126, 166, 255, 0.85)';
      ctx.fillText('floor  y900', 8, floorY - 6);
      ctx.fillStyle = 'rgba(226, 178, 116, 0.85)';
      ctx.fillText('pelvis  y610', 8, pelvisY - 6);
      ctx.restore();
    }

    if (!rec.ok && !rec.error) {
      ctx.fillStyle = '#9aa1b3';
      ctx.font = '13px ui-sans-serif, system-ui, sans-serif';
      ctx.fillText('loading…', 12, 24);
      return;
    }
    if (rec.error) {
      ctx.fillStyle = '#ff7f7f';
      ctx.font = '13px ui-sans-serif, system-ui, sans-serif';
      ctx.fillText(`missing file: ${entry.src}`, 12, 24);
      return;
    }

    const dw = entry.w * S;
    const dh = entry.h * S;
    const dx = tx - entry.ax * S;
    const dy = ty - entry.ay * S;

    if (opts.ghost) {
      const idle = packEntry('01_idle');
      if (idle.rec.ok) {
        const gy = anchorY(idle, floorY, S);
        ctx.save();
        ctx.globalAlpha = 0.22;
        ctx.drawImage(idle.rec.img, tx - idle.ax * S, gy - idle.ay * S, idle.w * S, idle.h * S);
        ctx.restore();
      }
    }

    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(rec.img, dx, dy, dw, dh);

    if (opts.anchors) {
      ctx.save();
      ctx.strokeStyle = 'rgba(124, 214, 165, 0.9)';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(tx - 9, ty + 0.5);
      ctx.lineTo(tx + 9, ty + 0.5);
      ctx.moveTo(tx + 0.5, ty - 9);
      ctx.lineTo(tx + 0.5, ty + 9);
      ctx.stroke();
      ctx.strokeStyle = 'rgba(124, 214, 165, 0.45)';
      ctx.setLineDash([4, 4]);
      ctx.strokeRect(dx, dy, dw, dh);
      if (entry.bounds) {
        const [x0, y0, x1, y1] = entry.bounds;
        ctx.strokeStyle = 'rgba(255, 207, 110, 0.75)';
        ctx.setLineDash([3, 3]);
        ctx.strokeRect(
          tx + (x0 - entry.ax) * S,
          ty + (y0 - entry.ay) * S,
          (x1 - x0) * S,
          (y1 - y0) * S,
        );
      }
      ctx.setLineDash([]);
      ctx.font = '10.5px ui-monospace, monospace';
      ctx.fillStyle = 'rgba(124, 214, 165, 0.95)';
      ctx.fillText(`origin ${entry.ax},${entry.ay}`, tx + 12, ty + 4);
      ctx.restore();
    }
  }

  let seqCanvas = null;
  let refCanvas = null;

  function draw() {
    if (!manifest || !seqCanvas) return;
    const S = state.scale;

    seqCanvas.ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    seqCanvas.ctx.clearRect(0, 0, seqCanvas.w, seqCanvas.h);
    const step = SEQUENCE[state.idx];
    const entry = entryFor(step);
    drawPose(seqCanvas.ctx, entry, S, seqCanvas.w, seqCanvas.h, {
      lines: state.lines,
      anchors: state.anchors,
      ghost: state.ghost && !(entry.kind === 'pack' && entry.id === '01_idle'),
    });

    refCanvas.ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    refCanvas.ctx.clearRect(0, 0, refCanvas.w, refCanvas.h);
    drawPose(refCanvas.ctx, packEntry('01_idle'), S, refCanvas.w, refCanvas.h, {
      lines: state.lines,
      anchors: state.anchors,
    });
  }

  function badgeFor(step) {
    if (step.type !== 'pack') return { text: 'unapproved', cls: 'uncertain' };
    const v = review.poses[step.id];
    return v ? { text: v.status, cls: v.status } : { text: 'unreviewed', cls: 'uncertain' };
  }

  function renderStrip() {
    els.strip.innerHTML = '';
    SEQUENCE.forEach((step, i) => {
      const b = badgeFor(step);
      const title =
        step.type === 'walk'
          ? WALK[step.i].title
          : (review.poses[step.id] || {}).label || step.id;
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = `step${i === state.idx ? ' active' : ''}${step.type === 'walk' ? ' walk' : ''}`;
      btn.innerHTML = `<span class="n">${String(i + 1).padStart(2, '0')}${step.type === 'walk' ? ' walk' : ''}</span>
        <span class="t">${title}</span>
        <span class="b badge ${b.cls}">${b.text}</span>`;
      btn.addEventListener('click', () => {
        state.idx = i;
        pause();
        sync();
      });
      els.strip.appendChild(btn);
    });
  }

  function renderChecks() {
    const step = SEQUENCE[state.idx];
    els.checkList.innerHTML = '';
    if (step.type === 'pack') {
      const v = review.poses[step.id];
      if (!v) {
        els.poseNote.textContent = 'No verdict recorded for this pose.';
        return;
      }
      v.checks.forEach(([name, status, evidence]) => {
        const row = document.createElement('div');
        row.className = 'check-row';
        row.innerHTML = `<span class="name">${name}</span>
          <span class="badge ${status}">${status}</span>
          <span class="ev">${evidence}</span>`;
        els.checkList.appendChild(row);
      });
      els.poseNote.textContent = v.note || '';
    } else {
      const key = WALK[step.i];
      const row = document.createElement('div');
      row.className = 'check-row';
      row.innerHTML = `<span class="name">walk key</span>
        <span class="badge uncertain">outside pack</span>
        <span class="ev">Earlier four-key study (right-hand mic, one mic, one cable), kept for comparison only. Its own note calls it an unapproved movement test; it is <em>not</em> the approved 132 BPM reference, which is the separate block above. Outside the 17-pose audit, and it still carries a floor-bound cable terminal.</span>`;
      els.checkList.appendChild(row);
      els.poseNote.textContent =
        'Different canvas and alignment from the pack. Shown so the sequence can be stepped idle → walk → BOX without implying the two sets are interchangeable. The approved four-pose 132 BPM reference is reviewed in its own block, not here.';
    }
  }

  function sync() {
    const step = SEQUENCE[state.idx];
    const entry = entryFor(step);
    const b = badgeFor(step);

    els.paneLabel.textContent = step.type === 'pack' ? step.id : entry.title;
    els.badge.textContent = b.text;
    els.badge.className = `badge ${b.cls}`;
    els.original.href = entry.src;

    if (step.type === 'pack' && entry.pose) {
      els.poseMeta.textContent = `${entry.pose.placement} · facing ${entry.pose.facing} · anchor ${entry.ax},${entry.ay} · origin ${entry.pose.origin.map((n) => n.toFixed(3)).join(', ')} · ${entry.pose.airborne ? 'airborne' : 'grounded'}`;
    } else {
      els.poseMeta.textContent = `four-key reference · canvas ${WALK_BOX.w}×${WALK_BOX.h} · sole y${WALK_BOX.ay}`;
    }

    els.strip.querySelectorAll('.step').forEach((el, i) => {
      el.classList.toggle('active', i === state.idx);
    });
    renderChecks();
    draw();
  }

  function step(delta) {
    state.idx = (state.idx + delta + SEQUENCE.length) % SEQUENCE.length;
    sync();
  }

  function pause() {
    state.playing = false;
    if (timer) clearTimeout(timer);
    timer = null;
    els.play.textContent = '▶ Play';
  }

  function play() {
    state.playing = true;
    els.play.textContent = '❚❚ Pause';
    tick();
  }

  function tick() {
    if (timer) clearTimeout(timer);
    if (!state.playing) return;
    timer = setTimeout(() => {
      step(1);
      tick();
    }, state.holdMs);
  }

  function wire() {
    els.play.addEventListener('click', () => (state.playing ? pause() : play()));
    els.prev.addEventListener('click', () => {
      pause();
      step(-1);
    });
    els.next.addEventListener('click', () => {
      pause();
      step(1);
    });
    els.hold.addEventListener('change', () => {
      state.holdMs = Number(els.hold.value);
    });
    els.scale.addEventListener('input', () => {
      state.scale = Number(els.scale.value) / 100;
      els.scaleOut.value = state.scale.toFixed(2);
      draw();
    });
    els.anchors.addEventListener('change', () => {
      state.anchors = els.anchors.checked;
      draw();
    });
    els.ghost.addEventListener('change', () => {
      state.ghost = els.ghost.checked;
      draw();
    });
    els.lines.addEventListener('change', () => {
      state.lines = els.lines.checked;
      draw();
    });

    window.addEventListener('keydown', (ev) => {
      const tag = (ev.target && ev.target.tagName) || '';
      if (tag === 'INPUT' || tag === 'SELECT' || tag === 'TEXTAREA') return;
      if (ev.key === 'ArrowRight') {
        pause();
        step(1);
      } else if (ev.key === 'ArrowLeft') {
        pause();
        step(-1);
      } else if (ev.key === ' ') {
        ev.preventDefault();
        state.playing ? pause() : play();
      } else if (ev.key === 'a') {
        els.anchors.checked = !els.anchors.checked;
        els.anchors.dispatchEvent(new Event('change'));
      } else if (ev.key === 'g') {
        els.ghost.checked = !els.ghost.checked;
        els.ghost.dispatchEvent(new Event('change'));
      }
    });
  }

  /* ---- Approved movement reference, restored from the 2026-11-13 transfer package ---- */
  const MV_BASE = '/review/appearance/movement/';
  const MV_FLOOR = 571; // measured support-sole line inside the 460 x 620 panel
  const mv = { manifest: null, imgs: [], idx: 0, playing: true, timer: null };

  function mvName(file) {
    return file
      .replace(/\.(webp|png)$/i, '')
      .replace(/^\d+_/, '')
      .replace(/_/g, ' ')
      .toUpperCase();
  }

  function mvDraw() {
    const canvas = document.getElementById('mv');
    if (!canvas || !mv.manifest) return;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.save();
    ctx.strokeStyle = 'rgba(126, 166, 255, 0.5)';
    ctx.setLineDash([6, 5]);
    ctx.beginPath();
    ctx.moveTo(0, MV_FLOOR + 0.5);
    ctx.lineTo(canvas.width, MV_FLOOR + 0.5);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.font = '11px ui-monospace, monospace';
    ctx.fillStyle = 'rgba(126, 166, 255, 0.8)';
    ctx.fillText('panel sole line  y571', 8, MV_FLOOR - 6);

    const key = mv.manifest.keys[mv.idx];
    const img = mv.imgs[mv.idx];
    if (img && img.naturalWidth) {
      ctx.drawImage(img, key.preview.x, key.preview.y, key.preview.width, key.preview.height);
    } else {
      ctx.fillStyle = '#ff7f7f';
      ctx.font = '13px ui-sans-serif, system-ui, sans-serif';
      ctx.fillText(img && img.dataset.failed ? `missing: ${key.file}` : 'loading…', 12, 46);
    }

    ctx.font = 'bold 15px ui-monospace, monospace';
    ctx.fillStyle = '#ffd899';
    ctx.fillText(`${mv.idx + 1}/4 · ${mvName(key.file)}`, 12, 26);
    ctx.restore();

    const info = document.getElementById('mvInfo');
    if (info) {
      info.textContent = `key ${mv.idx + 1} / 4 · ${key.preview.width}×${key.preview.height} at ${key.preview.x},${key.preview.y} · ${mv.manifest.poseFrames[mv.idx]} frames`;
    }
  }

  function mvTick() {
    if (mv.timer) clearTimeout(mv.timer);
    if (!mv.playing || !mv.manifest) return;
    const hold = (mv.manifest.poseFrames[mv.idx] / mv.manifest.fps) * 1000;
    mv.timer = setTimeout(() => {
      mv.idx = (mv.idx + 1) % mv.manifest.keys.length;
      mvDraw();
      mvTick();
    }, hold);
  }

  async function initMovement() {
    const canvas = document.getElementById('mv');
    if (!canvas) return;
    const res = await fetch(`${MV_BASE}reference-manifest.json`, { cache: 'no-cache' });
    if (!res.ok) throw new Error(`movement manifest ${res.status}`);
    mv.manifest = await res.json();

    mv.imgs = mv.manifest.keys.map((k) => {
      const img = new Image();
      img.onload = mvDraw;
      img.onerror = () => {
        img.dataset.failed = '1';
        mvDraw();
      };
      img.src = `${MV_BASE}${k.file}`;
      return img;
    });

    const meta = document.getElementById('mvMeta');
    if (meta) {
      meta.textContent = `${mv.manifest.effectiveBpm.toFixed(2)} BPM · ${mv.manifest.cycleFrames} frames / cycle @ ${mv.manifest.fps} fps · holds ${mv.manifest.poseFrames.join(' / ')}`;
    }

    const playBtn = document.getElementById('mvPlay');
    playBtn.addEventListener('click', () => {
      mv.playing = !mv.playing;
      playBtn.textContent = mv.playing ? '❚❚ Pause loop' : '▶ Play loop';
      if (mv.playing) mvTick();
      else if (mv.timer) clearTimeout(mv.timer);
    });

    document.getElementById('mvStep').addEventListener('click', () => {
      mv.playing = false;
      playBtn.textContent = '▶ Play loop';
      if (mv.timer) clearTimeout(mv.timer);
      mv.idx = (mv.idx + 1) % mv.manifest.keys.length;
      mvDraw();
    });

    // The cloud preview browser does not always issue a media request; say so instead of
    // showing a dead player. The file itself is served with range support.
    const video = document.getElementById('mvVideo');
    const note = document.getElementById('mvVideoNote');
    const reportVideoFailure = () => {
      if (!note) return;
      note.hidden = false;
      note.innerHTML = `The clip did not load inline in this browser (no media request was issued). <a class="link" style="margin-left:0" href="/review/appearance/movement/Feedback_Walk_132BPM_Preferred.mp4" target="_blank" rel="noreferrer">Open it directly ↗</a> — the file serves normally with byte-range support.`;
    };
    if (video) {
      video.addEventListener('error', reportVideoFailure);
      video.addEventListener('loadedmetadata', () => {
        if (note) note.hidden = true;
      });
      // Generous, because metadata over the preview proxy can take several seconds.
      setTimeout(() => {
        if (video.readyState === 0) reportVideoFailure();
      }, 8000);
    }

    mvDraw();
    mvTick();
  }

  async function main() {
    seqCanvas = setupCanvas(els.seq);
    refCanvas = setupCanvas(els.ref);
    wire();

    try {
      const res = await fetch(MANIFEST_URL, { cache: 'no-cache' });
      if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
      manifest = await res.json();

      const ids = Object.keys(manifest.poses);
      const counts = ids.reduce(
        (acc, id) => {
          const v = review.poses[id];
          if (v) acc[v.status] = (acc[v.status] || 0) + 1;
          return acc;
        },
        { pass: 0, fail: 0, uncertain: 0 },
      );

      els.meta.innerHTML = `<b>${ids.length}</b> poses · canvas ${manifest.canvas.join('×')} · origin base ${manifest.groundBaselineY}<br />
        verdicts: <b>${counts.fail}</b> fail · <b>${counts.uncertain}</b> uncertain · <b>${counts.pass}</b> pass<br />
        branch ${review.branch || 'review'}`;

      renderStrip();
      els.refMeta.textContent = `anchor ${manifest.poses['01_idle'].anchorPx.join(',')} · origin ${manifest.poses['01_idle'].origin.map((n) => n.toFixed(3)).join(', ')}`;
      sync();
      play();
    } catch (err) {
      els.meta.textContent = `manifest failed: ${err.message}`;
    }

    initMovement().catch((err) => {
      const meta = document.getElementById('mvMeta');
      if (meta) meta.textContent = `movement reference failed: ${err.message}`;
    });
  }

  main();
})();
