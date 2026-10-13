// tools/balance/sim.js (B141) -- offline balance simulator for one story act on the real Stage 1 path.
// Usage:  node tools/balance/sim.js            (runs every scenario in SCENARIOS at the bottom)
// What it models: the real Path_Main geometry (exported from Studio), enemies walking it at their speed,
// towers placed greedily at the spots that cover the most path, First targeting, small AoE splash, average
// crits, the match economy (800 start, per-wave StartCash, split kill cash) with a simple buy policy
// (place up to the limit, then upgrade the lowest tier), waves overlapping exactly like WaveDirector
// (5 s countdown; next wave after the field clears or 45 s), 3 lives, a leaked boss = instant loss.
// It does NOT model: stuns/slows, melee dash travel, meta levels/traits/rolls (all = unit level 1 base).
'use strict';

const PATH = [[-19.5,71.8],[-8.7,71.8],[-8.0,71.2],[-8.0,58.6],[-7.4,58.0],[5.2,57.9],[5.9,58.5],[5.9,71.1],[6.5,71.8],[19.1,71.8],[19.8,71.2],[19.8,58.6],[20.4,58.0],[33.0,57.9],[33.7,58.5],[33.7,71.1],[34.3,71.8],[46.9,71.8],[47.6,71.3],[47.6,58.6],[48.2,58.0],[60.8,57.9],[61.5,58.5],[61.5,71.1],[62.1,71.8]];

// ---------- path helpers
const seg = []; let PATH_LEN = 0;
for (let i = 1; i < PATH.length; i++) { const a = PATH[i - 1], b = PATH[i]; const L = Math.hypot(b[0] - a[0], b[1] - a[1]); seg.push({ a, b, L, s0: PATH_LEN }); PATH_LEN += L; }
function posAt(s) { s = Math.max(0, Math.min(PATH_LEN, s)); for (const g of seg) { if (s <= g.s0 + g.L) { const t = (s - g.s0) / g.L; return [g.a[0] + (g.b[0] - g.a[0]) * t, g.a[1] + (g.b[1] - g.a[1]) * t]; } } return PATH[PATH.length - 1]; }
function distToPath(p) { let best = 1e9; for (const g of seg) { const dx = g.b[0] - g.a[0], dz = g.b[1] - g.a[1]; let t = ((p[0] - g.a[0]) * dx + (p[1] - g.a[1]) * dz) / (g.L * g.L); t = Math.max(0, Math.min(1, t)); best = Math.min(best, Math.hypot(p[0] - g.a[0] - dx * t, p[1] - g.a[1] - dz * t)); } return best; }
const SAMPLES = []; for (let s = 0; s <= PATH_LEN; s += 0.5) SAMPLES.push([s, posAt(s)]);
function coverage(p, R) { let n = 0; for (const [, q] of SAMPLES) if (Math.hypot(q[0] - p[0], q[1] - p[1]) <= R) n++; return n * 0.5; }

// candidate spots: a 1-stud grid around the path, 3.5+ studs from the path centre line (PathDesigns clearance)
const CANDIDATES = [];
for (let x = -30; x <= 72; x += 1) for (let z = 45; z <= 85; z += 1) { const d = distToPath([x, z]); if (d >= 3.5 && d <= 20) CANDIDATES.push([x, z]); }
function placeSpots(n, R) { // greedy: best coverage, 2.5-stud footprint apart
  const spots = []; const scored = CANDIDATES.map(p => [p, coverage(p, R)]).sort((a, b) => b[1] - a[1]);
  for (const [p] of scored) { if (spots.length >= n) break; if (spots.every(q => Math.hypot(q[0] - p[0], q[1] - p[1]) >= 2.5)) spots.push(p); }
  return spots;
}

