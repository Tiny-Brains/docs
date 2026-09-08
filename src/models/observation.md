# What your model sees

The Ants observation is a JSON object for one colony on one turn. Your adapter's
`in` program receives this object directly. There is no setup message or terminal
observation; when a seat stops playing, its model stops receiving calls.

## Fields

| Field | Shape | Meaning |
|---|---|---|
| `size` | `[rows, columns]` | Board dimensions |
| `mine` | `[[row, column], …]` | All your living ants, sorted by row then column |
| `foes` | `[[row, column, owner], …]` | Currently visible enemy ants |
| `food` | `[[row, column], …]` | Currently visible food |
| `hills` | `[[row, column, owner], …]` | Currently visible standing hills |
| `water.rle` | `[value, count, value, count, …]` | Row-major known-water mask |

Coordinates are zero-based and wrap as described in [The world](../games/ants/world.md).
Empty lists are valid. Do not treat a list index as a permanent ant identity:
`mine` is sorted afresh, and births, deaths, and movement change its order.

### Ownership labels in the current cartridge

`mine` and `foes` reliably distinguish your ants from enemies. However, the current
Ants implementation emits raw seat numbers in the owner field of `foes` and
`hills`; it does **not** consistently relabel your colony as owner `0`. There is
also no explicit self-seat field. The design calls for observer-relative labels,
but that normalization is not implemented in this cartridge.

Do not build an adapter that blindly treats every owner-0 hill as friendly.
This is a limitation of the current observation contract; the sample below shows
seat 0's view only. Tests covering both seats are necessary before using hill
ownership as a feature.

## Known water

Read RLE as `(value, count)` pairs. Values are 0 or 1, and the counts cover
`rows × columns` cells in row-major order. A 1 means discovered water. A 0 can be
known land **or an unexplored square**. Water discovered earlier remains known
even when no ant currently sees it.

For a small encoding example, `size: [2, 3]` and `rle: [0, 2, 1, 1, 0, 3]`
expand to `[[0, 0, 1], [0, 0, 0]]`. This illustrates the encoding, not a supported
map preset. Use `tb.rle_expand` to build the tensor without a JSON loop over cells.

## What is hidden

Enemies, food, and hills are filtered to current vision. Only known water has
memory. The payload supplies no scores, turn number, hive count, explored mask,
or persistent model state. You can derive the current visibility mask by dilating
your ant positions with squared radius 77 and wrapped geometry.

A model call is a function of one observation. Recurrent outputs are not fed back
on the next turn, so an architecture requiring that state channel is not supported.
Train with the same missing information you will encounter during competition.

## A worked example

This illustrative seat-0 observation has two ants and no known water:

```json
{
  "size": [64, 96],
  "mine": [[12, 30], [13, 30]],
  "foes": [[12, 33, 1]],
  "food": [[11, 31]],
  "hills": [[12, 30, 0]],
  "water": {"rle": [0, 6144]}
}
```

The second ant is `mine[1]`, so the second action must address `[13, 30]`. The
water field does not say the whole board is land; it says there is no discovered
water in this view. The enemy and food coordinates are within current vision.


> **Replay visualiser — planned:** Select one turn from a real replay and display a player’s observation beside the full board. Highlight each JSON field and the ants’ action ordering; hide privileged state in player-view mode.

<!-- replay-visualiser: observation-payload
Use a recorded replay and its matching engine digest; select the relevant turns.
Provide a text caption and retain the explanation above as the accessible fallback.
Replay asset and turn range: to be selected. No synthetic match result is implied.
-->
