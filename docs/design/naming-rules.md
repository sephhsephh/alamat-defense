# Naming rules (player-facing names)
<!-- owner: AD-Game (applies to every chat) | since: B143 (2026-10-13) | user rule -->

Alamat Defense targets **worldwide players**, not only Filipinos. Player-facing names must read instantly in English.

| What | Filipino / myth name allowed? | Examples |
|---|---|---|
| Towers / units | **Yes** -- they are the myth heroes | Apolaki, Kapre, Lam-ang, Duwende |
| Bosses | **Yes** -- every boss is a unit (Stage 1: Duwende ... Apolaki) | "APOLAKI, God of the Sun" |
| Stage names | Only the stage's myth hero, rest English | "Apolaki's Sun Terraces" |
| **Normal enemies** (grunt / tank / sprinter / flyer / summons) | **NO -- English only** | Dirt Imp, Iron Ox, Field Rat, Winged Ghoul |
| Status effects, modifiers, items, UI text | English | Curse (not "Sumpa"), Burn, Shielded |

- The internal `Id` may keep an old name when renaming it would churn saves or wave files (e.g. `Manananggal`
  shows "Winged Ghoul"); the `DisplayName` is what must follow the rule.
- A myth flavour line in a description is fine ("the lamang-lupa of the terraces") -- the NAME stays English.
- Stage 1 renames (B143): Lamanglupa -> **DirtImp** "Dirt Imp", Kalabaw -> **IronOx** "Iron Ox",
  DagangBukid -> **FieldRat** "Field Rat". Old configs: `ServerStorage._EnemyConfigs_PreB143` (Game).
