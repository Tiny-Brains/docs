# Testing before you submit

Validate the **exact ONNX and adapter files** you plan to release. Check interface
correctness first, budget and timing second, and game behavior third. A successful
forward pass alone does not show that an entry plays valid or useful actions.

## Reference observations

The current deployment falls back to a single observation from Axon's
`tests/fixtures/ants-observation.json` unless a cartridge-owned reference file is
available. Ants does not yet ship that complete conformance observation set.
The existing fixture represents a large, partially explored 128 × 128 game.

Include every preset size, sparse and crowded positions, no visible enemies or
food, fragmented known water, and ants near wrapping borders in your own tests.
Test both seats, particularly if your features use hill ownership; the current
[ownership-label limitation](observation.md#ownership-labels-in-the-current-cartridge)
matters there. Check empty ant inputs in adapter tests even though eliminated
seats normally stop receiving calls.

## Validate with Axon

Axon provides `/load`, `/inspect`, and `/validate` in admission mode. These are
local service interfaces for testing and platform operation, not public Soma
API routes. Run the [local platform](../platform/running-locally.md) to obtain an
admission loader at `http://127.0.0.1:9091`, or configure Axon independently using
its repository README.

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

Replace every placeholder. Confirm `state: "resident"` for the pair. Supply the
configured bearer credential if local Axon authentication is enabled. Admission
mode restricts download hosts; it is not a general local-file upload endpoint.

Save the two real hashes in `model-ref.json`, then inspect:

```sh
curl --fail-with-body -sS http://127.0.0.1:9091/inspect   -H 'Content-Type: application/json' --data-binary @model-ref.json
```

`model-ref.json` contains only `weights_hash` and `adapter_hash`. Read
`size_metric_bytes`, `opset`, `ops`, `inputs`, and `outputs`. Compare them with
[format policy](format.md) and your [class](weight-classes.md); `/inspect` reports
facts and does not decide admission by itself.

Next call `POST /validate` with the hashes, `budget_ops: 1000000`,
`deadline_ms: 1000`, and `observations`, an array of your observation objects.
Saving this body in `validation.json` allows:

```sh
curl --fail-with-body -sS http://127.0.0.1:9091/validate   -H 'Content-Type: application/json' --data-binary @validation.json
```

Inspect the JSON body's `ok` field, not only the HTTP status. On failure, read
`reason`, `detail`, `failing_case`, and `over_budget`. On success, compare the
reported `inputs`, per-direction counts, and `flops_max` to your expected shapes
and limits. Admission currently allows 5,000 ms per validation observation;
using the actual 1,000 ms turn deadline locally is an additional check, not an
exact reproduction of that admission timeout.

Release your local hold afterward with `POST /unload` and a `models` array
containing the pair of hashes.

## Check the actions too

Validation reports `action_shape`, but does not enforce all Ants action semantics.
Use a replica-mode loader's `/play` or an adapter-level harness to inspect the
actual action. Assert its length equals `mine` and every item is an allowed
string. Use known output scores to verify direction-channel order and tie handling.
Admission-mode Axon deliberately does not serve `/play`.

## Playing a match locally

There is no packaged offline ONNX match runner yet. The available end-to-end
route is the local Compose stack: enter a release into an open local season and
let admission, the trial, and matchmaking execute it. This requires a configured
GitHub sign-in and runnable opponents. See [Running locally](../platform/running-locally.md).

You can test the Ants engine's replay reconstruction independently, without ONNX:

```sh
# From the ants checkout
cargo test a_replay_re_simulates_the_match_it_recorded
```

This checks an engine property; it does not validate your model.

## Before publishing

Confirm all preset shapes, both adapter directions, action order, class size,
compute caps, and turn timing. Hash the final files after every edit. Once ranked
matches are available, review losses and draws to distinguish interface problems
from tactical weaknesses. Keep the release tag, model ID, and hashes with your
training notes so results remain attributable to the version that produced them.


> **Replay visualiser — planned:** Replay a recorded local test match with checkpoints for an unexpected hold, collision, or failed hill attack. Pair each checkpoint with the actual observation and returned action.

<!-- replay-visualiser: testing-behaviour
Use a recorded replay and its matching engine digest; select the relevant turns.
Provide a text caption and retain the explanation above as the accessible fallback.
Replay asset and turn range: to be selected. No synthetic match result is implied.
-->
