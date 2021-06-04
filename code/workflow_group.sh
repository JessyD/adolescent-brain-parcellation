#!/bin/bash

pwd; hostname; date
set -e

#==============Shell script==============#
# Load the software needed
# module load matlab

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
mkdir -p ${PARCELLAITON_DIR}/group
task='rest'

corr_profiles=($(find ${PARCELLAITON_DIR}/sub-*/ses-*/surf -name *surf2surf-profile.mat))
corr_profiles_list=${PARCELLAITON_DIR}/group/group-average_task-${task}_surf2surf-profile_list.txt
rm -f ${corr_profiles_list}
for profile in ${corr_profiles[@]}; do
    echo ${profile} >> ${corr_profiles_list}
done

mesh_name='fs_LR_32k'
mask='NONE'
num_clusters=17;
output_file=${PARCELLAITON_DIR}/group/parcellation-${num_clusters}_task-${task}.mat
profile1=${PARCELLAITON_DIR}/group/group-average_task-${task}_surf2surf-profile.mat
profile2='NONE';
num_smooth='0';
num_tries='1000';
normalize='0';
max_iter='100';
no_silhouette='1';

echo "Start=================================="
echo "Compute Average Correlation Profile for ${#corr_profiles[@]} subjects of task: ${task}"
echo "Cluster analysis using ${num_clusters} clusters for ${profile1}"
if [ -e ${output_file} ]; then
	echo "Outputs already exist. Skipping......"
else
	cmd="$MATLAB -nodesktop -nodisplay -nosplash -r "
	cmd="$cmd \" addpath(genpath(fullfile('$CBIG_CODE_DIR')));"

    cmd="$cmd ComputeAverageCorrelationProfile('${corr_profiles_list}', '${profile1}');"

	cmd="$cmd CBIG_VonmisesSeriesClustering_fix_bessel_randnum_bsxfun('${mesh_name}', '${mask}',"
	cmd="$cmd '${num_clusters}', '${output_file}', '${profile1}', '${profile2}', '${num_smooth}',"
    cmd="$cmd '${num_tries}', '${normalize}', '${max_iter}', '${no_silhouette}'); exit; \" "
	
	echo Commandline: $cmd
	eval $cmd
	exitcode=$?
fi

echo Finished group task with exit code $exitcode
date