# Proposal: wire the PlayGUI reward preview to the shared curve

<!-- from: AD-Integration (B20, 2026-08-14) | to: AD-UI | status: OPEN -->

## What is already done (nothing here is blocked on data any more)

`RewardScalingConfig` is deployed in the LOBBY as of B20 — `ReplicatedStorage.Configs.Global.
RewardScalingConfig`, hash `1d789978`, byte-identical to the Game's copy, drift **26/26 GREEN**.
`RewardScalingConfig.GoldBand(wire, curveId)` returns the exact `(min, max)` the Game's
`RewardCalculator` rolls inside. Proven live in BOTH Places at wire 100 / 550 / 1000.

**So the preview no longer needs to invent anything. It needs a rendering decision.**

## Why B20 did not just wire it

The Integration brief allowed exactly ONE call to `StoryModeController`'s existing
`renderRewards(list)` and said to write a proposal if wiring needed more than that. It needs more
than that, for two independent reasons.

**1. `renderRewards` cannot express a BAND.** It renders one cell per entry and sets the quantity
badge from `tonumber(r.Qty)` as `"x" .. qty`. §8's preview is a RANGE — "Gold 100–300". Passing
`Qty = goldMin` understates what the player will be paid and `Qty = goldMax` overstates it; passing
two Gold cells renders two identical icons reading `x100` and `x300`, which reads as *two* rewards.
Rendering a range means changing the badge text in `renderRewards` itself — AD-UI's canon.

**2. The shipping call site is on the wrong edge.** `renderRewards` is called once, from
`fillSelectedAct`, i.e. **on act selection only**. `DifficultyController.publish()` rewrites
`DifficultyWire` and `DifficultyMode` on **every slider move and every mode toggle**. A preview
wired at the act-selection site alone would render the act's opening difficulty and then sit there
contradicting the slider the player is actively dragging — a preview that disagrees with the payout
is precisely what §8 exists to prevent, and it would be worse than the current honest blank panel.

Fixing (2) needs a `GetAttributeChangedSignal("DifficultyWire")` / `SelectionSerial` listener inside
`StoryModeController`, plus a require of `RewardScalingConfig`, plus the list builder. That is a new
seam in an AD-UI file, not one call.

Note `renderRewards` is a `local function`, so no other script can drive it from outside, and the
`DevFakeRewards` attribute is a TEST FIXTURE — routing the shipping path through it would make a
harness load-bearing, the same mistake the `OpenStageSelect` proposal declined to make.

## Suggested shape (AD-UI's call, not Integration's)

1. Require `RS.Configs.Global.RewardScalingConfig` in `StoryModeController`.
2. Add `refreshRewards()` that reads `SelectedAct`'s `DifficultyWire` (**never** re-deriving it from
   `DifficultyUI` — ADR-0011, `DifficultyScale` is the one conversion) and `DifficultyMode`, calls
   `GoldBand(wire, curveId)`, and builds the list.
3. Call it from `fillSelectedAct` **and** from a listener on `SelectedAct`'s `DifficultyWire` and
   `DifficultyMode` attribute-changed signals, so the panel tracks the slider.
4. Decide how a band renders. Cheapest honest option: let a reward entry carry an optional
   `QtyText` that overrides the `"x" .. qty` badge, so Gold can read `100-300` while item cells keep
   their existing behaviour. Alternative: a dedicated Gold row with a real range label — that is an
   authoring change and needs the user.
5. Insane adds cells, it does not change the gold band: `RewardScalingConfig.ItemsForMode(mode)`
   returns the two Insane items (`BannerTicket`, `TraitRerollToken`) and an empty list on Normal —
   append them so the preview mirrors what the server now actually pays on a v3 Insane launch.

**The curve id:** the Lobby's `StageRegistry` mirror carries no reward table, so there is no
per-act `GoldCurve` to read in this Place. Passing `nil` resolves to `DefaultCurve = "Standard"`,
which is the curve all three acts name today. If a future act names a different curve, the mirror
needs that one field added — call it out then rather than guessing now.

## What must NOT happen

- Do not compute gold from the UI 1–100 value. The curve takes the **WIRE** value (100–1000).
  `t = (wire-100)/99` is the UI mistake and shows maximum gold for a normal match (ADR-0011).
- Do not copy the numbers into the Lobby. §8's whole point is one curve, read by both sides.
- Do not fill the panel with a plausible figure while the range question is undecided. A blank
  panel is honest; a wrong number is not.
