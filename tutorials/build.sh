#!/bin/sh
# Rebuild the book's teaching replays, and the viewer that plays them.
#
# A lesson replay is ENGINE OUTPUT, exactly as the reference observations are: it is produced by
# playing a written script through the real cartridge, so what a page shows is what the rules do
# rather than a drawing of what someone believed they do. That also means it goes stale when the
# engine changes, which is why this is a script and not a one-off.
#
#     tutorials/build.sh              # needs `tinybrains` on PATH and a viewer at $ANTS_DIR/viz/dist
#
# ../Dockerfile runs this with both taken from artifact images -- the viewer from the cartridge's,
# the binary from devops' -- so neither needs a sibling checkout. Run it by hand the same way, or
# with ANTS_DIR pointing at an ants checkout that has been built.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"

command -v tinybrains > /dev/null 2>&1 || {
  echo "tinybrains is not on PATH." >&2
  echo "  from the CLI's artifact image:  docker create tinybrains/cli:dev, then docker cp its /artifacts/bin/tinybrains" >&2
  echo "  or from a checkout:             cargo install --path ../../devops/cli" >&2
  exit 1; }

echo "==> boards"
for txt in boards/*.txt; do
  name=$(basename "$txt" .txt)
  python3 make-map.py "$txt" --id "lesson-$name" > "boards/$name.json"
  echo "    $name"
done

echo "==> replays"
mkdir -p replays
# Every scenario spec in this directory. `real-match.json` under replays/ is NOT one: it is a real
# match, captured from a running stack, and it is copied rather than regenerated -- the digest
# check below is what catches it going stale.
for spec in *.json; do
  tinybrains "$spec" --out replays | grep -E "turns  board" | sed 's/^/    /'
done

echo "==> into the book"
mkdir -p ../src/tutorials ../src/viz
cp replays/*.json ../src/tutorials/

# The viewer, from the cartridge that produced the replays. Vendored rather than fetched, so the
# book builds offline -- and checked against the digest the replays name, because a viewer
# re-simulating with a different engine draws a plausible match that never happened.
VIZ="${ANTS_DIR:-../../ants}/viz/dist"
[ -d "$VIZ" ] || { echo "no viewer at $VIZ -- run ants/viz/build.sh" >&2; exit 1; }
cp -R "$VIZ/." ../src/viz/

# EVERY replay, not the first one. A captured match is copied rather than regenerated, so it is
# exactly the file that goes stale without anyone noticing -- and a viewer re-simulating with the
# wrong engine does not fail, it draws a plausible match that never happened.
python3 - <<'CHECKEOF'
import glob, json, sys
built = json.load(open("../src/viz/engine.json"))["engine_digest"]
bad = []
for f in sorted(glob.glob("replays/*.json")):
    played = json.load(open(f)).get("engine_digest")
    if played != built:
        bad.append((f, played))
if bad:
    print("    MISMATCH -- the viewer was built against", built, file=sys.stderr)
    for f, played in bad:
        print(f"      {f} was played on {played}", file=sys.stderr)
    print(file=sys.stderr)
    # Which file it is decides what the fix is, and only one of the two is this build's to make.
    if any("real-match" in f for f, _ in bad):
        print("    replays/real-match.json is a real match CAPTURED FROM A RUNNING STACK. Nothing",
              file=sys.stderr)
        print("    here can reproduce it: it is source, not build output, and it is referenced from",
              file=sys.stderr)
        print("    four pages. Re-capture a match played on the current engine and replace it --",
              file=sys.stderr)
        print("    and check the `data-turn` on each of those pages still falls inside the new match.",
              file=sys.stderr)
    if any("real-match" not in f for f, _ in bad):
        print("    The scenario replays are generated here; re-run this script to bring them forward.",
              file=sys.stderr)
    print(file=sys.stderr)
    print("    A viewer re-simulating with a different engine does not fail. It draws a plausible",
          file=sys.stderr)
    print("    match that never happened, which is why this is an error and not a warning.",
          file=sys.stderr)
    sys.exit(1)
print(f"    {len(glob.glob('replays/*.json'))} replays agree with the viewer on {built[:14]}...")
CHECKEOF
