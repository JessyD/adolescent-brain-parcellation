function ComputeAverageCorrelationProfile(corr_profiles_list, ave_profile1)

% read in files
fid = fopen(corr_profiles_list, 'r');
i = 0;
while(1)
   tmp = fscanf(fid, '%s\n', 1);
   if(isempty(tmp))
       break
   else
       i = i + 1;
       varargin{i} = tmp;
   end
end
fclose(fid);

tic
for i = 1:length(varargin)
  disp([num2str(i) ': ' varargin{i}]);
  x = load(varargin{i});
    if(sum(isnan(x.profile_mat(:))) > 0)
      disp(['Warning: ' varargin{i} ' contains ' num2str(sum(isnan(x.vol(:)))) ' isnan .']);
    end
    
  if(i == 1)
    output = x;
  else
    output.profile_mat = output.profile_mat + x.profile_mat;
  end
end
toc
clear x;
profile_mat = output.profile_mat/length(varargin);
save(ave_profile1, 'profile_mat', '-v7.3');
