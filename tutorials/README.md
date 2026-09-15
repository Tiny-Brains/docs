# Teaching replays

The rules pages show the rules *happening*, rather than describing them and hoping. Each lesson is
a real match: a hand-drawn board and a written script, played through the same cartridge the ladder
runs, producing the same replay envelope the platform stores. A diagram of a rule can be wrong
about the rule. This cannot.

```sh
tutorials/build.sh          # boards -> replays -> src/tutorials, and vendors the viewer
```

## Writing a lesson

**Draw half the board.** A board has to be symmetric or the cartridge refuses it, and for two
players the top half is a fundamental domain — every cell in it has exactly one image below.
`make-map.py` translates your drawing, so symmetry is by construction rather than by luck.

```text
boards/fight.txt        . land   # water   H hill   * food
............
.H..........
............
............
```

**Write what each seat does.** A scripted seat's orders are read, not inferred, because "two ants
walk into the same square" has to happen exactly and no model can be relied on to do it. An entry
is one order for every ant (`"E"`) or one per ant in `mine` order (`["E", "W"]`); past the end of
the script a seat holds.

```json
"seats": [
  { "seat": 0, "label": "red",  "script": ["S", "S", "E", "E", "E", "E"] },
  { "seat": 1, "label": "blue", "script": ["N", "N", "W", "W", "W", "W"] }
]
```

A scripted seat never reaches the loader, so a lesson needs no ONNX, no model store and no
inference — and still goes through `step`, which is the whole point.

**Put it in a page.**

```html
<div class="tb-replay" data-src="tutorials/2-fight.json" data-turn="3" data-zoom="6"></div>
```

`data-turn`, `data-from`, `data-to`, `data-zoom`, `data-centre` (`"r,c"`), `data-speed`,
`data-autoplay` and `data-height` all map to the viewer's options. Keep the prose above the slot
explaining what the replay shows: a page whose viewer fails to load is still a page that teaches
the rule, and that is why the fallback is a sentence rather than a broken frame.

## The lessons

| | Shows |
|---|---|
| `1-movement` | Walking, water refusing a move on turns 3 and 4, and the board wrapping from the top edge to the bottom |
| `2-fight` | One against one, equal focus, both die |
| `3-raze` | An ant reaching the enemy hill: +2 to the razer, −1 to the owner, `lone_survivor` |
| `4-growth` | Food gathered on one turn becoming an ant on the next, then two friendly ants walking into one square |
| `preset-*` | One turn on a real catalogue board, so a page can show the terrain a preset is played on |
| `real-match.json` | **Captured, not generated.** A real ladder match, pulled out of the replay bucket of a running stack. `build.sh` does not regenerate it — the digest check is what catches it going stale. See below for how it was taken |

## Re-taking `real-match.json`

It is the one file here that is source rather than output: a match the **ladder** played, which is
what makes it worth showing and also what stops `build.sh` regenerating it. When the engine moves it
has to be re-captured by hand. It should not be a mystery file while it waits, so:

**What is in it now.** A real ladder match on `standard-01`, taken from a local stack's replay
bucket on 15 September 2026 — `micro-bc` against `micro-percell`, both `micro` class, 246 turns,
`rank_stabilized` 3&ndash;0 to `micro-bc`, neither seat struck. Played on engine `185a2845…`.

**How to take another.** Run the stack until it has rated some matches, then read a replay out of
the bucket. `matches.replay_key` says which object belongs to which row:

```sh
# the rated matches and where their replays are
docker exec tinybrains-db-1 psql -U soma -d soma -c \
  "select id, reason, turns, replay_key from matches where status='rated'"

# pull the bucket out; pick a replay whose map_id and turn count suit the four pages below
docker exec tinybrains-minio-1 mc alias set loc http://127.0.0.1:9000 tinybrains tinybrains-dev-secret
docker exec tinybrains-minio-1 mc cp --recursive loc/tinybrains-replays /tmp/rp
docker cp tinybrains-minio-1:/tmp/rp ./capture
```

Copy the chosen file to `tutorials/replays/real-match.json` **verbatim** — the bytes the platform
wrote are the point, so do not reformat it or rename its `match_id`.

**Pick a match that teaches something.** The capture this replaced ran two smoke fixtures that never
moved, to a scoreless `idle_food` draw after 161 turns — a poor thing to open the book with. Prefer
a decisive one, long enough that every `data-turn` below still lands inside it.

**Then check the four pages that embed it.** `src/introduction.md` (turn 1), `src/games/ants.md`
(turn 40), `src/competing/replays.md` (turn 20) and `src/competing/matches.md` (its LAST turn, which
is `turns` itself — the decoder yields frames 0..`turns`). Every `data-turn` must still fall inside
the new match, and the captions on the last two describe *this* match — ants.md names the result and
matches.md says "its last turn" — so both move when the capture does.

## What the viewer cannot show

**Fog.** A replay frame carries the board as the *referee* sees it — every ant, all the water —
because that is what re-simulating an action stream reconstructs. What a seat *knew* at a turn is a
different question and `replay-decode` does not answer it. So `world-fog` and `observation-payload`
are deliberately empty, with a note saying why: a ground-truth replay in either place would teach
the reader the opposite of the point.

Filling them needs a **seat view** — `replay-decode` answering "what did seat N see on turn T",
which is `observe` applied to a re-simulated state. It is cheap (one optional argument, decoded for
the shown turn only) and it is an ABI change, so it is a decision rather than a task.

## What can go stale

A replay is engine output, so it goes stale when the engine changes. `build.sh` refuses when the
vendored viewer and the replays name different engine digests — a viewer re-simulating with the
wrong engine does not fail, it draws a plausible match that never happened, which is the one
failure a teaching page must not have.
