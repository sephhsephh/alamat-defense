# Dialogue + NPC talks + walk arrow (Lobby) -- B108 pt18 Part F

## Pieces
| Piece | Where | Job |
|---|---|---|
| `Configs.DialogueConfig` | ReplicatedStorage.Configs (Lobby) | **Every NPC line.** `Npcs[<NPC model name>]` = Name, Subtitle, Portrait (UnitModels id), Start, Nodes. `Sequences` = scripted talks (StarterIntro). `GuideName`, `GuideNpc`, `CharsPerSecond`. |
| `DialogueGUI` | StarterGui (authored) | Box (portrait viewport, gold name banner, subtitle, body, continue arrow + hint, X), Choices (Template button). DisplayOrder 55. |
| `DialogueController` | DialogueGUI | Typewriter, continue, choices, open screens, locks movement + disables other prompts while talking. |
| `NpcPromptRouter` | StarterPlayerScripts | An NPC with a DialogueConfig entry -> `ClientEvents.StartDialogue(npcName)`; the screen opens from a choice. NPCs without an entry still open their screen directly. |
| `WaypointController` | StarterPlayerScripts | `ClientEvents.GuideToNpc(name)` -> arrow beam from the player + bobbing marker with distance over the NPC; clears within 10 studs or with `GuideToNpc(nil)`. Template: `ReplicatedStorage.WaypointTemplate` (PathBeam, Marker). |
| `NPC_Guide` | Workspace | "True Saint (Holy)" -- PLACEHOLDER parts near the spawn (name tag + "Beginner's Path Event" + light). Swap for the real model; keep the name `NPC_Guide` (or update DialogueConfig.GuideNpc + the router). |

## Node format
```
Nodes = { Greet = { Lines = { "...", "..." }, Choices = {
    { Text = "Browse the Shop", Open = "OpenShop" },          -- close talk, fire ClientEvents.OpenShop(Arg)
    { Text = "When does stock reset?", Next = "Reset" },       -- go to node
    { Text = "Goodbye", Close = true } } } }
```
Tokens: `{Player}`, `{Guide}`, `{Starter}`. A node with no Choices ends after its last line.

## Controls
Continue = click / tap the box, Space / Enter, gamepad A (a press while typing finishes the line). Choices are buttons (gamepad focus on the first). Only the X or a choice ends a talk early.

## Hooks
- `ClientEvents.StartDialogue:Fire(npcName)` or `("seq:<SequenceId>")`.
- `ClientEvents.StarterChosen(towerId)` (fired by the starter Reveal's Continue) -> `Sequences.StarterIntro` spoken by the starter -> `ThenGuideTo = "NPC_Guide"` draws the walk arrow to the guide.
- The guide's "Open the Beginner's Path" fires `ClientEvents.OpenEvents("BeginnersPath")` (Events window = Part G).
