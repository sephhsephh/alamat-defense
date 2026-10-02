--!strict
-- IconCatalog (B108 pt16, SHARED CANON -- byte-identical in Game, Lobby and shared/src/).
-- THE one place every UI icon image lives. User: "never use emoji it looks goofy ... I will provide
-- icons ... browse the toolbox for now". These are FREE Creator Store placeholders (image ids, not
-- decal ids). To swap one: paste your own rbxassetid here, in BOTH Places + shared/src, and re-hash.
-- UI reads icons ONLY through this module, e.g. `IconCatalog.get("Lock")`, `IconCatalog.element("Fire")`.

local IconCatalog = {}

IconCatalog.Icons = {
	-- unit actions (Units rail etc.)
	Feed = "rbxassetid://103988071260502",
	Passives = "rbxassetid://120674109076896",
	View = "rbxassetid://15875255096",
	Favorite = "rbxassetid://3057073083",
	Lock = "rbxassetid://187897034",
	Unlock = "rbxassetid://187897041",
	Sell = "rbxassetid://14002617467",
	Swap = "rbxassetid://11769203234",
	-- general
	Star = "rbxassetid://3057073083",
	StarEmpty = "rbxassetid://130377121632515",
	Sparkle = "rbxassetid://13518130183",
	Check = "rbxassetid://119214585520707",
	Clock = "rbxassetid://17551409679",
	Hourglass = "rbxassetid://88880092924313",
	Search = "rbxassetid://15999597350",
	Gem = "rbxassetid://111400866463625",
	Gear = "rbxassetid://130515345307319",
	Heart = "rbxassetid://101973663994130",
	Skull = "rbxassetid://104438819470450",
	Trophy = "rbxassetid://13321838559",
	Megaphone = "rbxassetid://95949999607503",
	Emote = "rbxassetid://96873497927072",
	Players = "rbxassetid://1234540313",
	Bookmark = "rbxassetid://10596127415",
	Shield = "rbxassetid://7169354142",
	Money = "rbxassetid://18560905584",
	Wave = "rbxassetid://14963611911",
	Fire = "rbxassetid://118675873199574",
	-- unit info
	MaxPlacement = "rbxassetid://13441691835",
	Placement_Hill = "rbxassetid://10728596258",
	Placement_Ground = "rbxassetid://12568415256",
	Placement_Hybrid = "rbxassetid://81296747595776",
	Element_Fire = "rbxassetid://118675873199574",
	Element_Water = "rbxassetid://96882844509705",
	Element_Nature = "rbxassetid://131949649160319",
	Element_Light = "rbxassetid://8509432937",
	Element_Dark = "rbxassetid://8498174594",
	Element_Holy = "rbxassetid://11454949705",
	Element_Cosmic = "rbxassetid://98882790375799",
	Element_Neutral = "rbxassetid://120346118303549",
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
