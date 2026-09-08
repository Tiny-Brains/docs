# Admission

Admission checks whether the released model and adapter can be used by the arena.
It starts after a submission creates a `testing` version. It does not assess
whether your strategy is strong enough to win.

## What is checked

The platform processes these stages in order:

1. Resolve release metadata and construct the canonical asset URLs.
2. Download the model and adapter, verify both declared SHA-256 hashes, and load
   the pair. The admission loader mirrors verified bytes into the model store.
3. Inspect compressed size, parameter count, opset, and graph operators.
4. Assign a size class and apply the configured opset and operator policy.
5. Run the adapter and graph on reference observations under the operation budget.
6. Check estimated FLOPs at the actual input shapes against the assigned class cap.
7. Record either `verified` or `rejected`, releasing the loader's temporary hold.

The adapter must produce named tensors acceptable to the graph, and output
adaptation must yield JSON. This does not replace your own Ants action-length and
direction checks: the loader does not understand the game's complete semantics.

## Watching progress

`GET /v1/models/{id}` returns `phase` and, during testing, `admit_attempt`.
`queued` means verification has not started; `verifying` means it has been claimed.
The current admission clock runs every 20 seconds and processes a bounded batch.
Download, compression, queueing, and retries affect elapsed time; there is no
fixed promise that a submission finishes in one clock period.

The current verification claim allows 180 seconds per attempt, with at most
three attempts before `TIMED_OUT`. These are deployment values, not the match's
turn deadline. Reference inference currently uses a 5,000 ms validation deadline,
while actual Ants turns allow 1,000 ms.

## Verified

`verified` means the checks passed and the version is awaiting its trial. It is
not yet eligible for regular rated matches. The version response carries the
latest `trial` when one has been queued, including its match ID, status, preset,
queue time, and waiting seconds while pending.

There is no automatic “too long awaiting trial” expiry. If it stays verified,
inspect trial state rather than treating it as another admission attempt.

## Rejected

A model fault, such as a hash mismatch, unsupported operator, incompatible shape,
or over-budget adapter, produces a rejection reason. Correct the files, validate
locally, and create a new release tag. See [rejection reasons](../reference/rejection-reasons.md).

A rejection does not replace your previous active version. Keep using that
version's matches to evaluate your next change while fixing the candidate.

## When the platform cannot complete the check

A temporary download, storage, capacity, or loader failure is retried while the
version remains `testing`. It should not be interpreted as proof that your model
is malformed. Repeated inability to finish can eventually produce `TIMED_OUT`.
Report a model ID and the observed phase/reason when asking the operator to
investigate; do not change working weights merely to work around an unavailable
service.
