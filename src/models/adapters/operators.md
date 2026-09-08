# Operators

These are the tensor and helper operators implemented by adapter dialect 1.
Write each invocation as `{"tb.name":[arguments]}`. `T` below denotes an opaque
tensor, shapes are non-negative integer lists, and axes are zero-based.

## Building tensors

| Operator | Arguments | Result and behavior |
|---|---|---|
| `tb.zeros` | `shape, dtype` | Tensor filled with zero |
| `tb.full` | `shape, dtype, value` | Tensor filled with a scalar |
| `tb.tensor` | `values, shape, dtype` | Flat list to tensor; length must equal the shape's element count |
| `tb.scatter` | `points, shape, dtype, value?` | Zero tensor with indexed points written; default value 1 |
| `tb.rle_expand` | `runs, shape, dtype` | Expand value/count pairs in row-major order |
| `tb.one_hot` | `indices, depth, dtype` | Tensor of shape `[len(indices), depth]` |
| `tb.range` | `n` | JSON list `0` through `n−1` |

For a two-dimensional scatter, `[r,c]` writes the default and `[r,c,v]` writes
`v`. Out-of-bounds points are dropped, not wrapped, and later repeated points
overwrite earlier ones. Strip owner tags from `foes` before scattering a binary
presence plane, or the owner number will become the stored value.

```json
{"tb.scatter": [
  {"map": [{"var": "foes"}, [{"var": "0"}, {"var": "1"}]]},
  {"var": "size"},
  "int8"
]}
```

`tb.rle_expand` rejects runs exceeding the shape and pads a short expansion with
zeros. Valid Ants observations already cover the exact map area. `tb.one_hot`
leaves invalid indices as zero rows; it has no supported axis argument.

## Reshaping and combining

| Operator | Arguments | Meaning |
|---|---|---|
| `tb.stack` | `tensors, axis, dtype?` | Insert an axis; all input shapes must agree |
| `tb.concat` | `tensors, axis` | Join along an existing axis |
| `tb.unstack` | `T, axis` | Remove an axis into a list of tensors |
| `tb.reshape` | `T, shape` | Change shape while keeping the element count |
| `tb.transpose` | `T, perm` | Reorder axes by a permutation |
| `tb.pad` | `T, before, after, value` | Add cells before and after each axis |
| `tb.crop` | `T, offset, shape` | Extract a region |

Use non-negative dimensions and explicit axes; do not assume ONNX conventions
such as a reshape dimension of `-1` are supported in the adapter.
Stacking four `[H,W]` planes on axis 0 yields `[4,H,W]`. Reshaping to
`[1,4,H,W]` adds the batch dimension expected by a matching graph.

## Converting and deriving

| Operator | Arguments | Meaning |
|---|---|---|
| `tb.cast` | `T, dtype` | Convert with saturation for integer limits |
| `tb.normalise` | `T, mean, scale` | `(x − mean) × scale`, producing `float32` |
| `tb.dilate` | `T, radius2` | Mark cells around nonzero cells, wrapping the last two axes |

A visibility plane in `in` scope can be built directly:

```json
{"tb.dilate": [
  {"tb.scatter": [{"var": "mine"}, {"var": "size"}, "int8"]},
  77
]}
```

Dilation uses the squared radius and wraps; scatter itself does not. Do not use
an ordinary clipped neighbourhood expansion to model Ants vision at borders.

## Reading tensors and values

| Operator | Arguments | Result |
|---|---|---|
| `tb.argmax` | `T, axis` | Flat JSON list of winning indices after reducing the axis; first maximum wins ties |
| `tb.gather` | `T, indices, axis` | Tensor selected along an axis |
| `tb.to_list` | `T` | Nested JSON list matching the tensor shape |
| `tb.shape` | `T` | Shape list |
| `tb.dtype` | `T` | Dtype string |
| `tb.len` | `list` | Length; also accepts strings |
| `tb.at` | `list, i` | Item; negative indices count from the end, out-of-range returns null |
| `tb.get` | `value, path` | Lookup on an evaluated value; absent path returns null |

`tb.gather` does not return JSON. Apply a conversion before including its result
in an action. For a `[N,5]` policy tensor, `tb.argmax` on axis 1 already returns
the `N` indices needed by the [example adapter](../adapters.md).

## Costs at a glance

Each evaluated expression node costs 1, and element-moving operators additionally
charge the larger of elements read and elements produced. Metadata helpers and
reshape have no element charge. Argument expressions are counted separately.
Building and stacking a plane therefore pays for both operations even if the
result has the same dtype. See [The budget](budget.md) for measurement and examples.
