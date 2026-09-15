# Testing before you submit

Validate the **exact ONNX and manifest files** you will release. Check the interface first, the
budget and timing second, and the play third: a graph that runs and an adapter that returns do not
show that an entry plays valid, or useful, actions.

## Reference observations

Admission probes every entry against the cartridge's **reference set**: ten observations the engine
generates, across all three presets — 64 × 96, 96 × 96 and 128 × 128 — from a colony of two ants to
one of twenty-eight. It probes against those and nothing else, so what they do not cover is not
checked. The `tinybrains` commands below read the same file.

Your own tests should add what the set does not: crowded and late-game boards, turns with no foes
or food in sight, fragmented known water, ants on the wrapping edges, and an empty `mine`, even
though a seat with no ants normally stops being called. Owners in `hills` and `foes` are
[relative to you](observation.md#ownership-labels), so both seats of a match see the same encoding.

## The `tinybrains` CLI

`tinybrains` is the platform's command-line tool: it plays matches on your machine and makes
admission's own measurements without a server. **It links the two libraries a node links** —
`datalogic-rs` for your manifest's adapters and `tract-onnx` for the graph — so what it reports is
what the platform will report, and not a local approximation of it. Until a release is cut it is
built from source; [drill](https://github.com/Tiny-Brains/drill) explains the checkout it needs, and
is the place to run it from.

### Check it the way admission will

```sh
tinybrains check model.onnx manifest.json
```

This reads the graph from the protobuf, evaluates your manifest over the reference set and runs the
graph on what it produced. It prints the two hashes, the opset, the parameter count, the node count,
the operators, the size metric, the worst operation count against the budget, and the slowest
inference:

```text
graph
    opset            17
    parameters       3006
    nodes            46
    size metric      12280 bytes  (artifact + manifest -- the platform classifies it, this does not)
    operators        Cast, Concat, Constant, Conv, Relu, Slice
    inputs           board

adapters  (10 reference observations, budget 1000000, turn 1000 ms)
    PASSED
    worst case       229415 operations, 22% of the budget
    slowest graph    7.42 ms of inference  (measured here, not a threshold: no class caps compute)
```

`--json` prints all of it as one object, per case. **A pass is necessary and not sufficient**: the
size class is decided by admission against *your season's* table, and this machine has no season.

### See the tensors your adapter builds

```sh
tinybrains adapt model.onnx manifest.json --out tensors
```

This evaluates every adapter, through **datalogic**, over every reference observation, and writes
each input tensor as a numpy `.npy` file beside the observation that produced it:

```text
tensors/
  index.json               the budget, and each case's ops and tensor shapes
  case-0/observation.json
  case-0/board.npy         one file for each input your manifest declares
  case-1/…
```

`--obs FILE` runs your own observations instead: one, a list of them, or
`{"observations": [...]}`.

These are the tensors the ladder will feed your graph. **Before you train, assert that your
trainer's encoder produces the same ones**, element for element. An encoder that disagrees with the
adapter trains a model on inputs the arena never serves, and nothing fails: the rating is simply
lower than training promised.
[A real manifest](adapters/walkthrough.md#the-same-encoding-in-your-trainer) shows the test the
platform's own baselines run.

### Play a match

```sh
tinybrains matches/quick.json          # from a drill checkout
tinybrains view replays/quick.json
```

A match file names a model and a manifest for each seat by path, so your entry can play the
baselines, itself, or last week's version on your own machine, through the real cartridge and the
real evaluator. Every run prints the mean operations and inference per seat-turn, and what fraction
of the turn the worst one used.

### Prove a replay reproduces

```sh
tinybrains conform replays/quick.json
```

This rebuilds a match from its replay envelope alone, plays it locally, and diffs every field and
every turn of the action stream. It is how the platform keeps its own local runner and its match
workflow telling the same story about the same seeds, and it is worth running on a replay of your
own entry: a difference means the two engines disagree, which is a bug worth reporting.

## What you cannot check here

| | Why |
|---|---|
| Your weight class | It is decided against **your season's** table, which this machine does not have. `check` prints the metric; the season turns it into a class |
| Whether your files are where the platform expects | The platform reads them from the bucket you upload to, not from your disk |
| Whether a late-game turn fits the budget | The reference set is ten observations. A crowded board can cost more than any of them |
| How your entry rates | That is the ladder's, over many matches against many opponents |

## Check the actions too

`check` confirms that your head decodes to a valid action on every reference observation. It does
not confirm the action is any *good*, and it cannot: the platform reads your head with a fixed
channel order, so a graph trained against a rotated order produces valid moves in the wrong
directions and passes everything. Play a match and count the moves — a model whose hold channel
wins everywhere plays valid actions and never moves:

```sh
python3 -c "import json,collections; d=json.load(open('replays/quick.json')); \
  print(collections.Counter(c for t in d['deltas'] for s in t['a'] for c in s))"
```

## Before publishing

Confirm every preset's shapes, every adapter's budget, the channel order, the size metric and the
turn timing. **Hash the final files after every edit**: reformatting a manifest changes its hash and
its size, and the hash you declare is what the upload is checked against. Keep the release tag and
both hashes with your training notes, so that a result can always be traced to the version that
produced it.


<div class="tb-replay" data-src="tutorials/4-growth.json" data-turn="2" data-zoom="6"></div>

<p class="tb-replay-caption">Stepping a replay is how an unexpected result gets explained: here, why an ant did not appear until a turn after the food was gathered, and why two ants vanished at once.</p>

<!-- replay-visualiser: testing-behaviour — filled.
Asset: tutorials/4-growth.json, turn 2. Regenerate with tutorials/build.sh.
The prose above the slot stands alone: a page whose viewer fails to load still teaches the rule.
-->
