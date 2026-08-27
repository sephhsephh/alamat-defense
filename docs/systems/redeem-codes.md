# Redeem codes — promo codes (Lobby meta, AD-Gacha canon)

<!-- owner: lobby | scope: lobby | last-verified: 2026-08-27 (B39) -->

Promo codes: a player types a string, the server grants what it maps to, once per player per code.

| piece | what it is |
|---|---|
| `RS.Configs.Meta.CodeRegistry` | PURE: the code table, normalisation, the live-window test |
| `SSS.Server.Meta.CodeService` | **THE one writer of `Data.RedeemedCodes`**; owns `Remotes.RedeemCode` |

## ⚠ Every code here is PUBLIC. Design around it, do not try to fix it.

`CodeRegistry` sits in **ReplicatedStorage**, so any client can read the whole table — codes, rewards
and windows. That is a fact, not a bug to patch:

- A code is a **convenience, never a secret**. It is the same string for everybody and it gets posted
  publicly the day it ships. Its only real protection is the per-player "redeemed once" record.
- **If a reward must not be obtainable by everyone who reads the client, it does not belong in a code.**
- Moving the module to `ServerScriptService` would hide the strings and change nothing about that,
  while costing the client the ability to grey out an expired code without a round trip.

## Normalisation is what makes "once per player" true

`CodeRegistry.Normalize` is **the one place a player's typing becomes a key**: trimmed, uppercased,
and refused past 32 characters. Everything that looks a code up goes through it and must not roll its
own `string.upper` — if two spellings normalised differently, the same code could be redeemed twice.

The length bound exists because **the normalised string becomes a profile key**. Without it a client
could grow a player's own save with junk keys just by submitting long strings.

## ⚠ The rate limit is security, not UX

A redeem box is a remote that takes an arbitrary string and pays out on a match. Without a limit a
client can call it in a loop and **enumerate the code space** — the check is a table lookup, so the
server would happily answer thousands of guesses a second.

Two limits, because they stop different things:

- **`MinSeconds = 1.5`** spaces out attempts, so guessing costs wall-clock time.
- **`MaxFailures = 20` per session** caps the total, so a patient script cannot just wait between tries.

Two deliberate exemptions, both of which would otherwise punish honest players:

- **A successful redeem does not count** toward `MaxFailures`. Someone holding ten valid codes must
  be able to enter all ten.
- **`already_redeemed` does not count either.** Re-pasting a code you have used is the single most
  common thing that will ever happen to this remote; it is not a guess.
- `profile_not_loaded` does not count — that failure is ours, not theirs.

## GRANT FIRST, MARK SECOND

`Grant` validates and can refuse (an uncatalogued `Id`, a bad `Qty`); the mark cannot. Marking first
would **consume the player's one redemption and pay them nothing**, with no way to undo it. Same rule
as `DailyRewardService` and `GrantService.SellUnits`.

A refusal here is a **config bug, not a player guess** — it means an `Id` in `CodeRegistry` is not in
`ItemCatalog` — so it warns with the code and the reason, writes nothing, and leaves the code
redeemable.

## Reveal: the RETURN VALUE, not `RewardPush`

The player **typed the code**, so it is their own action. `RedeemCode` returns `Rewards = views` and
the client fires `ShowRewards`, exactly like summon, sell and the daily claim. (B37's rule.)

## Day numbers, not timestamps

`RedeemedCodes[CODE]` stores the **`MetaMath` day number** it was redeemed on, and `StartDay` /
`EndDay` windows are day numbers too — inclusive, both optional. Invariant 3, the same choice
`BannerChoice.ChosenAtDay` and `LoginStreak.LastClaimDayNumber` make.

## Reason codes

`invalid_code` · `unknown_code` · `not_started` · `expired` · `code_has_no_rewards` ·
`already_redeemed` · `too_fast` · `too_many_attempts` · `profile_not_loaded` · `grant_failed`

`code_has_no_rewards` exists so a live-but-empty code cannot consume a redemption for nothing.

## Verified live

| case | result |
|---|---|
| `"  alamat  "` | normalised to `ALAMAT`, granted Gold x500 |
| same code again | `already_redeemed` |
| after a **server restart** | still `already_redeemed` — the write persisted |
| expired code | `expired` |
| unknown code | `unknown_code` |
| second code immediately | `too_fast` |
| second code after the gap | granted BannerTicket x3 + Silver x250 |

The three shipped codes are **PLACEHOLDER CONTENT**, labelled in the file. `EXPIREDTEST` is
deliberately dead so the expiry path has something to exercise that is not a typo.

## Not built

The **screen**. `HUD.Right.UpperRight.RedeemCodes` is still unwired and there is no `TextBox` for a
code anywhere in `StarterGui`. The server side is complete and tested; the UI needs authored art
(B26 — art cannot be scripted across), spec in `docs/specs/`.

---

## B40 — the screen exists

`StarterGui.RedeemCodes` + its controller, scripted to the published spec and wired to
**`HUD.Right.UpperRight.RedeemCodesButton`**.

⚠ **That button's name ends in `Button`.** `places/lobby/CONTEXT.md` listed these five abbreviated
(`RedeemCodes`/`LeaderBoards`/…), and B40 lost a live run looking up `RedeemCodes` and finding
nothing. The doc is corrected.

The label is the state: every reason code lands on `StatusLabel` and stays. `CodeBox` has
`ClearTextOnFocus = false` because pasting is how most codes are entered. Enter submits as well as the
button. The client deliberately does **not** pre-validate against `CodeRegistry` even though it can
read it — the server must check anyway, and a client-side "that code doesn't exist" would leak which
strings are real faster than the rate limit can slow it down.

**Verified live:** the screen opens and closes, the box starts empty with its placeholder, and the
server path answers `unknown_code` / `already_redeemed` correctly. The button *click handler itself*
was not simulated — `MouseButton1Click` cannot be fired from a script and `VirtualInputManager` needs
a capability this tooling lacks — so what was exercised is the call the handler makes, which is the
half that can actually be wrong.
