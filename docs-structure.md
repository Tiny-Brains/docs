# TinyBrains documentation structure

The mdBook is a competitor guide: understand the game, build a valid entry, submit
it, and interpret results. Platform chapters serve contributors and local operators.
The published chapter order is maintained in `src/SUMMARY.md`.

## Page inventory

### [Introduction](src/introduction.md)

The first game: Ants · What you build · How to participate · How competition works · Start here

### [Quickstart](src/quickstart.md)

What you need · 1. Train something small · 2. Write the adapter · 3. Publish a GitHub release · 4. Submit it · 5. Watch the trial · Where to go next

### [Ants](src/games/ants.md)

The idea · What you command · What you can see · How a match ends · The three maps · Where the rules are exact

### [The world](src/games/ants/world.md)

The grid, and why it wraps · Terrain and water · Hills · Food · Vision and fog · Symmetry and presets

### [A turn](src/games/ants/turn.md)

The six steps, in order · Moving and collisions · Combat · Razing a hill · Food and new ants · Sending nothing

### [Ending and scoring](src/games/ants/scoring.md)

How score is computed · How a match ends · Ranks and ties · Strikes and forfeits

### [The maps](src/games/ants/maps.md)

Standard · Maze · Cell · Symmetric starts, varied matches

### [What your model sees](src/models/observation.md)

Fields · Known water · What is hidden · A worked example

### [What your model answers](src/models/actions.md)

One order per ant · Illegal and missing orders · The turn clock · A move is an intention

### [Model format](src/models/format.md)

ONNX compatibility · Inputs and outputs · How size is measured · What is inspected

### [Weight classes](src/models/weight-classes.md)

The five classes · How your class is decided · The Open ladder · Choosing what to enter

### [Adapters](src/models/adapters.md)

The two directions · A minimal adapter, end to end · Where it runs and what it may do

### [The dialect](src/models/adapters/dialect.md)

Expressions and objects · Core operators · Variables and scope · Tensor values · Equality and empty values · Versions

### [Operators](src/models/adapters/operators.md)

Building tensors · Reshaping and combining · Converting and deriving · Reading tensors and values · Costs at a glance

### [The budget](src/models/adapters/budget.md)

What counts as an operation · What over budget means · Measuring before you submit · Spending less

### [Testing before you submit](src/models/testing.md)

Reference observations · Validate with Axon · Check the actions too · Playing a match locally · Before publishing

### [Submitting a version](src/competing/submitting.md)

Prepare the release · Make the call · Season and candidate restrictions · What happens next

### [Admission](src/competing/admission.md)

What is checked · Watching progress · Verified · Rejected · When the platform cannot complete the check

### [The trial](src/competing/trial.md)

Who you play · Why losing is fine · When a trial fails · How long you wait

### [The life of a version](src/competing/version-life.md)

The five states · Promotion · What the new version inherits · What happens to old matches · Withdrawal and rejection

### [Matches](src/competing/matches.md)

Who decides that you play · Match states · What a match record shows · Cancelled and failed matches · Reading your results

### [Replays](src/competing/replays.md)

Getting a replay · What is stored · Watching a replay: current tooling · Using replay examples in this book · Improving from a replay

### [Ranking](src/competing/ranking.md)

Reading a rating · Your ladders · Why a result arrives before its rating change · Provisional and settled · Ratings after a new version · Seasons and comparisons

### [Seasons](src/competing/seasons.md)

The submission window · Rules that can affect entry · How a season closes · What carries over · Historical standings

### [Rejection reasons](src/reference/rejection-reasons.md)

Request refusals · Release assets and graph · Adapter and interface · Trials and administrative outcomes · Platform-side retries

### [Limits and budgets](src/reference/limits.md)

Model and adapter · Ants matches · Admission and submissions · Ratings and scheduling · Where values come from

### [HTTP API](src/reference/api.md)

Signing in · Games, seasons, and ladders · Versions and matches · Submitting · Errors and rate limits · Administrative routes

### [Glossary](src/reference/glossary.md)



### [How TinyBrains is built](src/platform/architecture.md)

The parts · One match table between scheduling and execution · What one entry touches · Deployment and scaling · Boundaries to preserve

### [The repositories](src/platform/repositories.md)

The seven application repositories · Which repository owns a change? · Generated and vendored files · What is not supplied yet

### [Running the platform locally](src/platform/running-locally.md)

What you need · Configure the stack · Bring it up · Sign in and make a match happen · Reloading and stopping · When nothing plays

### [Adding a game](src/platform/adding-a-game.md)

