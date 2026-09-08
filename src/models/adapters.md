# Adapters

An adapter connects Ants' JSON protocol to the tensor representation you choose.
It is declarative data in `adapter.json`, evaluated by Axon before and after every
model inference. You submit it with the model and its compressed bytes count
toward your class.

## The two directions

```text
observation JSON → in → named input tensors → ONNX
ONNX output tensors + original observation → out → action JSON
```

The file has three required fields:

| Field | Meaning |
|---|---|
| `dialect` | Evaluator language version; currently `1` |
| `in` | Expression producing an object of named tensors |
| `out` | Expression producing the game's action JSON |

`in` reads the observation directly: `{"var":"mine"}` accesses your ants.
`out` reads a document containing `outputs` and `observation`:
`{"var":"outputs.policy"}` accesses a graph output named `policy`, while
`{"var":"observation.mine"}` accesses the original ant positions.

## A minimal adapter, end to end

The following complete adapter is for a deliberately simple graph with one
`float32` input named `positions`, shape `[N, 2]`, and a `float32` output named
`policy`, shape `[N, 5]`. It feeds raw ant coordinates to the graph and interprets
five scores per ant as `N, E, S, W, -`.

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

For `mine: [[12,30],[13,30]]`, `positions` contains `[12,30,13,30]` with shape
`[2,2]`. If the graph's winning channels are 0 and 1, the action is `["N","E"]`.
The adapter is complete, but a matching trained ONNX graph is still required;
this limited representation ignores enemies, food, and terrain.

A spatial model can instead scatter position lists onto planes, expand known
water, stack channels, and derive visibility. The
[operator reference](adapters/operators.md) provides those building blocks.

## Where it runs and what it may do

The evaluator has no filesystem, network, clock, ambient randomness, or persistent
state. Its supported operators transform JSON and tensors within a deterministic
operation count. There is no facility to upload Python or arbitrary native code
as an adapter.

General tensor arithmetic and neural computation belong in the ONNX graph.
The adapter provides arrangement, conversion, indexing, and selected transforms;
it does not provide matrix multiplication or convolution as a second model.

Each direction has its own [operation budget](adapters/budget.md), and both share
the turn deadline with inference. Output must be ordinary JSON: convert tensors
using `tb.argmax` or `tb.to_list` before returning an action. `tb.gather` still
returns a tensor and is not by itself a JSON conversion.

Read [the dialect](adapters/dialect.md) before using nested loops: a map body sees
its element, not the outer observation. Then [test](testing.md) both directions
against real and boundary-case observations.
