--!strict
-- IconCatalog (B108 pt16, SHARED CANON -- byte-identical in Game, Lobby and shared/src/).
-- THE one place every UI icon image lives. User: "never use emoji it looks goofy ... I will provide
-- icons ... browse the toolbox for now". B167: EVERY entry is now the user's own Alamat art (SuperLazy
-- Devworks image ids; the toolbox placeholders are gone). To swap one: paste the new rbxassetid here,
-- in BOTH Places + shared/src, and re-hash.
-- UI reads icons ONLY through this module, e.g. `IconCatalog.get("Lock")`, `IconCatalog.element("Fire")`.

local IconCatalog = {}

IconCatalog.Icons = {
	-- unit actions (Units rail etc.)
	Feed = "rbxassetid://71373202560378",
	Passives = "rbxassetid://120007478296776",
	View = "rbxassetid://129838764739823",
	Favorite = "rbxassetid://105467914399412",
	Lock = "rbxassetid://113461681206626",
	Unlock = "rbxassetid://113431413694343",
	Sell = "rbxassetid://79454116646008",
	Swap = "rbxassetid://111044708607666",
	-- general
	Star = "rbxassetid://92064400353876",
	StarEmpty = "rbxassetid://103132031058722",
	Sparkle = "rbxassetid://78635282604738",
	Check = "rbxassetid://132391593566606",
	Clock = "rbxassetid://84231061032456",
	Hourglass = "rbxassetid://121844732081089",
	Search = "rbxassetid://74986984326602",
	Gem = "rbxassetid://107685607825536",
	Gear = "rbxassetid://108301817655324",
	Heart = "rbxassetid://116583108548734",
	Skull = "rbxassetid://123832050902220",
	Trophy = "rbxassetid://126811666635816",
	Megaphone = "rbxassetid://88425664163660",
	Emote = "rbxassetid://101231165814673",
	Players = "rbxassetid://113746206086192",
	Bookmark = "rbxassetid://131387939648455",
	Shield = "rbxassetid://129685435443454",
	Money = "rbxassetid://102327421801087",
	Wave = "rbxassetid://90673935238890",
	Fire = "rbxassetid://70598796366947",
	-- B108 pt17: Play menu / party
	Crown = "rbxassetid://124596280620309",
	Gift = "rbxassetid://134552927651615",
	Info = "rbxassetid://112805828959865",
	Arrow = "rbxassetid://127180170694803",
	-- B167: Units / Inventory filter + discard buttons
	Filter = "rbxassetid://76543774291496",
	Discard = "rbxassetid://77872937729898",
	-- B167: stat pills (DMG / SPA / RNG) -- Units hall, Starter Choice, hotbar hover card
	Stat_DMG = "rbxassetid://112443858103904",
	Stat_SPA = "rbxassetid://74191266565551",
	Stat_RNG = "rbxassetid://77039343948319",
	-- unit info
	MaxPlacement = "rbxassetid://75714208256013",
	Placement_Hill = "rbxassetid://102988893682928",
	Placement_Ground = "rbxassetid://118539917969865",
	Placement_Hybrid = "rbxassetid://110430165363423",
	Element_Fire = "rbxassetid://131215439812848",
	Element_Water = "rbxassetid://82847057558021",
	Element_Nature = "rbxassetid://136195612051343",
	Element_Light = "rbxassetid://102195987611847",
	Element_Dark = "rbxassetid://78774409777537",
	Element_Holy = "rbxassetid://76198950188005",
	Element_Cosmic = "rbxassetid://138976881003451",
	Element_Neutral = "rbxassetid://104037721935673",
}

function IconCatalog.get(name: string?): string
	return (name and IconCatalog.Icons[name]) or ""
end

function IconCatalog.element(element: string?): string
	return IconCatalog.get(element and ("Element_" .. element) or nil)
end

function IconCatalog.placement(placement: string?): string
	return IconCatalog.get(placement and ("Placement_" .. placement) or nil)
end

-- Sets an ImageLabel/ImageButton to a named icon; returns true when the icon exists.
function IconCatalog.apply(img: Instance?, name: string?): boolean
	if img == nil or not (img:IsA("ImageLabel") or img:IsA("ImageButton")) then return false end
	local id = IconCatalog.get(name)
	;(img :: ImageLabel).Image = id
	return id ~= ""
end

return IconCatalog
