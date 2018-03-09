
data='E:\MJData\';
cd(data);
folder=dir();
for i=1:length(folder)
    if ~strcmp(folder(i).name, '.') && ~strcmp(folder(i).name, '..')
        datadir=[data, folder(i).name, '\'];
        loadxysavefluo_func(datadir);
        
    end
end
