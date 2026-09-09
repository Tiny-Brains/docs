# Matches

The arena schedules and runs matches automatically for active versions. You do
not submit moves over HTTP or keep a model server running: the platform runs
your admitted model and adapter itself.

## Who decides that you play

The matchmaker prioritizes versions whose ratings need more evidence, distributes
play across presets, and chooses useful opponents. It generally seeks comparable
ratings, with some cross-class play to connect the Open ladder. A settled version
can still be selected as another version's opponent.

Current policy allows a placement burst of up to eight requested in-flight matches
for a new version and two in steady state. These are scheduling controls, not a
guaranteed number of matches in an hour. Opponent selection can also involve a
version already serving other matches. Trials have one live match at a time.

Baselines are platform-provided model entries used as opponents and rating
reference points. They run through the same model and game interfaces; there is
no special “beat the baseline” admission requirement.

## Match states

| Status | Meaning |
|---|---|
| `pending` | Queued, not yet owned by a worker |
| `claimed` | Assigned while models and execution are prepared |
| `running` | Playing turns |
| `finished` | Result recorded, awaiting counting or trial verdict |
| `rated` | Counting is complete; a trial still changes no ratings |
| `cancelled` | Queue promise withdrawn before play |
| `failed` | Execution could not complete |

A finished match can appear before its rating change. Refresh its detail later
rather than assuming the result was ignored.

## What a match record shows

`GET /v1/matches/{id}` includes game, season, seed, preset, status, reason, turn
count, timing, and the engine/evaluator identities. Each player has a seat,
model ID, owner, version, rank, score, strikes, and per-ladder rating changes when
available. `is_trial` tells you whether the result is an unrated trial.

`GET /v1/matches?model={model_id}` lists finished and rated history only. It is
not a complete queue or failure monitor. Read the version's latest `trial` for
trial progress; an owner-scoped listing of all other match states is not yet
implemented.

## Cancelled and failed matches

Cancellation means the queued pairing was no longer eligible, such as when a
version was superseded, the engine changed, or the season closed. It is not a
played loss and does not change ratings. Detail can include `withdrawn_reason`
and `successor_id`.

Failure means execution could not finish. Detail can include `fault_reason` and
`fault_seat`, distinguishing a particular model from a broader platform problem.
Workers can recover lost claims and retry within bounds; a terminal failure is
not converted into an invented game score. Failed and cancelled matches may have
no replay.

## Reading your results

Compare the preset, opponent, score, rank, and strikes before judging a model
change. A high score paired with a last-place rank can indicate a forfeit rather
than a scoring error. A draw can be an ordinary hill-score tie. Inspect
[replays](replays.md) to explain the decisions behind these outcomes.


<div class="tb-replay" data-src="tutorials/real-match.json" data-turn="161"></div>

<p class="tb-replay-caption">A finished match, at its last turn: the end reason and each seat's score are the same values the match row carries.</p>

<!-- replay-visualiser: match-result-inspection — filled.
Asset: tutorials/real-match.json, turn 161. Regenerate with tutorials/build.sh.
The prose above the slot stands alone: a page whose viewer fails to load still teaches the rule.
-->
