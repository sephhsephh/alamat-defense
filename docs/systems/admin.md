# Admin panel + "Admin Abuse" (B108 pt12)

**Owner:** AD-Meta. **Places:** Lobby (panel, all admin actions), Game (listens only: banner + global Rewards buff).
**User's ask:** an admin panel only the owner can use ("unhackable, maximum security"), for testing (give units,
items, amounts, buffs), plus an "admin abuse" panel like modern Roblox games: global messages that reach every
running server, give to everyone in the server, global buffs in all servers.

## Who is an admin
`ServerScriptService.Server.Admin.AdminConfig.Admins` (Lobby, server-only) -- numeric **UserIds**, never names.
Today: `1746652074` (SuperiorBeing_S, owner). The list is copied and `table.freeze`d when `AdminService` boots;
nothing at runtime (no remote, attribute, DataStore key or group rank) can add an admin. Add one = edit the file
and republish the Lobby. Studio local-server test clients have negative UserIds and are never admins.

## Security model (AdminService header has the long form)
1. **The panel does not exist for non-admins.** `ServerStorage.AdminUI.AdminPanel` is never replicated. On join,
   an allowlisted player gets a clone parented into THEIR `PlayerGui` only (replicates to that one client).
2. **Per-admin remote.** `AdminRequest` (RemoteFunction) is created inside that clone -- there is no admin remote in
   ReplicatedStorage for anyone to find. (The only public object is `Remotes.AdminBroadcast`, server -> client,
   display-only; the server never listens on it.)
3. **Every call re-authorised:** caller must be the player that remote was made for, still in the game, positive
   UserId, on the frozen allowlist. Hiding the UI is defence in depth; this check is the lock.
4. **Whitelisted actions + validation** against server data: ids must exist in `ItemCatalog` (units must be
   `Kind = "Tower"`), traits via `TraitRegistry` (rerollable only), targets must be players in THIS server,
   integers range-checked (NaN, fractions, negatives, huge values refused), strings length-checked.
5. **Rate limit:** `RateMaxActions` (15) per `RateWindowSec` (10) per admin; refused calls count too.
6. **Audit:** every action (ok or refused) is printed `[ADMIN] ...`, kept for the Log tab (last 60, this server),
   and appended to DataStore **`Beta1_AdminAudit`** key `Ring` (last 200, all servers).
7. **Broadcast text is filtered** (`TextService:FilterStringAsync` + `GetNonChatStringForBroadcastAsync`); if the
   filter fails, nothing is sent.
8. **Grants go through `GrantService`** (catalogued ids, MaxOwned caps, integer qty) and are revealed with
   `RewardPush.To`, then `UnitsChanged.Fire`.
9. **Mass/global actions need the UIKit confirm dialog** (2-second gate) on the client; if the dialog module is
   missing the panel refuses to send them.

Proven live (B108 pt12): 17 hostile requests (fake ids, qty -5 / 1.5 / 1e15 / NaN, level 101, unknown target,
out-of-range buff, unknown buff, take from "global", global personal luck, made-up action names, non-string
action) were all refused; rate limit refused calls 2-18 of a burst; the client sees 0 children of ServerStorage
and ServerScriptService and no admin remote in ReplicatedStorage.

## Actions (`AdminService` ACTIONS table)
| action | args | notes |
|---|---|---|
| getState | - | catalogue (towers/items/traits), players, active global buffs, limits, recent log |
| giveUnit | target, towerId, qty 1..50, level 1..100, shiny, trait | `GrantService.Grant({TowerId,Qty,MetaLevel,Shiny,Trait})` |
| giveItem | target, itemId, qty 1..1,000,000 | currencies (Gold/Silver/StatRerolls...) and items |
| takeItem | target (one player), itemId, qty | `GrantService.Spend` / `SpendItems`, clamped to what they own |
| luck / clearLuck | target (not global), percent 1..1000 | personal Luck buff via `LuckService.Apply` / `DevClear` |
| announce | text, color (Gold/Red/Purple/Green/Blue), seconds 3..30, scope server/global | filtered |
| startBuff / stopBuff | kind Luck (10..1000 %) / Rewards (x1.5..x10), minutes 1..240 | global, auto-announced |

**Targets:** `"self"`, a UserId in this server, `"server"` (everyone here with a loaded profile), `"global"`.
A **global give** is a *gift*: stored in MemoryStore `AlamatAdminGifts_v1` for 24h; every Lobby grants it once per
player (on join and when the gift is announced) and records the claim in `Data.AdminGifts[giftId] = os.time()`
(AdminService is its one writer; records older than 3 days are pruned). Players in a match get it when they
return to the Lobby.

## Cross-server layer: `Server.Admin.AdminGlobal` (SHARED CANON, both Places, `shared/src/AdminGlobal.luau`)
- MessagingService topic **`AlamatAdmin_v1`**: `announce`, `buffs` (refresh now), `gift` (claim now). Payloads are
  type-checked on receipt; text clipped to 300, seconds clamped 3..30.
- MemoryStore sorted map **`AlamatAdminBuffs_v1`**: key = kind, value `{Value, EndsAt, StartedAt, By}`, stored with
  an expiration = the buff's duration (ends by itself even if every server restarts). Each server caches it
  (refresh every 20s + on a `buffs` message).
- Readers: `LuckService.ActivePercent` adds `AdminGlobal.LuckPercent()` (summons, trait + stat reroll best-of-N);
  `BuffService` shows `AdminLuck` / `AdminRewards` cards ("ADMIN ABUSE"); Game `RewardCalculator` multiplies the
  (Victory-only) reward multiplier by `AdminGlobal.RewardMult()` -- stacks with Weekend Rush.
- Game has `Server.Admin.AdminBoot` (requires AdminGlobal so the subscription runs); the Game has NO panel/remote.

## UI
- **Panel** (Lobby, `ServerStorage.AdminUI.AdminPanel`, DisplayOrder 95 so the reward popup and confirm dialog sit
  above it): ADMIN pill (top-left, F2, gamepad Select), window 960x600 scaled to the viewport (mobile), sidebar
  tabs Units / Items / Players / Admin Abuse / Audit Log, target dropdown (Me / players / Everyone in THIS server /
  Everyone in ALL servers), searchable lists cloned from authored row templates, qty/level chips, Shiny toggle,
  trait cycler, announcement composer (colour + duration chips, THIS SERVER / ALL SERVERS), global buff composer
  with an active list (live countdown + STOP), status toast. Studio harness: `AdminPanel:SetAttribute("DevOpen", true)`,
  `DevPage = "Units"|"Items"|"Players"|"Abuse"|"Log"`.
- **Banner** (`StarterGui.AdminBroadcastGUI`, both Places, identical controller): slides in from the top with an
  ADMIN tag, looping gradient border, shine sweep and a timer bar; queues up to 5. Resting height = ScreenGui
  attribute `RestY` (Lobby 74, Game 104 under the match HUD). Sound slot `SoundService.UI.AdminAnnounce` (empty).
  Harness: `AdminBroadcastGUI:SetAttribute("DevAnnounce", "text|Gold|6")`.

## Limits worth knowing
MessagingService: 1KB per message, topic <= 80 chars, publisher receives its own message; per-server publish
budget 600 + 240/player per minute. Admin traffic is tiny. MemoryStore quota is per experience; two small maps.
