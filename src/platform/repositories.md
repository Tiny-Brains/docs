# The repositories

TinyBrains is developed as sibling repositories. For ordinary model competition,
your own model repository is separate from all of these. Use this map when you
need to inspect implementation behavior or contribute a platform change.

## The seven application repositories

| Repository | Owns | Start reading |
|---|---|---|
| [Soma](https://github.com/Tiny-Brains/soma) | API, authentication, schema, season administration | `channels/`, `workflows/`, `migrations/` |
| [Jodi](https://github.com/Tiny-Brains/jodi) | Admission, pairing, rating, and version lifecycle | `scripts/gen-jodi.py`, `plugins/` |
| [Kalam](https://github.com/Tiny-Brains/kalam) | Match execution, claims, strikes, and replay upload | `scripts/gen-kalam.py` |
| [Ants](https://github.com/Tiny-Brains/ants) | Game rules, generation, observations, replay reconstruction | `src/turn.rs`, `src/observe.rs`, `src/map.rs`, `src/replay.rs` |
| [Web](https://github.com/Tiny-Brains/web) | Browser application and typed API client | `src/api.ts`, application components, proxy configuration |
| [DevOps](https://github.com/Tiny-Brains/devops) | Local topology, runtime templates, registration, package loading | `docker-compose.yml`, `orion/`, `loader/run.sh` |

The [Docs repository](https://github.com/Tiny-Brains/docs) contains this mdBook:
`src/` holds chapters, `src/SUMMARY.md` orders them, and `book.toml` configures the
build. It is separate from the six application packages.

> **There is no model-runner repository.** `axon` was one until 14 September 2026; Orion's own
> `models` entity replaced it whole, so ONNX loading, the expression language and the operation
> budget are the *server's* now rather than a service this platform maintains.
> [The archived repository](https://github.com/Tiny-Brains/axon) maps each call it answered to what
> answers it today.

## Which repository owns a change?

A rule or observation change belongs in Ants, with matching competitor docs and adapter
compatibility checks. **An evaluator operator or operation-count change belongs upstream**, in
datalogic — it is not this platform's to make, which is why the operator reference points at what
the engine has rather than at a list somebody here maintains. A submission check can span Soma's
request contract, Jodi's verdict, and the facts the node reports; identify each responsibility
before editing.

Match execution and result persistence belong in Kalam; rating math and opponent
selection belong in Jodi. Database definitions always originate in Soma even
when Jodi or Kalam is the consumer. Deployment addresses and secret wiring belong
in DevOps rather than embedded in package definitions.

## Generated and vendored files

Jodi and Kalam keep readable workflow generators and commit their generated
JSON. Edit the generator, regenerate, and include the output in the same change.
Ants generates its JSON manifest and registration data through its build script.
Kalam vendors the built Ants component and manifests; changing Ants source alone
does not update the engine Kalam runs.

The full local stack expects the application checkouts under one parent directory.
[Running locally](running-locally.md) gives the required layout and commands.

## What is not supplied yet

There is no packaged competitor training SDK, standalone ONNX game runner, complete
browser replay viewer, cloud autoscaler, or finished production rollout pipeline
in these repositories. The Web shell currently provides sign-in and API probes.
Use the API and local validation paths documented in this book without assuming
those future tools exist.
