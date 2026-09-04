# notifications — HUD "new / claimable" badges (Lobby UI, AD-Meta/AD-Gacha)
<!-- owner: AD-Meta/AD-Gacha | scope: lobby | added: 2026-09-02 (B49) -->

The red count badge that appears on a HUD button when there is something NEW or CLAIMABLE on it —
Inbox unread, Daily/Event claimable, Quests claimable, Battlepass claimable tiers.

## The idea: read the AUTHORITATIVE count, don't re-derive it
Each system already has a remote that returns exactly the state a badge needs. Rather than duplicate
"is this claimable?" logic (which would drift from the service that owns it), the badge controller
calls those existing remotes and counts:

| Button | Source remote | Count |
|---|---|---|
| `HUD.Right.UpperRight.InboxButton` | `GetInbox` | `.Unread` |
| `HUD.Right.Buttons.DailyRewardsButton` | `GetDailyState` | `.CanClaim` → 1 |
| `HUD.Right.Buttons.EventButton` | `GetDailyState` | `.Event.CanClaim` → 1 |
| `HUD.Left.Buttons.QuestsButton` | `GetQuests` | count of `Quests[].CanClaim` |
| `HUD.Right.Buttons.BattlePassButton` | `GetBattlepass` | unlocked+unclaimed tiers (Free always, Paid if `Owned`) |

**No server code, no new remotes, no schema change, no shared canon** — a pure Lobby-UI layer over
state that already exists. Adding a badge later = one `{path, source}` row + a count extractor.

## Pieces
- `StarterGui.HUD.NotifBadgeTemplate` — an authored round red badge (Visible=false) with a `Count`
  TextLabel. A plain Frame, so it **never captures input** — clicks pass through to the button.
  Anchored (1,0) at the button's top-right corner INSET a few px, so it stays fully visible even on the
  right-edge-anchored panels (a corner-overlap badge there clips off-screen).
- `StarterGui.HUD.NotificationController` — clones one badge onto each configured button; on refresh it
  calls the 4 remotes once each, computes every count, and shows/hides each badge (`>9` shows `9+`).

## Refresh
- On join (after the profile loads) and a **15s poll** (backstop).
- Immediately on `ClientEvents.RefreshBadges` — fired by anything that changes a count: **`ShowRewards`**
  (every claim reveal — Quests/Daily/Battlepass — fires it, so all claim paths are covered with NO edits
  to those controllers) and the **Inbox controller** after it mark-all-reads on open.

## Verified live (B49)
Dev profile at BP level 22, event claimable, one unread inbox message: badges showed **Battlepass 9+**
(15 claimable tiers), **Event 1**, **Inbox 1**; Daily and Quests correctly showed nothing. Opening the
Inbox mark-all-read + fired `RefreshBadges`, and the Inbox badge cleared immediately (`true → false`).

## Cross-refs
`inbox.md` (unread source) · `daily-rewards.md` (CanClaim + Event) · `quests.md` · `battlepass.md` ·
`ui-feedback.md` (the HUD button conventions).
