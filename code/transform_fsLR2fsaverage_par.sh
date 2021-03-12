#!/usr/bin/env bash

set -e
DATA_DIR="/shared/project-brain-parcellation/data/input/derivatives/abcd-hcp-pipeline"
bolds=($(find ${DATA_DIR}/sub-*/ses-*/func -name *timeseries.dtseries.nii))

# for bold in ${bolds[@]}; do nohup bash transform_fsLR2fsaverage.sh ${bold} & done
# ${#bolds[@]}
for (( i = 2; i < 11; i++ )); do 
	echo ${bolds[i]}
	./transform_fsLR2fsaverage.sh ${bolds[i]} 
done

# ./transform_fsLR2fsaverage.sh ${bolds[1]}
