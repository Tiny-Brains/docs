# The dialect

Adapter dialect 1 is JSONLogic with a fixed list of operators, an explicit rule for objects, and
tensor operators under the `tb.` prefix. Axon implements it, counts every operation it evaluates,
and is the only implementation that decides anything. A general JSONLogic engine —
[DataLogic Studio](studio.md) included — runs the JSON half the same way, with the differences that
page lists, and counts nothing.

## Expressions and objects

A number, a string, `true`, `false` or `null` is itself. An array evaluates each of its elements.
An object is decided by one rule:

> **An object whose single key is an operator is an operation. Any other object is a literal, whose
> values are evaluated and whose keys are kept.**

That rule is how `in` names its tensors: `{"positions": {"tb.zeros": [[2, 2], "float32"]}}` is a
literal with one key, `positions`, whose value is an operation.

It also means a misspelt operator is not an error. `{"filtr": …}` and `{"split": …}` are objects
with one key, so the program runs and hands the next operator an object. The `tb.` prefix is the
exception: `{"tb.zeross": …}` is refused as `ADAPTER_INVALID`, because nothing but an operator may
use that prefix.

An operator's arguments go in an array, and a single argument may be written bare:
`{"var": "mine"}` is `{"var": ["mine"]}`.

## Core operators

These, and the `tb.*` operators in [Operators](operators.md), are the whole dialect. Any other key
is a literal.

| Purpose | Operators |
|---|---|
| Access and presence | `var`, `val`, `missing`, `missing_some`, `??` |
| Branching and Boolean logic | `if`, `?:`, `!`, `!!`, `and`, `or` |
| Comparisons | `==`, `===`, `!=`, `!==`, `>`, `>=`, `<`, `<=` |
| Scalar arithmetic | `+`, `-`, `*`, `/`, `%`, `max`, `min`, `abs`, `ceil`, `floor` |
| Strings and membership | `cat`, `substr`, `in` |
| Collections | `merge`, `map`, `filter`, `reduce`, `all`, `some`, `none`, `length`, `slice`, `sort`, `distinct` |
| Object inspection | `keys`, `values`, `entries`, `type` |

`if`, `and` and `or` evaluate only the branches they need, and a branch that is not evaluated costs
nothing. `??` returns its first argument that is not `null`. `/` and `%` by zero return `null`
rather than failing the turn, so follow them with `??` when a count can be zero. `>`, `>=`, `<` and
`<=` compare two strings as strings and anything else as numbers, and take a third argument for a
range: `{"<=": [0, {"var": "0"}, 63]}` is `0 ≤ row ≤ 63`. `sort` orders values that read as numbers
by value, and the rest as text. An expression nested deeper than 64 levels is refused.

## Variables and scope

`{"var": "size.0"}` reads the first element of `size`: a path splits on `.`, and a number indexes an
array. An empty path, `{"var": ""}`, is the whole document. A path that does not resolve is `null`,
unless `var` has a second argument, which is its fallback: `{"var": ["hills.0.2", -1]}`. `val` is
another name for `var`.

**Inside `map`, `filter`, `all`, `some` and `none`, the document is the element.** For a coordinate
pair, `{"var": "0"}` is its row. Nothing outside the element can be reached from inside the body —
and asking does not fail, it reads `null`:

{{#studio studio/scope-trap.json}}

Every ant comes back with a `null` where the board's width was meant to be. Handed to `tb.scatter`,
a `null` coordinate reads as `0`, so every point lands in column 0 and nothing reports a problem.

**`reduce` is the one way in.** Its body sees `{"current": <element>, "accumulator": <so far>}`,
and its third argument — the starting accumulator — is evaluated *outside* the loop. So an outer
value the body needs goes into the accumulator, and is handed on at every step:

{{#studio studio/reduce-seed.json}}

The body has to return the whole accumulator, width included, or the next step loses it. At the
end, `tb.get` projects the part you wanted out of the result: `var` reads the document, and
`tb.get` reads any value. This is an `in` expression; in `out`, the same paths begin with
`observation.`, as in [the baselines' `out` program](walkthrough.md#each-ants-flat-index).

## Tensor values

A tensor is not a nested JSON array. It is an opaque value with a shape and a dtype, made by a
`tb.*` operator and consumed by one. A program may ask it two things —
`{"var": "outputs.policy.shape"}` and `{"var": "outputs.policy.dtype"}`, or `tb.shape` and
`tb.dtype` — and nothing else: no indexing, no `map`, no arithmetic. The dtypes are `int8`, `uint8`,
`int16`, `int32` and `float32`.

A tensor is truthy, and equal only to itself. [Operators](operators.md) lists the ways into a
tensor, and the two ways back out.

## Equality and truth

`==` compares the way JavaScript does, with one rule to remember: **`null` equals only `null`**.
`{"==": [0, null]}` is `false`, so a missing lookup never passes for zero. The platform's workflow
engine and DataLogic Studio answer `true` there; it is the one known difference in the JSON half
([more](studio.md#where-the-studio-and-the-arena-differ)). `===` compares without converting.

`0`, `""`, `null` and `[]` are false, and everything else is true, `{}` included. `all` and `some`
over an empty list are `false`, and `none` is `true`. Test the turn with no foes and no food in
sight, where all three meet an empty list.

## What the dialect will not do

There is no tensor arithmetic beyond `tb.cast` and `tb.normalise`: no add, no multiply, no matrix
multiply, no convolution. That is deliberate. A tensor operator is priced by the larger of the
elements it reads and the elements it produces, which is right for moving data and wrong for
computing with it: a 128 × 128 matrix multiply would be charged 32,769 operations for two million
multiply-adds. An adapter that could compute would be a second, unpriced model in front of the
priced one.

It is against your interest anyway. The adapter is interpreted; the graph is compiled, threaded and
vectorised, and the two share one turn deadline. Put the arithmetic in the graph.

When an operator you want is missing, ask whether it moves or reshapes information, or computes
with it. Moving is the dialect's job, and a missing mover is worth asking the platform for.
Computing is the graph's.

## Versions

`"dialect": 1` declares the language the adapter is written in, and a version the evaluator does
not implement is refused at admission. Every reply from Axon also carries an `evaluator_digest`: a
hash of the dialect's meaning — its operators, its counting rules, and semantic choices such as
"`null` equals only `null`". It moves when an adapter's meaning could change, not when Axon is
merely rebuilt, and admission records it on every version it admits.

A sweep that re-validates admitted versions when the digest moves is designed but not built. After
an announced evaluator change, re-run [local validation](../testing.md) rather than trusting an
older pass.
