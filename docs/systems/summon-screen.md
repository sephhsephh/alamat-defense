# summon-screen — the B55 rebuild, plus Luck, gem packs and auto-sell
<!-- owner: AD-UI + AD-Gacha | home Place: Lobby | scope: lobby | added: 2026-09-08 (B55) -->
<!-- read with: docs/systems/gacha.md (the engine underneath) and gacha-selection.md -->

The user supplied a reference screen and four decisions. This doc is the screen and the three
systems it needed. The banner engine, pity, rates, the reveal and Selection banners are unchanged
and live in `gacha.md` / `gacha-selection.md`.

## What the user decided (B55)
- 4 tabs became **3**: Friend Banner dropped. `Special` = the SELECTION banner, `Standard Banner` =
  the STANDARD banner, `Limited Banner` = the EVENT banner.
- The gem packs are **currency + a REAL timed Luck buff**, bought with **Robux Developer Products**.
- The currency stays **Gold**; the gem art is a placeholder the user will replace.
- The Luck buff is **timed (1 hour)**, **highest percent wins**, and buying **always refreshes** it.
- The rarity pill under the banner subtitle: **removed**.
- Auto-sell offers **the game's real 6 tiers, Common included**.
- The reference's bottom bar is a composite of another screen: **ignored**.

## The layout
`StarterGui.SummonScreen.Main.Panel` is now three columns: `Tabs` (left rail) · `Banner` (centre) ·
`Packs` (right), with `Title`, `CloseButton`, `IndexButton` and `AutoSummonButton` in the header.
The B6 CAROUSEL is gone -- one card per banner with prev/next arrows was a different shape, so the
layout was rebuilt rather than bent. `ChoiceOverlay`, `ChooseButton` and `ClosedOverlay` were
REPARENTED out of the dead `BannerCardTemplate` onto `Banner`, which is why the Selection flow
survived the rebuild intact. The old controller is parked at
`ServerStorage.SummonController_B54_backup` -- **delete it once B55 is confirmed.**

**Tabs are mapped by banner TYPE, not by id**, so shipping a second event is dropping in a banner
file -- the property `BannerRegistry` was built to have. An unknown type falls back to its own
display name rather than vanishing.

**The countdown tells the truth per type**: an Event counts its WINDOW ("Banner Ends"); Standard and
Selection count the next FEATURED ROTATION ("Featured Rotates"), because those banners never end;
an ENDED banner gets **no clock at all**, since a rotation countdown there would promise something
on a banner nobody can pull from. A banner with neither gets no clock rather than a fake one.

**Pity bars** come from `GetSummonState` and skip any threshold above 5000 -- `Secret` is 100000 and
a bar that never visibly moves is noise, not information.

## Show Chances -- the one thing that could quietly lie
Computed the SAME way `SummonEngine.BuildContext` computes it, from the same config and including
the player's live Luck buff: banner `LuckMult` x the buff multiplies the **pity tiers only**
(`PityConfig.CheckOrder`), and inside a tier a **featured** unit's weight is x`Featured.Boost`.
Verified against 40k dry rolls. Tiers with weight but an EMPTY pool are **excluded from the split
and named in the footer** -- their rolls fall to a stocked tier, and listing them as obtainable
would be exactly the fabrication this screen exists to avoid.

## Luck (`LuckConfig` pure + `LuckService`, the one writer of `Data.LuckBuff`)
**Expiry is a COMPARISON against an absolute `os.time()`, never a scheduled write.** A buff ends on
time whether or not a server was up, whether or not the player was online, with no task and no
migration pass -- and an expired buff and no buff are the same state to every reader.
`LuckConfig.Apply` decides the result (started / raised / **kept**); `LuckService` only stores it.
`LuckConfig.Mult` is the ONE formula turning 25 into 1.25, so the screen's "+25% Luck" and the
weight the roll used cannot drift.

`SummonEngine.BuildContext` gained a 4th optional arg, `luckBonusMult` -- the same shape as
`featuredOverride`: a plain NUMBER resolved by `SummonService` and handed in, so the engine still
never learns what a profile is and the odds harness still calls it with two arguments.
**`SummonService` resolves it ONCE per batch**, so an x10 rolls under one consistent multiplier even
if the buff expires mid-batch. The player paid for the batch when they pressed the button.

## Gem packs (`GemPackConfig` pure + `GemPackService`) and `ReceiptService`
**`ReceiptService` is THE one owner of `MarketplaceService.ProcessReceipt` and a REGISTRY, not just
the gem packs.** ProcessReceipt is a single callback for the whole Place -- assigning it twice
silently discards the first, and the system that lost would take money and grant nothing. The
battlepass level-skip products (5/10/50), already noted as wanted, plug in here.

Its rules are not style choices:
1. **Idempotency lives in the PROFILE** (`Data.Purchases.Ids`, schema v6, capped 50), not in server
   memory -- Roblox re-delivers a receipt until the callback returns `PurchaseGranted`, and the
   retry usually arrives on a **different server**.
2. **Anything uncertain returns `NotProcessedYet`** -- unknown product, profile not loaded, handler
   errored. Granting on a failure is the one truly unrecoverable outcome: charged, nothing given.
3. The purchase id is recorded in the SAME profile write as the grant.
4. `receiptInfo.PlayerId` is the truth; the buyer may not be in this server.

A pack whose Luck half fails AFTER the currency landed **accepts the receipt anyway** and warns
loudly: a player short an hour of Luck is recoverable, a duplicated currency grant is not.

**Prices are read from `MarketplaceService`, not typed in config** -- a price in a file goes stale
the first time it is edited on the website. `PriceText` is only the fallback if that call fails.

