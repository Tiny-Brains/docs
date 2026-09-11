# Submitting a version

A submission identifies a public GitHub release containing your model and adapter,
and says which of your [models](models.md) it is a version of. The API records a
new version; [admission](admission.md) and an unrated [trial](trial.md) decide
whether it becomes that model's active version.

Create the model first. A submission never creates one: a repository with no model
behind it is refused `unknown_model` rather than adopted, because a typo in a
repository path would otherwise start a second lineage with its own version
numbers and its own rating.

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
do not update an admitted version. Publish a new tag for a new attempt: one model
cannot enter the same tag twice in one season, even if the earlier version was
rejected. The next season is a fresh start, and the same tag may be entered again
there.

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
    model: 'your-handle/your-repository',
    release_tag: 'v1',
    weights_hash: 'sha256:<64 hexadecimal digits>',
    adapter_hash: 'sha256:<64 hexadecimal digits>'
  })
});
const result = await response.json();
if (!response.ok) throw new Error(JSON.stringify(result));
console.log(result);
```

`model` names the model this release belongs to, either as its repository path or
as the `model_id` the create call returned.

The hashes must be actual 64-digit values; the placeholders intentionally are
not valid. A successful response has status `201` and fields `version_id`,
`model_id`, `model`, `repo`, `version`, `status`, `season`, `weights_hash`, and
`adapter_hash`. Store the version ID to follow this exact version.

**Version numbers restart per model.** Your second model's first release is v1,
not v4 — a lineage whose history began at 4 because you had an earlier model would
be a number the Version screen could not explain.

## Season and candidate restrictions

The API chooses the game's open season. You cannot use this endpoint to target a
closed or future season. What else a season restricts is the season's own to
declare — see [Seasons](seasons.md) for the whole list — and every restriction is
reported before the request as well as after it, in the same words.

**One `testing` or `verified` version per model may exist at a time.** That rule
is per model, so a competitor with three models may have three versions in
admission at once; a season may additionally cap how many of yours may be in
flight together. A model's currently active version does not prevent a
replacement submission to it.

## What happens next

Read `GET /v1/versions/{version_id}`. Initially status is `testing`, with phase
`queued` or `verifying`. A successful admission changes it to `verified` and
`awaiting_trial`; successful trial completion promotes it to `active`.

A request error is different from a later rejection. Missing hashes return `400`;
season or duplicate/candidate conflicts return `409`; an invalid session returns
`401`. Fix the request before retrying. If the request succeeded but a later check
fails, read `reject_reason` and the [rejection reference](../reference/rejection-reasons.md).
Do not repeatedly submit just because verification is asynchronous.
