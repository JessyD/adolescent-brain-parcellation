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

###########################
# compute correlation profile
###########################
mkdir -p ${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/surf
scrub_flag=1
scrub_thr=0.2
seed_mesh='fs_LR_900'
target='fs_LR_32k'
output_file1=${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/surf/${bold_id}_task-${task}_surf2surf-profile.mat
output_file2='NONE'
threshold='0.1'
varargin_file1=${DCAN_DIR}/sub-${sub}/ses-${ses}/func/${bold_id}_${sufix}.dtseries.nii
varargin_file2='NONE'
split_data='0'

echo "Start=================================="
echo "Compute Correlation Profile for sub: ${sub}, ses: ${ses}, task: ${task}"
if [ -e ${output_file1} ]; then
	echo "Outputs already exist. Skipping......"
else
	cmd="$MATLAB -nodesktop -nodisplay -nosplash -r "
	cmd="$cmd \" addpath(genpath(fullfile('$CBIG_CODE_DIR')));"

	cmd="$cmd CBIG_ComputeCorrelationProfile('${seed_mesh}', '${target}', '${output_file1}',"
	cmd="$cmd '${output_file2}', '${threshold}', '${varargin_file1}', '${varargin_file2}'"
	
	if [ $scrub_flag == 1 ]; then
		## Generate outlier file
		mkdir -p ${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/qc
		outlier_text=${PARCELLAITON_DIR}/sub-${sub}/ses-${ses}/qc/${bold_id}_task-${task}_outliers-motion.txt
		#rm -f ${outlier_text}
		if [ -e ${outlier_text} ]; then
			echo "Outlier text file already exist. Skipping......"
		else
			qualities=($(ls ${DCAN_DIR}/sub-${sub}/ses-${ses}/func/sub-${sub}_ses-${ses}_task-${task}_run-*_desc-filteredincludingFD_motion.tsv))
			for quality in ${qualities[@]}; do
				FDs=($(cut -f1 ${quality} | awk '{print $NF}'))
				for (( i = 4; i < ${#FDs[@]}; i++ )); do
					# echo ${FDs[i]}'<'${scrub_thr} | bc -l >> ${outlier_text}
					echo $(echo ${FDs[i]} ${scrub_thr} | awk '{if ($1 < $2) print 1; else print 0}') >> ${outlier_text}
				done
			done
		fi
		# Add outlier argument to matlab cmd and exit
		cmd="$cmd, '${outlier_text}'); exit; \" "
	else
		cmd="$cmd); exit; \" "
	fi
	echo Commandline: $cmd
	eval $cmd
	exitcode=$?
fi

#echo Finished tasks ${SLURM_ARRAY_TASK_ID} with exit code $exitcode
echo Finished tasks 2 with exit code $exitcode
date