# TinyBrains documentation structure

The mdBook is a competitor guide: understand the game, build a valid entry, submit
it, and interpret results. Platform chapters serve contributors and local operators.
The published chapter order is maintained in `src/SUMMARY.md`.

## Page inventory

### [Introduction](src/introduction.md)

The first game: Ants · What you build · How to participate · How competition works · Start here

### [Quickstart](src/quickstart.md)

What you need · 1. Train something small · 2. Write the adapter · 3. Publish a GitHub release · 4. Submit it · 5. Watch the trial · Where to go next

### [Ants](src/games/ants.md)

The idea · What you command · What you can see · How a match ends · The three maps · Where the rules are exact

### [The world](src/games/ants/world.md)

The grid, and why it wraps · Terrain and water · Hills · Food · Vision and fog · Symmetry and presets

### [A turn](src/games/ants/turn.md)

The six steps, in order · Moving and collisions · Combat · Razing a hill · Food and new ants · Sending nothing

### [Ending and scoring](src/games/ants/scoring.md)

How score is computed · How a match ends · Ranks and ties · Strikes and forfeits

### [The maps](src/games/ants/maps.md)

Standard · Maze · Cell · Symmetric starts, varied matches

### [What your model sees](src/models/observation.md)

Fields · Known water · What is hidden · A worked example

### [What your model answers](src/models/actions.md)

One order per ant · Illegal and missing orders · The turn clock · A move is an intention

### [Model format](src/models/format.md)

ONNX compatibility · Inputs and outputs · How size is measured · What is inspected

### [Weight classes](src/models/weight-classes.md)

The five classes · How your class is decided · The Open ladder · Choosing what to enter

### [Adapters](src/models/adapters.md)

The two directions · A minimal adapter, end to end · Where it runs and what it may do

### [The dialect](src/models/adapters/dialect.md)

Expressions and objects · Core operators · Variables and scope · Tensor values · Equality and empty values · Versions

### [Operators](src/models/adapters/operators.md)

Building tensors · Reshaping and combining · Converting and deriving · Reading tensors and values · Costs at a glance

### [The budget](src/models/adapters/budget.md)

What counts as an operation · What over budget means · Measuring before you submit · Spending less

### [Testing before you submit](src/models/testing.md)

Reference observations · Validate with Axon · Check the actions too · Playing a match locally · Before publishing

### [Submitting a version](src/competing/submitting.md)

Prepare the release · Make the call · Season and candidate restrictions · What happens next

### [Admission](src/competing/admission.md)

What is checked · Watching progress · Verified · Rejected · When the platform cannot complete the check

### [The trial](src/competing/trial.md)

Who you play · Why losing is fine · When a trial fails · How long you wait

### [The life of a version](src/competing/version-life.md)

The five states · Promotion · What the new version inherits · What happens to old matches · Withdrawal and rejection

### [Matches](src/competing/matches.md)

Who decides that you play · Match states · What a match record shows · Cancelled and failed matches · Reading your results

### [Replays](src/competing/replays.md)

Getting a replay · What is stored · Watching a replay: current tooling · Using replay examples in this book · Improving from a replay

### [Ranking](src/competing/ranking.md)

Reading a rating · Your ladders · Why a result arrives before its rating change · Provisional and settled · Ratings after a new version · Seasons and comparisons

### [Seasons](src/competing/seasons.md)

The submission window · Rules that can affect entry · How a season closes · What carries over · Historical standings

### [Rejection reasons](src/reference/rejection-reasons.md)

Request refusals · Release assets and graph · Adapter and interface · Trials and administrative outcomes · Platform-side retries

### [Limits and budgets](src/reference/limits.md)

Model and adapter · Ants matches · Admission and submissions · Ratings and scheduling · Where values come from

### [HTTP API](src/reference/api.md)

Signing in · Games, seasons, and ladders · Versions and matches · Submitting · Errors and rate limits · Administrative routes

### [Glossary](src/reference/glossary.md)



### [How TinyBrains is built](src/platform/architecture.md)

The parts · One match table between scheduling and execution · What one entry touches · Deployment and scaling · Boundaries to preserve

### [The repositories](src/platform/repositories.md)

The seven application repositories · Which repository owns a change? · Generated and vendored files · What is not supplied yet

### [Running the platform locally](src/platform/running-locally.md)

What you need · Configure the stack · Bring it up · Sign in and make a match happen · Reloading and stopping · When nothing plays

### [Adding a game](src/platform/adding-a-game.md)

The five functions · State and determinism · The two manifests · Registering and integrating · Documentation competitors need

### [Contributing](src/platform/contributing.md)

Choosing work · Source conventions · Checks that matter · Writing documentation · Opening a change

## Replay visualiser placeholders

Use a visible “Replay visualiser — planned” caption beside the explanation, followed
by an HTML comment starting `replay-visualiser: <unique-id>`. The caption states what
the eventual recorded game should illustrate. The comment reserves implementation
metadata without inventing an asset or match result.

Before enabling an example, supply the actual replay asset, matching engine digest,
turn range, player perspective, and accessible text caption. Resolve the stored
envelope/decoder initialization contract documented in [Replays](src/competing/replays.md).
Keep explanatory prose usable without playback. Do not add placeholders to pages
where a game animation contributes no useful explanation.

### Reserved examples

| Placeholder ID | Chapter |
|---|---|
| `match-result-inspection` | [matches](src/competing/matches.md) |
| `replay-viewer` | [replays](src/competing/replays.md) |
| `trial-playability` | [trial](src/competing/trial.md) |
| `maps-standard` | [maps](src/games/ants/maps.md) |
| `maps-maze` | [maps](src/games/ants/maps.md) |
| `maps-cell` | [maps](src/games/ants/maps.md) |
| `scoring-hill-result` | [scoring](src/games/ants/scoring.md) |
| `turn-collision` | [turn](src/games/ants/turn.md) |
| `turn-focus-combat` | [turn](src/games/ants/turn.md) |
| `turn-spawn-delay` | [turn](src/games/ants/turn.md) |
| `world-wrapping` | [world](src/games/ants/world.md) |
| `world-fog` | [world](src/games/ants/world.md) |
| `ants-overview` | [ants](src/games/ants.md) |
| `introduction-match` | [introduction](src/introduction.md) |
| `actions-to-outcomes` | [actions](src/models/actions.md) |
| `observation-payload` | [observation](src/models/observation.md) |
| `testing-behaviour` | [testing](src/models/testing.md) |
| `quickstart-first-trial` | [quickstart](src/quickstart.md) |
