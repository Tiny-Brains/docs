# Limits and budgets

These values describe the checked-in Ants registration and deployment configuration
as of **8 September 2026**. A deployed competition's announced rules take precedence
when its configuration differs. Byte units are binary: 1 KiB = 1,024 bytes and
1 MiB = 1,048,576 bytes.

## Model and adapter

| Limit | Current value | Applies to |
|---|---:|---|
| Raw ONNX asset | 96 MiB | Loader fetch/load ceiling |
| Raw adapter asset | 4 MiB | Loader ceiling |
| Maximum compressed size metric | 64 MiB | Largest eligible class |
| ONNX opset range | 13–19 inclusive | Admission policy |
| Adapter dialect | 1 | `adapter.json` |
| Adapter expression depth | 64 | Evaluator nesting |
| Adapter operations | 1,000,000 per direction | Each `in` and each `out` call |
| Adapter boundary dtypes | int8, uint8, int16, int32, float32 | Tensors passed through the adapter |

The compressed metric includes initializer data and exact adapter bytes. Raw file
limits are separate backstops. The [class table](../models/weight-classes.md)
contains all five size boundaries and per-class FLOP caps; the
[format page](../models/format.md) lists configured ONNX operators.

## Ants matches

| Setting | Current value |
|---|---:|
| Players in each registered preset | 2 |
| Maximum turns | 1,000 |
| Turn deadline, including both adapter directions and inference | 1,000 ms |
| View radius squared | 77 |
| Attack radius squared | 5 |
| Gathering radius squared | 1 |
| Strikes before forfeit | 5 cumulative per match |
| Stalemate duration | 150 consecutive qualifying turns |
| Domination threshold | At least 85% of living ants |

The [map table](../games/ants/maps.md) gives dimensions and generation inputs.
Strikes are platform accounting; ordinary illegal movement into water simply
stays in place under the game rules.

## Admission and submissions

| Setting | Current value |
|---|---:|
| In-flight candidate slots | 1 per owner and game, covering testing and verified |
| Duplicate release | Disallowed per owner/game/season/repository/tag |
| Admission polling interval | 20 seconds |
| Admission batch | Up to 4 candidates per run |
| Verification claim timeout | 180 seconds |
| Admission attempts | At most 3 before timeout rejection |
| Validation deadline per reference observation | 5,000 ms |
| Trial repair limit | 3 trial rows |
| Submission endpoint rate | 1 request/second, burst 5, per authenticated principal |

A rate limit does not override the one-candidate or duplicate-release rules. The
admission timeout is not a guarantee of total turnaround time, and its validation
deadline is longer than the actual turn deadline.

## Ratings and scheduling

| Setting | Current value |
|---|---:|
| Initial rating mean | 25 |
| Initial uncertainty | 8.333333333333334 |
| Displayed rating | `mu − 3 × sigma` |
| Provisional uncertainty threshold | Greater than 3 |
| Placement target / initial request cap | 8 |
| Steady-state request cap | 2 |
| Successor uncertainty multiplier | 2, capped at initial uncertainty |
| Requested cross-class fraction | 0.20, with pool-dependent fallback |

These are policy settings, not per-competitor match-rate guarantees. Read
[Ranking](../competing/ranking.md) before interpreting an idle or provisional entry.

## Where values come from

Ants' `cartridge.json` declares presets, turn limits, adapter budget, and FLOP caps.
The engine source implements geometry and game-ending rules. Jodi's admission
judging fixes size boundaries, while the DevOps Orion templates configure opsets,
trials, ratings, and scheduling. Axon's configuration sets raw asset ceilings.
The [repositories page](../platform/repositories.md) identifies each owner.
