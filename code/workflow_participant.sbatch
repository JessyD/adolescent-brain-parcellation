#!/bin/bash
#SBATCH --job-name=abcd-parcellation
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4gb
#SBATCH --account=iacc_nbc
#SBATCH --qos=pq_nbc
#SBATCH --partition=investor
# Outputs ----------------------------------
#SBATCH --output=log/abcd-parcellation-%j-%A-%a.out   
#SBATCH --error=log/abcd-parcellation-%j-%A-%a.err   
#SBATCH --mail-type=ALL,ARRAY_TASKS
#SBATCH --mail-user=jperaza@fiu.edu
# ------------------------------------------

pwd; hostname; date
set -e

#==============Shell script==============#
# Load the software needed
module load matlab-2019b

###############
# Variables
MATLAB=$(which matlab)
WB_DIR=/home/jpera054/Documents/workbench/bin_rh_linux64
export CBIG_CODE_DIR=/home/jpera054/Documents/abcd-parcellation/code/CBIG
BIDS_DIR="/home/jpera054/Documents/abcd-parcellation"
DERIVS_DIR=${BIDS_DIR}/derivatives
DCAN_DIR=${DERIVS_DIR}/abcd-hcp-pipeline
PARCELLAITON_DIR=${DERIVS_DIR}/abcd-yeo-parcellation

bolds_list=$1
bolds=(`cat $bolds_list`)
bold_id=${bolds[${SLURM_ARRAY_TASK_ID} - 1]}

sub=$(echo ${bold_id} | awk -F'_' '{print $1}' | awk -F'-' '{print $2}')
ses=$(echo ${bold_id} | awk -F'_' '{print $2}' | awk -F'-' '{print $2}')
task=rest
sufix="task-rest_bold_desc-filtered_timeseries"
sm_sufix="task-rest_bold_desc-filteredSM6mm_timeseries"

###########################
# Smooth
if [ -e ${DCAN_DIR}/sub-${sub}/ses-${ses}/func/${bold_id}_${sm_sufix}.dtseries.nii ]; then
	echo "Outputs already exist. Skipping......"
else
	export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
	Sigma=`awk 'BEGIN { SmoothingFWHM = 6; print SmoothingFWHM / ( 2 * ( sqrt ( 2 * log( 2 ) ) ) ) }'`
	echo "Smoothing 6mm: Sigma = $Sigma"
	${WB_DIR}/wb_command -cifti-smoothing \
	    ${DCAN_DIR}/sub-${sub}/ses-${ses}/func/${bold_id}_${sufix}.dtseries.nii \
	    ${Sigma} \
	    ${Sigma} \
	    COLUMN \
	    ${DCAN_DIR}/sub-${sub}/ses-${ses}/func/${bold_id}_${sm_sufix}.dtseries.nii \
	    -left-surface ${DCAN_DIR}/sub-${sub}/ses-${ses}/anat/sub-${sub}_ses-${ses}_hemi-L_space-MNI_mesh-fsLR32k_midthickness.surf.gii \
	    -right-surface ${DCAN_DIR}/sub-${sub}/ses-${ses}/anat/sub-${sub}_ses-${ses}_hemi-R_space-MNI_mesh-fsLR32k_midthickness.surf.gii
fi

###########################
# compute correlation profile
###########################
mkdir -p ${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/surf
scrub_flag=1
scrub_thr='0.2'
seed_mesh='fs_LR_900'
target='fs_LR_32k'
output_file1=${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/surf/${bold_id}_task-${task}_surf2surf-profile.mat
output_file2='NONE'
threshold='0.1'
varargin_file1=${DCAN_DIR}/sub-${sub}/ses-${ses}/func/${bold_id}_${sm_sufix}.dtseries.nii
varargin_file2='NONE'
split_data='0'

echo "Start=================================="
echo "Compute Correlation Profile for sub: ${sub}, ses: ${ses}, task: ${task}"
if [ -e ${output_file1} ]; then
	echo "Outputs already exist. Skipping......"
else
	cmd="$MATLAB -nodesktop -nodisplay -nosplash -r "
	cmd="$cmd \" addpath(genpath(fullfile('$CBIG_CODE_DIR')));"
	
	if [ $scrub_flag == 1 ]; then
		## Generate outlier file from *motion_mask.mat
		mkdir -p ${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/qc
		outlier_text=${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/qc/${bold_id}_task-${task}_outliers-motion${scrub_thr}.txt
		if [ -e ${outlier_text} ]; then
			echo "Outlier text file already exist. Skipping......"
		else
			mask_file=${DCAN_DIR}/sub-${sub}/ses-${ses}/func/sub-${sub}_ses-${ses}_task-${task}_desc-filtered_motion_mask.mat
			cmd="$cmd MotionMask2TXT('${mask_file}', '${outlier_text}', '${scrub_thr}');"
		fi
	fi


	cmd="$cmd CBIG_ComputeCorrelationProfile('${seed_mesh}', '${target}', '${output_file1}',"
	cmd="$cmd '${output_file2}', '${threshold}', '${varargin_file1}', '${varargin_file2}'"

	if [ $scrub_flag == 1 ]; then
		# Add outlier argument to matlab cmd and exit
		cmd="$cmd, '${outlier_text}'); exit; \" "
	else
		cmd="$cmd); exit; \" "
	fi
	echo Commandline: $cmd
	eval $cmd
	exitcode=$?
fi

echo Finished tasks ${SLURM_ARRAY_TASK_ID} with exit code $exitcode
date