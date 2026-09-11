# A real adapter, piece by piece

The platform's own baselines — `nano-bc` and `micro-bc` in
[ants-baselines](https://github.com/Tiny-Brains/ants-baselines) — play with one adapter, byte for
byte: 1,229 bytes, 394 after compression. It turns an observation into seven planes stacked as one
tensor, `board: int8[1, 7, rows, cols]`, and turns the graph's dense policy map,
`policy: float32[1, 5, rows, cols]`, back into one move per ant. This page reads it a piece at a
time.

It is not written by hand. `ants-baselines/src/tb_baselines/planes.py` declares each plane once,
with two renderings side by side — the JSONLogic below, and the numpy the trainer uses — and a test
proves the two agree. [The end of this page](#the-same-encoding-in-your-trainer) comes back to why
that matters.

Every fragment below has a link that opens it in [DataLogic Studio](studio.md), against this
illustrative observation:

```json
{"size": [64, 96], "mine": [[12, 30], [13, 30], [43, 66]], "foes": [[12, 33, 1]],
 "food": [[11, 31]], "hills": [[12, 30, 0], [44, 70, 1]],
 "water": {"rle": [0, 1250, 1, 3, 0, 4891]}}
```

Three ants — one on your hill at `[12, 30]`, one beside it, and a third within sight of the enemy
hill at `[44, 70]` — a foe next to the first two, one food, and three cells of known water on
row 13.

## The whole `in` program

{{#studio studio/baseline-in.json embed}}

The Studio evaluates the JSON half and stops at the tensor half. Every `tb.*` call comes back with
its arguments already worked out — the points, the shape, the dtype — which is exactly what Axon's
operator receives; the Studio never builds the tensor. [Seeing it in DataLogic Studio](studio.md)
says what to look at, and where the Studio and the arena disagree.

The same program against a real input, one of the ten observations admission validates every
adapter against:

{{#studio studio/baseline-in-reference.json nocode}}

## Seven planes

Each plane is a `rows × cols` grid of `0` and `1`, built from one field of the observation:

| # | Plane | Built by | What it tells the graph |
|---|---|---|---|
| 0 | your ants | `{"tb.scatter": [{"var": "mine"}, {"var": "size"}, "int8"]}` | Where your ants are: the only positions you are told in full |
| 1 | foes | a scatter of `foes`, owner stripped | Enemy ants you can see this turn |
| 2 | food | `{"tb.scatter": [{"var": "food"}, {"var": "size"}, "int8"]}` | Food you can see |
| 3 | water | `{"tb.rle_expand": [{"var": "water.rle"}, {"var": "size"}, "int8"]}` | Known water: the one field the game remembers for you |
| 4 | your hills | a scatter of `hills` whose owner is `0` | What you lose points for |
| 5 | enemy hills | a scatter of `hills` whose owner is not `0` | What you gain points for razing |
| 6 | visible | `{"tb.dilate": [<plane 0>, 77]}` | Every cell you can see right now |

`tb.scatter` starts from a grid of zeros in the given shape and writes `1` at each `[row, col]`
point. The shape is `{"var": "size"}`, read from the observation and never written down: the three
presets are 64 × 96, 96 × 96 and 128 × 128, and an adapter that fixes one of them fails the other
two.

### Stripping the owner

A foe arrives as `[row, col, owner]`, and `tb.scatter` reads a third element as **the value to
write**. In today's two-seat presets every foe is labelled `1`, so scattering them as they come
happens to write the right value; strip the owner anyway, so the plane means "a foe is here" and not
"foe number N is here". A `map` rebuilds each triple as a pair:

{{#studio studio/foe-positions.json}}

Inside the `map` body the document is one foe, so `{"var": "0"}` is its row and `{"var": "1"}` its
column.

### Splitting hills by owner

`hills` holds both sides' standing hills, and owners are **relative to you**: `0` is always yours,
and `1` upward is an opponent ([ownership labels](../observation.md#ownership-labels)). A `filter`
on the third element splits them, and the same `map` strips the owner:

{{#studio studio/hills-split.json}}

The two keys, `mine` and `theirs`, are only there so the Studio can show both halves at once; the
adapter puts each list straight into its own `tb.scatter`. An object with keys that are not
operators is a literal — its values are evaluated and its keys kept — which is also how the `in`
program names its tensors.

### Water

`water.rle` is the known-water mask, run-length encoded in row-major order as
`[value, count, value, count, …]`. `tb.rle_expand` unrolls it straight into a plane, with no JSON
loop over the cells. The runs must not add up to more than `rows × cols`, and the game's always add
up to exactly that.

A `0` in this plane means known land **or never seen**: the game does not tell the two apart.
Plane 6 is the half of that question the adapter can answer.

### What you can see right now

The observation carries no visibility mask, but one can be derived: a cell is in sight when it lies
within squared distance 77 of one of your ants, measured on a board that wraps. `tb.dilate` does
exactly that — every cell within `radius2` of a non-zero cell, wrapping the last two axes:

```json
{"tb.dilate": [{"tb.scatter": [{"var": "mine"}, {"var": "size"}, "int8"]}, 77]}
```

The operator exists because this plane cannot be written correctly without it. The alternative —
adding each offset of the disk to every ant — costs about seven times as much and is wrong at the
edges: offsets that run off the board are dropped by `tb.scatter` instead of wrapping round to the
other side, and the modulo that would wrap them needs the board's size, which a loop body cannot
see ([scope](dialect.md#variables-and-scope)).

With plane 6 beside plane 3, a `0` for water under a `1` for visible means land you are looking at.
Under a `0`, it means only that no water is known there.

### Stacking, and the batch axis

```json
{"board": {"tb.reshape": [
  {"tb.stack": [[<plane 0>, <plane 1>, …, <plane 6>], 0, "int8"]},
  {"merge": [[1, 7], {"var": "size"}]}
]}}
```

`tb.stack` on axis 0 turns seven `[rows, cols]` planes into one `[7, rows, cols]` tensor.
`tb.reshape` adds a leading axis of `1`, with the shape built at run time — `merge` of `[1, 7]` and
the size is `[1, 7, 64, 96]` — and costs a single operation, because a reshape moves no elements.

The leading `1` is the **batch axis**, and the graph declares it dynamic: `tinybrains check` reports
its input as `board[null, 7, null, null]`. That is what lets Axon stack the boards of several
matches into one inference when they are the same size. A graph exported with a fixed `1` there
still plays, one inference per seat. The two trailing `null`s are how one graph plays all three
board sizes.

The object `{"board": …}` is the `in` program's result: one key per graph input, and every value a
tensor. A graph with two inputs gets an object with two keys.

## What it costs

`tinybrains check` runs admission's own validation over the cartridge's ten reference observations.
For this adapter, measured on 11 September 2026:

| Board | Cells | `in` operations | `out` operations |
|---|---:|---:|---:|
| 64 × 96 | 6,144 | 92,234 – 92,284 | 30,868 – 31,548 |
| 96 × 96 | 9,216 | 138,314 | 46,188 |
| 128 × 128 | 16,384 | 245,834 – 245,839 | 82,108 – 83,068 |

Against a budget of 1,000,000 per direction, the worst case uses a quarter of it.

**The cost is the board, not the ants.** A plane-building operator is charged for every cell it
produces, whether or not it writes anything there. Six scatters and one RLE expansion each produce a
full grid, the dilation reads and writes another, and the stack reads all seven planes again: fifteen
charges per cell, which is 245,760 on the largest board. The ants, foes and food add a few
operations each.

**`out` pays for the board too.** It reads the policy back at your ants with `tb.gather`, which is
charged for everything it reads — all five channels of every cell, 81,920 on the largest board. A
graph that answered `[ants, 5]` directly would pay a few hundred operations on the way out instead,
and would need per-ant inputs to do it. That trade is yours to make.
[The budget](budget.md#what-each-operator-charges) lists what every operator charges.

## The `out` program

```json
{"map": [
  {"tb.argmax": [
    {"tb.transpose": [
      {"tb.gather": [
        {"tb.reshape": [{"var": "outputs.policy"},
                        [5, {"*": [{"var": "observation.size.0"}, {"var": "observation.size.1"}]}]]},
        <each ant's flat index>,
        1
      ]},
      [1, 0]
    ]},
    1
  ]},
  {"tb.at": [["N", "E", "S", "W", "-"], {"var": ""}]}
]}
```

Read it from the inside out:

1. `{"var": "outputs.policy"}` is the graph's output: five scores for every cell,
   `[1, 5, rows, cols]`.
2. `tb.reshape` flattens the board into `[5, rows × cols]`, so each cell is one column: cell
   `[r, c]` is column `r × cols + c`. A reshape is free.
3. Each ant's flat index is computed from `observation.mine` — the next section.
4. `tb.gather` takes those columns along axis 1, giving `[5, ants]`. That is still a tensor.
5. `tb.transpose` with `[1, 0]` swaps the axes: `[ants, 5]`, one row per ant.
6. `tb.argmax` along axis 1 returns a JSON list of each row's winning channel. On a tie, the first
   channel wins.
7. `map` turns each index into its letter with `tb.at`.

The letters must be in the order your graph was trained to mean them. The baselines put the hold,
`-`, last. [drill's sample models](https://github.com/Tiny-Brains/drill/blob/main/models/README.md)
include one whose last channel wins everywhere, and its whole colony stands still for the entire
match: valid actions, a legal match, and nothing happening.

### Each ant's flat index

The flat index is `row × cols + col`, and computing it is the fiddliest thing in the dialect. A
`map` over `observation.mine` cannot do it, because inside the body the document is one ant and
`observation.size.1` is out of reach. A `reduce` can, because its starting accumulator is evaluated
outside the loop — so the width goes in with it and is handed on at every step:

{{#studio studio/flat-index.json}}

The accumulator is `{"idx": [...], "w": 96}`: each step appends one index and passes the width
along. `tb.get` then projects `idx` out of the finished accumulator, which `var` cannot do, because
`var` reads the document and not a computed value. The Studio shows that finished accumulator,
`{"idx": [1182, 1278, 4194], "w": 96}`, inside the `tb.get` it does not run.

The shipped file reads the accumulator inside the body with
`{"tb.get": [{"var": "accumulator"}, "idx"]}`, where the version above uses
`{"var": "accumulator.idx"}`. Axon builds the same tensors from both on every reference
observation, and the `var` form costs fewer operations. The Studio can run only the `var` form.

## The same encoding in your trainer

A model trained in Python sees observations through a numpy encoder, and plays through
`adapter.json`. That is one encoding written twice, and when the two disagree nothing fails: the
model trains on one distribution and plays on another, and the only symptom is a rating below what
training promised.

The baselines' answer is worth copying. `planes.py` declares every plane once, with both
renderings next to each other, and `tests/test_adapter_conformance.py` runs `tinybrains adapt` —
Axon's own evaluator — over the cartridge's reference observations and asserts that the adapter's
tensors equal the numpy encoder's, element for element:

```python
theirs = np.load(out / f"case-{i}" / "board.npy")            # the ladder's own tensor
ours = planes.encode(json.loads((out / f"case-{i}" / "observation.json").read_text()))
assert np.array_equal(ours, theirs)
```

[Testing before you submit](../testing.md#see-the-tensors-your-adapter-builds) shows the command.
