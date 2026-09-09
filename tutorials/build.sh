#!/bin/sh
# Rebuild the book's teaching replays, and the viewer that plays them.
#
# A lesson replay is ENGINE OUTPUT, exactly as the reference observations are: it is produced by
# playing a written script through the real cartridge, so what a page shows is what the rules do
# rather than a drawing of what someone believed they do. That also means it goes stale when the
# engine changes, which is why this is a script and not a one-off.
#
#     tutorials/build.sh              # needs `tinybrains` on PATH and ../ants beside this repo
set -eu
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"

command -v tinybrains > /dev/null 2>&1 || {
  echo "tinybrains is not on PATH -- cargo install --path ../../devops/cli" >&2; exit 1; }

echo "==> boards"
for txt in boards/*.txt; do
  name=$(basename "$txt" .txt)
  python3 make-map.py "$txt" --id "lesson-$name" > "boards/$name.json"
  echo "    $name"
done

echo "==> replays"
mkdir -p replays
for spec in [0-9]-*.json; do
  tinybrains "$spec" --out replays | sed -n 's/^\([0-9]\)/    \1/p'
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

built=$(python3 -c "import json;print(json.load(open('../src/viz/engine.json'))['engine_digest'])")
played=$(python3 -c "import json,glob;print(json.load(open(sorted(glob.glob('replays/*.json'))[0]))['engine_digest'])")
if [ "$built" != "$played" ]; then
  echo "    MISMATCH" >&2
  echo "      the replays were played on $played" >&2
  echo "      the viewer was built against $built" >&2
  echo "    rebuild ants, then re-run this" >&2
  exit 1
fi
echo "    viewer and replays agree on ${built%${built#sha256:???????}}..."
