#!/bin/bash
#SBATCH --job-name=abcd-parcellation
#SBATCH --time=80:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10gb
#SBATCH --account=iacc_nbc
#SBATCH --qos=pq_nbc
#SBATCH --partition=investor
# Outputs ----------------------------------
#SBATCH --output=log/abcd-parcellation-%j.out
#SBATCH --error=log/abcd-parcellation-%j.err
#SBATCH --mail-type=ALL
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
# For 7 cluster use '07'
num_clusters='17'
output_file=${PARCELLAITON_DIR}/group/parcellation-${num_clusters}_task-${task}.mat
profile1=${PARCELLAITON_DIR}/group/group-average_task-${task}_surf2surf-profile.mat
profile2='NONE'
num_smooth='0'
num_tries='1000'
normalize='0'
max_iter='100'
no_silhouette='1'

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

# Plot Figure
output_fig=${PARCELLAITON_DIR}/group/parcellation-${num_clusters}_task-${task}.jpg
if [ -e ${output_fig} ]; then
	echo "Outputs already exist. Skipping......"
else
	ref_file=${CBIG_CODE_DIR}/data/1000subjects_reference/1000subjects_clusters0${num_clusters}_ref.mat
	
	cmd="$MATLAB -nodesktop -nodisplay -nosplash -r "
	cmd="$cmd \" addpath(genpath(fullfile('$CBIG_CODE_DIR')));"

    cmd="$cmd VisualizeCluster('${output_file}', '${num_clusters}', '${ref_file}',"
	cmd="$cmd '${mesh_name}', '${output_fig}'); exit; \" "
	
	echo Commandline: $cmd
	eval $cmd
fi

echo Finished group task with exit code $exitcode
date