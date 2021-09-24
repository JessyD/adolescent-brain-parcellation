#!/bin/bash
# ------------------------------------------

pwd; hostname; date
set -e

#==============Shell script==============#
# Load the software needed
module load matlab/2020b
module load connectome-workbench/1.5.0

###############
# Variables
MATLAB=$(which matlab)
WB_DIR=/usr/local/apps/connectome-workbench/1.5.0/workbench/bin_rh_linux64
export CBIG_CODE_DIR=/data/jdafflon/adolescent-brain-parcellation/code/CBIG
BIDS_DIR="/data/ABCD_MBDU/abcd_bids/bids"
DERIVS_DIR=${BIDS_DIR}/derivatives
DCAN_DIR=${DERIVS_DIR}/abcd-hcp-pipeline
OUTDIR=/data/NIMH_scratch/abcd_parcellation/abcd_mbdu
PARCELLATION_DIR=${OUTDIR}/abcd-yeo-parcellation

bolds_list=$1
bolds=(`cat $bolds_list`)
#bold_id=${bolds[${SLURM_ARRAY_TASK_ID} - 1]}

missing_subjs=()
for bold_id in $(cat $bolds_list); do
    echo " "
    echo "$bold_id"
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
        FILTERED_DIR=${PARCELLATION_DIR}/sub-${sub}/ses-${ses}/func
        # Check if the current subject has data, if not proceed to next
        if [ -e ${DCAN_DIR}/sub-${sub}/ses-${ses}/func/${bold_id}_${sufix}.dtseries.nii ]; then
            # Create output folder to save the smoothed images
            mkdir -p ${FILTERED_DIR}
            Sigma=`awk 'BEGIN { SmoothingFWHM = 6; print SmoothingFWHM / ( 2 * ( sqrt ( 2 * log( 2 ) ) ) ) }'`
            echo "Smoothing 6mm: Sigma = $Sigma"
            ${WB_DIR}/wb_command -cifti-smoothing \
                ${DCAN_DIR}/sub-${sub}/ses-${ses}/func/${bold_id}_${sufix}.dtseries.nii \
                ${Sigma} \
                ${Sigma} \
                COLUMN \
                ${FILTERED_DIR}/${bold_id}_${sm_sufix}.dtseries.nii \
                -left-surface ${DCAN_DIR}/sub-${sub}/ses-${ses}/anat/sub-${sub}_ses-${ses}_hemi-L_space-MNI_mesh-fsLR32k_midthickness.surf.gii \
                -right-surface ${DCAN_DIR}/sub-${sub}/ses-${ses}/anat/sub-${sub}_ses-${ses}_hemi-R_space-MNI_mesh-fsLR32k_midthickness.surf.gii
        else
            echo "${sub} does not have ${bold_id}_${sufix}.dtseries.nii"
            missing_subjs+=(sub-${sub})
            continue
        fi
    fi
    ###########################
    # compute correlation profile
    ###########################
    mkdir -p ${PARCELLATION_DIR}/sub-${sub}/ses-${ses}/surf
    scrub_flag=1
    scrub_thr='0.2'
    seed_mesh='fs_LR_900'
    target='fs_LR_32k'
    output_file1=${PARCELLATION_DIR}/sub-${sub}/ses-${ses}/surf/${bold_id}_task-${task}_surf2surf-profile.mat
    output_file2='NONE'
    threshold='0.1'
    varargin_file1=${FILTERED_DIR}/${bold_id}_${sm_sufix}.dtseries.nii
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
            mkdir -p ${PARCELLATION_DIR}/sub-${sub}/ses-${ses}/qc
            outlier_text=${PARCELLATION_DIR}/sub-${sub}/ses-${ses}/qc/${bold_id}_task-${task}_outliers-motion${scrub_thr}.txt
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
    fi
    echo Finished tasks ${bold_id}
done

# Print list of missing files and save it
echo "Subjects with missing input data: ${missing_subjs[@]}"
printf  "%s\n" "${missing_subjs[@]}" > missing_subjs.txt
date
