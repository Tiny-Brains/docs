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
```

There is no test suite and no linter. `book/` is build output and gitignored; **everything under
`src/tutorials/` and `src/viz/` is build output that is committed.**

`tutorials/build.sh` needs `tinybrains` on PATH (`cargo install --path ../devops/cli`) and a built
viewer at `../ants/viz/dist` (`ants/viz/build.sh`); `ANTS_DIR` overrides the location.

## How a page shows a rule

The rules chapters do not draw diagrams of rules — they play them. A lesson is a real match through
the real cartridge, so the page cannot be wrong about the rule in a way the engine is not:

```
tutorials/boards/*.txt  --make-map.py-->  boards/*.json  ─┐
tutorials/<lesson>.json (seat scripts, vars) ─────────────┴-- tinybrains --> replays/*.json
                                                                                  │  cp
../ants/viz/dist ──────────────────── cp ──────────────> src/viz/ <── digest check ┴─> src/tutorials/
```

- Half a board is drawn (`.` land, `#` water, `H` hill, `*` food); `make-map.py` translates it into
  the symmetric whole, because the cartridge refuses a board that is not closed under its orbit.
- Seats are **scripted**, not modelled — a scripted seat never reaches the loader, so a lesson needs
  no ONNX, no model store and no inference, and still goes through the engine's `step`.
- `tutorials/replays/real-match.json` is **captured from a running stack, not generated**;
  `build.sh` copies it and never rebuilds it.
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
  templates, Axon's config). Verify against the current producer before changing a number here, and
  never invent a match result or a replay identity to fill an example.
- Relative links only, and `src/SUMMARY.md` must stay aligned with the files on disk — `mdbook
  build` fails otherwise.
- Label planned tooling as planned; do not describe a proposal as a working endpoint.
