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
| `409` duplicate release | Same repository/tag already entered this season | Publish a new tag for changed bytes |
| `409` candidate conflict | A testing or verified candidate already exists | Follow that candidate to a verdict |
| `401` / `session_revoked` | Session absent, invalid, expired, or revoked | Sign in again |

The current uniqueness-conflict response comes from the platform's database error
mapping; do not depend on an invented `duplicate_release` error code.

## Release assets and graph

| Reason | Meaning | Next step |
|---|---|---|
| `ASSET_MISSING` | Asset URL is unavailable to the loader, including private or missing release assets | Check public access, tag, and exact filenames |
| `HASH_MISMATCH` | Downloaded bytes do not match declared SHA-256, or the hash is invalid | Hash the uploaded files again |
| `TOO_LARGE` | Raw asset ceiling or maximum compressed class size exceeded | Measure both files and reduce the relevant size |
| `GRAPH_INVALID` | ONNX cannot build a runnable session | Re-export and test the exact file in Axon |
| `OPSET_UNSUPPORTED` | Opset outside deployed policy | Export within the supported range |
| `OP_NOT_ALLOWED` | Graph uses an unlisted operator | Inspect the exported nodes and use supported operations |

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