The five functions · State and determinism · The two manifests · Registering and integrating · Documentation competitors need

### [Contributing](src/platform/contributing.md)

Choosing work · Source conventions · Checks that matter · Writing documentation · Opening a change

## Replay visualiser placeholders

Use a visible “Replay visualiser — planned” caption beside the explanation, followed
by an HTML comment starting `replay-visualiser: <unique-id>`. The caption states what
the eventual recorded game should illustrate. The comment reserves implementation
metadata without inventing an asset or match result.

Before enabling an example, supply the actual replay asset, matching engine digest,
turn range, player perspective, and accessible text caption. Resolve the stored
envelope/decoder initialization contract documented in [Replays](src/competing/replays.md).
Keep explanatory prose usable without playback. Do not add placeholders to pages
where a game animation contributes no useful explanation.

### Reserved examples

| Placeholder ID | Chapter |
|---|---|
| `match-result-inspection` | [matches](src/competing/matches.md) |
| `replay-viewer` | [replays](src/competing/replays.md) |
| `trial-playability` | [trial](src/competing/trial.md) |
| `maps-standard` | [maps](src/games/ants/maps.md) |
| `maps-maze` | [maps](src/games/ants/maps.md) |
| `maps-cell` | [maps](src/games/ants/maps.md) |
| `scoring-hill-result` | [scoring](src/games/ants/scoring.md) |
| `turn-collision` | [turn](src/games/ants/turn.md) |
| `turn-focus-combat` | [turn](src/games/ants/turn.md) |
| `turn-spawn-delay` | [turn](src/games/ants/turn.md) |
| `world-wrapping` | [world](src/games/ants/world.md) |
| `world-fog` | [world](src/games/ants/world.md) |
| `ants-overview` | [ants](src/games/ants.md) |
| `introduction-match` | [introduction](src/introduction.md) |
| `actions-to-outcomes` | [actions](src/models/actions.md) |
| `observation-payload` | [observation](src/models/observation.md) |
| `testing-behaviour` | [testing](src/models/testing.md) |
| `quickstart-first-trial` | [quickstart](src/quickstart.md) |

## The theme

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
| `theme/fonts/fonts.css` | Empty on purpose. The design system is set in the reader's own interface font, so the book ships no webfont |
| `theme/favicon.svg` | The application's `logo-network.svg` |

**What must stay true**

- **The palette is the application's, to the digit.** `theme/tokens.css` is a copy; a colour invented
  here is a colour the site does not have.
- **The logo is markup, not an image.** Every stroke names a region token, so it wears the palette
  and follows the theme switch. It is defined once as a `<symbol>` and referenced twice, because it
  appears in two places and only one of them shows at a time.
- **`theme/index.hbs` is pinned to mdBook 0.5.4.** book.js reaches for `.menu-title`,
  `#mdbook-theme-toggle` and `#mdbook-theme-list` by name and throws without them, and the two theme
  names — `navy` and `light` — are read by book.js (which syntax stylesheet) and by `tb-replay.js`
  (which palette the viewer wears). On an mdBook upgrade, re-diff the template and re-apply the
  marked blocks; nothing at build time notices one that has fallen behind.
- **Which brand shows is CSS, not script.** The swap runs off the sidebar toggle's own checkbox, so
  it is right on the first paint and right with JavaScript off. The theme button works the same way:
  both the sun and the moon are in the markup and the theme class picks one, so it never draws the
  wrong glyph first. The icon names where the click goes, not where the reader is.
- **There is one `<h1>` per page and it lives in the bar.** `.page-name` is the heading; its
  container is a `div`, because upstream's `<h1>` wrapper would make two. book.js finds the container
  by class, so the tags are free to be the right ones.
- **The chapter's own heading is hidden, not deleted.** `.content main > h1:first-child` — first
  child only, so a page that opens some other way is untouched, and so is every chapter but the
  first when `print.html` strings them together. It comes back under `@media print`: there is no bar
  on paper, and a printed chapter with no title is worse than one that says its name twice. Every
  page in `src/` opens with exactly one `#` heading today, which is what makes the rule safe; a page
  that stops doing so keeps its heading and shows the title twice.
- **`site-url` is where the book is served**, and it is `/` because the book has its own host.
  mdBook writes `<base href>` into `404.html` alone, so that page finds its stylesheets only if this
  is right. A local stack that mounts the book under `/docs/` is the one case it is wrong for — and
  `mdbook serve` overrides it with `/` for its own preview, so finish with `mdbook build`.
