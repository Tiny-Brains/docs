# Adapters

Your entry is two files, and this is the one that is not a network. `adapter.json` holds two small
programs that Axon, the platform's model runner, evaluates around every inference: `in` turns the
game's observation into the tensors your graph takes, and `out` turns the tensors your graph returns
into the game's action. The graph never sees JSON, and the game never sees a tensor.

An adapter is **data, not code**: a JSONLogic expression tree with tensor operators, evaluated by
Axon under an operation budget it counts itself. Its exact bytes are hashed into your submission and
compressed into your size metric `S`, beside the graph's weights.

## One turn, end to end

```text
observation (JSON)           {"size": [64, 96], "mine": [[12, 30], …], …}
      │
      ▼   in                 Axon evaluates your first program
{input_name: tensor}         {"board": int8[1, 7, 64, 96]}
      │
      ▼   model.onnx         ONNX Runtime runs your graph
{output_name: tensor}        {"policy": float32[1, 5, 64, 96]}
      │   + the observation, again
      ▼   out                Axon evaluates your second program
action (JSON)                ["N", "-", "E"]
```

All three steps share one turn deadline — 1,000 ms for the whole call — and each program has its
own [budget](adapters/budget.md) of 1,000,000 operations.

## The file

```json
{ "dialect": 1, "in": <program>, "out": <program> }
```

| Field | What it must be |
|---|---|
| `dialect` | `1`. Any other value is refused at admission as `ADAPTER_INVALID` |
| `in` | An expression over the observation that produces **an object whose every value is a tensor**. Each key names one input of your graph |
| `out` | An expression over `{"outputs": …, "observation": …}` that produces the action: **plain JSON, with no tensor left anywhere in it** |

Other top-level keys are ignored by the evaluator, but they are still bytes: they change the hash
and count toward `S`.

## Two documents

`in` reads the observation exactly as the game sends it, so `{"var": "mine"}` is your ants and
`{"var": "size.1"}` is the board's width.

`out` reads a document Axon builds after inference:

```json
{ "outputs":     { "policy": <tensor> },
  "observation": { "size": [64, 96], "mine": [[12, 30], …], … } }
```

`{"var": "outputs.policy"}` is the graph output named `policy`, and `{"var": "observation.mine"}`
is the same ant list `in` saw. The observation is there because a dense output — a score for every
cell of the board — has to be read back at your ants' positions, and the positions are only in the
observation.

## Two halves: JSON, and tensors

A program is JSONLogic — `var`, `map`, `filter`, `reduce`, arithmetic, comparisons — over ordinary
JSON values, plus **`tb.*` operators** that cross into tensors and back. That split is the most
useful thing to know about the dialect:

- **A tensor is opaque.** A program can ask for its shape and its dtype, and nothing else. There is
  no indexing into a tensor, no `map` over one, and no arithmetic on one.
- **Into tensors**: `tb.scatter`, `tb.rle_expand`, `tb.tensor`, `tb.zeros`, `tb.full` and
  `tb.one_hot` build one from JSON.
- **Between tensors**: `tb.stack`, `tb.concat`, `tb.reshape`, `tb.transpose`, `tb.pad`, `tb.crop`,
  `tb.cast`, `tb.normalise`, `tb.dilate` and `tb.gather`.
- **Back to JSON**: `tb.argmax` and `tb.to_list`. Nothing else turns a tensor into a value an
  action can hold.

So the JSON half of an adapter selects and rearranges the observation — which lists, which fields,
which coordinates — and the tensor half packs the result into the shapes your graph expects.
Anything that *computes* with the numbers belongs in the graph, where it runs compiled; the dialect
has no matrix multiply and no convolution, on purpose
([why](adapters/dialect.md#what-the-dialect-will-not-do)).

## A minimal adapter

The smallest complete adapter feeds raw ant coordinates to a graph with one `float32` input named
`positions`, of shape `[N, 2]`, and one `float32` output named `policy`, of shape `[N, 5]`. It reads
the five scores per ant as `N, E, S, W, -`:

```json
{
  "dialect": 1,
  "in": {
    "positions": {
      "tb.tensor": [
        {"reduce": [
          {"var": "mine"},
          {"merge": [{"var": "accumulator"}, {"var": "current"}]},
          []
        ]},
        [{"length": [{"var": "mine"}]}, 2],
        "float32"
      ]
    }
  },
  "out": {
    "map": [
      {"tb.argmax": [{"var": "outputs.policy"}, 1]},
      {"tb.at": [["N", "E", "S", "W", "-"], {"var": ""}]}
    ]
  }
}
```

`in` flattens `mine` into one list with `reduce` and `merge`, and hands it to `tb.tensor` with the
shape `[N, 2]`. For [the worked observation](observation.md#a-worked-example)'s two ants, that is
the list `[12, 30, 13, 30]` and the shape `[2, 2]`. Open the `in` program in DataLogic Studio and
the result shows each `tb.*` operator with the arguments it will receive:

{{#studio adapters/studio/minimal-in.json nocode}}

`out` takes the argmax along axis 1 — one winning channel per ant — and maps each index to its
letter. If ant 0's winning channel is 0 and ant 1's is 1, the action is `["N", "E"]`. The `out`
program cannot run in the Studio: its input is a tensor, and JSON cannot hold one.

It is a complete adapter and a poor encoding: it ignores foes, food and water.
[A real adapter, piece by piece](adapters/walkthrough.md) reads the one the platform's own
baselines play with.

## Where it runs, and what it may do

The evaluator has no filesystem, network, clock, randomness or memory between turns. Its operators
transform JSON and tensors within a deterministic operation count, and the same adapter on the same
observation costs the same on any machine. There is no way to submit Python or native code as an
adapter.

Each direction has its own [operation budget](adapters/budget.md), and both share the turn
deadline with inference.

## Getting one right

1. Read [a real adapter](adapters/walkthrough.md) end to end: seven planes in, a dense policy map
   out, and what each piece costs.
2. Open your programs in [DataLogic Studio](adapters/studio.md) to watch the JSON half run, and learn
   the places where the Studio and the arena disagree.
3. Keep [the dialect](adapters/dialect.md)'s scope rule in mind: inside `map`, `filter` and
   `reduce`, the document is the element, and an outer path quietly reads `null`.
4. Look up any operator in [Operators](adapters/operators.md), and its price in
   [The budget](adapters/budget.md).
5. Run [`tinybrains adapt`](testing.md#see-the-tensors-your-adapter-builds) and compare its tensors
   with your trainer's encoder, element for element, before you train on anything.
