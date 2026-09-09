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

## What can go stale

A replay is engine output, so it goes stale when the engine changes. `build.sh` refuses when the
vendored viewer and the replays name different engine digests — a viewer re-simulating with the
wrong engine does not fail, it draws a plausible match that never happened, which is the one
failure a teaching page must not have.
