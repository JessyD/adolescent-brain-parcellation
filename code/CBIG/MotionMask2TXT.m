function MotionMask2TXT(mask_file, outlier_text, FD_threshold)
% Based on https://github.com/DCAN-Labs/cifti-connectivity/blob/master/src/cifti_conn_matrix_exaversion.m

if isnumeric(FD_threshold)==1
else
    FD_threshold = str2num(FD_threshold);
end

motion_data = load(mask_file).motion_data;
allFD = zeros(1,length(motion_data));
for j = 1:length(motion_data)
    allFD(j) = motion_data{j}.FD_threshold;
end
FDidx = find(round(allFD,3) == round(FD_threshold,3));
FDvec = motion_data{FDidx}.frame_removal;
FDvec = abs(FDvec-1);
writematrix(FDvec, outlier_text)