#!/bin/sh
# Rebuild the whole Bakunawa Cove scene in order (each step saves the .blend), then render the map shots.
# Usage: sh tools/maps/pirate/build_all.sh [notex]   (notex = keep the existing textures)
cd "$(dirname "$0")"
[ "$1" = "notex" ] || ./run.sh textures.py
for s in terrain kit_nature kit_harbour kit_village kit_village2 kit_landmarks kit_skull layout; do
  echo "== $s"; ./run.sh $s.py save | cut -c1-300
done
./run.sh preview.py | cut -c1-120
