# The world

The Ants world is a rectangular grid of land and water. Coordinates are
`[row, column]`, both starting at zero. The observation's `size` gives
`[rows, columns]`; do not assume a square board.

## The grid, and why it wraps

Both axes wrap. On a 64 × 96 board, moving north from `[0, 10]` reaches
`[63, 10]`, and moving east from `[20, 95]` reaches `[20, 0]`. A border is not a
wall, and a hill near it can be attacked from across the board boundary.

Ranges use the shorter wrapped displacement on each axis. With row difference
`dr` and column difference `dc`, use:

```text
dr = min(abs(r1 - r2), rows - abs(r1 - r2))
dc = min(abs(c1 - c2), cols - abs(c1 - c2))
distance_squared = dr * dr + dc * dc
```

This same geometry controls vision, fighting, and food collection.


> **Replay visualiser — planned:** Step through a recorded border crossing. Highlight the departure and arrival cells, plus a vision or combat radius spanning that boundary.

<!-- replay-visualiser: world-wrapping
Use a recorded replay and its matching engine digest; select the relevant turns.
Provide a text caption and retain the explanation above as the accessible fallback.
Replay asset and turn range: to be selected. No synthetic match result is implied.
-->

## Terrain and water

Water is impassable and permanent. A move into water leaves the ant where it was;
that ant can still collide with another ant arriving there. Land can carry food,
a hill, and an ant. Two ants cannot remain on one square after movement resolves.

The observation remembers water you have discovered. A zero in its water mask
means either land or an undiscovered square; it does not certify that a route is
clear. See [the observation format](../../models/observation.md) for the encoding.

## Hills

Hills are the only places new ants spawn. A surviving enemy ant razes a hill by
standing on it after combat. A razed hill is gone permanently. An ant on your own
hill blocks spawning there, even when food is available in your hive.

Losing all hills does not immediately eliminate a colony. Living ants continue
to move and attack, but cannot be replaced without a standing hill.

## Food

Food on or directly beside an ant can be gathered after spawning resolves. It
enters the colony's hive, a shared store rather than a map location. One unit of
stored food can create one ant on a free hill. Food placed near starting hills
helps colonies begin growing; new food is placed symmetrically as play proceeds.

## Vision and fog

A square is visible if its wrapped squared distance from any of your living ants
is at most **77**. Water does not block this radius. Enemies, food, and hills
outside it are absent from the current observation. Losing an ant can therefore
hide an area you could see a turn earlier.

The engine remembers discovered water for you. It does not retain out-of-sight
enemies, food, or hills in the observation. There is no turn number, score, hive
count, explicit visibility mask, or model state carried between calls.


> **Replay visualiser — planned:** Show the same recorded turns with full-board and player-view modes. Mark an enemy disappearing from sight while discovered water remains known.

<!-- replay-visualiser: world-fog
Use a recorded replay and its matching engine digest; select the relevant turns.
Provide a text caption and retain the explanation above as the accessible fallback.
Replay asset and turn range: to be selected. No synthetic match result is implied.
-->

## Symmetry and presets

The generator gives both starting seats matching terrain and resource
opportunities by translating one half of the world by half its rows and columns.
Play can break that symmetry immediately because the colonies choose different
moves. Symmetric starts do not imply identical outcomes.

The [map preset](maps.md) determines dimensions, terrain generation, and seat
count. All three current presets have two seats; use the preset contract rather
than inferring seat count from map size.
