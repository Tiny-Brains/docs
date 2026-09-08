# Replays

A replay records what happened in a match so you can investigate a result and
compare model behavior. Look for the first decision that changed the position:
an avoidable collision, blocked spawning, lost vision, or an undefended hill.

## Getting a replay

Read `GET /v1/matches/{id}` and use its `replay_url` when present. The URL is
signed for temporary read access. Fetch a fresh match detail if an old link
expires; keep the match ID as the stable reference, not the signed URL.

A null replay URL can be normal for queued, cancelled, or failed work that never
produced a replay. A successful match's detail also supplies the preset, seed,
engine digest, evaluator digest, and per-seat result.

## What is stored

The current Kalam upload is a JSON envelope containing match and attempt IDs,
seed, preset, engine and evaluator identities, dialect version, engine ranks,
scores, ending reason, turn count, and action deltas. A delta uses `t` for the
turn and `a` for a list of per-seat strings. Each string contains directions in
that seat's ant order, with `-` for holding.

These are actions, not pre-rendered frames. The matching engine reconstructs
positions by replaying the actions deterministically. A model is not run again
to choose new moves during playback.

`engine_ranks` records the game's result before the platform applies forfeit
ranking. Use the match record's player ranks for the official competitive result;
keep the engine ranks when diagnosing game behavior.

## Watching a replay: current tooling

The browser replay viewer is not implemented yet. Ants has a `replay-decode`
export and an engine replay test, but the stored-envelope integration is also
unfinished: the current decoder requires a packed `state0`, while Kalam's upload
contains seed and preset without that field. Feeding a downloaded envelope
straight to that decoder is not yet a complete playback path.

A future viewer needs to resolve the matching engine and bridge initialization
from the recorded envelope, then verify reconstruction against known outcomes.
Until that integration exists, retain the raw JSON and match metadata for
inspection; do not interpret a missing viewer as a missing match result.


> **Replay visualiser — planned:** Embed an actual recorded match with play/pause, turn stepping, speed, score, and full-board/player-view controls. Resolve the envelope initialization and matching-engine contract before enabling playback.

<!-- replay-visualiser: replay-viewer
Use a recorded replay and its matching engine digest; select the relevant turns.
Provide a text caption and retain the explanation above as the accessible fallback.
Replay asset and turn range: to be selected. No synthetic match result is implied.
-->

## Using replay examples in this book

Planned visualisers are marked beside explanations where a real game helps.
Each example should identify its replay asset, engine digest, relevant turns,
player perspective, and explanatory caption. No match IDs or outcomes are
invented for these placeholders.

Full-board playback contains information a competitor could not see during play.
Use a player-view overlay when explaining what a model could reasonably infer.
Retain the accompanying prose so the rule remains understandable without the
viewer or when replay assets are unavailable.

## Improving from a replay

First check strikes and output validity. Then inspect growth, movement collisions,
combat support, scouting, and hill defence. Compare the same behavior across
several seeds and presets; one attractive victory is weak evidence that a model
revision is stronger overall.
