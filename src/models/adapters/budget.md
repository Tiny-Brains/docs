# The budget

Ants allows **1,000,000 adapter operations per direction per call**: the `in` program and the `out`
program each get their own million. Inference is not counted; the whole call — both programs and
the graph — has to fit the turn deadline.

## What counts as an operation

- **Every node the evaluator visits costs 1**: an operator, a literal, each element of an array
  written in the program. A loop body pays again for every element it runs over, and a branch that
  is not taken pays nothing.
- **Every tensor operator also costs the larger of the elements it reads and the elements it
  produces.** The charge is made before the work, so an operator that would exceed the budget is
  refused rather than run.
- **The two directions are counted apart.** `/validate` reports `ops_in` and `ops_out` for every
  case. `/play` reports their sum, so a total over a million does not mean either direction was
  over.

`{"tb.zeros": [[128, 128], "int8"]}` costs 16,389: 1 for the operator, 16,384 for the elements it
produces, and 4 for evaluating its arguments — the shape array, its two numbers, and the dtype.

## What each operator charges

On top of its own 1 and the cost of evaluating its arguments. `n` is the number of elements in the
tensor argument, and `m` the number in the result.

| Operator | Charge |
|---|---|
| `tb.zeros`, `tb.full` | `m` |
| `tb.tensor` | The larger of `len(values)` and `m` |
| `tb.scatter` | The larger of the number of points and `m`. **A scatter pays for the whole grid**, however few points it writes |
| `tb.rle_expand` | The larger of `len(runs)` and `m` |
| `tb.one_hot` | The larger of `len(indices)` and `m` |
| `tb.range` | Its length |
| `tb.stack`, `tb.concat` | The elements of all the inputs |
| `tb.unstack`, `tb.transpose`, `tb.cast`, `tb.normalise`, `tb.dilate`, `tb.to_list` | `n` |
| `tb.pad`, `tb.crop` | The larger of `n` and `m` |
| `tb.argmax` | `n`: it reads everything |
| `tb.gather` | The larger of `n` and `m`. **It reads the whole input**, not only the slices it keeps |
| `tb.reshape`, `tb.shape`, `tb.dtype`, `tb.len`, `tb.at`, `tb.get` | Nothing: a reshape moves no elements |

## What a real adapter costs

The baselines' adapter — seven planes in and a dense policy map out, read in full in
[A real adapter, piece by piece](walkthrough.md) — measured with `tinybrains check` over the
reference observations on 11 September 2026. The worst case on each board:

| Board | `in` | `out` |
|---|---:|---:|
| 64 × 96 | 92,284 | 31,548 |
| 96 × 96 | 138,314 | 46,188 |
| 128 × 128 | 245,839 | 83,068 |

Both follow the board, not the ants: about 15 operations per cell in, because every plane is a full
grid and the stack reads them all again, and about 5 per cell out, because `tb.gather` reads all
five channels of the policy map. On the largest board that is a quarter of the budget in, and a
twelfth of it out.

## What over budget means

The direction stops the moment a charge crosses the budget, and the call answers `ADAPTER_FAILED`
with `over_budget: true`. It is never retried: the same adapter on the same observation costs the
same on any machine. At admission it is a rejection, `ADAPTER_OVER_BUDGET`; in a match it is a
strike, like a missed deadline.

Passing admission does not prove every later turn fits. The count is taken on real input, and a
late-game turn — more ants, more food and foes in sight, a larger board — can cost more than any
reference case. An adapter whose cost follows the board, as the baselines' does, is predictable;
one whose loops run over ants or visible objects grows with the game.

## Measuring before you submit

`tinybrains check model.onnx adapter.json` reports the worst case over the reference set, and
`--json` adds `ops_in` and `ops_out` for every case. `tinybrains adapt adapter.json` prints the `in`
count for each case, and `--obs` measures observations of your own.
[Testing before you submit](../testing.md) has both. Compare the larger of the two directions with
the budget, not their sum.

## Spending less

- Build planes with `tb.scatter` and `tb.rle_expand`, never with a JSON loop over cells.
- Each plane costs about two operations per cell: one to build it and one to stack it. Drop the
  planes your graph does not use.
- Derive vision with `tb.dilate`. Building it by hand costs about seven times as much, and is wrong
  at the edges.
- A dense policy head pays for the whole map on the way out. A per-ant head pays per ant, and needs
  per-ant inputs to be one.
- Convert to JSON as late and as small as possible: `tb.argmax` before `tb.to_list`, never after.

Test all three [presets](../../games/ants/maps.md): the 128 × 128 board costs 2.7 times what the
64 × 96 one does.
