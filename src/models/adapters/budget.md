# The budget

Ants currently allows **1,000,000 adapter operations per direction per call**.
The `in` program and the `out` program each receive that budget independently.
Inference has no separate cap of its own; the whole call must meet the turn deadline.

## What counts as an operation

Every evaluated expression node costs 1. A loop body pays again on each element;
an unselected conditional branch does not run and does not pay. Scalars cost 1,
while arrays and object values in expression position are recursively evaluated.
Large literal collections therefore still have evaluated child nodes as well as
contributing to compressed adapter size.

Tensor operators add `max(elements read, elements produced)` to their node cost.
Their argument expressions also pay their ordinary evaluation costs. Reshape and
metadata helpers have no element charge.

For `{"tb.zeros":[[128,128],"int8"]}`, the operator and its 16,384 output
elements cost 16,385; evaluating the shape array, its two numbers, and the dtype
adds 4, for **16,389 total**. For argmax over `[180,5]`, the operator's own charge
is 901 before evaluating its tensor lookup and axis arguments.

Counts describe evaluator work, not wall-clock milliseconds. The same valid
expression and data under the same evaluator produce the same count regardless
of the host's speed.

## What over budget means

Execution aborts when a charge exceeds the available budget. An oversized tensor
operation is refused before its element work begins. It is not retried with more
budget. In admission, an over-budget adapter is rejected; during play, a failed
answer contributes a strike.

Passing reference cases cannot guarantee every later observation fits. More ants,
more visible objects, and larger maps can change counts. A late-game observation
can be more demanding than the opening.

## Measuring before you submit

Axon's `/validate` reports `ops_in` and `ops_out` per case and `ops_max` across the
run. Check the maximum of the two directions, not their sum, against one million.
`/play` reports a combined `ops` count, so a total over one million need not mean
either individual direction exceeded its limit.

Use the [testing workflow](../testing.md) with real observations and constructed
boundary cases. The existing reference-adapter test in Axon prints measured counts:

```sh
# From the axon checkout
cargo test --test ants_adapter -- --nocapture
```

Those measurements describe the test adapter and fixture, not your entry.

## Spending less

Build dense planes with `tb.scatter` and `tb.rle_expand` instead of nested JSON
loops. Derive wrapped visibility with `tb.dilate`. Avoid converting a full policy
plane into JSON when argmax or a targeted gather can reduce it first. Reconsider
repeated copies, stacks, and dtype conversions if they dominate your count.

Keep a margin below the limit and test all [map presets](../../games/ants/maps.md).
An adapter that fits the smallest board exactly is unlikely to be reliable on
cell's 128 × 128 board.
