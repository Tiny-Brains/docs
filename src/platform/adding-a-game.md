# Adding a game

A game cartridge defines the world competitors act in: generation, rules,
observations, actions, scoring, and replay reconstruction. The platform runs its
WebAssembly component while Axon runs competitor models. Game code must not
schedule its own matches, fetch models, or write ratings.

Ants is the reference implementation. The interface is designed for additional
games, but the current package and registration scripts still contain Ants-specific
configuration. Adding a game requires checking those integration points; it is
not yet a finished self-service upload flow.

## The five functions

Export these operations in the game's own `tb.<game>` namespace:

| Function suffix | Input and result |
|---|---|
| `worldgen` | Seeds and preset, with configured limits, to initial packed wave state |
| `observe` | Wave state and opaque seat references to per-seat observations |
| `step` | Wave state and actions to updated state, completion flags, and replay deltas |
| `finish` | Wave state to per-match ranks, integer scores, and ending reasons |
| `replay-decode` | Replay payload and target turn to a reconstructed frame |

The export uses a hyphen in `replay-decode`. Declare exact input fields in the
plugin manifest rather than relying on this abbreviated table as an ABI schema.
Ants' `plugin.toml` supplies a complete worked contract.

Operate on a **wave of matches**, including waves where individual matches finish
at different turns. Return no observations for finished matches. Echo opaque seat
references so the caller can associate actions and failures without interpreting
game state. Match results must provide one-based ranks with ties allowed.

## State and determinism

All state must round-trip through the packed wave value; the sandbox does not
retain it between invocations. Keep this encoding opaque to workflows and compact
enough for plugin request/response ceilings at the intended wave size.

Use integer game arithmetic and seeded randomness. The same initial inputs and
action stream must reproduce the same states and result. Do not depend on clocks,
network, filesystem, or ambient randomness.

Tests should cover seed repeatability, state round trips, player symmetry,
observation privacy, action ordering, end conditions, ties, and replay reconstruction.
Cross-host conformance between the platform and a browser is also needed before
claiming portable replay fidelity; that browser conformance run is not yet supplied
by the Ants reference implementation.

## The two manifests

The **plugin manifest** describes the Orion ABI, component path, namespaced
functions, and input fields. Ants authors `plugin.toml` and generates `plugin.json`.
The **cartridge registration manifest** describes game/version/ABI, presets with
seat counts, turn limits, adapter operation budget, and per-class FLOP caps.
Ants generates `cartridge.json` from its preset implementation.

Generate registration facts from the same definitions the engine uses so map
sizes and seat counts do not drift. Ship the component and manifests together.
The intended trust model includes signed components; component signing and trust
enforcement are not yet complete in the current stack.

## Registering and integrating

Load the component on compatible Kalam workers, register its manifest and engine
digest, and supply reference observations for admission. Update scheduling presets,
execution function references, and deployment wiring that currently name Ants.
Align the game's live season identity with the engine that will claim its matches.

Provide reference cases covering the smallest and largest states and meaningful
boundary conditions. Validate a real model/adapter pair against them; an empty
or unrepresentative reference set is not an adequate admission contract.

Replay writing and decoding must agree on initialization, action ordering, turn
numbering, and engine identity. The current Ants/Kalam gap between `state0` and
the stored seed/preset envelope is documented under [Replays](../competing/replays.md);
resolve that seam in a new game rather than reproducing it implicitly.

## Documentation competitors need

Publish a game overview, world description, exact turn order, ending/scoring
rules, presets, observation schema, action schema, and working examples. Explain
what a model cannot see as carefully as what it can see. State limits and invalid
action behavior precisely.

Where a visual explanation helps, reserve a replay visualiser placeholder naming
the concept, required player perspective, and turns to select. Later attach actual
recorded games with matching engine identities and text captions. Competitors
should be able to understand the rule before the viewer is implemented.
