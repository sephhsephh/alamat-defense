# UI spacing -- the "no claustrophobic UI" rules (BOTH Places)

<!-- owner: AD-UI | scope: lobby+game | since: B115 (2026-10-06) -->

User (B115): "objects / texts too clamped to each other, it makes me claustrophobic ... use paddings properly".
Based on the 8pt-grid practice every major design system uses (spacing in steps of 8 px, 4 px inside small
components) and the **internal <= external** rule: the space AROUND a group is at least the space INSIDE it.

## Rules for every new screen
1. **Card / panel inner margin: 6% of the card's width** (about 8-16 px). Nothing touches a card's edge.
2. **Gaps between rows in a card: about 4% of its height** (8 px+). Stacked text (title over description,
   caption over value) is never flush: at least 5% of the parent's height between the two lines.
3. **Grid / list gaps between cards: 14 px** (pixel cells in scrolling grids; see Unit Manager `fitPanel`),
   and a `UIPadding` (10 px, 14 px on the scrollbar side) inside every scroller.
4. **Buttons: text never touches the button edge** -- a `UIPadding` of 6% left/right and 10% top/bottom.
5. Side-by-side text keeps at least 3% of the parent's width between items.

## The tool
`tools/ui_breathing.luau` (Edit mode, per Place; DRY_RUN first) applies rules 2, 4 and 5 to every StarterGui
screen:
- **What it changes:** scale-positioned, TextScaled text only, and adds UIPadding only to real buttons (<= 3 children,
  all text). Each padded button gets the `B115Spaced` attribute, so re-runs do nothing.
- **What it never touches:** UIListLayout / UIGridLayout containers (those use their own Padding), the Hotbar (user
  rule), admin / dev tools, `*_Retired` screens, and hand-tuned layouts listed in `HAND_TUNED`.
- B115 runs: Game 104 changes, Lobby 174.

## Hand-tuned in B115
- **Unit Manager card (`UnitManager.CardTemplate`):** 6% side margins and an even vertical rhythm. Rows: portrait
  .04-.34, name -.43, upgrade .46-.61, target/sell .645-.775, auto .81-.92. Grid gap 14 px, cards 0.58 aspect,
  the CardGrid has inner padding, and the automation buttons are centred with 3.5% gaps.
