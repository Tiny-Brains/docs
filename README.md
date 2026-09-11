# docs

Docs is the TinyBrains competitor guide: an mdBook of thirty-six pages that carries a reader from
the rules of the game to a submitted model and a rating that means something. It is also the only
repository whose pages *play* what they describe — the rules chapters embed real matches, produced
by the same cartridge the ladder runs and replayed by the cartridge's own viewer, and every adapter
example opens in DataLogic Studio, already evaluated.

## The name

**Docs** is the book, and only the book. Each application repository keeps its own design documents
under `docs/`; this repository is the reader-facing half, written for someone who has not seen the
source and is not going to.

## Scope

**It owns**

- The thirty-six pages, their chapter order in `src/SUMMARY.md`, and the words each uses.
- The teaching replays: hand-drawn boards, written seat scripts, and the build that plays them.
- The adapter examples under `src/models/adapters/studio/`, and `studio/studio.py`, which turns each
  into the code a page shows and a DataLogic Studio link that encodes the same file.
- The book's theme — the application's design system restated for the elements mdBook emits.
- The vendored replay viewer under `src/viz/`, and the slot that mounts one in a page.

**It does not**

- Own a single value it documents. Presets and budgets come from [Ants](https://github.com/Tiny-Brains/ants)' `cartridge.json`, size boundaries from [Jodi](https://github.com/Tiny-Brains/jodi)'s admission judging, opsets and scheduling from [DevOps](https://github.com/Tiny-Brains/devops)' Orion templates, asset ceilings from [Axon](https://github.com/Tiny-Brains/axon)'s configuration.
- Draw a replay or know a rule of one; Ants ships the viewer and this repository vendors it.
- Evaluate an adapter. DataLogic Studio runs the JSON half of an example in the reader's browser,
  with datalogic-rs; Axon is the only evaluator whose answer counts, and every cost the book quotes
  comes from it, through `tinybrains check` and `tinybrains adapt`.
- Serve itself; [Web](https://github.com/Tiny-Brains/web)'s nginx mounts the rendered book today, and its own host will serve it.
- Hold the platform's design documents, decision log, or deployment design; those stay in the repository that owns the behaviour.

## Where it sits

```text
[ants: cartridge + viz/dist] --+
                               |  tutorials/build.sh
[tutorials/boards + scripts] --+--> src/tutorials/ + src/viz/ --+
                                                                |  mdbook build
[web: design-system/tokens.css] -- copied --> theme/tokens.css --+--> book/ --> [reader]
```

| Direction | Party | Over | What moves |
|---|---|---|---|
| reads | Ants | its artifact image, `/artifacts/viz` | The viewer bundle, copied into `src/viz/` so the book builds offline |
| calls | DevOps CLI | `tinybrains <spec>`, from its artifact image | Scripted lessons played through the real cartridge into replay envelopes |
| copies | Web | `web/public/design-system/tokens.css` | The palette, to the digit |
| restates | Ants, Jodi, DevOps, Axon | Their configuration | Every number on the limits, weight-class and format pages |
| read by | Web's nginx, or the book's own host | Static HTTP | The rendered `book/` |
| links to, embeds | DataLogic Studio | `goplasmatic.github.io/datalogic-rs/` | Every adapter example as a playground link; the embed bundle `theme/tb-studio.js` mounts in a page |

The [system map](https://github.com/Tiny-Brains/devops#where-it-sits) describes the services the
book documents. Nothing in the platform reads this repository at runtime.

## Interface

There is no API. What this repository publishes is a directory of static files, and what a page
author uses is a slot:

```html
<div class="tb-replay" data-src="tutorials/2-fight.json" data-turn="3" data-zoom="6"></div>
<p class="tb-replay-caption">What this replay shows, in a sentence.</p>
<!-- replay-visualiser: turn-focus-combat — filled. -->
```

| Attribute | Viewer option | Default |
|---|---|---|
| `data-src` | The replay, resolved against the book's root | required |
| `data-turn` | Open on this turn | 0 |
| `data-from`, `data-to` | Limit the scrubber to a range | the whole match |
| `data-zoom` | Cell size in pixels | fits the board |
| `data-centre` | `"row,col"` to centre on | the board's centre |
| `data-speed`, `data-autoplay` | Playback rate, and whether it starts | paused |
| `data-height` | Slot height in pixels | 360 |

`theme/tb-replay.js` imports `src/viz/viz.js` once per page and only when a slot exists — the
component is a quarter of a megabyte and most pages do not want it. The marker comment reserves the
example's identity: `grep -rn 'replay-visualiser:' src` is the inventory, and each says `filled`,
names what a planned recording must show, or says `BLOCKED` and why.

The adapter chapter has a second slot, and a page author never writes its markup: a directive names
an example file, relative to the page, and `studio/studio.py` expands it on every build.

```text
{{#studio studio/foe-positions.json}}          the example's logic as a JSON block, then its link
{{#studio studio/flat-index.json nocode}}      the link alone, when the prose already shows the code
{{#studio studio/baseline-in.json embed}}      the code, the Studio itself in the page, then the link
```

An example is `{"about", "templating", "logic", "data"}`. `about` becomes the link's caption, and
`templating` stays `true` for an adapter: it is the Studio mode that follows the dialect's object
rule and shows a `tb.*` call with its arguments evaluated instead of refusing it. The link is the
Studio's own share format — `{l, d, t}` as MessagePack, raw DEFLATE, base64url in `?s=` — so it
opens that exact example. `theme/tb-studio.js` mounts an `embed` slot with datalogic-rs's own
mdBook widget, fetched from the Studio's site once the slot scrolls into view; without it the slot
takes no space and the code and the link are the whole example.

`src/SUMMARY.md` is the published chapter order and the page list. `create-missing = false`, so an
entry without a file is a build error rather than a new stub.

## Run it, test it

All commands run from this repository's root.

- **mdBook 0.5.4.** `theme/index.hbs` is that version's template, vendored; another version's
  `book.js` may look for elements it does not find.
- Python 3, for `studio/studio.py` — an mdBook preprocessor, so every `mdbook build` runs it — and
  for `tutorials/make-map.py` and the build's digest check.
- The `tinybrains` CLI and a viewer at `$ANTS_DIR/viz/dist`, to regenerate the lessons. `Dockerfile`
  takes both from artifact images and needs neither on the host; by hand, `docker cp` them out of
  `tinybrains/cli:dev` and `tinybrains/ants:dev`, or use a built checkout of each.

```sh
mdbook build                # the whole check: no test suite, no linter
mdbook serve                # preview at http://localhost:3000
tutorials/build.sh          # boards -> replays -> src/tutorials, and re-vendor the viewer
python3 studio/studio.py link src/models/adapters/studio/flat-index.json   # one example's link
```

`mdbook build` fails on a `SUMMARY.md` entry with no file behind it, and on a `{{#studio}}`
directive whose example is missing, is not JSON, or lacks `logic` or `data`; those are the only
automated checks this repository has. Relative links, embedded values, the prose around a replay,
and what an example evaluates to in the Studio are verified by reading.

`tutorials/build.sh` refuses when a replay and the vendored viewer name different engine digests. A
viewer re-simulating with the wrong engine does not fail — it draws a plausible match that never
happened, which is the one failure a teaching page must not have.

## What a deployment owes it

The book is static files with no runtime configuration. What it needs is a serving layer that
answers for them correctly.

| Setting | Owner | Missing or inconsistent value |
|---|---|---|
| `site-url` | book.toml | mdBook writes `<base href>` into `404.html` alone; wrong here, that page loads no stylesheet at any depth |
| `$uri.html` before `$uri` | The serving layer | `models/adapters` is both a page and a section; match the directory first and the chapter becomes unreachable |
| 404 with a 404 status | The serving layer | A `try_files` fallback answers 200, which tells a crawler the page exists and a reader nothing |
| `application/wasm` for `.wasm` | The serving layer's MIME table | `WebAssembly.compileStreaming` refuses the response and no replay draws |
| No SPA fallback above `/viz/` | The serving layer | A wildcard that answers HTML for a missing module leaves every replay showing its fallback sentence |
| A rebuilt `book/` | CI, or `mdbook build` by hand | `mdbook serve` overwrites `book/` with a livereload preview whose `site-url` is forced to `/` — a `serve` left running is what gets served |
| `goplasmatic.github.io` reachable, and allowed | The reader's network, and any Content-Security-Policy the serving layer adds | Every Studio slot shows its fallback sentence; the links under the examples still open the Studio in a tab of its own |

`site-url = "/"` because the book has its own host. The local stack is the one case it is wrong
for: `devops/docker-compose.yml` binds `docs/book` into Web's nginx at `/docs/`, where the
not-found page looks for its stylesheets one level too high. That is the preview, not the
deployment.

## Layout

```text
src/                 the pages -- two openers, then thirty-four chapters in five sections
src/SUMMARY.md       the published chapter order; create-missing = false
src/models/adapters/studio/   the adapter examples: logic, data, and what the data is
studio/studio.py     the {{#studio}} preprocessor, and `link FILE` to print one example's URL
src/tutorials/       generated: the lesson replays (gitignored)
src/viz/             the cartridge's viewer bundle, from its artifact image (gitignored)
tutorials/           the lessons' sources -- boards/*.txt, seat scripts, build.sh, make-map.py
tutorials/README.md  how to write a lesson, and what the viewer cannot show
theme/               the book wearing the application's design system
book.toml            the wiring, with the reasoning in comments
book/                output (gitignored)
```

### The theme

The book wears the application's design system — the same palette, the same type, the same brand —
so a reader crossing from tinybrains.dev to docs.tinybrains.dev does not cross a visual seam.
Nothing about that lives in a page; it is all in `theme/`, and `book.toml` is what wires it up.

The book is its own host, so it carries no site navigation and no footer. The bar holds the search,
**the page's title**, the theme button and the way to the source. The title is centred on the bar
and it is the page's `<h1>`: the chapter's own heading is taken out of the content, because the two
said the same words a few lines apart. The bar is sticky, so a page keeps its title on screen the
whole way down. The brand belongs to the sidebar's heading band and moves into the bar, in front of
the title, when the sidebar is away — and then the title follows it rather than centring.

| File | What it is |
|---|---|
| `theme/tokens.css` | **A copy of `web/public/design-system/tokens.css`, and it must stay one.** Same values, keyed to mdBook's theme classes instead of the application's `data-theme` attribute. `diff` the declarations when the application's palette moves |
| `theme/tinybrains.css` | mdBook's own variables answered in Cobalt roles, then the site's components — the bar, the brand, the sidebar, notes, tables, code — restated for the elements mdBook emits. It names no colour, only tokens |
| `theme/index.hbs` | mdBook 0.5.4's template, vendored. Every change carries a `TINYBRAINS` comment: the logo sprite, the brand in the sidebar band and in the bar, `{{ chapter_title }}` as the page's `<h1>` in the bar, the sun/moon theme button beside the source link, and two themes instead of five |
| `theme/tb-site.js` | The bar's theme button. It sets no theme and it does not choose the glyph — it clicks mdBook's own hidden theme buttons, which is where all the work already lives, and keeps the label saying what the click does |
| `theme/tb-replay.js`, `theme/tb-replay.css` | The embedded replay viewer, and the frame around it |
| `theme/tb-studio.js`, `theme/tb-studio.css` | DataLogic Studio in a page — fetched from the Studio's own site when a slot scrolls into view, and mounted again when the reader switches theme — and the link under every adapter example |
| `theme/fonts/fonts.css` | Empty on purpose. The design system is set in the reader's own interface font, so the book ships no webfont |
| `theme/favicon.svg` | The application's `logo-network.svg` |

The order of `additional-css` in `book.toml` is the mechanism: mdBook appends these after its own
stylesheets, so `tokens.css` can answer mdBook's palette and `tinybrains.css` can restate the
site's components without an `!important` in sight.

## What must stay true

- **A lesson is engine output, not a drawing.** Every replay is played through the real cartridge
  from a written script, and `build.sh` checks each one's `engine_digest` against the viewer's. A
  diagram of a rule can be wrong about the rule; this cannot.
- **`tutorials/replays/real-match.json` is captured, not generated.** It is a real match copied from
  a running stack, so it is the file that goes stale silently — the digest check is what catches it.
- **The prose teaches the rule without the replay.** A viewer that fails to load falls back to a
  sentence, and a page whose explanation lived in the animation would teach nothing.
- **`world-fog` and `observation-payload` stay empty until there is a seat view.** A replay frame is
  the referee's view; ground truth in either slot would teach the reader the opposite of the point.
  Filling them needs `replay-decode` answering "what did seat N see on turn T" — an Ants ABI change,
  and so a decision rather than a task.
- **No invented result.** A planned example states what a recording must show; it never names a
  match, an asset or a digest that does not exist.
- **A Studio link is written from its example, never pasted.** A link carries its whole expression
  and data, so one pasted beside an example is a second copy that drifts the first time either is
  edited. The page holds a `{{#studio}}` directive; the build writes the code and the link from one
  file.
- **The Studio is not the referee.** It runs datalogic-rs, which agrees with Axon on the JSON half
  but for `null` equality, has operators the dialect lacks, shows `tb.*` calls without running them,
  and counts nothing. Every page that links to it can say so without the reader leaving the book,
  and every claim about what the arena does — a cost, a tensor, a trap — is checked with
  `tinybrains adapt` or `tinybrains check`, which run Axon's own evaluator.
- **The numbers belong to whoever computes them.** `src/reference/limits.md` dates its snapshot and
  names each owner. Verify against the current producer before changing a value here.
- **The palette is the application's, to the digit.** `theme/tokens.css` is a copy; a colour
  invented here is a colour the site does not have.
- **The logo is markup, not an image.** Every stroke names a region token, so it wears the palette
  and follows the theme switch. It is defined once as a `<symbol>` and referenced twice, because it
  appears in two places and only one of them shows at a time.
- **`theme/index.hbs` is pinned to mdBook 0.5.4.** book.js reaches for `.menu-title`,
  `#mdbook-theme-toggle` and `#mdbook-theme-list` by name and throws without them, and the two theme
  names — `navy` and `light` — are read by book.js (which syntax stylesheet) and by `tb-replay.js`
  (which palette the viewer wears). On an mdBook upgrade, re-diff the template against
  `mdbook init --theme` from the new version and re-apply the marked blocks; nothing at build time
  notices one that has fallen behind.
- **Which brand shows is CSS, not script.** The swap runs off the sidebar toggle's own checkbox, so
  it is right on the first paint and right with JavaScript off. The theme button works the same way:
  both the sun and the moon are in the markup and the theme class picks one, so it never draws the
  wrong glyph first. The icon names where the click goes, not where the reader is.
- **There is one `<h1>` per page and it lives in the bar.** `.page-name` is the heading; its
  container is a `div`, because upstream's `<h1>` wrapper would make two. book.js finds the
  container by class, so the tags are free to be the right ones.
- **The chapter's own heading is hidden, not deleted.** `.content main > h1:first-child` — first
  child only, so a page that opens some other way is untouched, and so is every chapter but the
  first when `print.html` strings them together. It comes back under `@media print`: there is no bar
  on paper, and a printed chapter with no title is worse than one that says its name twice. Every
  page in `src/` opens with exactly one `#` heading today, which is what makes the rule safe; a page
  that stops doing so keeps its heading and shows the title twice.
- **Nothing generated is committed, and `real-match.json` is the exception that proves it.**
  `src/tutorials/`, `src/viz/`, `tutorials/boards/*.json` and the scenario replays are rebuilt by
  `Dockerfile` from artifact images. `tutorials/replays/real-match.json` is committed because it is
  *input*: a real match captured from a running stack, which nothing here can reproduce. It is also
  the file that goes stale without anyone noticing, which is why `build.sh` refuses to finish when
  its `engine_digest` disagrees with the viewer's.

## Status

**11 September 2026 — a leaderboard entry's `trend` and `history` are in the API reference.**
Soma has carried `trend` since the entry split and gains `history` today, the last twelve ratings
on the ladder for the site's sparkline; neither was in `reference/api.md`'s field list.

**11 September 2026 — the adapter chapter explains the adapter, and every example opens in
DataLogic Studio.** Two new pages: *A real adapter, piece by piece* reads the baselines' adapter
plane by plane, both programs, with its measured cost; *Seeing it in DataLogic Studio* says how to
open your own, what the Studio shows, and the places it and the arena disagree. The overview, the
dialect, the operators, the budget and the testing page are rewritten against Axon's source: the
object rule stated exactly (an unknown key is a silent literal, not an error), the scope trap shown
running, every operator's charge in one table, the defaults and failure cases the operator table
left out, and the `tinybrains check` / `tinybrains adapt` workflow. Four things were wrong and are
not: the testing page said the reference set was one fixture observation and linked to an anchor
that did not exist, and it and the introduction still named a compute cap.

Nine examples live under `src/models/adapters/studio/`. Every link was decoded with the Studio's own
libraries and evaluated with its engine, and every claim about the arena — the costs, the `null`
trap, `split` as a literal, a `null` scatter coordinate landing in column 0 — was run through
`tinybrains adapt` or `tinybrains check`. The embed is datalogic-rs's own mdBook widget, loaded from
its site and unpinned; `design/tracker.md` holds that as a decision.

**11 September 2026 — a baseline is described as an entry.** `competing/matches.md` and the
glossary say what the platform now does: a baseline is paired, rated and settled like any entry,
carries a tag, and is the opponent in every trial.

**10 September 2026 — the book builds from artifact images, and the build is RED.** Nothing
generated is committed: `src/viz/`, `src/tutorials/`, `tutorials/boards/*.json` and the scenario
replays are gitignored, and `Dockerfile` rebuilds them — the viewer from the cartridge's artifact
image, the `tinybrains` binary that plays the lessons from devops'. Building the book no longer
needs the platform checked out around it, nor a Rust toolchain.

**It does not currently finish.** The seven scripted lesson replays regenerate cleanly on the
current engine, but `tutorials/replays/real-match.json` was captured on `sha256:d41f863f…` and the
cartridge now ships `sha256:0807b641…`, so `build.sh`'s digest check refuses it. That file is
**source, not build output** — a real match captured from a running stack, which nothing here can
reproduce — and it is embedded on four pages, including the introduction.

The fix is a re-captured match, not a looser check: a viewer re-simulating with a different engine
does not fail, it draws a plausible match that never happened. When you replace it, check that the
`data-turn` on each of those four pages still falls inside the new match — `src/competing/matches.md`
asks for turn 161.

**Decision 46, 10 September 2026 — no compute cap.** Nine pages changed. The weight-class table lost
its FLOP column and says plainly that size is the only thing a class limits, with the turn deadline —
divided among the seats in a call — named as the compute bound. `FLOPS_OVER_CAP` is gone from the
rejection reasons: one fewer way to be refused for something a competitor could not predict locally.

**10 September 2026.** Thirty-three pages across five sections build clean under mdBook 0.5.4 with
`create-missing = false`. The competitor path — rules, model format, weight classes, the adapter
dialect and its budget, testing, submitting, admission, the trial, ranking and seasons — is written
against the current producers, with `src/reference/limits.md` dated and each value's owner named.

Sixteen replays are embedded and play the cartridge's own viewer: four scripted lessons, three
preset boards, and one real match captured from a running stack. `quickstart-first-trial` is still a
planned recording. `world-fog` and `observation-payload` are deliberately empty and say why.

The theme is done and the book is ready for a host of its own — `site-url = "/"`, no link that
assumes the application's origin. **`docs.tinybrains.dev` does not exist yet**: Web's nginx serves
the rendered book at `/docs/` from a read-only bind, and the root-relative `/docs...` links in
`web/` become absolute when the host does exist. That mount is also the one case `site-url` is
wrong for, which shows on the 404 page alone.

Owed: a re-diff discipline for the vendored template on any mdBook upgrade, the seat view that
would fill the two blocked slots, and a clone-and-build check from a fresh directory.

## More

- Local references: [`src/SUMMARY.md`](src/SUMMARY.md) (the chapter order), [`tutorials/README.md`](tutorials/README.md) (how to write a lesson), [`book.toml`](book.toml) (the wiring, with the reasoning in comments).
- The platform section — [architecture](src/platform/architecture.md), [the repositories](src/platform/repositories.md), [running locally](src/platform/running-locally.md), [adding a game](src/platform/adding-a-game.md), [contributing](src/platform/contributing.md) — is the orientation for someone new to the codebase.
- Related repositories: [Ants](https://github.com/Tiny-Brains/ants), [Web](https://github.com/Tiny-Brains/web), [DevOps](https://github.com/Tiny-Brains/devops), [Soma](https://github.com/Tiny-Brains/soma), [Jodi](https://github.com/Tiny-Brains/jodi), [Kalam](https://github.com/Tiny-Brains/kalam), [Axon](https://github.com/Tiny-Brains/axon), [Drill](https://github.com/Tiny-Brains/drill).
