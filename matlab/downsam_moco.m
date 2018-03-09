data='E:\MJData\';
cd(data);
folder=dir();
for i=1:length(folder)
    if ~strcmp(folder(i).name, '.') && ~strcmp(folder(i).name, '..')
        datadir=[data, folder(i).name];
        stitchTiffs_registered(datadir,3, 'registered','registered','stitched',1000, 1);
        
    end
end