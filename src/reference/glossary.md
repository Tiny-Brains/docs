# Glossary

| Term | Meaning |
|---|---|
| Action | The JSON answer for one seat's turn; in Ants, an ordered array of direction strings |
| Active | A version eligible to be scheduled within its season |
| Adapter | Submitted declarative programs mapping observation JSON to tensors and outputs to actions |
| Admission | Static and reference-case checks before a candidate is verified |
| Axon | Service that loads ONNX models and evaluates adapters |
| Baseline | Platform-provided model opponent used to populate and anchor the field |
| Candidate | A submitted version still testing or awaiting its trial verdict |
| Cartridge | A game's rules, observations, scoring, generation, and replay reconstruction in a WebAssembly component |
| Class | A model's assigned compressed-size category: Nano, Micro, Mini, Small, or Large |
| Conservative rating | Displayed strength estimate, `mu − 3 × sigma` |
| Dialect | The versioned expression language accepted in an adapter |
| Engine digest | Identity of the game component bytes used for a match |
| Evaluator digest | Identity of the adapter evaluator's semantics |
| Focus | An Ants unit's count of enemies in attack range, used to resolve combat |
| Forfeit | Platform-imposed last-place treatment after too many failed turn answers |
| Hill | A colony's spawn location and the objective that determines Ants score |
| Hive | A colony's stored food, available for spawning on free hills |
| Initializer | Stored tensor data in the ONNX graph; its compressed bytes contribute to class size |
| Jodi | Package responsible for admission, matchmaking, counting, promotion, and withdrawal |
| Kalam | Package that claims and executes matches and records replays |
| Ladder | A ranking with its own rating estimates: a size class or Open |
| Match | One game among specified model versions, recorded from queueing through its outcome |
| Model ID | UUID identifying one submitted version |
| Observation | The information a game gives one seat to choose its next action |
| Open | The ladder where models of different sizes compete |
| Placement | Early scheduling intended to gather enough evidence about a new version |
| Preset | A named map-generation configuration, including dimensions and seat count |
| Provisional | A rating whose uncertainty exceeds the configured threshold |
| Raze | Permanently destroy an enemy hill by surviving on it through combat |
| Replay | Recorded initialization metadata and actions used to reconstruct a match |
| RLE | Run-length encoding; Ants water uses alternating value/count pairs |
| Season | A game-specific competition with a submission window and retained standings |
| Seat | A player's position in one match; separate from account and model identity |
| Seed | Deterministic initialization input; meaningful with the matching game engine and preset |
| Settled | Sufficiently established under rating and placement policy to need fewer scheduled matches |
| Soma | Public API and owner of the platform database schema |
| Strike | One failed turn answer counted toward a match forfeit |
| Superseded | A version replaced by a successful candidate in the same season |
| Trial | An unrated match checking whether a verified candidate can play |
| Verified | Admission passed, but trial promotion has not yet occurred |
| Version | One submission of model and adapter assets belonging to an owner, game, and season |
| Wave | A group of matches advanced turn by turn by one worker |
| Weight hash | SHA-256 of the exact ONNX asset, separate from its compressed size metric |
| Withdrawal | Cancellation of a queued match that is no longer eligible to play |

For the entry sequence, return to the [quickstart](../quickstart.md). For an
exact number or error, use [limits](limits.md) or [rejection reasons](rejection-reasons.md).
