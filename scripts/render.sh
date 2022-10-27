#!/bin/bash
# usage: bash render.sh scene_file.txt
#       ex. bash render.sh scenes.txt

filename=$1
scene_names=()
while read line; do
    # read each line
    scene_names+=($line)
done < $filename

for scene_name in ${scene_names[@]}
do
    python -m render --gin_configs=configs/$scene_name.gin --gin_bindings="Config.render_step = 10000"
    python -m render --gin_configs=configs/$scene_name.gin --gin_bindings="Config.render_step = 50000"
    python -m render --gin_configs=configs/$scene_name.gin --gin_bindings="Config.render_step = 100000"
done