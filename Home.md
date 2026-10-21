# Alamat Defense — Home

The repo IS the vault: every note here is the same file the AI chats read and write. Edit freely, git tracks it.
Start a session from [[CLAUDE]] (the rules), [[STATE]] (where the project is + open PENDINGs) and the top of [[CHANGELOG]].

## Core
- [[CLAUDE]] — constitution: bootstrap ritual, landing checklist, hard rules
- [[STATE]] — project snapshot + PENDINGs
- [[CHANGELOG]] — newest first, one entry per landing
- [[INDEX]] — the map of every doc · [[OWNERSHIP]] — who owns what · [[ROADMAP]] — done / partial / planned

## Places
- Game: `places/game/CONTEXT.md` · Lobby: `places/lobby/CONTEXT.md`

## Match (Game)
[[match-architecture]] · [[match-modules]] · [[match-networking]] · [[match-hud]] · [[match-end]] · [[match-audio]] ·
[[stage-info]] · [[unit-manager]] · [[unit-selection]] · [[hotbar]] · [[tower-authoring]] · [[tower-vfx]] ·
[[maps-apolaki]] · [[balance]] · [[challenges]] · [[movement]]

## Lobby
[[lobby-map]] · [[lobby-ui]] · [[areas]] · [[play-menu]] · [[units-screen]] · [[loading-screen]] · [[dialogue]] ·
[[leaderboards]] · [[admin]]

## Progression & meta
[[gacha]] · [[gacha-selection]] · [[summon-screen]] · [[ascension]] · [[evolution]] · [[trait-reroll]] · [[stat-reroll]] ·
[[exp-food]] · [[crafting]] · [[unit-capacity]] · [[collection-index]] · [[inventory]]

## Rewards, events & economy
[[economy-map]] · [[rewards]] · [[reward-push]] · [[reward-reveal]] · [[quests]] · [[achievements]] · [[events]] ·
[[battlepass]] · [[daily-rewards]] · [[shop]] · [[buffs]] · [[inbox]] · [[redeem-codes]] · [[hud-currencies]] · [[notifications]]

## UI system
[[alamat-ui]] · [[ui-kit]] · [[ui-spacing]] · [[responsive-ui]] · [[ui-feedback]] · [[screen-fx]] · [[settings]]

## Design & art
[[unit-roster]] · [[naming-rules]] · [[icon-art-style]] · [[combat-icons]] · [[content-howto]]

## Contracts, decisions, plans
- Contracts: [[save-schema]] · [[teleport]]
- Decisions (ADRs): `docs/decisions/` — e.g. [[ADR-0001-hybrid-canon]], [[ADR-0006-state-md-cap]]
- Blueprints (law for the features they cover): [[playgui]] · [[phase-a-foundations]] · [[phases-b-f-meta]]
- Proposals: `docs/proposals/` · Screen specs: `docs/specs/`

## Working with the AI (cheap + precise)
- One task per chat. Long chats re-send everything every message and get summarised (detail is lost).
- The repo is the memory: a chat ends with the landing ritual, the next one starts from [[STATE]] + [[CHANGELOG]].
- Write ideas / to-dos / design thoughts in `notes/` (yours, free-form) — the AI reads them only when you point at one.
