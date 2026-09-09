# What your model answers

The Ants action is a JSON array with one string per ant in the observation's
`mine` list. Your adapter's `out` program produces this array after inference.

| String | Move |
|---|---|
| `N` | Row −1 |
| `E` | Column +1 |
| `S` | Row +1 |
| `W` | Column −1 |
| `-` | Stay |

Every move wraps at the map boundary. There are no diagonal moves, destinations,
ant identifiers, or action objects in this contract.

## One order per ant

For `mine: [[12, 30], [13, 30]]`, the action `["N", "E"]` moves the first ant
toward `[11, 30]` and the second toward `[13, 31]`. Return the same number of
orders as ants. Zero ants means `[]`.

If the network produces `[N_ants, 5]` scores in the channel order
`N, E, S, W, -`, an output adapter can select each row's maximum and map its index
to the corresponding string. The complete expression appears in [Adapters](adapters.md).
Keep training labels, output channels, and the string lookup in the same order.

## Illegal and missing orders

Moving into water leaves the ant still. The current engine also treats missing
or unrecognized direction strings as staying and ignores surplus positional
orders. These fallbacks do not make a malformed action conformant: produce only
the five allowed strings and exactly one per ant.

The loader validates tensor compatibility and JSON conversion, not the complete
Ants action schema. An adapter can run without an error yet produce unusable
orders. Check action values and length yourself during [testing](testing.md).

## The turn clock

The standard turn deadline is **1,000 ms** for input adaptation, inference, and
output adaptation together. A failed or timed-out call contributes a strike and
leaves the seat with no movement for that turn. At five cumulative strikes the
seat forfeits; successful calls between failures do not reset the count.

A deliberate hold array such as `["-", "-"]` is a normal answer. It is different
from failing to return an action. There is no resign action in the current Ants
contract. See [scoring and forfeits](../games/ants/scoring.md).

## A move is an intention

An accepted action is not a guarantee the ant survives or reaches a useful
position. Opponents move simultaneously, friendly ants can collide, and battle
runs before hill razing. Evaluate outcomes using the [turn rules](../games/ants/turn.md),
not only the validity of the direction strings.


<div class="tb-replay" data-src="tutorials/1-movement.json" data-turn="4" data-zoom="6"></div>

<p class="tb-replay-caption">Eight orders, and what the engine did with them. Two of the moves are refused by water on turns 3 and 4 — the ant stays put — and one crosses the wrapping edge. Played by the engine from a written script, so the rule happens exactly. Arrow keys step a turn at a time; click a cell to see what is on it.</p>

<!-- replay-visualiser: actions-to-outcomes — filled.
Asset: tutorials/1-movement.json, turn 4. Regenerate with tutorials/build.sh.
The prose above the slot stands alone: a page whose viewer fails to load still teaches the rule.
-->
