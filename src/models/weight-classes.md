# Weight classes

TinyBrains groups entries by compressed model-plus-adapter size. Your class is
assigned automatically at admission; it is not a field you choose when submitting.
Every active entry also participates in the Open ladder.

## The five classes

| Class | Maximum measured size | Ants FLOP cap per inference |
|---|---:|---:|
| Nano (`nano`) | 8 KiB = 8,192 bytes | 250,000,000 |
| Micro (`micro`) | 64 KiB = 65,536 bytes | 1,000,000,000 |
| Mini (`mini`) | 512 KiB = 524,288 bytes | 4,000,000,000 |
| Small (`small`) | 4 MiB = 4,194,304 bytes | 16,000,000,000 |
| Large (`large`) | 64 MiB = 67,108,864 bytes | 128,000,000,000 |

Limits are inclusive. An entry measuring exactly 8,192 bytes is Nano; 8,193 bytes
is Micro. An entry over 64 MiB is too large. The compute caps above come from the
current Ants registration; season and deployment policy determine the applicable
rules for an entry.

## How your class is decided

The [size metric](format.md#how-size-is-measured) counts compressed initializer
data and compressed adapter bytes. Admission chooses the smallest class whose
size limit contains that total, then checks the compute cap for that class.
A graph that fits Nano's bytes but exceeds Nano's FLOP cap is rejected; it is not
automatically moved to Micro to obtain more compute.

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

Begin with a model you can train, inspect, and run reliably. Measure size and
FLOPs early, leave operation-budget headroom for larger observations, and verify
all map presets before optimizing for a boundary.

There is no automatic score bonus for unused bytes within a class. Smaller size
is the constraint and engineering challenge; [ranking](../competing/ranking.md)
still comes from game results. Compare revisions using both their measured size
and their match performance.
