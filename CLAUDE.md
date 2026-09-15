# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

`docs/` is the TinyBrains competitor guide: an mdBook served on its own host,
`docs.tinybrains.dev`. It is one of the nine repos assembled under `tinybrains/` (see that
directory's `CLAUDE.md` for the platform as a whole); nothing here runs in the platform, but the
book *restates* numbers and behaviour those repos own, and it *embeds real engine output*.

`README.md` is this repo's map, in the same shape as every sibling repo's (Scope / Where it sits /
Interface / Run it, test it / What a deployment owes it / Layout / What must stay true / Status).
Read its **What must stay true** before touching `theme/` or a replay, and update its **Status**
when work lands. The page inventory lives in `src/SUMMARY.md` and nowhere else; the replay-slot
inventory is `grep -rn 'replay-visualiser:' src`.

## Commands

```sh
mdbook build                  # the whole check: create-missing = false, so a SUMMARY entry
                              # without a file is an error, not a new stub
mdbook serve                  # preview; it overrides site-url with "/", so finish with `mdbook build`
tutorials/build.sh            # regenerate the teaching replays and re-vendor the viewer
python3 studio/studio.py link src/models/adapters/studio/<name>.json   # one example's Studio URL
```

There is no test suite and no linter. **Nothing generated is committed**: `book/`, `src/viz/`,
`src/tutorials/`, `tutorials/boards/*.json` and the scenario replays under `tutorials/replays/` are
all gitignored. `Dockerfile` rebuilds them, taking the viewer from the cartridge's artifact image
and the `tinybrains` binary from devops', so building the book needs neither a sibling checkout nor
a Rust toolchain.

The one exception is `tutorials/replays/real-match.json`, which is **source**: a real match captured
from a running stack, which nothing here can reproduce.

`tutorials/build.sh` still runs by hand — it needs `tinybrains` on PATH and a viewer at
`$ANTS_DIR/viz/dist`; both can come out of the images with `docker cp`.

> **The image build is currently RED, on purpose.** `real-match.json` was captured on engine
> `d41f863f…` and the cartridge now ships `0807b641…`, so the digest check refuses it. That check is
> the whole guarantee — see below — and the fix is a re-captured match, not a looser check.

## How a page shows a rule

The rules chapters do not draw diagrams of rules — they play them. A lesson is a real match through
the real cartridge, so the page cannot be wrong about the rule in a way the engine is not:

```
tutorials/boards/*.txt  --make-map.py-->  boards/*.json  ─┐
tutorials/<lesson>.json (seat scripts, vars) ─────────────┴-- tinybrains --> replays/*.json
                                                                                  │  cp
ants artifact image ─────────────── COPY ──────────────> src/viz/ <── digest check ┴─> src/tutorials/
```

- Half a board is drawn (`.` land, `#` water, `H` hill, `*` food); `make-map.py` translates it into
  the symmetric whole, because the cartridge refuses a board that is not closed under its orbit.
- Seats are **scripted**, not modelled — a scripted seat never reaches the loader, so a lesson needs
  no ONNX, no model store and no inference, and still goes through the engine's `step`.
- `tutorials/replays/real-match.json` is **captured from a running stack, not generated**;
  `build.sh` copies it and never rebuilds it. It is the one file under `tutorials/replays/` that is
  committed, because it is the only one that is an input rather than an output — and it is exactly
  the file that goes stale without anyone noticing, which is what the check below is for.
- `build.sh` fails if any replay's `engine_digest` differs from `src/viz/engine.json`. That check is
  load-bearing: a viewer re-simulating with the wrong engine does not error, it draws a plausible
  match that never happened.

A page embeds one with a slot, a caption, and a marker comment:

```html
<div class="tb-replay" data-src="tutorials/2-fight.json" data-turn="3" data-zoom="6"></div>
<p class="tb-replay-caption">…what this replay shows…</p>
<!-- replay-visualiser: turn-focus-combat — filled. -->
```

`theme/tb-replay.js` imports the viewer module only on pages that have a slot (the cartridge is a
quarter of a megabyte), resolving `path_to_root` against `document.baseURI`. Keep the prose above
the slot self-sufficient: the fallback for a viewer that fails to load is a sentence, and a page
must still teach its rule without playback.

`world-fog` and `observation-payload` are **deliberately empty**, and their comments say why: a
replay frame is the referee's view, so ground truth in either slot would teach the reader the
opposite of the point. Filling them needs a seat view from `replay-decode` — an ABI change in Ants,
i.e. a decision, not a task.

## How a page shows an adapter

The adapter chapter shows programs, and every example opens in DataLogic Studio — datalogic-rs's
playground, `goplasmatic.github.io/datalogic-rs/playground/`. **A page never holds a Studio link.**
It holds `{{#studio studio/<name>.json}}` (flags: `nocode`, `embed`), and `studio/studio.py`, an
mdBook preprocessor, writes the example's code and a link whose URL encodes that same file on every
build. A pasted link is a second copy of the example, and drifts.

- An example is `{about, templating, logic, data}` in `src/models/adapters/studio/`. Keep
  `templating: true`: it is the Studio mode an adapter is read under.
- The link format is the Studio's own `ui/src/utils/url-share.ts` in the datalogic-rs checkout:
  `{l, d, t}` as MessagePack, raw DEFLATE, base64url in `?s=`. If upstream changes it, every link
  in the book opens something else and nothing here notices.
- **The Studio runs datalogic-rs, and so does the arena** — since the 1.8.1 rebuild an adapter is
  evaluated by the same engine, so most of the old differences are gone: `{"==": [0, null]}` is now
  `true` on both sides. What still differs is **objects**: with Templating on the Studio treats a
  multi-key object as a literal, and the arena refuses one — every object is an operation, and an
  unknown key fails at *evaluation*, not at compile. That was measured with `tinybrains adapt`, not
  assumed, and the accumulator examples are arrays because of it. An example must evaluate in the
  Studio to what its page says, and anything a page claims about the arena — a cost, a tensor, a
  trap — must come from `tinybrains adapt` or `tinybrains check`, which link the node's own two
  libraries. `models/adapters/studio.md` is the reader's copy of that list; keep the two in step.
- `theme/tb-studio.js` mounts an `embed` slot with datalogic-rs's mdBook widget, fetched from the
  Studio's site when the slot scrolls into view. It is unpinned; `design/tracker.md` has why.

## The theme

`README.md` §The theme documents each file and what must stay true. The load-bearing parts:

- `theme/index.hbs` is **mdBook 0.5.4's template, vendored**, with every edit marked `TINYBRAINS`.
  book.js reaches for `.menu-title`, `#mdbook-theme-toggle` and `#mdbook-theme-list` by name, and
  the theme names `navy`/`light` are read by book.js and `tb-replay.js`. On an mdBook upgrade,
  re-diff and re-apply the marked blocks — nothing at build time notices a stale template.
- `theme/tokens.css` is a **copy of `web/public/design-system/tokens.css`** keyed to mdBook's theme
  classes. A colour invented here is a colour the site does not have.
- The `additional-css` order in `book.toml` is the mechanism that avoids `!important`; the comments
  there explain it, as does the one on `site-url = "/"` (it is what makes `404.html` find its
  assets, and it is wrong only for a local stack mounting the book under `/docs/`).
- **One `<h1>` per page, and it lives in the bar.** CSS hides `.content main > h1:first-child`, so
  every page in `src/` must open with exactly one `#` heading; a page that opens some other way
  shows its title twice.

## Writing pages

- Competitors first: what to build, what the platform checks, what they can observe, what to do
  next. Architecture belongs in the platform chapters unless it explains a practical limitation.
- **The book duplicates values it does not own.** `src/reference/limits.md` dates its snapshot and
  names the owner of each number (Ants' `cartridge.json`, Jodi's admission judging, the DevOps Orion
  templates, the season's rules in the database). Verify against the current producer before
  changing a number here, and
  never invent a match result or a replay identity to fill an example.
- Relative links only, and `src/SUMMARY.md` must stay aligned with the files on disk — `mdbook
  build` fails otherwise.
- Label planned tooling as planned; do not describe a proposal as a working endpoint.
