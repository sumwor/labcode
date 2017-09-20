% This is an utility to load the .mat file generated by CellROI, modify
% variables, and then re-save. 
%
% Motivation for making this utility is that early version of cellROI saved the area-summed pixel value as cellf,
% whereas later version of cellROI (circa 2016 and on) saved the per-pixel value as cellf. This is a way to load 
% the old .mat file and re-save them into the new format.
%
% 
% Kwan Lab,11/30/2016
% 
% edit 12/2/2016: also some .mat files saved as cell1.mat, whereas new cellROI saves them as cell001.mat

clear all;
 
data_dir = '/Users/alexkwan/Desktop/Clean data set/Data M2/';

%ask user where to load and where to save
h=msgbox('Select the directory with reference ROI .mat files');
uiwait(h);
load_dir=uigetdir(data_dir,'Select the directory with reference ROI .mat files');

h=msgbox('Select the directory to save the modified ROI .mat files');
uiwait(h);
save_dir=uigetdir(data_dir,'Select the directory with reference ROI .mat files');

%check to see how many ROIs there are
cd(load_dir);
roifiles=dir('*cell*.mat');

cellmask=[]; neuropilmask=[]; isred=[];
for k=1:numel(roifiles)
    clear bw cellf cellxall cellyall neuropilf neuropilmask subtractmask;
    
    %load the old file
    cd(load_dir);
    load(roifiles(k).name);

    %----- !!! divide the cellf and neuropilf so they are per-pixel
    %----- !!! only use this if the original .mat is from legacy cellROI
%     cellf=cellf/sum(sum(bw));
%     if exist('neuropilf','var')
%         neuropilf=neuropilf/sum(sum(neuropilmask));
%     end
    %-----
    
    %older version of cellROI saves the binary mask for neuropil as
    %'neuropilmask', whereas new version saves it as 'subtractmask'
    if exist('neuropilmask','var')
        subtractmask=neuropilmask;
    end
    
    %older version of cellROI saves with filename e.g. cell1.mat
    %everything should be e.g. cell001.mat instead
    tempidx=findstr(roifiles(k).name,'_cell');
    filenameCellNum=str2num(roifiles(k).name(tempidx+5:end-4)); %isolate the number
    savefilename=[roifiles(k).name(1:tempidx-1) '_cell' num2str(filenameCellNum,'%03i') '.mat'];
        
    %save the new file
    cd(save_dir);
    if exist('neuropilf','var') && exist('isRedCell','var')
        save(savefilename,'bw','cellf','cellxall','cellyall','neuropilf','subtractmask','isRedCell');
    elseif exist('neuropilf','var')
        save(savefilename,'bw','cellf','cellxall','cellyall','neuropilf','subtractmask');
    else
        save(savefilename,'bw','cellf','cellxall','cellyall');
    end
end

disp(['Processed ' int2str(numel(roifiles)) ' ROIs --- All done!']);