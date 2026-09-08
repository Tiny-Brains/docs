# Submitting a version

A submission identifies a public GitHub release containing your model and adapter.
The API records a new version; [admission](admission.md) and an unrated
[trial](trial.md) decide whether it becomes active.

## Prepare the release

Attach these exact asset names to a release in a public repository:

| Asset | Content |
|---|---|
| `model.onnx` | Self-contained ONNX model |
| `adapter.json` | Adapter dialect declaration and both programs |

The platform constructs their download URLs from your repository and release tag.
Do not supply a branch name, source archive, or arbitrary download URL instead.
Ensure the assets are publicly downloadable without your GitHub session.

Compute SHA-256 over each final file using `sha256sum model.onnx adapter.json`
on Linux or `shasum -a 256 model.onnx adapter.json` on macOS. Prefix each digest
with `sha256:` in the request. Whitespace changes in JSON change the hash too.

The platform verifies and mirrors the admitted bytes. Later edits to a release
do not update an admitted version. Publish a new tag for a new attempt: the same
owner, game, repository, and tag cannot be entered twice in one season, even if
the earlier version was rejected.

## Make the call

Sign in with GitHub through the competition site. The current API authenticates
with the HttpOnly `soma_session` browser cookie; standalone API tokens are not
implemented. The browser shell currently supplies sign-in and API probes, rather
than a complete submission form.

A same-origin browser client can make this request after sign-in. Replace the
repository, tag, and both illustrative hashes:

```javascript
const response = await fetch('/v1/submissions', {
  method: 'POST',
  credentials: 'same-origin',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    game: 'ants',
    repo: 'your-handle/your-repository',
    release_tag: 'v1',
    weights_hash: 'sha256:<64 hexadecimal digits>',
    adapter_hash: 'sha256:<64 hexadecimal digits>'
  })
});
const result = await response.json();
if (!response.ok) throw new Error(JSON.stringify(result));
console.log(result);
```

The hashes must be actual 64-digit values; the placeholders intentionally are
not valid. A successful response has status `201` and fields `model_id`,
`version`, `status`, `season`, `weights_hash`, and `adapter_hash`. Store the model
ID to follow this exact version. Version numbers increase per owner and game.

## Season and candidate restrictions

The API chooses the game's open season. You cannot use this endpoint to target a
closed or future season. The season may restrict participant accounts or require
weights not already entered by a different owner, either within the season or
across the game.

Only one `testing` or `verified` candidate per owner and game may exist at a time.
A currently active version does not prevent a replacement submission. Wait for
the candidate to become active or rejected before submitting another.

## What happens next

Read `GET /v1/models/{model_id}`. Initially status is `testing`, with phase
`queued` or `verifying`. A successful admission changes it to `verified` and
`awaiting_trial`; successful trial completion promotes it to `active`.

A request error is different from a later rejection. Missing hashes return `400`;
season or duplicate/candidate conflicts return `409`; an invalid session returns
`401`. Fix the request before retrying. If the request succeeded but a later check
fails, read `reject_reason` and the [rejection reference](../reference/rejection-reasons.md).
Do not repeatedly submit just because verification is asynchronous.
