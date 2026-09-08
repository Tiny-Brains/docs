# Running the platform locally

The local stack lets you exercise submission, admission, trials, matches, and
rankings together. It is also the current route to playing an ONNX entry locally;
a standalone model-versus-model runner is not supplied yet.

## What you need

Install Docker with Compose v2 and a POSIX shell. Check out the application
repositories as siblings:

```text
tinybrains/
  soma/
  jodi/
  kalam/
  axon/
  ants/
  web/
  devops/
```

Compose builds images and mounts packages from these paths, so a DevOps-only
checkout is insufficient. The stack uses the pinned Orion 1.7.0 runtime,
Postgres 16, Redis, MinIO, Axon, and the browser application. Python 3 is needed
for supplementary SQL checks; host Rust is not required just to load the committed
game component.

## Configure the stack

From `devops/`, create your local configuration if it does not already exist:

```sh
test -e .env || cp .env.example .env
openssl rand -hex 32
```

Use the generated value for `SOMA_SESSION_SECRET`. Fill the required database,
restricted Kalam role, storage, and GitHub OAuth values listed in `.env.example`.
Keep local credentials in the ignored `.env` file.

Register a GitHub OAuth App with homepage `http://localhost:5173` and callback
`http://localhost:5173/v1/auth/github/callback`. Set `APP_URL` and
`OAUTH_REDIRECT_URI` consistently. Plain HTTP development uses a non-Secure cookie;
HTTPS deployments require their corresponding cookie policy.

## Bring it up

```sh
docker compose up --build -d
./scripts/check-configs.sh
docker compose ps -a
docker compose logs loader
```

The loader registers the game, model/reference data, engine identity, storage,
and Orion packages. Check that it finished successfully and that channels or
plugins were not quarantined. A healthy server before package loading is not yet
a working competition.

Open `http://localhost:5173`, or verify the proxy:

```sh
curl --fail --silent --show-error http://localhost:5173/v1/games
```

Local host ports include Soma at 8080, the first Kalam at 8082, admission Axon at
9091, Web at 5173, and MinIO at 9000/9001. They bind to loopback. For application
requests and sign-in, use the browser origin consistently.

## Sign in and make a match happen

Use the Web shell's GitHub sign-in, then inspect `/v1/me`, games, and seasons.
The shell currently offers API probes rather than all competition screens. Submit
a public release using the [authenticated request example](../competing/submitting.md).
A game needs an open local season, an eligible account, and at least one runnable
opponent for the trial and regular matches.

The development fixture script can populate baseline assets:

```sh
./scripts/seed-baselines.sh
```

Seed rows containing hashes alone are not runnable models. The model bytes must
exist in the same store used by admission and replica loaders. Season creation
requires an administrator account; signing in as a competitor does not grant
that role. Use the deployment's administrator provisioning and Soma season route
when a local season needs to be created.

Follow the submitted model's phase, its trial ID, then its finished match history
and leaderboard entry. This is stronger evidence of a working stack than a
successful health probe alone.

## Reloading and stopping

After editing package definitions, reload them:

```sh
docker compose run --rm loader
```

Database initialization scripts run only on fresh volumes. Reloading packages
does not apply pending schema migrations to an existing database; follow the
migration procedure appropriate to that development checkout.

Stop services with `docker compose stop`. Match workers are configured to drain,
but a forced shutdown can still require claim recovery. Avoid deleting volumes
unless you intend to discard local history. The development schema resync script
is guarded repair tooling, not a production migration mechanism.

## When nothing plays

| Symptom | Check |
|---|---|
| Sign-in loops or returns unauthenticated | Browser origin, OAuth callback, cookie policy, and session secret |
| Candidate stays testing | Admission loader, public asset access, registered reference observations, admission clock |
| Candidate stays verified | Latest trial status, available opponent, pairing clock |
| Pending matches never run | Loaded `tb-wave` channel and engine; queued engine digest matches worker digest |
| Models cannot load | Shared bucket, actual assets, store credentials, residency capacity |
| Matches play but cannot finish | Replay bucket, upload connectivity, current claim and lease |
| Results exist but ratings do not move | Counting clock; confirm the match is not an unrated trial |

Use `docker compose logs` for the relevant service and keep model/match IDs in
reports. A cloud deployment, TLS ingress, live R2 verification, and autoscaling
are separate work from this local setup.
