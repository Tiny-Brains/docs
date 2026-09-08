# How TinyBrains is built

The competitor-facing loop is submit, verify, trial, compete, and review. The
platform separates accepting requests, deciding which games to play, executing
games, and running models so each can operate at a suitable scale.

This chapter is for contributors and local operators. You do not need to deploy
these services to enter a hosted competition.

## The parts

| Part | Responsibility |
|---|---|
| Web | Browser sign-in, session display, and current API probes; future competition UI |
| Soma | Public HTTP API, sessions, submissions, seasons, and shared schema |
| Jodi | Four clocks: admit, pair, count, and withdraw |
| Kalam | Claim matches, play turns, record results and replays |
| Ants | Deterministic game cartridge |
| Axon | Adapter evaluation, ONNX inference, admission inspection, and model storage access |
| DevOps | Assemble packages, runtime configuration, stores, and local deployment |

Postgres stores versions, seasons, match rows, seats, and rating events. Object
storage holds model/adapter assets and replay blobs. The
[repository map](repositories.md) identifies the code for each component.

## One match table between scheduling and execution

Jodi inserts a pending match and its seats. Kalam claims that same row, plays it,
and finishes it with results and a replay key. Jodi later counts the finished
result and marks the row rated. The row is both queue item and durable history;
there is no message broker or direct Jodi-to-Kalam dispatch call.

Claims have leases and tokens, so a lost worker can be recovered and a stale
worker cannot finish someone else's attempt. Jodi's writes use run fences and a
roster epoch to prevent stale scheduling or rating work from changing the field.
These mechanisms protect the competitor's history from duplicate or misattributed
results.

## What one entry touches

1. Web or an authenticated client asks Soma to record a GitHub release.
2. Jodi's admission clock asks an admission-mode Axon to fetch, hash, inspect,
   validate, and mirror the two assets.
3. Jodi verifies the candidate and queues its trial.
4. Kalam claims the match and asks its replica Axon to hold the model pairs.
5. Ants produces observations; Axon adapts them, runs the models, and returns
   actions; Ants resolves the next turn. This repeats for live matches in a wave.
6. Kalam uploads the replay and records the result under its claim token.
7. Jodi counts the result or decides the trial. A trial pass promotes the version;
   later ordinary matches update its ratings.
8. Soma exposes version status, match results, standings, and signed replay reads.

The game state is opaque outside the cartridge. The adapter is submitted data
executed inside Axon, not an Orion workflow uploaded by a competitor. Tensors
stay inside Axon; the surrounding match loop carries game JSON.

## Deployment and scaling

The local stack hosts Soma and Jodi together on one Orion instance using shared
Postgres runtime state and Redis. Each Kalam replica has independent Orion state
and its own Axon sidecar. Another Axon runs admission. All loaders share a model
store so admitted bytes are available during play.

Sharing scheduler state coordinates Jodi's clocks across hosts. Separating Kalam
state lets several replicas each run a wave instead of contending for one global
wave lock. Model residency stays near the worker that uses it. The cloud
autoscaler and production rollout pipeline remain future work; Compose is the
implemented deployment path.

## Boundaries to preserve

Only Jodi's counting path writes competitive rating updates. Kalam's database
role is restricted to execution fields. Models and adapters are retrieved by
hash during matches. Queued matches can be withdrawn, but already running matches
stay attributed to the versions originally paired. Replays and match records
retain the engine and evaluator identities needed to investigate outcomes.

When changing any boundary, test its producer and consumer together. A successful
package load or health endpoint does not by itself demonstrate a working admission,
match, or replay loop.