// ---------- the sim
function simulate(sc) {
  const dt = 0.05; const unit = sc.unit; const enemiesDef = sc.enemies; const waves = sc.waves;
  let cash = sc.startCash, lives = 3, t = 0, leaks = 0, bossLeak = false, kills = 0;
  const towers = []; // { pos, tier, cd, invested }
  const spots = placeSpots(unit.limit, unit.tiers[unit.tiers.length - 1].range);
  const enemies = []; let waveIdx = 0, waveStartAt = 0, nextWaveAt = 0, waveAlive = {};
  const log = []; let bossInfo = null;
  function buy() {
    let progress = true;
    while (progress) {
      progress = false;
      if (towers.length < unit.limit && cash >= unit.cost) { cash -= unit.cost; towers.push({ pos: spots[towers.length], tier: 0, cd: 0 }); progress = true; continue; }
      if (towers.length >= Math.min(unit.limit, sc.maxTowers || 99) || cash < unit.cost) {
        let low = null; for (const tw of towers) if (tw.tier < unit.tiers.length - 1 && (!low || tw.tier < low.tier)) low = tw;
        if (low) { const c = unit.tiers[low.tier].upCost; if (cash >= c) { cash -= c; low.tier++; progress = true; } }
      }
    }
  }
  const spawnQ = []; // { at, def, hp, boss, wave }
  function launchWave(i) {
    const w = waves[i]; cash += w.cash; waveAlive[i] = 0; buy();
    for (const g of w.groups) { const def = enemiesDef[g.id]; for (let k = 0; k < g.count; k++) { spawnQ.push({ at: t + (g.delay || 0) + k * (g.every || 0.7), def, hp: g.hp, boss: !!g.boss, wave: i }); waveAlive[i]++; } }
  }
  nextWaveAt = 5; // initial countdown
  while (t < 2000) {
    // wave scheduling
    if (waveIdx < waves.length && t >= nextWaveAt) { launchWave(waveIdx); waveStartAt = t; waveIdx++; nextWaveAt = t + 45 + 5; }
    if (waveIdx < waves.length && waveIdx > 0 && waveAlive[waveIdx - 1] === 0 && nextWaveAt > t + 5) nextWaveAt = t + 5;
    // spawns
    for (let i = spawnQ.length - 1; i >= 0; i--) if (spawnQ[i].at <= t) { const q = spawnQ[i]; enemies.push({ s: 0, hp: q.hp, max: q.hp, speed: q.def.speed, boss: q.boss, wave: q.wave, cash: q.def.cash, dmg: q.boss ? 99999 : 1 }); spawnQ.splice(i, 1); }
    // move
    for (let i = enemies.length - 1; i >= 0; i--) { const e = enemies[i]; e.s += e.speed * dt; if (e.s >= PATH_LEN) { lives -= e.dmg; leaks++; if (e.boss) { bossLeak = true; bossInfo = { leakedWithHp: e.hp, max: e.max }; } waveAlive[e.wave]--; enemies.splice(i, 1); } }
    if (lives <= 0) return { win: false, wave: waveIdx, leaks, t, cash, towers: towers.map(x => x.tier + 1), bossInfo, bossLeak };
    // towers attack
    for (const tw of towers) {
      tw.cd -= dt; if (tw.cd > 0) continue;
      const st = unit.tiers[tw.tier]; let target = null;
      for (const e of enemies) { const p = posAt(e.s); if (Math.hypot(p[0] - tw.pos[0], p[1] - tw.pos[1]) <= st.range && (!target || e.s > target.s)) target = e; }
      if (!target) continue;
      const crit = 1 + (st.crit || 0) * ((st.critMult || 2) - 1);
      const tp = posAt(target.s);
      for (const e of enemies) {
        if (e === target) { const fh = (unit.firstHit && !e.hitBy) ? unit.firstHit : 1; e.hp -= st.dmg * crit * fh; e.hitBy = true; }
        else if (st.aoe) { const p = posAt(e.s); if (Math.hypot(p[0] - tp[0], p[1] - tp[1]) <= st.aoe) e.hp -= st.dmg * crit * (st.falloff || 0.6); }
      }
      tw.cd = st.spa;
    }
    for (let i = enemies.length - 1; i >= 0; i--) { const e = enemies[i]; if (e.hp <= 0) { kills++; cash += e.cash * (sc.killShare || 1); if (e.boss) bossInfo = { killedAtPathPct: Math.round(100 * e.s / PATH_LEN), max: e.max }; waveAlive[e.wave]--; enemies.splice(i, 1); } }
    buy();
    if (waveIdx >= waves.length && enemies.length === 0 && spawnQ.length === 0) return { win: true, wave: waveIdx, leaks, t: Math.round(t), cash: Math.round(cash), towers: towers.map(x => x.tier + 1), bossInfo, kills };
    t += dt;
  }
  return { win: false, timeout: true };
}

