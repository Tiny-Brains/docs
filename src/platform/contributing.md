# Contributing

A useful contribution makes competition easier to understand, enter, run, or
verify. Start by identifying the [repository](repositories.md) that owns the
behavior and reading its README, source, and relevant tests. The application
repositories are separate Git checkouts even when developed under one parent.

## Choosing work

Each repository carries its own design documents under `docs/`, and DevOps carries
the whole-system map, the decision log, the deployment design, and the Orion notes.
Verify claims against the current producer and consumer before copying them into
code or docs.

Concrete open areas include the browser replay viewer and envelope integration,
a cartridge-owned reference observation set, competitor tooling, and production
rollout verification. For a user-visible change, describe the competitor's trigger
and resulting behavior rather than only the internal component involved.

## Source conventions

Edit Jodi and Kalam workflows in their Python generators, regenerate, and commit
the generated JSON. Keep built plugin artifacts and manifests with source changes
that alter them. When updating Ants, rebuild its artifacts and explicitly vendor
them into Kalam if that repository is part of the change.

Put schema changes in Soma migrations and check every consuming package. Keep
deployment addresses and credentials in configuration. Use the pinned Orion
version when linting definitions; a different version can report misleading
compatibility failures.

## Checks that matter

Run checks appropriate to the repository and changed boundary:

| Area | Existing checks, from that repository's root |
|---|---|
| Docs | `mdbook build`; check relative links and examples |
| Ants | `./deny.sh`, `cargo test`, and `./build.sh` for regenerated distributables |
| Axon | `cargo test`; relevant adapter, inference, or store cases |
| Jodi plugins | `cargo test --manifest-path plugins/tb-rating/Cargo.toml` and the corresponding pairing manifest |
| Soma, Jodi, Kalam definitions | `orion-server lint . --deny-warnings` and `./scripts/check-sql.sh` |
| Web | `npm run lint` and `npm run build` |
| DevOps | `./scripts/check-configs.sh`, loader output, and a representative end-to-end flow |

SQL checks create disposable scratch databases and verify shipped statements;
they do not prove live scheduling or concurrency. Axon's live S3 tests require
explicit store configuration and otherwise skip their external exercises.
Configuration checks can skip runtime parsing when the required image is missing.
Report what actually ran, including those limits.

An API contract change should be exercised through the HTTP workflow. A game or
adapter change needs behavioral examples. A replay change needs reconstruction
from an actual stored envelope, not only an engine-internal fixture. Use a local
stack for integration evidence where unit checks cannot establish the result.

## Writing documentation

Address competitors first: what they need to build, what the platform checks,
what they can observe, and what to do next. Keep architecture details in this
platform section unless they explain a practical limitation. Label planned tools
clearly and avoid describing a design proposal as a working endpoint.

Use relative links within the book and keep `src/SUMMARY.md` aligned with pages.
A replay placeholder should state the behavior to illustrate and retain a text
explanation. Record real replay/engine identities when assets become available;
do not invent a game result to fill an example slot.

## Opening a change

Explain the concrete problem and resulting behavior, list affected contracts,
and give the checks that support the change. Include generated or vendored output
where needed and update the competitor-facing documentation in the same work.
For cross-repository changes, name the required companion revisions and deployment
order so reviewers can assess a consistent set of artifacts.

A report should include the relevant version or match ID, expected and actual
behavior, and reproducible steps. Do not include session cookies or deployment
credentials. Preserve the failing input or replay where possible so a fix can be
verified against the original problem.
