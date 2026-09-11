# Operators

The tensor operators of dialect 1, and four small helpers. Each is invoked as
`{"tb.name": [arguments]}`. Below, `T` is a tensor, a shape is a list of non-negative integers, and
axes count from 0. What each one costs is in [The budget](budget.md#what-each-operator-charges).

## Building tensors

| Operator | Arguments | Result |
|---|---|---|
| `tb.zeros` | `shape, dtype` | A tensor of zeros |
| `tb.full` | `shape, dtype, value` | A tensor filled with `value` |
| `tb.tensor` | `values, shape, dtype` | A **flat** list, laid out in row-major order. Its length must equal the shape's element count, or the call fails; a value that is not a number becomes `0` |
| `tb.scatter` | `points, shape, dtype, value?` | Zeros, with each point written: `[r, c]` writes `value` (default `1`), and `[r, c, v]` writes `v` |
| `tb.rle_expand` | `runs, shape, dtype` | `[v0, n0, v1, n1, …]` expanded in row-major order. Runs past the end fail; runs short of it are padded with zeros |
| `tb.one_hot` | `indices, depth, dtype` | `[len(indices), depth]`, with a `1` at each index. An index outside `0 … depth − 1` gives a row of zeros. There is no axis argument |
| `tb.range` | `n` | The JSON list `[0, 1, …, n − 1]`, not a tensor |

A scatter point outside the shape is **dropped, not wrapped**, and a later point on the same cell
overwrites an earlier one. Every value is saturated to the dtype as it is written: `300` into
`int8` is `127`, not a wrapped `44`.

A point's third element is a value, which is why foes and hills are stripped to `[r, c]` before
they make a presence plane:

```json
{"tb.scatter": [
  {"map": [{"var": "foes"}, [{"var": "0"}, {"var": "1"}]]},
  {"var": "size"},
  "int8"
]}
```

The `map` inside it, run against an observation:

{{#studio studio/foe-positions.json nocode}}

## Reshaping and combining

| Operator | Arguments | Result |
|---|---|---|
| `tb.stack` | `tensors, axis, dtype?` | A new axis at `axis`. Every input must have the same shape. The optional dtype converts, with saturation |
| `tb.concat` | `tensors, axis` | Joined along an existing axis. Every other dimension must agree |
| `tb.unstack` | `T, axis` | A JSON list of tensors, one for each index along `axis` |
| `tb.reshape` | `T, shape` | The same elements in a new shape. The element counts must match, and there is no `-1` |
| `tb.transpose` | `T, perm?` | The axes reordered: `perm[i]` is the input axis that becomes axis `i`. Without `perm`, the axes are reversed |
| `tb.pad` | `T, before, after, value` | `before[d]` and `after[d]` cells added on each axis `d`, filled with `value` (default `0`) |
| `tb.crop` | `T, offset, shape` | The `shape`-sized region that starts at `offset`. Any part of it past the input's edge is zeros |

Stacking seven `[H, W]` planes on axis 0 gives `[7, H, W]`, and reshaping that to `[1, 7, H, W]`
adds the batch axis a graph expects. [A real adapter](walkthrough.md#stacking-and-the-batch-axis)
builds the second shape from the observation's size, so one adapter serves every board.

## Converting and deriving

| Operator | Arguments | Result |
|---|---|---|
| `tb.cast` | `T, dtype` | Converted. Integer dtypes saturate and truncate toward zero |
| `tb.normalise` | `T, mean, scale?` | `(x − mean) × scale`, as `float32`. `scale` defaults to `1` |
| `tb.dilate` | `T, radius2` | `1` at every cell within squared distance `radius2` of a non-zero cell, on the last two axes and **wrapping** at the edges; `0` elsewhere |

A visibility plane, built in `in`:

```json
{"tb.dilate": [
  {"tb.scatter": [{"var": "mine"}, {"var": "size"}, "int8"]},
  77
]}
```

`tb.dilate` wraps and `tb.scatter` does not. Build vision with the operator, not by adding offsets
to each ant: those offsets fall off the edge instead of wrapping round, and the wrap needs the
board's size, which a loop body cannot see.

## Reading tensors and values

| Operator | Arguments | Result |
|---|---|---|
| `tb.argmax` | `T, axis` | A flat JSON list: the winning index along `axis` for every position of the other axes, in row-major order. On a tie, the first wins |
| `tb.gather` | `T, indices, axis?` | A **tensor** of the slices at `indices` along `axis` (default `0`). An index past the end fails the call |
| `tb.to_list` | `T` | The tensor as nested JSON lists |
| `tb.shape` | `T` | Its shape, as a list |
| `tb.dtype` | `T` | Its dtype, as a string |
| `tb.len` | `list` | Its length; a string's length in characters; `0` for anything else |
| `tb.at` | `list, i` | The item at `i`. A negative `i` counts from the end, and out of range is `null` |
| `tb.get` | `value, path` | `var`'s path lookup, applied to any value instead of to the document. A path that does not resolve is `null` |

Only `tb.argmax` and `tb.to_list` turn a tensor into JSON. `tb.gather` selects and still returns a
tensor, so an `out` program that ends in one fails: the action must be JSON. For a `[N, 5]` policy,
`tb.argmax` on axis 1 is already the `N` indices an action needs, as in
[the minimal adapter](../adapters.md#a-minimal-adapter).

`tb.to_list` is priced per element like every other operator, so converting a whole board costs the
whole board. Reduce first, with `tb.argmax` or `tb.gather`.
