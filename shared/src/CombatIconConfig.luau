--!strict
-- CombatIconConfig (Game, B143) -- the ICON, English NAME, COLOUR and one-line TIP of every status effect and
-- enemy modifier, for the health bars (enemy billboards, boss billboard, the top-of-screen boss bar).
--
-- ===== TO ADD YOUR GENERATED ICON: paste its asset id into `Icon` below. NOTHING ELSE. =====
-- While `Icon` is "" the bar shows the 2-letter `Glyph` on the coloured badge instead (a readable placeholder).
-- The icon prompts (one per entry, same art style as the unit icons) are in docs/design/combat-icons.md.
--
-- TWO SHAPES, ONE RULE (user, B143):
--   STATUS  = what YOUR units did to the enemy  -> ROUND badge in the effect's colour, UNDER the bar, stack number.
--   MODIFIER = what the enemy IS                -> dark DIAMOND badge with a red rim, on the NAME line.
-- Names are ENGLISH (docs/design/naming-rules.md): the internal id may be Filipino (Sumpa), the name is not (Curse).

local M = {}

export type Entry = {
	Name: string,     -- shown in tooltips
	Icon: string,     -- "rbxassetid://..." or "" (= show Glyph)
	Glyph: string,    -- 1-2 characters, placeholder until Icon is set
	Color: Color3,    -- badge colour (status) / rim colour (modifier)
	Tip: string,      -- one line, what it does
	Order: number?,   -- left-to-right order on the bar (lower = first)
}

local C = Color3.fromRGB

-- ===== STATUS EFFECTS (ids = Configs.StatusEffects modules; model attribute "Status_<id>" = stacks) =====
M.Status = {
	Burn   = { Name = "Burn",   Icon = "rbxassetid://79957406317288", Glyph = "BU", Color = C(255, 120, 40),  Order = 1, Tip = "Takes fire damage over time. Stops Regen." },
	Swarm  = { Name = "Swarm",  Icon = "rbxassetid://89390621263726", Glyph = "SW", Color = C(140, 200, 60),  Order = 2, Tip = "Insects bite it over time. Spreads on death." },
	Slow   = { Name = "Slow",   Icon = "rbxassetid://93742277186602", Glyph = "SL", Color = C(110, 190, 255), Order = 3, Tip = "Moves slower." },
	Stun   = { Name = "Stun",   Icon = "rbxassetid://99242306037017", Glyph = "ST", Color = C(255, 214, 60),  Order = 4, Tip = "Cannot move." },
	Sleep  = { Name = "Sleep",  Icon = "rbxassetid://102809808876267", Glyph = "Zz", Color = C(120, 120, 230), Order = 5, Tip = "Asleep -- wakes up when hit." },
	Weaken = { Name = "Weaken", Icon = "rbxassetid://103841661253423", Glyph = "WK", Color = C(190, 110, 255), Order = 6, Tip = "Takes more damage." },
	Sumpa  = { Name = "Curse",  Icon = "rbxassetid://132206305762435", Glyph = "CU", Color = C(205, 60, 160),  Order = 7, Tip = "Each stack makes it take more damage." },
	Judged = { Name = "Judged", Icon = "rbxassetid://117423467980359", Glyph = "JU", Color = C(255, 205, 90),  Order = 8, Tip = "Marked by Bathala: takes more damage." },
}

-- ===== ENEMY MODIFIERS (ids = Configs.Enemies.EnemyModifierConfig; model attribute "Modifiers" = "A,B") =====
M.Modifier = {
	Shielded   = { Name = "Shielded",   Icon = "rbxassetid://118712069566359", Glyph = "SH", Color = C(90, 170, 255),  Order = 1, Tip = "Blocks the next hits completely -- one shield per hit." },
	Overshield = { Name = "Overshield", Icon = "rbxassetid://70793459938127", Glyph = "OS", Color = C(130, 215, 255), Order = 2, Tip = "An extra health bar that takes half damage. Break it first." },
	Bulwark    = { Name = "Bulwark",    Icon = "rbxassetid://79739267015546", Glyph = "BW", Color = C(200, 200, 215), Order = 3, Tip = "Becomes untouchable for a moment, again and again." },
	Regen      = { Name = "Regen",      Icon = "rbxassetid://94205529564394", Glyph = "RG", Color = C(90, 220, 110),  Order = 4, Tip = "Heals over time. Burn stops it." },
	Strong     = { Name = "Strong",     Icon = "rbxassetid://81474904997637", Glyph = "HP", Color = C(230, 70, 70),   Order = 5, Tip = "Has extra health." },
	Fast       = { Name = "Fast",       Icon = "rbxassetid://139397002175801", Glyph = ">>", Color = C(255, 200, 70),  Order = 6, Tip = "Runs faster." },
	Immune     = { Name = "Immune",     Icon = "rbxassetid://104497442305731", Glyph = "IM", Color = C(240, 240, 240), Order = 7, Tip = "Ignores Stun, Slow and Sleep." },
	Commander  = { Name = "Commander",  Icon = "rbxassetid://130535594924238", Glyph = "CM", Color = C(255, 170, 60),  Order = 8, Tip = "Nearby enemies move faster." },
	Splitter   = { Name = "Splitter",   Icon = "rbxassetid://71160879358312", Glyph = "SP", Color = C(200, 120, 255), Order = 9, Tip = "Splits into smaller copies when it dies." },
	Explosive  = { Name = "Explosive",  Icon = "rbxassetid://100573736048612", Glyph = "EX", Color = C(255, 90, 50),   Order = 10, Tip = "Explodes on death and stuns nearby units." },
}

-- How many badges a row shows before collapsing the rest into "+N" (keeps the bars clean).
M.MaxPerRow = { Billboard = 3, BossBar = 6 }

-- The modifier diamond's rim (enemy-owned = threat colour). Status discs use their own Color.
M.ModifierRim = C(225, 60, 60)

function M.Get(kind: string, id: string): Entry?
	local t = (M :: any)[kind]
	return t and t[id] or nil
end

return M
