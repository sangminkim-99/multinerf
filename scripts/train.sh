#!/bin/bash
# usage: bash train.sh gpu_id scene_file.txt
#       ex. bash train.sh 1,2,3 scenes.txt

filename=$2
scene_names=()
while read line; do
    # read each line
    scene_names+=($line)
done < $filename

gpu_tokens=($(echo "$1" | tr ',' '\n')) # split available gpu ids
gpu_ids=()
for gpu_id in ${gpu_tokens[@]}
do
    gpu_ids+=($gpu_id)
done

pids=() # init pid array
running_gpu_ids=() # init current running gpus

for scene_name in ${scene_names[@]}
do
    # if there is no available gpu, then wait until any process finishes
    while [ ${#gpu_ids[@]} -eq ${#running_gpu_ids[@]} ]
    do
        sleep 1
        for i in ${!pids[@]}
        do
            # check i-th job is finished
            if ! kill -0 ${pids[$i]} 2>/dev/null; then
                running_gpu_ids=( "${running_gpu_ids[@]:0:$i}" "${running_gpu_ids[@]:$((i + 1))}" )
                pids=( "${pids[@]:0:$i}" "${pids[@]:$((i + 1))}" )
                break
            fi
        done
    done
    # train on the empty gpu
    empty_gpu=("${gpu_ids[@]}")
    for running_gpu in ${running_gpu_ids[@]}
    do
        empty_gpu=(${empty_gpu[@]/$running_gpu})
    done

    empty_gpu=${empty_gpu[0]}
    ###########################
    ##### GPU Assignment ######
    ###########################
    export CUDA_VISIBLE_DEVICES="$empty_gpu,$((empty_gpu + 1))"
    running_gpu_ids+=($empty_gpu)

    ###########################
    #######  Main Code  #######
    ###########################
    python -m train --gin_configs=configs/$scene_name.gin --logtostderr & # train on background
    pids+=($!)

    echo "${scene_name} is running on gpu ${CUDA_VISIBLE_DEVICES} with pid ${!}"
done