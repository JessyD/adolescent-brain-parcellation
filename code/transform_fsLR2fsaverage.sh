#!/usr/bin/env bash

set -e

# Variables
WB_DIR=/shared/project-brain-parcellation/software/workbench/bin_linux64
DATA_DIR="/shared/project-brain-parcellation/data/input/derivatives/abcd-hcp-pipeline"
OUT_DIR="/shared/project-brain-parcellation/data/output/abcd-yeo-parcellation"
TEMPLATE_DIR="/shared/project-brain-parcellation/data/templates/standard_mesh_atlases/resample_fsaverage"

export OMP_NUM_THREADS=1

bold=$1
THR=0.2

#SmoothingFWHM=6
#Sigma=`echo "$SmoothingFWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l`
Sigma=`awk 'BEGIN { SmoothingFWHM = 6; print SmoothingFWHM / ( 2 * ( sqrt ( 2 * log( 2 ) ) ) ) }'`

surf_stem="_task-rest_desc-filtered_sm6_space-fsaverage5_timeseries"
outlier_stem="_FDRMS0.2_motion_outliers"


base=$(basename ${bold})
tempboldfile="${base%%.*}"

subj=$(echo ${base} | awk -F'-' '{print $2}' | awk -F'_' '{print $1}')
ses=$(echo ${base} | awk -F'-' '{print $3}' | awk -F'_' '{print $1}')
echo "Processing sub: ${subj}, ses: ${ses}, file: ${tempboldfile}"

mkdir -p ${OUT_DIR}/subjects/subj${subj}_sess${ses}/logs
mkdir -p ${OUT_DIR}/subjects/subj${subj}_sess${ses}/qc
mkdir -p ${OUT_DIR}/subjects/subj${subj}_sess${ses}/surf
for hemis in rh lh; do
	temp_dir=${OUT_DIR}/subjects/subj${subj}_sess${ses}/temp
	mkdir -p ${temp_dir}
	if [ ${hemis} == 'lh' ]; then
		surface2smooth_on="${TEMPLATE_DIR}/fs_LR.L.midthickness_va_avg.32k_fs_LR.shape.gii"
        structure='CORTEX_LEFT'
        current_sphere="${TEMPLATE_DIR}/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii"
		new_sphere="${TEMPLATE_DIR}/fsaverage5_std_sphere.L.10k_fsavg_L.surf.gii"
		current_area="${TEMPLATE_DIR}/fs_LR.L.midthickness_va_avg.32k_fs_LR.shape.gii"
		new_area="${TEMPLATE_DIR}/fsaverage5.L.midthickness_va_avg.10k_fsavg_L.shape.gii"
    elif [ ${hemis} == 'rh' ]; then
        structure='CORTEX_RIGHT'
        current_sphere="${TEMPLATE_DIR}/fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii"
        new_sphere="${TEMPLATE_DIR}/fsaverage5_std_sphere.R.10k_fsavg_R.surf.gii"
        current_area="${TEMPLATE_DIR}/fs_LR.R.midthickness_va_avg.32k_fs_LR.shape.gii"
		new_area="${TEMPLATE_DIR}/fsaverage5.R.midthickness_va_avg.10k_fsavg_R.shape.gii"
    fi

    # Get the surface timeseries from cifti
	${WB_DIR}/wb_command -cifti-separate \
		${bold} \
		COLUMN \
		-metric ${structure} \
		${temp_dir}/${tempboldfile}.func.gii
		
	# Spatial smoothing
	${WB_DIR}/wb_command -metric-smoothing \
		${current_sphere} \
		${temp_dir}/${tempboldfile}.func.gii \
	 	$Sigma \
	 	${temp_dir}/${tempboldfile}_sm6.func.gii
		
	# Resampling to fsaverage5
	${WB_DIR}/wb_command -metric-resample \
		${temp_dir}/${tempboldfile}_sm6.func.gii \
		${current_sphere} \
		${new_sphere} \
		ADAP_BARY_AREA \
		${temp_dir}/${tempboldfile}_sm6_space-fsaverage5.func.gii \
		-area-metrics \
		${current_area} \
		${new_area}
	
	# Convert to nifti1
	${WB_DIR}/wb_command -metric-convert \
	    -to-nifti \
	    ${temp_dir}/${tempboldfile}_sm6_space-fsaverage5.func.gii \
	    ${temp_dir}/${hemis}.subj${subj}_sess${ses}_bld002${surf_stem}.nii.gz

	# Name it in Yeo's code format
	cp ${temp_dir}/${hemis}.subj${subj}_sess${ses}_bld002${surf_stem}.nii.gz \
		${OUT_DIR}/subjects/subj${subj}_sess${ses}/surf/

	rm -r ${temp_dir}
done

echo "002" > ${OUT_DIR}/subjects/subj${subj}_sess${ses}/logs/subj${subj}_sess${ses}.bold

# Write outlier fiels from .tsv
rm -f ${OUT_DIR}/subjects/subj${subj}_sess${ses}/qc/subj${subj}_sess${ses}_bld002${outlier_stem}.txt
qualities=($(ls ${DATA_DIR}/sub-${subj}/ses-${ses}/func/sub-${subj}_ses-${ses}_task-rest_run-*_desc-filteredincludingFD_motion.tsv))
for quality in ${qualities[@]}; do
	FDs=($(cut -f1 ${quality} | awk '{print $NF}'))
	for (( i = 4; i < ${#FDs[@]}; i++ )); do
		# echo ${FDs[i]}'<'${THR} | bc -l >> ${OUT_DIR}/subjects/subj${subj}_sess${ses}/qc/subj${subj}_sess${ses}_bld002${outlier_stem}.txt
		echo $(echo ${FDs[i]} ${THR} | awk '{if ($1 < $2) print 1; else print 0}') >> ${OUT_DIR}/subjects/subj${subj}_sess${ses}/qc/subj${subj}_sess${ses}_bld002${outlier_stem}.txt
	done
done
echo "Finish sub: ${subj}, ses: ${ses}"
