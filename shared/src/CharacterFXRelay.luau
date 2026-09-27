--!strict
-- CharacterFXRelay (SHARED CANON -- deploy path ServerScriptService.Server.CharacterFXRelay)
-- Added B92. A Script, hashed as source (the MovementController precedent).
--
-- Forwards a player's movement FX (Jump / DoubleJump / Dash sounds + VFX) to every OTHER client, so
-- other players see and hear them (user, B92). The player's own client already played them locally
-- with no lag, which is why the sender is skipped.
--
-- The server trusts nothing: only the three known action names pass, each player is rate-limited per
-- action, and a player without a character is ignored. Worst case a cheater spams harmless sparkles
-- at the rate below -- nothing here touches gameplay state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Action -> the minimum seconds between two relays of it for one player.
local MIN_GAP: { [string]: number } = {
	Jump = 0.15,
	DoubleJump = 0.15,
	Dash = 0.5,
}

local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local remote = remotes and remotes:WaitForChild("CharacterFX", 10)
if remote == nil or not remote:IsA("RemoteEvent") then
	warn("[DIAG] CharacterFXRelay: RS.Remotes.CharacterFX is missing -- other players will not see movement FX.")
	return
end

local lastSent: { [Player]: { [string]: number } } = {}

remote.OnServerEvent:Connect(function(player: Player, action: any)
	if type(action) ~= "string" then
		return
	end
	local gap = MIN_GAP[action]
	if gap == nil or player.Character == nil then
		return
	end
	local now = os.clock()
	local mine = lastSent[player]
	if mine == nil then
		mine = {}
		lastSent[player] = mine
	end
	if now - (mine[action] or -math.huge) < gap then
		return
	end
	mine[action] = now
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			remote:FireClient(other, player, action)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastSent[player] = nil
end)

print("[DIAG] CharacterFXRelay ready (Jump / DoubleJump / Dash forwarded to other clients, rate-limited).")
