#!/bin/bash

set -e
###############
# Variables
export MATLAB_DIR=/Applications/MATLAB_R2020b.app
export PATH=$MATLAB_DIR/bin:$PATH
MATLAB=$(which matlab)
export CBIG_CODE_DIR=/Users/jperaza/Documents/GitHub/adolescent-brain-parcellation/code/CBIG
BIDS_DIR="/Users/jperaza/Documents/GitHub/adolescent-brain-parcellation-old/dataset/abcd"
DERIVS_DIR=${BIDS_DIR}/derivatives
DCAN_DIR=${DERIVS_DIR}/abcd-hcp-pipeline
PARCELLAITON_DIR=${DERIVS_DIR}/abcd-yeo-parcellation
mkdir -p ${PARCELLAITON_DIR}

bolds_list=$1
bolds=(`cat $sub_list`)
# bold=${bolds[${SLURM_ARRAY_TASK_ID} - 1]}
bold=${bolds[0}

base=$(basename ${bold})
tempboldfile="${base%%.*}"
sub=$(echo ${base} | awk -F'-' '{print $2}' | awk -F'_' '{print $1}')
ses=$(echo ${base} | awk -F'-' '{print $3}' | awk -F'_' '{print $1}')
echo "Processing sub: ${sub}, ses: ${ses}, file: ${tempboldfile}"

###########################
# compute correlation profile
###########################
mkdir -p ${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/surf
scrub_flag=1
scrub_thr=0.2
seed_mesh='fs_LR_900'
target='fs_LR_32k'
output_file1=${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/surf/${tempboldfile}_surf2surf-profile.mat
output_file2='NONE'
threshold='0.1'
varargin_file1=${DCAN_DIR}/sub-${sub}/ses-${ses}/func/${tempboldfile}.dtseries.nii
varargin_file2='NONE'
split_data='0'

echo "Start=================================="
if [ -e ${output_file1} && -e ${output_file2} ]; then
	echo "Outputs already exist. Skipping......"
else
	set cmd = ( $MATLAB_DIR -nodesktop -nodisplay -nosplash -r '"')
	set cmd = ($cmd 'addpath(genpath(fullfile('"'"$CBIG_CODE_DIR"'"')));')

	set cmd = ($cmd CBIG_ComputeCorrelationProfile "'"${seed_mesh}"'" "'"${target}"'")
	set cmd = ($cmd  "'"${output_file1}"'" "'"${output_file2}"'" "'"${threshold}"'")
	set cmd = ($cmd "'"${varargin_file1}"'" "'"${varargin_file2}"'")
	
	if [ $scrub_flag == 1 ]; then
		## Generate outlier file
		mkdir -p ${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/qc
		outlier_text=${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/qc/${tempboldfile}_outliers-motion.txt
		rm -f ${outlier_text}
		qualities=($(ls ${DCAN_DIR}/sub-${subj}/ses-${ses}/func/sub-${subj}_ses-${ses}_task-rest_run-*_desc-filteredincludingFD_motion.tsv))
		for quality in ${qualities[@]}; do
			FDs=($(cut -f1 ${quality} | awk '{print $NF}'))
			for (( i = 4; i < ${#FDs[@]}; i++ )); do
				# echo ${FDs[i]}'<'${scrub_thr} | bc -l >> ${outlier_text}
				echo $(echo ${FDs[i]} ${scrub_thr} | awk '{if ($1 < $2) print 1; else print 0}') >> ${outlier_text}
			done
		done
		# Add outlier argument to matlab cmd and exit
		set cmd = ($cmd "'"${outlier_text}"'"'; exit;''"')
	else
		set cmd = ($cmd '; exit;''"')
	fi
	eval $cmd
fi