> **USER TODO: create four Developer Products and paste their ids into `GemPackConfig`.** A Developer
> Product cannot be created from a script. Until then each pack is UNCONFIGURED: the column still
> renders, the button reads "Coming soon", and `BuyGemPack` refuses `pack_not_configured`. It never
> prompts with a zero id -- that fails in front of the player with no explanation. `GemPackService`
> also **warns loudly at boot** while any pack is a placeholder, so shipping with nothing on sale
> cannot happen by accident.
>
> **Checked 2026-09-09:** the Experience has exactly ONE Developer Product, `3711220080`
> *"Premium Battlepass Season 1"* (799 R$). **Do not point a gem pack at it** -- reusing it would
> charge a player for the battlepass and hand them Gold, and it would collide in `ReceiptService`
> the day the battlepass registers its own products. There is nothing else to borrow, so the four
> `ProductId = 0` values stay as marked placeholders (user, B55).

## Auto Summon = auto-sell (`AutoSellConfig` pure + `AutoSellService`)
**The tier list is DERIVED, not typed**: the tiers any registered banner can actually award, in
`TierConfig.Order` order. `TierConfig` carries eight, but `Exclusive`/`Bathala` have no weight and no
unit, and offering a toggle for a tier that can never be summoned would be a lie. Today that is
exactly Common / Rare / Epic / Legendary / Mythic / Secret. A banner shipping Bathala weight grows
the panel a row on its own.

`Data.AutoSell` is **SPARSE** -- `[tier] = true`, never `false`. Absent means off, so a tier added
later defaults to KEPT, the safe direction.

The selling is **`SummonService` step 12**, AFTER the grant and after `views` is captured, so the
reveal still shows what was pulled and THEN it is sold. The write is `GrantService.SellUnits` -- the
ONE code path that deletes a `Data.Units` record -- so auto-sell inherits its favourited/locked
protections and its credit-before-destroy ordering for free. **A sell failure never fails the
summon**: the player already has their units.

Toggles are saved on popup CLOSE, not per tap -- six toggles would otherwise be six remote calls.
The server `Sanitize`s whatever arrives and RETURNS what it stored, so the panel re-renders from
what actually landed.

## Remotes added (40 -> 44)
`GetSummonState` (pity + luck + auto-sell + balances -- deliberately small: everything else the
screen derives from ReplicatedStorage config) · `SetAutoSell` · `GetGemPacks` · `BuyGemPack`.
The client asks the SERVER to prompt a purchase rather than prompting itself, because the server
owns the product id -- a client that could name its own id could prompt for any product.

## Verifying a change
Harness attributes on the ScreenGui, each running the SAME function a real click runs:
`DevPull` (1/10) · `DevChoose` (a towerId) · `DevTab` (a banner id) · `DevPopup`
("chances"/"info"/"autosell"/""). Server-side, `ReplicatedStorage:SetAttribute("DevLuck", 100)`
applies a real buff through `LuckService` (Studio only, grants NO currency).

**`DevPopup` is the ONE Dev attribute here that does NOT self-reset.** The others write themselves
back to a neutral value so the same value can be set twice; their re-entrant call then hits an early
return and does nothing. `DevPopup` cannot, because its neutral value `""` is a REAL command (close
everything) -- the reset re-fired the signal and closed the popup the first call had just opened.
**A re-entry flag does not fix it either: Roblox attribute signals are DEFERRED**, so the re-entrant
call runs after the flag has been cleared. (That was the first attempted fix, and it failed the same
way.) So `DevPopup` is a STATE, not a pulse: set a popup name to open, `""` to close, and go through
`""` to re-open the same one.

**The screen re-polls `GetSummonState` every 5s while it is OPEN.** A gem-pack purchase lands in
`ProcessReceipt`, possibly seconds later and possibly on a different server, and there is no
server->client push for it (the reveal contract deliberately has none). Without the re-poll a player
who had just bought Luck would see "no Luck" and **Show Chances would quote the unbuffed odds** --
a stale odds table is the one thing this screen must never show. Verified: clearing a buff
server-side re-renders an OPEN chances popup from 5.854%/1.456% back to 4%/0.995% with no
interaction.


## B57 — packs configured + luck-only passes + the luck buff shown

- **Gem packs are LIVE.** `GemPackConfig`'s four `ProductId`s are the user's Developer Products
  (verified live B57). No more `pack_not_configured`.
- **Luck-only passes (NEW).** `RS.Configs.Gacha.LuckPackConfig` + `SSS.Server.Meta.LuckPackService`
  — 4 Robux Dev Products (25/50/75/100% Luck for 1 hour) that grant Luck ALONE (no currency), over
  the same `ReceiptService` registry (now 8 products). Remotes `GetLuckPacks` / `BuyLuckPack`.
- **Summon pack column.** The gem grid + a new **LUCK BOOSTS** grid stack inside a `ScrollingFrame`
  (`Packs.Scroll`, vertical `UIListLayout`), so all 8 cards fit; the gem 2x2 grid is untouched.
  `SummonController.renderLuckPacks` mirrors `renderPacks`. `refreshLuckStrip` now resizes `Scroll`.
- **The active luck buff** shows in the existing `Packs.LuckStrip` here AND in the new Buffs UI
  (`docs/systems/buffs.md`).
- **ReceiptService** gained a Studio-only test seam (`_Decide`) driven by `LuckPackService`'s
  `DevReceiptTest` harness — the first real exercise of the receipt pipeline. A real Robux charge
  is still untested (needs a purchase).
