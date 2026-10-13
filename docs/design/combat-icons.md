# Combat icons -- status effects + enemy modifiers (image-gen prompts)
<!-- owner: AD-Game | since: B143 (2026-10-13) | style: docs/design/icon-art-style.md (THE ONE-SHOT PROMPT) -->

**Where they show:** enemy billboards, the boss billboard, and the top-of-screen boss bar (B143).
- STATUS = what your units did to the enemy. A **round disc in the effect's colour**, under the bar, stack number.
- MODIFIER = what the enemy IS. A **dark diamond with a red rim**, on the name line, hit count for Shielded.
- The UI draws the disc / diamond. The icon is ONLY the symbol (transparent background, no container).

**To install one:** upload the PNG, paste its id into `Icon = "rbxassetid://..."` for that entry in
`ReplicatedStorage.Configs.Global.CombatIconConfig` (Game). Until then the badge shows its 2-letter glyph.

## How to generate
Use **THE ONE-SHOT PROMPT** from `icon-art-style.md` unchanged. Fill its top box with one row below.
ICON TYPE is always **SYMBOL**. After the first icon you like, attach it and say "Match the approved icon's style exactly."

- **Status icons** sit on a COLOURED disc, so draw them light. Use EXTRA DETAILS:
  `"mostly white-and-cream symbol with only a light tint of the dominant colour, dark indigo outline, so it reads on a disc of that colour"`
- **Modifier icons** sit on a DARK diamond, so draw them in full colour. Use EXTRA DETAILS:
  `"full-colour symbol, bright, high contrast, reads on a near-black background"`

## Status effects (8) -- `CombatIconConfig.Status`
| ICON NAME | SUBJECT | DOMINANT COLOURS |
|---|---|---|
| `Status_Burn` | a single fierce flame with a smaller flame curling off its side | ember orange, yellow core |
| `Status_Swarm` | three small stylized beetles/insects circling in a loop | lime green, dark olive |
| `Status_Slow` | a snail shell spiral with a frost crystal on top | icy blue, white frost |
| `Status_Stun` | three cartoon stars circling above a small lightning zig-zag | bright yellow, gold |
| `Status_Sleep` | a crescent moon with a stack of floating "z" shapes drawn as curls (no letters) | soft indigo, lavender |
| `Status_Weaken` | a cracked round shield split down the middle | violet, pale purple |
| `Status_Curse` (id Sumpa) | a voodoo-style cloth doll pierced by a single thorn, purple smoke wisp | magenta, deep plum |
| `Status_Judged` | a radiant golden eye inside a sun disc (divine judgement) | gold, warm white |

## Enemy modifiers (10) -- `CombatIconConfig.Modifier`
| ICON NAME | SUBJECT | DOMINANT COLOURS |
|---|---|---|
| `Mod_Shielded` | a round sun-rimmed buckler with a glowing blue crystal centre (matches the orbiting shield mesh) | sky blue, gold rim |
| `Mod_Overshield` | a translucent energy dome over a small heart | pale cyan, white glow |
| `Mod_Bulwark` | a tall stone tower-shield with a closed keyhole lock | stone grey, steel blue |
| `Mod_Regen` | a heart with a small green leaf sprouting from it and a plus-shaped sparkle | leaf green, soft pink |
| `Mod_Strong` | a flexed arm with a bulging muscle and a red vein glow | crimson red, skin tan |
| `Mod_Fast` | a winged sandal with three speed streaks | golden yellow, white streaks |
| `Mod_Immune` | a white gem shield with a chain breaking off it | white, silver, light gold |
| `Mod_Commander` | a war banner on a short spear with a horn beside it | orange, gold |
| `Mod_Splitter` | a round slime blob cracking into two smaller blobs | purple, lilac |
| `Mod_Explosive` | a round black bomb with a lit sparking fuse and a skull mark | charcoal black, fire orange |

## Also uses these icons
- A unit stunned by an Explosive enemy shows the **Status_Stun** icon over its head (RS.EnemyModifierFX.Stunned).
- The Lobby's Recommended / loadout warning can reuse the modifier icons later (same ids).
