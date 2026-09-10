# HTTP API

Soma serves the competitor API under `/v1`. Use the competition's browser-facing
origin; the local stack proxies these routes through `http://localhost:5173`.
Responses are JSON unless the route redirects or clears a session without a body.

The contracts below describe the current workflows. The browser client implements
only part of this surface; a method listed here is not necessarily available as
a completed UI screen.

## Signing in

Navigate the browser to `GET /v1/auth/github`. GitHub returns through
`GET /v1/auth/github/callback`, and Soma sets an HttpOnly `soma_session` cookie.
The current session lifetime is 30 days, with server-side revocation checked on
authenticated requests. Use same-origin requests so the browser sends the cookie.

| Method | Path | Authentication | Result |
|---|---|---|---|
| GET | `/v1/auth/github` | Public | Begin OAuth via redirect |
| GET | `/v1/auth/github/callback` | OAuth callback | Complete sign-in |
| GET | `/v1/me` | Session | Current account |
| DELETE | `/v1/session` | Session | Revoke session and clear cookie |

API bearer tokens for an SDK or CLI are not implemented. Do not send a GitHub
personal access token as though it were a Soma session.

## Games, seasons, and ladders

| Method | Path | Query parameters | Result |
|---|---|---|---|
| GET | `/v1/games` | None | Array of registered games |
| GET | `/v1/games/{game}/seasons` | None | Seasons, newest first |
| GET | `/v1/games/{game}/leaderboard` | `ladder`, `season`, `limit`, `cursor` | Standings page |

These reads are public. `game` is a slug such as `ants`. Ladder values are `nano`,
`micro`, `mini`, `small`, `large`, and `open`; default is `open`. `season` is a
season number, not a UUID. Omit it for the live season, or latest closed season
when there is no live one.

Leaderboard `limit` defaults to 50 and `cursor` to `"0"`. The cursor is an offset
string. Use returned `next_cursor` until it is null. Live ratings can reorder
between requests, so pagination is not a stable snapshot.

```sh
curl --fail-with-body -sS   'http://localhost:5173/v1/games/ants/leaderboard?ladder=open&limit=10'
```

The body has `season`, `closed`, `entries`, and `next_cursor`. Each entry includes
`rank`, `model_id`, `owner`, `version`, `class`, `size_bytes`, `rating`,
`provisional`, and `matches`.

A season entry includes `number`, `state`, `submissions_open_at`,
`submissions_close_at`, `closed_at`, `close_requested_at`, `engine_digest`, and
`rules`. See [Seasons](../competing/seasons.md).

## Versions and matches

| Method | Path | Authentication | Parameters |
|---|---|---|---|
| GET | `/v1/models` | Session | Optional `game` query; returns caller's versions |
| GET | `/v1/models/{id}` | Public | Model UUID |
| GET | `/v1/matches` | Public | Required `model` UUID; optional `limit`, default 25 |
| GET | `/v1/matches/{id}` | Public | Match UUID |

A version detail reports its owner, game, version, release metadata, class, size,
parameter count, measured inference time, hashes, evaluator identity, season, status,
phase, admission attempt, successor, rejection reason, latest trial, and ratings.
Many fields are null before admission produces them. `ratings` is keyed by ladder.

Match history is an array of **finished and rated matches only**, newest played
first, with the requested model's rank and score. There is no history cursor in
the current workflow. Queued, cancelled, and failed matches are not included in
that list; passing an undocumented status filter does not enable them.

A match detail contains `players`, `is_trial`, engine/evaluator identities, seed,
preset, ending reason, timing, status, cancellation/failure fields, and a temporary
`replay_url` when available. Each player records its model/version, score, rank,
strikes, and per-ladder `rating_change`. Trial progress is also available through
the version's `trial` field.

The current detail workflows do not explicitly turn an absent database row into
`404`; clients should handle a null body as well as HTTP errors. Do not assume
that every unknown UUID receives a structured not-found error.

## Submitting

`POST /v1/submissions` requires a session and this body shape:

```json
{
  "game": "ants",
  "repo": "OWNER/REPO",
  "release_tag": "TAG",
  "weights_hash": "sha256:<64 hex digits>",
  "adapter_hash": "sha256:<64 hex digits>"
}
```

Replace the illustrative values with your release and actual hashes. The response
is `201` with `model_id`, `version`, `status`, `season`, and both hashes. It records
a testing version rather than accepting the entry directly onto the ladder.
See [Submitting a version](../competing/submitting.md) for a session-based example.

## Errors and rate limits

Handle the HTTP status before interpreting a success body. Request refusals
include `400` for missing hashes, `401` for invalid sessions, and `409` for season,
eligibility, duplicate-release, or in-flight candidate conflicts. Error details
can vary by whether Soma or the underlying runtime produced the response.
The [rejection reference](rejection-reasons.md) separates request errors from
later version verdicts.

The submission route declares 1 request/second with burst 5 per signed-in user.
`/me`, `/models`, and session deletion declare 10 requests/second with burst 20.
Back off on `429`; when a response provides retry timing, respect it. No daily
submission allowance is declared by these channels. Public-route or deployment
limits may apply separately; use modest polling instead of a tight loop.

## Administrative routes

`POST /v1/games/{game}/seasons` creates a season and
`POST /v1/games/{game}/seasons/current/close` requests closure. Both require an
administrator's live session and are not competitor actions. Their request
contracts are maintained in Soma's workflows. There is no public route for
forcing a match, promoting a version, or withdrawing your own version.
