function CBIG_Yeo2011_generate_example_results(output_dir, sub_list, code_dir, surf_stem, outlier_stem, fs_dir)

% CBIG_Yeo2011_generate_example_results(output_dir)
%
% This function is a matlab wrapper to run the csh script to generate the
% example results for Yeo2011. 
% See README file for more details about the example: 
% $CBIG_CODE_DIR/stable_projects/brain_parcellation/Yeo2011_fcMRI_clustering/examples/README.md
%
% Input:
%     - output_dir:
%       The output directory where example results are saved.
%     - sub_list:
%       txt file with subject IDs
%     - code_dir:
%       Path to scripts
%     - surf_stem:
%       Prefix of bold images
%     - fs_dir
%       Path to freesurfer
%
% Written by XUE Aihuiping and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

script_dir = fileparts(mfilename('/Users/jperaza/Documents/GitHub/adolescent-brain-parcellation/scripts'));
if(~exist(output_dir, 'dir'))
    mkdir(output_dir)
end

% Run the example
cmd = [fullfile(script_dir, './CBIG_Yeo2011_example.csh'), ' ', output_dir, sub_list, code_dir, surf_stem, outlier_stem];
system(cmd);

out_file = fullfile(output_dir, 'clustering', 'HNU_example_clusters017_scrub.mat');
if(~exist(out_file, 'file'))
    error('Fail to generate final output')
end

end


