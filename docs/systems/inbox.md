# inbox — stored message history (Lobby meta, AD-Meta/AD-Gacha)
<!-- owner: AD-Meta/AD-Gacha | scope: lobby | added: 2026-09-02 (B48, schema v5) -->

A listable history of things a player received — gifts, mail, code/login rewards — shown on the Inbox
screen (the last of the five upper-right HUD buttons to be built). Backed by a NEW v5 profile field.

## Why this one needed schema v5 (the first genuinely necessary bump since v4)
`LoginStreak`/`Quests`/`ShopStock`/`Battlepass` all rode v2 unwritten, so they dodged bumps. **Inbox
did not:** there was no inbox/mail/history field on the schema (mail DELIVERS and reveals but stored
nothing — `MailService`'s own header said so). A listable history must be persisted, so v5 was
unavoidable. `Data.Inbox = { Messages = { {Id, Title, Body, Rewards?, Day, Read} } }`. Contract:
`docs/contracts/save-schema.md`. The bump is **forward-tolerant** (Reconcile fills the key, never
prunes), so the publish window is safe.

## Pieces (all Lobby-local; the schema field is shared, deployed both Places)
| piece | what it is |
|---|---|
| `Data.Inbox` (v5) | `{ Messages = { InboxMessage } }` — a CAPPED history (`MAX_MESSAGES = 30`, oldest dropped). `Day` is a `MetaMath.Slot` day number (invariant 3). |
| `SSS.Server.Meta.InboxService` | self-running Script; **THE one writer of `Data.Inbox`**. Owns `GetInbox` + `MarkInboxRead`, and the record channel. |
| `ServerStorage.InboxRecord` | a **BindableFunction** (the `BattlepassAddXP` pattern) — the server-only append channel, so senders record WITHOUT requiring InboxService. |
| `RS.Remotes.GetInbox` / `MarkInboxRead` | authored RemoteFunctions (Remotes 36 → 38). |
| `StarterGui.Inbox` + `InboxController` | blockout screen (message-row template) + controller; opens from `HUD.Right.UpperRight.InboxButton` (was UNWIRED) + `ClientEvents.OpenInbox`. |

## How mail feeds it (exactly-once)
`MailService.handle` GRANTS FIRST, then records the delivered mail via `ServerStorage.InboxRecord`,
then `processed()`. The record write lands in the **SAME atomic save** as the acknowledgement, so mail's
at-least-once redelivery cannot double-append — the same trick that makes the grant exactly-once. A
missing InboxRecord (Inbox not booted) or a failure never blocks the mail; it is already granted.

## Server contract
```
GetInbox()          -> { ok, Messages = { {Id,Title,Body,Rewards?,Day,Read} }, Unread, Today }  (newest first)
                     |  { ok=false, reason }
MarkInboxRead(id?)  -> { ok, ... }   -- id = a message Id, or "*"/nil for all
```
Read-only screen: no claim, no grant (rewards were already granted at delivery). The controller
mark-all-reads on view so the unread state clears; the dots on that view stay so the player still sees
what was new.

## Screen contract (controller reads ONLY these names — re-skin at zero code cost)
`Main` · `Overlay` · `Main.CloseButton` · `Main.List` (ScrollingFrame) · `Main.List.MessageTemplate`
(Visible=false) with `TitleLabel` / `BodyLabel` / `DayLabel` / `UnreadDot` (Frame, shown when unread) ·
`Main.EmptyLabel`.

## Verified live (B48)
Schema v5 migrated the real dev profile in one step (`Migrated ... forward 1 step(s) to v5`,
`DataStoreState=Access`, no strand). Two messages recorded through the real `InboxRecord` bridge;
`GetInbox` returned them newest-first with `Unread=2` and rewards preserved; the screen rendered them;
`MarkInboxRead("*")` cleared the unread; **both messages AND the read-state survived a stop/start
round trip** (v5 persistence proven). Cap is `while #Messages > 30 do remove(1) end`.

## Future
Other sources (login gifts, code rewards) can append through the same `InboxRecord` channel; a HUD
unread badge on the InboxButton (anticipated in `PendingReveals`) is a small follow-up.

## Cross-refs
`docs/contracts/save-schema.md` (v5) · the mail delivery mechanism (`MailService`) · `reward-push.md`
(the live reveal path, `RewardPush.ToOrQueue`) · `leaderboards.md` / `quests.md` (the screen pattern).
