main_dir='F:\Raw Data from Variable Reward Task (MJS for HW)\'


subdir=dir(main_dir);
cd(main_dir);
for i =1:length(subdir)
    if subdir(i).isdir && ~(isequal(subdir(i).name,'.')) && ~(isequal(subdir(i).name,'..'))
        wholepath=strcat(main_dir,subdir(i).name);
        stitchTiffs_func(wholepath, 3,'raw_green','raw_green','rigistered_green_noMC',1000,5)
        stitchTiffs_func(wholepath, 3,'raw_red','raw_red','rigistered_red_noMC',1000,5)
        
    end
end
