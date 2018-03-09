
data='E:\MJData\';
cd(data);
folder=dir();
for i=1:length(folder)
    if ~strcmp(folder(i).name, '.') && ~strcmp(folder(i).name, '..')
        datadir=[data, folder(i).name];
        getGreen_func(datadir);
        getRed_func(datadir);
        
        %stitch
        stitchTiffs_func(datadir,3, 'raw_green','raw_green','stitchedGreen',1000, 8);
        stitchTiffs_func(datadir,3, 'raw_red','raw_red','stitchedRed',1000, 8);
    end
end
