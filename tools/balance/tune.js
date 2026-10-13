// tools/balance/tune.js -- try starter tier tables against the act ceiling search (prints x-multiplier per tower count)
'use strict';
const { simulate } = require('./sim.js');
const ENEMIES = { grunt: { speed: 1, cash: 4 }, tank: { speed: 0.75, cash: 6 }, rat: { speed: 1.8, cash: 5 }, boss: { speed: 0.6, cash: 150 } };
const RATIO = { grunt: 1, tank: 1.6, rat: 0.7 };
const HP = [20, 22, 24, 27, 29, 32, 35, 39, 43, 47, 52, 57, 63, 69, 76];
const G = (n) => ({ id: 'grunt', count: n, every: 0.7 }), T = (n) => ({ id: 'tank', count: n, every: 1.1 }), R = (n) => ({ id: 'rat', count: n, every: 0.5 });
const ACT = [[G(5)], [G(7)], [G(6), T(2)], [G(8), R(3)], [G(8), T(3)], [G(10), R(4)], [G(10), T(3), R(3)], [G(12), T(4)], [G(12), R(6)], [G(14), T(4), R(4)], [G(14), T(5), R(5)], [G(16), T(5), R(6)], [G(18), T(6), R(6)], [G(20), T(6), R(8)], [G(12), T(4), { id: 'boss', count: 1, boss: true, delay: 4 }]];
const bossRatio = Number(process.env.BOSS || 25);
function waves(mult) { return ACT.map((groups, i) => ({ cash: Math.round(125 * Math.pow(1.08, i) / 5) * 5 * (groups.some(g => g.boss) ? 2 : 1), groups: groups.map(g => ({ ...g, hp: HP[i] * mult * (g.boss ? bossRatio : RATIO[g.id]) })) })); }
// tier builder: base stats + per-tier growth (dmg x1.3/tier, spa -0.05/tier, range +0.5/tier), costs 120/180/260/360
function tiers(dmg, spa, range, extra) {
  const out = []; const ups = [120, 180, 260, 360];
  for (let i = 0; i < 5; i++) out.push({ dmg: Math.round(dmg * Math.pow(1.3, i)), spa: +(spa - 0.05 * i).toFixed(2), range: +(range + 0.5 * i).toFixed(1), crit: 0.05 + 0.015 * i, ...extra, upCost: ups[i] });
  return out;
}
function ceiling(unit) {
  const row = [];
  for (const n of [2, 3, 4]) {
    const u = { ...unit, limit: n }; let lo = 0.1, hi = 40;
    for (let k = 0; k < 20; k++) { const mid = Math.sqrt(lo * hi); const r = simulate({ unit: u, enemies: ENEMIES, waves: waves(mid), startCash: 800 }); if (r.win && r.leaks <= 1) lo = mid; else hi = mid; }
    row.push(lo.toFixed(2));
  }
  return row;
}
const C = JSON.parse(process.argv[2]);
for (const [name, c] of Object.entries(C)) {
  const unit = { cost: c.cost || 150, limit: 4, firstHit: c.firstHit, tiers: tiers(c.dmg, c.spa, c.range, c.extra || {}) };
  console.log(name.padEnd(9), JSON.stringify(c).padEnd(70), 'x', ceiling(unit).join(' / '));
}
