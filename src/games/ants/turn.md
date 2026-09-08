# A turn

Every player chooses actions from its own observation before the turn resolves.
You cannot react to the opponent's move until the following observation.

## The six steps, in order

| Step | Resolution | Consequence |
|---|---|---|
| 1. Move | Apply moves, then remove collisions | Friendly ants can kill each other |
| 2. Battle | Evaluate combat among survivors | Reaching a hill is not enough if the ant dies |
| 3. Raze | Surviving enemies destroy occupied hills | A destroyed hill cannot spawn |
| 4. Spawn | Stored food creates ants on free hills | An occupied hill blocks growth |
| 5. Gather | Nearby food enters the hive | This food cannot spawn until a later turn |
| 6. New food | Place fresh food | Freshly placed food is available on later turns |

After these steps, the engine advances the turn count and checks
[ending conditions](scoring.md).

## Moving and collisions

An ant moves one square north, east, south, or west, or stays. Moving into water
is treated as staying. Missing orders also leave ants still. Movement wraps at
both edges; see [The world](world.md).

All ants use their final destinations for collisions. If two or more arrive on
one square, **all die**, regardless of owner. Moving onto a friendly ant that
stays is a collision. Swapping two adjacent ants does not itself collide because
their destinations differ; combat still follows at their new positions.


> **Replay visualiser — planned:** Compare recorded moves into one destination with a safe swap. Show submitted arrows and surviving ants after the complete turn; distinguish any combat deaths.

<!-- replay-visualiser: turn-collision
Use a recorded replay and its matching engine digest; select the relevant turns.
Provide a text caption and retain the explanation above as the accessible fallback.
Replay asset and turn range: to be selected. No synthetic match result is implied.
-->

## Combat

An enemy is in attack range when wrapped squared distance is at most **5**.
For each ant after collisions, count enemies in range. This count is its
**focus**. Friendly ants do not add to its focus.

An ant dies if any enemy in range has focus less than or equal to its own.
Equivalently, an ant survives only when every enemy it faces has strictly higher
focus. An ant with no enemy in range survives combat.

All focus values are computed before any combat deaths. A dying ant still counts
for that turn's comparisons; deaths do not cascade.

| Position after movement | Focus values | Result |
|---|---|---|
| One ant against one, in range | Both 1 | Both die |
| Two allies each in range of one enemy, no other enemies | Allies 1 each; enemy 2 | Allies survive; enemy dies |
| Two against two, all in mutual range | All 2 | All die |
| Four adjacent cells in a row: A A B B | Outer ants 1; inner ants 2 | Inner ants die; outer ants survive |

The last two cases have the same number of ants but different outcomes. Model
position and support, not only the size of each army.


> **Replay visualiser — planned:** Use recorded one-against-one and supported-combat examples. Overlay each ant’s focus before the turn resolves, then explain the casualties from those values.

<!-- replay-visualiser: turn-focus-combat
Use a recorded replay and its matching engine digest; select the relevant turns.
Provide a text caption and retain the explanation above as the accessible fallback.
Replay asset and turn range: to be selected. No synthetic match result is implied.
-->

## Razing a hill

A surviving enemy on a standing hill destroys it, earning +2 and costing its
owner 1 point. An attacker killed during collisions or battle razes nothing.
Your own ant cannot raze your hill.

## Food and new ants

Each stored food unit spawns one ant on an unoccupied friendly hill. When several
hills are free, the least recently used spawns first, with position breaking ties.
Each hill can spawn at most one ant per turn because it then becomes occupied.
Food waits in the hive when no hill is available.

Gathering uses squared radius **1**: the food square and its four orthogonal
neighbours. If exactly one colony has surviving ants in range, it collects the
food. With none, food stays. The engine also implements destruction of food
contested by multiple colonies, but current attack and gathering radii prevent
opposing ants from both surviving in gathering range of the same food.

Food gathered on this turn can spawn **next turn at the earliest**. Vacating a
hill while another ant gathers nearby is therefore a useful growth pattern.


> **Replay visualiser — planned:** Follow a recorded food collection over two turns. Label the hive increase, the later spawn, and a turn where an occupied hill blocks spawning.

<!-- replay-visualiser: turn-spawn-delay
Use a recorded replay and its matching engine digest; select the relevant turns.
Provide a text caption and retain the explanation above as the accessible fallback.
Replay asset and turn range: to be selected. No synthetic match result is implied.
-->

## Sending nothing

The game leaves unordered ants still. That is distinct from a failed model call:
the platform counts missing or failed answers as strikes, substitutes no movement,
and eventually forfeits the seat. Always return a correctly sized action array,
even when your policy chooses to hold every ant. See [actions](../../models/actions.md).
