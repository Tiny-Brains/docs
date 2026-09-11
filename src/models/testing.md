# Testing before you submit

Validate the **exact ONNX and adapter files** you will release. Check the interface first, the
budget and timing second, and the play third: a graph that runs and an adapter that returns do not
show that an entry plays valid, or useful, actions.

## Reference observations

Admission validates every adapter against the cartridge's **reference set**: ten observations the
engine generates, across all three presets — 64 × 96, 96 × 96 and 128 × 128 — from a colony of two
ants to one of twenty-eight. It validates against those and nothing else, so what they do not cover
is not checked. The `tinybrains` commands below read the same file.

Your own tests should add what the set does not: crowded and late-game boards, turns with no foes
or food in sight, fragmented known water, ants on the wrapping edges, and an empty `mine`, even
though a seat with no ants normally stops being called. Owners in `hills` and `foes` are
[relative to you](observation.md#ownership-labels), so both seats of a match see the same encoding;
replays recorded before engine `sha256:f17b51b6c92b…` do not follow that rule.

## The `tinybrains` CLI

`tinybrains` is the platform's command-line tool: it plays matches on your machine and runs
admission's checks without a server. Until a release is cut it is built from source;
[drill](https://github.com/Tiny-Brains/drill) explains the checkout it needs, and is the place to run
it from.

### Check it the way admission will

```sh
tinybrains check model.onnx adapter.json
```

This runs Axon's own `inspect` and `validate` — the calls admission makes — over the reference set,
and prints the graph's opset, operators, inputs and outputs, the size metric, the worst operation
count against the budget, and the slowest inference. `--json` prints everything, including
`ops_in`, `ops_out` and the input shapes of every case. A pass is necessary and not sufficient:
there is no download allowlist on your machine, and the size class is decided by admission, not
here.

### See the tensors your adapter builds

```sh
tinybrains adapt adapter.json --out tensors
```

This runs only the `in` program, through Axon's evaluator, over every reference observation, and
writes each input tensor as a numpy `.npy` file beside the observation that produced it:

```text
tensors/
  manifest.json            evaluator digest, budget, and each case's ops_in and tensor shapes
  case-0/observation.json
  case-0/board.npy         one file for each input your in program names
  case-1/…
```

`--obs FILE` runs your own observations instead: one, a list of them, or
`{"observations": [...]}`.

These are the tensors the ladder will feed your graph. **Before you train, assert that your
trainer's encoder produces the same ones**, element for element. An encoder that disagrees with the
adapter trains a model on inputs the arena never serves, and nothing fails: the rating is simply
lower than training promised. [A real adapter](adapters/walkthrough.md#the-same-encoding-in-your-trainer)
shows the test the platform's own baselines run.

### Play a match

```sh
tinybrains matches/quick.json          # from a drill checkout
tinybrains view replays/quick.json
```

A match file names a model for each seat by path, so your model can play the baselines, itself, or
last week's version on your own machine, through the real cartridge and the real evaluator. Every
run prints the adapter's mean operations per seat-turn.

## Validate against a running loader

On a [local platform](../platform/running-locally.md), the admission loader at
`http://127.0.0.1:9091` answers the same calls over HTTP. It fetches assets by URL from allowed
hosts, so this is the route for a release that is already published. These are service interfaces
for testing and platform operation, not public Soma API routes.

First call `POST /load` with the release asset URLs and their actual hashes:

```json
{
  "models": [{
    "weights_hash": "sha256:<model hash>",
    "adapter_hash": "sha256:<adapter hash>",
    "weights_url": "https://github.com/OWNER/REPO/releases/download/TAG/model.onnx",
    "adapter_url": "https://github.com/OWNER/REPO/releases/download/TAG/adapter.json"
  }],
  "wait_ms": 5000
}
```

Replace every placeholder, and confirm `state: "resident"` for the pair. Supply the configured
bearer credential if local Axon authentication is enabled.

Save the two hashes as `model-ref.json`, then inspect:

```sh
curl --fail-with-body -sS http://127.0.0.1:9091/inspect   -H 'Content-Type: application/json' --data-binary @model-ref.json
```

Read `size_metric_bytes`, `opset`, `ops`, `inputs` and `outputs`, and compare them with the
[format policy](format.md) and your [class](weight-classes.md). `/inspect` reports facts; it does
not decide admission.

Then call `POST /validate` with the hashes, `budget_ops: 1000000`, `deadline_ms: 1000`, and
`observations`, an array of observation objects. With that body saved as `validation.json`:

```sh
curl --fail-with-body -sS http://127.0.0.1:9091/validate   -H 'Content-Type: application/json' --data-binary @validation.json
```

Read the body's `ok` field, not only the HTTP status. On failure, read `reason`, `detail`,
`failing_case` and `over_budget`. On success, compare each case's `inputs`, `ops_in` and `ops_out`,
and the run's `infer_us_max`, with what you expect. `infer_us_max` is the slowest case's inference
in microseconds; compare it with the turn deadline divided by the seats a wave plays at once.
Admission allows 5,000 ms per validation observation, so using the real 1,000 ms turn deadline
locally is the stricter check.

Release the hold afterwards with `POST /unload` and a `models` array holding the pair of hashes.

## Check the actions too

`validate` reports each case's `action_shape` — `array[17] of string`, say — but does not check
Ants' action rules. Assert for yourself that the action has one entry per ant in `mine`, and that
every entry is one of `N`, `E`, `S`, `W` and `-`. Feed known scores through `out` to check the
channel order, and how ties fall. Then play a match and count the moves: a model whose hold channel
wins everywhere plays valid actions and never moves.

```sh
python3 -c "import json,collections; d=json.load(open('replays/quick.json')); \
  print(collections.Counter(c for t in d['deltas'] for s in t['a'] for c in s))"
```

## Before publishing

Confirm every preset's shapes, both adapter directions, the action order, the size class, and the
turn timing. Hash the final files after every edit: reformatting an adapter changes its hash and its
size. Keep the release tag, the model ID and both hashes with your training notes, so that a result
can always be traced to the version that produced it.


<div class="tb-replay" data-src="tutorials/4-growth.json" data-turn="2" data-zoom="6"></div>

<p class="tb-replay-caption">Stepping a replay is how an unexpected result gets explained: here, why an ant did not appear until a turn after the food was gathered, and why two ants vanished at once.</p>

<!-- replay-visualiser: testing-behaviour — filled.
Asset: tutorials/4-growth.json, turn 2. Regenerate with tutorials/build.sh.
The prose above the slot stands alone: a page whose viewer fails to load still teaches the rule.
-->