module.exports = { simulate, PATH_LEN, coverage, placeSpots };
const STARTERS_TABLE = {
  Bantong: { cost: 150, limit: 4, tiers: [ { dmg: 10, spa: 1.8, range: 12, crit: 0.07, aoe: 2.5, falloff: 0.5, upCost: 120 }, { dmg: 13, spa: 1.8, range: 12, crit: 0.08, aoe: 2.5, upCost: 180 }, { dmg: 17, spa: 1.75, range: 13, crit: 0.09, aoe: 2.5, upCost: 260 }, { dmg: 22, spa: 1.7, range: 13, crit: 0.1, aoe: 3, upCost: 360 }, { dmg: 29, spa: 1.65, range: 14, crit: 0.12, aoe: 3.5 } ] },
  Baltog: { cost: 150, limit: 4, tiers: [ { dmg: 8, spa: 1.1, range: 10, crit: 0.05, upCost: 120 }, { dmg: 10, spa: 1.05, range: 10, crit: 0.06, upCost: 180 }, { dmg: 13, spa: 1.0, range: 11, crit: 0.07, upCost: 260 }, { dmg: 17, spa: 0.95, range: 11, crit: 0.08, upCost: 360 }, { dmg: 22, spa: 0.9, range: 12, crit: 0.1 } ] },
  Handyong: { cost: 150, limit: 4, tiers: [ { dmg: 9, spa: 2.2, range: 19, crit: 0.05, aoe: 3, falloff: 0.6, upCost: 120 }, { dmg: 12, spa: 2.2, range: 19, crit: 0.06, aoe: 3, upCost: 180 }, { dmg: 15, spa: 2.15, range: 20, crit: 0.07, aoe: 3, upCost: 260 }, { dmg: 20, spa: 2.1, range: 21, crit: 0.08, aoe: 3.5, upCost: 360 }, { dmg: 26, spa: 2.0, range: 22, crit: 0.1, aoe: 3.5 } ] },
};
module.exports.STARTERS_FOR_CEILING = STARTERS_TABLE;

// ---------------------------------------------------------------- scenarios (edit + rerun)
if (require.main === module && process.argv[2] !== 'ceiling') {
  const ENEMIES = { grunt: { speed: 1, cash: 4, hp: 1 }, tank: { speed: 0.75, cash: 6, hp: 1.6 }, rat: { speed: 1.8, cash: 5, hp: 0.7 } };
  const STARTERS = {
    Bantong: { cost: 150, limit: 4, tiers: [ { dmg: 10, spa: 1.8, range: 12, crit: 0.07, aoe: 2.5, falloff: 0.5, upCost: 120 }, { dmg: 13, spa: 1.8, range: 12, crit: 0.08, aoe: 2.5, upCost: 180 }, { dmg: 17, spa: 1.75, range: 13, crit: 0.09, aoe: 2.5, upCost: 260 }, { dmg: 22, spa: 1.7, range: 13, crit: 0.1, aoe: 3, upCost: 360 }, { dmg: 29, spa: 1.65, range: 14, crit: 0.12, aoe: 3.5 } ] },
    Baltog: { cost: 150, limit: 4, tiers: [ { dmg: 8, spa: 1.1, range: 10, crit: 0.05, upCost: 120 }, { dmg: 10, spa: 1.05, range: 10, crit: 0.06, upCost: 180 }, { dmg: 13, spa: 1.0, range: 11, crit: 0.07, upCost: 260 }, { dmg: 17, spa: 0.95, range: 11, crit: 0.08, upCost: 360 }, { dmg: 22, spa: 0.9, range: 12, crit: 0.1 } ] },
    Handyong: { cost: 150, limit: 4, tiers: [ { dmg: 9, spa: 2.2, range: 19, crit: 0.05, aoe: 3, falloff: 0.6, upCost: 120 }, { dmg: 12, spa: 2.2, range: 19, crit: 0.06, aoe: 3, upCost: 180 }, { dmg: 15, spa: 2.15, range: 20, crit: 0.07, aoe: 3, upCost: 260 }, { dmg: 20, spa: 2.1, range: 21, crit: 0.08, aoe: 3.5, upCost: 360 }, { dmg: 26, spa: 2.0, range: 22, crit: 0.1, aoe: 3.5 } ] },
  };
  const col = (start, g, n) => Array.from({ length: n }, (_, i) => Math.round(start * Math.pow(g, i)));
  function act(waveHp, lines, actScale, bossRatio) {
    return lines.map((groups, i) => ({
      cash: Math.round(125 * Math.pow(1.08, i) / 5) * 5 * (groups.some(g => g.boss) ? 2 : 1),
      groups: groups.map(g => ({ ...g, hp: Math.round(waveHp[i] * actScale * (g.boss ? bossRatio : ENEMIES[g.id].hp) * (g.hpScale || 1)) })),
    }));
  }
  const G = (n, o) => ({ id: 'grunt', count: n, every: 0.7, ...o }), T = (n, o) => ({ id: 'tank', count: n, every: 1.1, ...o }), R = (n, o) => ({ id: 'rat', count: n, every: 0.5, ...o });
  const BOSS = (o) => ({ id: 'grunt', count: 1, boss: true, delay: 4, ...o });
  const ACT1 = [
    [G(5)], [G(7)], [G(6), T(2)], [G(8), R(3)], [G(8), T(3)], [G(10), R(4)], [G(10), T(3), R(3)], [G(12), T(4)],
    [G(12), R(6)], [G(14), T(4), R(4)], [G(14), T(5), R(5)], [G(16), T(5), R(6)], [G(18), T(6), R(6)], [G(20), T(6), R(8)],
    [G(12), T(4), BOSS({ speed: 0.6 })],
  ];
  const HP = col(Number(process.env.HP0 || 20), Number(process.env.HPG || 1.10), 15);
  const bossRatio = Number(process.env.BOSS || 25);
  console.log('PATH_LEN', PATH_LEN.toFixed(1), 'WAVE_HP', JSON.stringify(HP), 'bossRatio', bossRatio);
  for (const [name, unit] of Object.entries(STARTERS)) {
    for (const maxT of [4]) {
      const enemies = { ...ENEMIES }; // boss uses grunt def with its own speed
      const waves = act(HP, ACT1, 1.0, bossRatio).map(w => ({ ...w, groups: w.groups.map(g => g.boss ? { ...g } : g) }));
      // boss speed override
      enemies.boss = { speed: 0.6, cash: 150 };
      waves.forEach(w => w.groups.forEach(g => { if (g.boss) g.id = 'boss'; }));
      const r = simulate({ unit, enemies, waves, startCash: 800, maxTowers: maxT });
      const cov = placeSpots(4, unit.tiers[0].range).map(p => coverage(p, unit.tiers[0].range));
      console.log(name.padEnd(9), 'cov/tower', cov.map(c => c.toFixed(0)).join(','), '=>', JSON.stringify(r));
    }
  }
}

