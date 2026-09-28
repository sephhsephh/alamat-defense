local PLACE=...
local E={{"AscensionConfig","ReplicatedStorage.Configs.Meta.AscensionConfig","59aa8e15","59aa8e15","59aa8e15"},
{"ItemCatalog","ReplicatedStorage.Configs.Meta.ItemCatalog","2ee5f976","2ee5f976","2ee5f976"},
{"LoadoutConfig","ReplicatedStorage.Configs.Meta.LoadoutConfig","5ac9b8c0","5ac9b8c0","5ac9b8c0"},
{"MetaMath","ReplicatedStorage.Shared.MetaMath","6badac1d","6badac1d","6badac1d"},
{"MetaConfig","ReplicatedStorage.Configs.Meta.MetaConfig","5166d377","5166d377","5166d377"},
{"MatchModifiersConfig","ReplicatedStorage.Configs.Global.MatchModifiersConfig","42c252dc","42c252dc","42c252dc"},
{"ChallengeConfig","ReplicatedStorage.Configs.Global.ChallengeConfig","1640a980","1640a980","1640a980"},
{"PlayerDataService","ServerScriptService.Server.Data.PlayerDataService","613f0d39","613f0d39","613f0d39"},
{"ProfileStore","ServerScriptService.Server.Data.ProfileStore","1e3a6f3f","1e3a6f3f","1e3a6f3f"},
{"ProfileTemplate","ReplicatedStorage.Shared.ProfileTemplate","461fed3e","461fed3e","461fed3e"},
{"Signal","ReplicatedStorage.Shared.Signal","91becf7a","91becf7a","91becf7a"},
{"StatGradeConfig","ReplicatedStorage.Configs.Meta.StatGradeConfig","49a6edfd","49a6edfd","49a6edfd"},
{"TierConfig","ReplicatedStorage.Configs.Meta.TierConfig","4aa53b25","4aa53b25","4aa53b25"},
{"TraitDefinitions","ReplicatedStorage.Configs.Traits.TraitDefinitions","26f1ad06","26f1ad06","26f1ad06"},
{"TraitRegistry","ReplicatedStorage.Configs.Traits.TraitRegistry","7e15f405","7e15f405","7e15f405"},
{"UIKitBootstrap","StarterPlayer.StarterPlayerScripts.UIKitBootstrap","9c9539c0","9c9539c0","9c9539c0"},
{"UIKitButton","ReplicatedStorage.Shared.UIKit.Button","30da2e10","30da2e10","30da2e10"},
{"UIKitFilterPanel","ReplicatedStorage.Shared.UIKit.FilterPanel","72b49660","72b49660","72b49660"},
{"UIKitHotbar","ReplicatedStorage.Shared.UIKit.Hotbar","f330b74f","f330b74f","f330b74f"},
{"UIKitItemIcon","ReplicatedStorage.Shared.UIKit.ItemIcon","776247af","776247af","776247af"},
{"UnitStatsCatalog","ReplicatedStorage.Configs.Meta.UnitStatsCatalog","94321bc4","94321bc4","94321bc4"},
{"RewardScalingConfig","ReplicatedStorage.Configs.Global.RewardScalingConfig","e0a3bc2d","e0a3bc2d","e0a3bc2d"},
{"UIKitMotion","ReplicatedStorage.Shared.UIKit.Motion","ed85d82c","ed85d82c","ed85d82c"},
{"UIKitSound","ReplicatedStorage.Shared.UIKit.Sound","46ab4d7f","46ab4d7f","46ab4d7f"},
{"UIKitConfirm","ReplicatedStorage.Shared.UIKit.Confirm","999c40f3","999c40f3","999c40f3"},
{"UIKitNotify","ReplicatedStorage.Shared.UIKit.Notify","5e2b09d4","5e2b09d4","5e2b09d4"},
{"UIKitUnitCard","ReplicatedStorage.Shared.UIKit.UnitCard","ccd2dd06","ccd2dd06","ccd2dd06"},
{"SettingsConfig","ReplicatedStorage.Configs.Global.SettingsConfig","601163e7","601163e7","601163e7"},
{"MovementConfig","ReplicatedStorage.Configs.Global.MovementConfig","f09bb47f","f09bb47f","f09bb47f"},
{"MovementController","StarterPlayer.StarterPlayerScripts.Client.MovementController","89552a9b","89552a9b","89552a9b"},
{"CharacterAnimConfig","ReplicatedStorage.Configs.Global.CharacterAnimConfig","550dd460","550dd460","550dd460"},
{"CharacterFXRelay","ServerScriptService.Server.CharacterFXRelay","5fc0e42c","5fc0e42c","5fc0e42c"},
{"InputMode","ReplicatedStorage.Shared.InputMode","a59fca85","a59fca85","a59fca85"},
{"GamepadMenus","StarterPlayer.StarterPlayerScripts.Client.GamepadMenus","af5b28ad","af5b28ad","af5b28ad"},
{"AuthoredFX","ReplicatedStorage.Shared.AuthoredFX","f6a6afda","f6a6afda","f6a6afda"},
{"SettingsService","ServerScriptService.Server.Settings.SettingsService","8b3b1a72","8b3b1a72","8b3b1a72"},
{"ClientSettings","StarterPlayer.StarterPlayerScripts.Client.Settings.ClientSettings","a3a9d32f","a3a9d32f","a3a9d32f"},
{"SettingsUI","StarterPlayer.StarterPlayerScripts.Client.UI.SettingsUI","10f3d48c","10f3d48c","10f3d48c"},
{"PlayerLevelConfig","ReplicatedStorage.Configs.Meta.PlayerLevelConfig","2e99d041","2e99d041","2e99d041"},
{"WeekendRushConfig","ReplicatedStorage.Configs.Meta.WeekendRushConfig","44c549f0","44c549f0","44c549f0"},
{"QuestRegistry","ReplicatedStorage.Configs.Meta.QuestRegistry","7c5df4d2","7c5df4d2","7c5df4d2"}}

local function fnv(s)
 local h=2166136261
 for i=1,#s do h=bit32.bxor(h,string.byte(s,i)); local lo=h%65536; local hi=(h-lo)/65536; h=((lo*16777619)+((hi*16777619)%65536)*65536)%4294967296 end
 return string.format("%08x",h)
end
local function find(path) local o=game for part in path:gmatch("[^.]+") do o=o:FindFirstChild(part) if not o then return nil end end return o end
local bad,ok={},0
for _,e in ipairs(E) do
 local inst=find(e[2]); local want=(PLACE=="Game") and e[4] or e[5]
 if not inst then table.insert(bad,e[1].." MISSING") else
  local h=fnv(inst.Source)
  if h~=e[3] or h~=want then table.insert(bad,e[1].." live="..h.." hash="..e[3].." deployed="..want) else ok+=1 end
 end
end
return ok.."/"..#E.." ok\n"..table.concat(bad,"\n")
