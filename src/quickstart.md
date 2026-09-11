# Quickstart

Your first target is a version that completes a trial and enters the ladder.
Start with a simple model whose inputs and outputs you understand, then improve
its decisions using match results.

## What you need

You need a GitHub account, a public repository with release assets, a way to train
and export an ONNX model, and an adapter for Ants. Check the game's
[seasons](competing/seasons.md) before preparing an entry: submissions must arrive
inside an open window and satisfy that season's participation rules.

The submission and match loop is implemented. There is no packaged training SDK;
the `tinybrains` command-line tool, built from source until a release is cut,
plays matches and runs admission's checks on your own machine. The steps below
use the existing file contracts and HTTP API. You do not need to operate the
platform to enter a hosted competition.

## 1. Train something small

Read [Ants](games/ants.md), then decide how to represent the
[observation](models/observation.md). For example, a spatial model can consume
planes for your ants, visible enemies, food, and known water and produce five
move scores per ant or per board square.

Train using the same information the arena supplies. Export to `model.onnx`,
with named tensor inputs and outputs that your adapter can address. Check the
[model requirements](models/format.md) and [size classes](models/weight-classes.md)
before committing to an architecture. Export success alone does not establish
admission compatibility.

## 2. Write the adapter

Create `adapter.json` with `dialect`, `in`, and `out`. The input program builds
the model's tensors; the output program returns one of `N`, `E`, `S`, `W`, or `-`
for each ant, in observation order. See the complete small example in
[Adapters](models/adapters.md), and [a real adapter, piece by piece](models/adapters/walkthrough.md)
for one that plays.

Run the pair through [local validation](models/testing.md). Exercise all three
map sizes, empty lists, large colonies, and fragmented known-water masks. Check
both operation counts and the actual actions, not only whether execution returns.

## 3. Publish a GitHub release

Attach the files under the exact names `model.onnx` and `adapter.json` to a public
release. Compute SHA-256 hashes of those exact bytes:

```sh
# Linux
sha256sum model.onnx adapter.json

# macOS
shasum -a 256 model.onnx adapter.json
```

Keep the files unchanged after hashing. The submission uses `sha256:` followed
by each file's 64 hexadecimal digits. A GitHub source archive is not a substitute
for the two attached assets.

## 4. Create the model, then submit to it

Sign in through the competition's GitHub sign-in flow. A model is your entry: one
repository, a name, and every release you enter from it. Create it once:

```json
POST /v1/games/ants/models
{ "name": "First try", "url": "https://github.com/your-handle/your-repository" }
```

Then submit the release to it:

```json
POST /v1/submissions
{
  "game": "ants",
  "model": "your-handle/your-repository",
  "release_tag": "v1",
  "weights_hash": "sha256:<64 hex digits for model.onnx>",
  "adapter_hash": "sha256:<64 hex digits for adapter.json>"
}
```

Replace the illustrative hash values; they are not valid hashes. Save the
returned `version_id`. A `201` response creates a `testing` version, which still
needs to pass admission. See [Submitting](competing/submitting.md) for session
usage and error handling, and [Models and versions](competing/models.md) for why
the two calls are separate.

## 5. Watch the trial

Read `GET /v1/versions/{version_id}`. Its `phase` distinguishes waiting for verification
from waiting for a trial. If admission succeeds, status becomes `verified`, then
`active` after a successful trial. **Losing the trial is fine**; forfeiting it is
not. The trial checks playability and never changes ratings.

A rejection includes `reject_reason`. Fix the named issue, validate again, and
publish a new release. If the version is waiting, inspect its phase and trial
status before attempting another submission to the same model: one candidate per
model may be in flight. Another of your models can be submitted to meanwhile.

## Where to go next

Read [matches](competing/matches.md), [replays](competing/replays.md), and
[ranking](competing/ranking.md) to understand your first results. Improve one
behavior at a time and enter another version while the submission window remains
open. A model's active version stays in competition while its replacement is
tested, and your other models keep playing throughout.


> **Replay visualiser — planned:** Follow one admitted entry through its trial, highlighting the first food collection, a fight, and the final result. Show the candidate’s view alongside the full replay.

<!-- replay-visualiser: quickstart-first-trial
Use a recorded replay and its matching engine digest; select the relevant turns.
Provide a text caption and retain the explanation above as the accessible fallback.
Replay asset and turn range: to be selected. No synthetic match result is implied.
-->
