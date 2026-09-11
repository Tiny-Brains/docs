# Weight classes

TinyBrains groups entries by compressed model-plus-adapter size. Your class is
assigned automatically at admission; it is not a field you choose when submitting.
Every active entry also participates in the Open ladder.

## The classes are the season's

**A season declares its own size limits, so read them from the season you are
entering rather than from this page.** The API returns them on every season it
reports — `GET /v1/games/{game}` and `GET /v1/games/{game}/seasons` both carry a
`weight_classes` table — and the site shows them on the home page and beside your
entry. A season may also offer only some of the classes: a focused season might run
Nano alone, and a model measuring into a class it is not running is rejected
`CLASS_NOT_OFFERED` — which is not the same refusal as being too large for every
class there is. A focused season might run
Nano alone.

These are the limits the platform started with, and the default a new season
inherits from the season before it:

| Class | Maximum measured size |
|---|---:|
| Nano (`nano`) | 8 KiB = 8,192 bytes |
| Micro (`micro`) | 64 KiB = 65,536 bytes |
| Mini (`mini`) | 512 KiB = 524,288 bytes |
| Small (`small`) | 4 MiB = 4,194,304 bytes |
| Large (`large`) | 64 MiB = 67,108,864 bytes |

Limits are inclusive. Under the table above an entry measuring exactly 8,192 bytes
is Nano and 8,193 bytes is Micro; an entry over the largest class the season offers
is too large for that season.

**Size is the only thing your class limits.** There is no compute cap: a class does
not ration how much arithmetic your graph may do. What bounds that is the game's turn
deadline — 1,000 ms for Ants — and the platform divides one turn's deadline among the
seats being played in it, so a graph too slow to answer in its share misses the turn
and takes a [strike](../competing/matches.md). Admission measures and reports your
inference time on the reference set; it does not reject you for it.

Because the size limits belong to the season, **a class result is comparable within
its season and not necessarily across seasons.** Two seasons that ran different Nano
limits produced two different competitions, and the standings say which limits they
were played under.

## How many parameters that actually is

The metric compresses **initializer data**, so what fits depends on the dtype you export
in. Measured with zstd level 19 over trained-shaped weights:

| Initializer dtype | Bytes per parameter | Relative capacity |
|---|---:|---:|
| `float32` | 3.69 | 1.00x |
| `float16` | 1.82 | **2.03x** |
| `int8` | 0.76 | 4.86x |

**Exporting float16 weights roughly doubles the model your class holds**, and costs
nothing you would notice: keep the graph's compute in float32 by casting each
initializer back at its use, and the runtime folds that cast away at load. The
operator set does not change — `Cast` is configured — and in a measured comparison the
float16 graph chose the same move as the float32 one on every ant of three matches.

Subtract your adapter first. A plain seven-plane Ants adapter compresses to about 400
bytes, which is 5% of a Nano budget and nothing at all above that.

## The deadline, not the class, is what limits a big model

The table above is generous at the top and the turn is not. Your seat owns
`turn_deadline / rows in the play call` — with sixteen matches of two seats in a wave,
about 31 ms — unless several rows in that call share your exact model file, which is a
thing baselines get and a single entry does not.

That has a consequence worth knowing before you design a large network: **a fully
convolutional network over the largest Ants board runs out of turn at roughly 65,000
parameters**, which is inside Micro. Filling Mini and above means spending parameters
where they cost less per turn — at a reduced resolution, or in a lookup that is read
rather than multiplied — not simply making the same network wider.

The reason is worth stating plainly, because it is structural rather than a tuning
problem. In a convolution every parameter is applied at every cell, so bytes and
arithmetic are locked together: one parameter costs `2 × cells` multiply-accumulates,
and nothing about the kernel size, the grouping or the dtype changes that ratio. A
class cap is a budget in bytes; the turn is a budget in arithmetic; and above Micro the
second runs out first.

Admission reports your measured inference time and never rejects you for it. The
rejection, if it comes, comes later and looks like a [strike](../competing/matches.md).

## How your class is decided

The [size metric](format.md#how-size-is-measured) counts compressed initializer
data and compressed adapter bytes. Admission chooses the smallest class whose
size limit contains that total **in the season you submitted to**. That is the
whole rule — there is no second check, and no class is chosen for you to give you
more compute, because compute is not what a class rations.

Measure the released pair rather than estimating from parameter count. Quantization,
weight structure, and adapter size all affect the result. A larger adapter can
move an otherwise unchanged network into the next class.

## The Open ladder

Open compares models across all sizes. It is an additional rating, not a sixth
size class, and has no separate submission artifact.

A match whose competitors all share a class updates that class and Open. A
mixed-class match updates Open only. Ratings from different class ladders are
not directly comparable; use Open to compare entries of different sizes.

## Choosing what to enter

Begin with a model you can train, inspect, and run reliably. Measure size early,
leave operation-budget headroom for larger observations, watch your inference time
against the turn deadline, and verify all map presets before optimizing for a
boundary.

There is no automatic score bonus for unused bytes within a class. Smaller size
is the constraint and engineering challenge; [ranking](../competing/ranking.md)
still comes from game results. Compare revisions using both their measured size
and their match performance.
