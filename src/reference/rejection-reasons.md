# Rejection reasons

Start with the version's `reject_reason` from `GET /v1/models/{id}`. A submission
request refusal, an admission rejection, a trial failure, and a failed match are
different events; use the stage to decide what to do next.

## Request refusals

These occur before a new version is successfully recorded.

| Error or condition | Meaning | Next step |
|---|---|---|
| `hashes_required` | Missing or obviously malformed declared hashes | Supply both `sha256:<64 hex>` values |
| `season_not_open` | No season accepting submissions | Read the season dates and wait for an open window |
| `not_a_participant` | Account not admitted by the season's participant rule | Check eligibility with the organizer |
| `weights_already_entered` | Another owner already holds these weights under the season's rule | Check the rule scope and submit an eligible entry |
| `409` duplicate release | This model has already entered that tag this season | Publish a new tag for changed bytes |
| `version_in_flight` | This model already has a testing or verified candidate | Follow that candidate to a verdict; your other models are unaffected |
| `unknown_model` | No model of yours publishes from that repository | Create the model first — a submission never creates one |
| `model_retired` | The model takes no new releases | Revive it, or submit to another |
| `too_many_in_flight` | You are at the season's limit for versions in admission at once | Wait for one to reach a verdict |
| `too_many_versions` | You have entered as many versions as the season allows | The next season starts you fresh |
| `cooling_down` | The season asks for a gap between one model's submissions | The response carries the instant you may try again |
| `entries_max` | You hold as many models as the season allows | Retire one to free a slot |
| `repo_invalid` | The URL does not name exactly one repository | Give `owner/name`, or the repository's own page |
| `repo_unverified` | GitHub did not confirm who owns the repository — it may not exist, or we are briefly rate-limited | Check the spelling; if it is right, try again shortly |
| `repo_private` | The repository is private, and release assets are fetched without a token | Make it public, or publish from one that is |
| `repo_not_owned` | GitHub says the repository belongs to a different account | Use one your signed-in account owns, or an organisation the season allows |
| `repo_taken` | That repository already has a model on it | One repository is one model, platform-wide; submit a release to it |
| `model_name_taken` | You already have a model with that name | Names are how yours are told apart |
| `401` / `session_revoked` | Session absent, invalid, expired, or revoked | Sign in again |

The current uniqueness-conflict response comes from the platform's database error
mapping; do not depend on an invented `duplicate_release` error code.

`cooling_down` is the one refusal that can legitimately disagree with itself
between two calls a second apart, because it is a function of the current time.
That is why it reports the instant you may retry rather than a yes or no.

## Release assets and graph

| Reason | Meaning | Next step |
|---|---|---|
| `ASSET_MISSING` | Asset URL is unavailable to the loader, including private or missing release assets | Check public access, tag, and exact filenames |
| `HASH_MISMATCH` | Downloaded bytes do not match declared SHA-256, or the hash is invalid | Hash the uploaded files again |
| `TOO_LARGE` | Raw asset ceiling or maximum compressed class size exceeded | Measure both files and reduce the relevant size |
| `GRAPH_INVALID` | ONNX cannot build a runnable session | Re-export and test the exact file in Axon |
| `OPSET_UNSUPPORTED` | Opset outside deployed policy | Export within the supported range |
| `OP_NOT_ALLOWED` | Graph uses an operator this season does not allow | Inspect the exported nodes and use supported operations |
| `CLASS_NOT_OFFERED` | It measured into a weight class this season does not run | Reach a class the season offers — this is not the same as being too large |
| `CLASS_FULL` | You already hold the season's limit of models in that class | Retire one in that class, or aim at another |
| `PARAMS_EXCEEDED` | More parameters than this season allows | Reduce the parameter count, not only the bytes |
| `DTYPE_NOT_ALLOWED` | The weights are stored in an element type this season does not accept | A quantised-only season lists `int8`; export with quantised weights, not merely quantised inputs |
| `TOO_SLOW` | Slower than this season's inference ceiling | Rare: most seasons set none. Simplify the graph |

A compute-cap failure does not automatically move the entry to a larger class.
See [model format](../models/format.md) and [weight classes](../models/weight-classes.md).

## Adapter and interface

| Reason | Meaning | Next step |
|---|---|---|
| `ADAPTER_INVALID` | Invalid JSON/dialect/expression or invalid adapter result | Check required fields, supported operators, scopes, and output type |
| `ADAPTER_OVER_BUDGET` | A validation direction exceeds its operation budget | Measure cases and reduce adapter work |
| `SHAPE_MISMATCH` | Graph inputs or execution do not match what validation can run | Compare actual input names, dtypes, and shapes; inspect local validation detail |

Local Axon `/validate` can return `ADAPTER_FAILED` with `over_budget: true`;
admission maps that case to `ADAPTER_OVER_BUDGET`. The loader's response can
include `detail` and `failing_case`. The current public version response exposes
`reject_reason` but does not expose all of that loader detail. Reproduce with
[local validation](../models/testing.md), or provide the model ID to the operator.

## Trials and administrative outcomes

| Reason | Meaning | Next step |
|---|---|---|
| `FORFEIT` | Candidate reached five cumulative strikes in a completed trial | Inspect timing and adapter failures, then retest |
| `FAULT:<reason>` | Failed trial attributed to the candidate seat | Investigate the underlying model fault |
| `UNPLAYABLE` | Trial repair limit exhausted | Check whether failures came from the model or infrastructure |
| `SEASON_CLOSED` | Waiting candidate could not proceed after closure | Enter an eligible later season |
| `TIMED_OUT` | Admission exhausted attempts without completing verification | Check service availability before a new tagged submission |

## Platform-side retries

Temporary `FETCH_FAILED`, `MEMORY`, `STORE_UNAVAILABLE`, loader unreachability,
and incomplete registration can leave a candidate testing while admission retries.
An eventual timeout does not establish that the neural network is invalid.
`MANIFEST_INCOMPLETE` is an operator configuration problem, not an instruction to
change the competitor's adapter.

A rejected candidate does not displace your active version. Once you understand
the cause, publish a new release tag and hashes for the next attempt. Preserve
the failed version and trial IDs in any report; they identify the evidence the
operator needs.
