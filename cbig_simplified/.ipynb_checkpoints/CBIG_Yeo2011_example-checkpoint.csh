#!/bin/csh
# Written by CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

#set output_dir = "/Users/jperaza/Documents/GitHub/adolescent-brain-parcellation/dataset/yeo"
#set sub_list = "/Users/jperaza/Documents/GitHub/adolescent-brain-parcellation/scripts/example_sub_list.txt"
#set code_dir = "/Users/jperaza/Documents/GitHub/adolescent-brain-parcellation/scripts"
#set surf_stem = "_rest_skip4_stc_mc_residc_interp_FDRMS0.2_DVARS50_bp_0.009_0.08_fs6_sm6_fs5"
#set outlier_stem = "_FDRMS0.2_DVARS50_motion_outliers"
set surf_stem = "_task-rest_desc-filtered_sm6_space-fsaverage5_timeseries"
set outlier_stem = "_FDRMS0.2_motion_outliers"
#set CBIG_CODE_DIR=/Users/jperaza/Documents/GitHub/adolescent-brain-parcellation/scripts
#setenv CBIG_CODE_DIR /Users/jperaza/Documents/GitHub/adolescent-brain-parcellation/scripts

set output_dir = $1
set sub_list = $2
set subjects = `cat $sub_list`
set code_dir = $3
set data_dir = $4
#set surf_stem = $4
#set outlier_stem = $5
#setenv CBIG_MATLAB_DIR /Applications/MATLAB_R2020b.app
#setenv CBIG_CODE_DIR ${code_dir}
#setenv FREESURFER_DIR $6

## Create folder structure within output_dir, and make soft links of input files to orig_data_dir
# Make sure that the data is inside the output/subjects

## Call wrapper function
mkdir -p $output_dir/clustering
${code_dir}/CBIG_Yeo2011_general_cluster_fcMRI_surf2surf_profiles.csh \
-sd ${output_dir}/subjects -sub_ls ${sub_list} -surf_stem ${surf_stem} \
-n 17 -out_dir ${output_dir}/clustering \
-cluster_out ${output_dir}/clustering/HNU_example_clusters017_scrub.mat \
-tries 5 -outlier_stem ${outlier_stem}
