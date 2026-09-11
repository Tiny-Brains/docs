# Seeing it in DataLogic Studio

[DataLogic Studio](https://goplasmatic.github.io/datalogic-rs/playground/) is a visual editor and
debugger for JSONLogic, built on datalogic-rs — the engine the platform's own workflows run on. An
adapter is JSONLogic with tensor operators, so the Studio can draw one as a flow diagram, run its
JSON half against an observation, and step through the evaluation one node at a time.

Every example in this chapter has an **Open in DataLogic Studio** link. The expression and the data
travel in the link itself, so it opens exactly that example, already evaluated, with no account and
nothing to save. The same is true of a link you make: a link to your own adapter *is* your adapter,
readable by anyone you send it to.

The Studio is a picture of your program and a runner for its JSON half. **It is not the referee.**
The ladder runs Axon's evaluator, and the two differ in the ways listed below.

## Opening your own adapter

1. Open the [Studio](https://goplasmatic.github.io/datalogic-rs/playground/).
2. Tick **Templating**, above the diagram. Without it every `tb.*` operator is refused as an invalid
   operator, and so is an object like `{"board": …}` that names your tensors. Templating is the mode
   in which the Studio follows the dialect's object rule: an object whose key is not an operator is a
   literal, and its values are evaluated.
3. Paste **one program** into Logic: the value of `in` or of `out`, not the whole file.
4. Paste a document into Data. For `in`, that is an observation. For `out`, wrap an observation as
   `{"observation": …}`: the policy tensor has no JSON form, so only the observation half of the
   `out` document can be given.
5. **Share** copies a link to what is on the screen.

For observations to paste, [What your model sees](../observation.md#a-worked-example) has a small
one, and `tinybrains adapt` writes every reference observation beside the tensors it produced, as
`case-N/observation.json` ([how](../testing.md#see-the-tensors-your-adapter-builds)).

## What you are looking at

- **Logic, Data, Result.** Result is what the Studio computed. For an `in` program that is the
  object your program builds, with every `tb.*` call still in it and its arguments evaluated:
  `{"tb.scatter": [[[12, 30], [13, 30], [43, 66]], [64, 96], "int8"]}` says that Axon's
  `tb.scatter` will receive those three points, that shape, and that dtype.
- **The diagram.** The JSON operators — `var`, `map`, `filter`, `merge` — are drawn as nodes, and
  they feed the object the program builds, where the tensor operators appear as fields. **Flow**
  draws the data left to right; **Hierarchy** draws the JSON's nesting.
- **The debugger.** The step controls walk the evaluation one node at a time, and the current node
  shows the value it produced. It is the quickest way to watch a `map` body receive each element in
  turn, or a `reduce` accumulator grow.

## Where the Studio and the arena differ

| | In the Studio | In the arena |
|---|---|---|
| The JSON operators the dialect has — `var`, `map`, `filter`, `reduce`, `if`, arithmetic, comparisons, `merge` and the rest | Evaluated | Evaluated the same way. Axon runs both engines over its test cases, and one difference is known: the next row |
| `==` with `null` on one side | `{"==": [0, null]}` is `true` | `false`: only `null` equals `null` |
| An operator only the Studio has: `split`, `upper`, `lower`, `trim`, `starts_with`, `ends_with`, `exists`, `switch`, `match`, `try`, `throw`, `group_by`, `now`, `datetime`, `timestamp`, `parse_date`, `format_date`, `date_diff`, `sem_ver`, `fractional` | Evaluated | **Not an operator.** A single-key object whose key is not an operator is an object literal: the program runs, and the value is an object |
| `tb.*` operators | Shown with their arguments evaluated; nothing is built | Tensors are built |
| A `tb.*` result used by a JSON operator — `tb.get` inside a `reduce` body, `tb.len` in arithmetic | The JSON operator receives the unevaluated call, an object, and the result is wrong or an error | Works |
| The operation count | Not shown | Counted, and each direction capped at 1,000,000 |
| Shapes, dtypes, saturation, a scatter point off the board | Not modelled | Enforced |

Two of these bite without warning.

**A comparison with a missing field.** `{"var": "3"}` on a `[row, col, owner]` triple is `null`. In
the Studio `null == 0` is true; in the arena it is false. This filter keeps both hills in the Studio
and neither in the arena:

{{#studio studio/null-equality.json}}

Never compare a lookup that can be missing with `0`. Test for it with `missing`, or give `var` a
fallback: `{"var": ["3", -1]}`.

**An operator the dialect does not have.** `{"split": ["a,b", ","]}` is `["a", "b"]` in the Studio.
In the arena `split` is not an operator, so the same expression is an object with one key, `split`
— no error, and a value your next operator does not expect. Only the `tb.` prefix is refused when
it does not name an operator. [The dialect](dialect.md#core-operators) lists every operator the
arena has: if it is not there, do not use it.

## When the Studio is enough, and when it is not

The Studio answers "does my JSON half pick out the right things" — the right lists, the right
fields, the right coordinates, the right shape — and answers it by showing you. A scope mistake, a
filter on the wrong field, or a shape assembled in the wrong order is visible in the Result pane.

It cannot answer "does my adapter build the tensor my graph was trained on", or "does it fit the
budget". [`tinybrains adapt`](../testing.md#see-the-tensors-your-adapter-builds) runs Axon's own
evaluator and writes out the tensors, and
[`tinybrains check`](../testing.md#check-it-the-way-admission-will) runs admission's validation and
reports every count.
