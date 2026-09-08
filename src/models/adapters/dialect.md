# The dialect

Adapter dialect 1 is a fixed JSONLogic-style expression language with explicit
tensor operators. It is implemented by Axon; using a general JSONLogic library
is not sufficient to reproduce its complete semantics or operation counts.

## Expressions and objects

Scalars evaluate to themselves. Arrays evaluate each element as an expression.
An object with one recognized operator key invokes that operator. Other objects
construct a result object by evaluating their values and keeping their keys.
Unknown single-key `tb.*` expressions are errors because that namespace is reserved.

For example, `{"positions":{"tb.zeros":[[2,2],"float32"]}}` constructs a
named tensor field. `{"tb.zeross":[[2,2],"float32"]}` is an error, not a literal
object. Check operator spelling: unknown names outside `tb.*` can be interpreted
as object keys rather than rejected.

## Core operators

| Purpose | Operators |
|---|---|
| Access and presence | `var`, `val`, `missing`, `missing_some`, `??` |
| Branching and Boolean logic | `if`, `?:`, `!`, `!!`, `and`, `or` |
| Comparisons | `==`, `===`, `!=`, `!==`, `>`, `>=`, `<`, `<=` |
| Scalar arithmetic | `+`, `-`, `*`, `/`, `%`, `max`, `min`, `abs`, `ceil`, `floor` |
| Strings and membership | `cat`, `substr`, `in` |
| Collections | `merge`, `map`, `filter`, `reduce`, `all`, `some`, `none`, `length`, `slice`, `sort`, `distinct` |
| Object inspection | `keys`, `values`, `entries`, `type` |

`if`, `and`, and `or` evaluate only needed branches. `??` chooses the first
non-null value. Division or remainder by zero returns `null`; handle it explicitly
when a count may be zero. Expressions deeper than 64 levels are refused.

## Variables and scope

`{"var":"size.0"}` reads the first dimension. An empty path reads the current
document, and a missing path returns `null` unless a fallback is provided:
`{"var":["optional",0]}`. `val` is an alias for `var`.

Inside `map`, `filter`, and the collection predicates, the current document is
the element. For a coordinate pair, `{"var":"0"}` reads its row. A path such
as `size.1` inside that body cannot reach the outer observation.

A `reduce` body receives `current` and `accumulator`. Its initial accumulator is
evaluated in the outer scope, so it can carry a dimension or other outer value
into the loop. `tb.get` reads a field from a computed result; unlike `var`, its
first argument need not be the current document.

```json
{
  "tb.get": [
    {"reduce": [
      {"var": "mine"},
      {"width": {"var": "accumulator.width"},
       "indices": {"merge": [
         {"var": "accumulator.indices"},
         [{"+": [
           {"*": [{"var": "current.0"}, {"var": "accumulator.width"}]},
           {"var": "current.1"}
         ]}]
       ]}},
      {"width": {"var": "size.1"}, "indices": []}
    ]},
    "indices"
  ]
}
```

This expression computes row-major indices while preserving the width inside
the reducer. It is an `in`-scope expression; in `out`, use `observation.mine`
and `observation.size.1` at the outer level.

## Tensor values

A tensor is an opaque value with a shape and dtype, not a nested JSON array.
`var` can inspect its `shape` and `dtype`; use tensor operators to access elements.
The supported dtypes are `int8`, `uint8`, `int16`, `int32`, and `float32`.
Scalars and collection operators do not perform tensor arithmetic.

## Equality and empty values

The deliberate difference from the platform's workflow evaluator is that
`{"==":[0,null]}` is **false** in adapters. Do not use a missing lookup as a
numeric zero. `===` compares without loose type conversion.

Empty arrays are falsy. `all` and `some` over an empty array return false; `none`
returns true. Test these cases when no ants, enemies, or food are present.

## Versions

`dialect: 1` declares the language version. The loader also reports an
`evaluator_digest` identifying its implementation semantics, and admitted versions
record that digest. Engine identity and evaluator identity are separate.

The v2 design includes revalidation after evaluator changes, but the automatic
sweep is not implemented. Re-run [local validation](../testing.md) after an
announced evaluator change rather than assuming an older pass proves compatibility.
