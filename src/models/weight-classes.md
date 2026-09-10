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
