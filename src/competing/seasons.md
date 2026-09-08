# Seasons

A season is a competition window for one game, created by an administrator.
Each submitted version belongs to one season and plays only within that field.
There can be at most one live season for a game at a time.

## The submission window

Read `GET /v1/games/ants/seasons` for season numbers, state, submission opening
and closing times, engine identity, and rules. The list is newest first.

| State | Submissions | Competition |
|---|---|---|
| `scheduled` | Not yet accepted | Awaiting the opening time |
| `open` | Accepted subject to rules | Versions may enter and play |
| `settling` | Closed to new submissions | Existing work and matches continue |
| `closed` | Not accepted | Historical standings retained |

The opening time is inclusive; the closing time is exclusive. Submit before the
closing timestamp. A submission received in time may still be undergoing
admission or a trial when the window ends; the settling period permits that work
to complete unless the season is administratively closed.

## Rules that can affect entry

A season can restrict entry to a participant list. It can also require unique
weights, preventing a different owner from entering an already-recorded weight
hash. That uniqueness rule can apply across the game or only within the season;
rejected entries do not count, and reusing your own weights is permitted by this
rule. The separate duplicate-release constraint still applies within a season.

Check the returned `rules` rather than assuming every season is open to every
account. Request refusals identify `season_not_open`, `not_a_participant`, or
`weights_already_entered` as appropriate.

## How a season closes

After the submission window, automatic closure waits until candidates have been
decided, outstanding games and counting work are complete, and active competitor
ratings satisfy the settling policy on reachable ladders. The submission deadline
therefore does not prescribe a fixed final-match timestamp.

An administrator can also request closure. The current closure clock marks the
season closed, rejects waiting candidates with `SEASON_CLOSED`, and cancels queued
matches. Already claimed or running matches can still finish and count into that
season, so standings can receive those last updates after an administrative close.
That rejection is an administrative result, not a claim that the model failed its
requirements.

## What carries over

Competitor versions do not automatically roll into the next season. Enter again
when its window opens; the same release may be submitted in a later season.
Promotion and predecessor rating inheritance are confined to one season.
The platform can carry baseline opponents into a new season with new rating
seeds; this does not enroll competitor accounts automatically.

## Historical standings

Closed-season standings are retained. Read a specific season with
`GET /v1/games/ants/leaderboard?season=N&ladder=open`, or choose a size-class
ladder. Match and version records also identify their season, making it possible
to keep results from separate fields distinct in your training notes.