// ---------------------------------------------------------------- CEILING SEARCH: `node tools/balance/sim.js ceiling`
// For each starter and tower count, binary-search the largest act HP multiplier it still beats with 0 boss leak
// and <= 1 life lost. "Act HP multiplier" = StageScale x ActScale x mode/co-op, i.e. how strong an act can get.
if (require.main === module && process.argv[2] === 'ceiling') {
  const ENEMIES = { grunt: { speed: 1, cash: 4 }, tank: { speed: 0.75, cash: 6 }, rat: { speed: 1.8, cash: 5 }, boss: { speed: 0.6, cash: 150 } };
  const RATIO = { grunt: 1, tank: 1.6, rat: 0.7 };
  const STARTERS = module.exports.STARTERS_FOR_CEILING;
  const HP = [20, 22, 24, 27, 29, 32, 35, 39, 43, 47, 52, 57, 63, 69, 76];
  const G = (n) => ({ id: 'grunt', count: n, every: 0.7 }), T = (n) => ({ id: 'tank', count: n, every: 1.1 }), R = (n) => ({ id: 'rat', count: n, every: 0.5 });
  const ACT = [[G(5)], [G(7)], [G(6), T(2)], [G(8), R(3)], [G(8), T(3)], [G(10), R(4)], [G(10), T(3), R(3)], [G(12), T(4)], [G(12), R(6)], [G(14), T(4), R(4)], [G(14), T(5), R(5)], [G(16), T(5), R(6)], [G(18), T(6), R(6)], [G(20), T(6), R(8)], [G(12), T(4), { id: 'boss', count: 1, boss: true, delay: 4 }]];
  const bossRatio = Number(process.env.BOSS || 25);
  function waves(mult) { return ACT.map((groups, i) => ({ cash: Math.round(125 * Math.pow(1.08, i) / 5) * 5 * (groups.some(g => g.boss) ? 2 : 1), groups: groups.map(g => ({ ...g, hp: HP[i] * mult * (g.boss ? bossRatio : RATIO[g.id]) })) })); }
  for (const [name, unit] of Object.entries(STARTERS)) {
    const row = [];
    for (const n of [2, 3, 4]) {
      const u = { ...unit, limit: n };
      let lo = 0.1, hi = 40;
      for (let k = 0; k < 22; k++) { const mid = Math.sqrt(lo * hi); const r = simulate({ unit: u, enemies: ENEMIES, waves: waves(mid), startCash: 800 }); if (r.win && r.leaks <= 1) lo = mid; else hi = mid; }
      row.push(`${n} towers: x${lo.toFixed(2)}`);
    }
    console.log(name.padEnd(9), row.join('   '));
  }
}
