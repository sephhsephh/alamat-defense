#!/bin/sh
# Run one Bakunawa Cove build script headless against the work file: tools/maps/pirate/run.sh <script.py> [save]
# 'save' writes the .blend afterwards (terrain / kits / layout steps). Extra python can go in $PRE (e.g. ONLY = {...}).
BL="/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"
BLEND="${BLEND_FILE:-C:/Users/Joseph Elton Estilo/Downloads/BakunawaCove_Map/BakunawaCove.blend}"  # BLEND_FILE=... to target another file
DIR="C:/Users/Joseph Elton Estilo/Documents/alamat-defense/tools/maps/pirate"
SAVE=""
[ "$2" = "save" ] && SAVE="; import bpy; bpy.ops.wm.save_as_mainfile(filepath='$BLEND')"
"$BL" -b "$BLEND" --python-expr "${PRE:-pass}; exec(open('$DIR/$1', encoding='utf-8').read()); print('RESULT', result)$SAVE" 2>&1 \
  | grep -E 'RESULT|Error|error:|Traceback|File "|line [0-9]' | grep -v 'Read blend' | head -40
