basePath='F:\Raw Data from Variable Reward Task (MJS for HW)\';
cd(basePath);
dirs = dir(basePath);

%isub = [dirs(:).isdir]; %# returns logical vector
%nameFolds = {dirs(isub).name}';

%nameFolds(ismember(nameFolds,{'.','..'})) = [];

for i = 1:length(dirs)
    if ~strcmp(dirs(i).name, '.') & ~strcmp(dirs(i).name,'..')
        path=[basePath,dirs(i).name,'\'];
        stitchTiffs_func(path,3, 'raw_green','raw_green','stitched', 1000, 5);
        stitchTiffs_func(path,3, 'raw_red','raw_red','stitched_redChan',1000, 5);
    end
end
