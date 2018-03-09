function loadxysavefluo_func(filepath)
% This is Step 4 for processing calcium imaging data.
%
% After Step 3: ROI selection in Matlab GUI -->
% Take the selected ROI, go back to the motion-corrected image files, and extract signal
%
% AC Kwan, 11/19/2016


tic;
 
%% create directory structure for loading and saving files

%default values
default_scim_ver = '3';
default_data_dir = filepath;
%default_scim_ver = '5';
%default_data_dir = '/Users/alexkwan/Desktop/ongoing data analysis/ROI extraction/testdata_resonant/';
default_reg_subdir = 'registered';

%ask user
%prompt = {'ScanImage verison (3 or 5):','Root directory (for saving):','Subdirectory with registered .tiff images (to be analyzed):'};
%dlg_title = 'Load ROIs and extract signals from registered images';
%num_lines = 1;
%defaultans = {default_scim_ver,default_data_dir,default_reg_subdir};
%answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
scim_ver=3;
data_dir=filepath;
reg_subdir='registered';

%h=msgbox('Select the directory with reference ROI .mat files');
%uiwait(h);
save_dir=[filepath,'stitched'];

%% load the ROI masks
cd(save_dir);
folder=dir();
for i=1:length(folder)
    if ~strcmp(folder(i).name, '.') && ~strcmp(folder(i).name, '..') && isdir(folder(i).name)
        cd(folder(i).name)
        roifiles=dir('*.mat');
    end
end

cellmask=[];
for k=1:numel(roifiles)
    load(roifiles(k).name);

    cellmask(:,:,k)=bw;
    neuropilmask(:,:,k)=subtractmask;
    isred(k)=isRedCell;
end
clear bw subtractmask;

%% do we want to shift the ROI masks in x,y (e.g. use same masks for longitudinal data)
% nudge=1;
% curr_x=0; curr_y=0; curr_contrast=1;
% meanprojpic=[];
% 
% while (nudge==1)
%     choice = questdlg('Would you like to nudge the x-y position of the ROIs?', ...
%         'Moving the ROIs', ...
%         'Yes, let me nudge (again)','No, the ROIs are good','No, the ROIs are good');
%     switch choice
%         case 'Yes, let me nudge (again)'
%             nudge = 1;
%         case 'No, the ROIs are good'
%             nudge = 0;
%     end
%     
%     if nudge==1
%         %if no image loaded, ask for mean projection image
%         if isempty(meanprojpic)
%             h=msgbox('Select the mean projection .tiff file');
%             uiwait(h);
%             [filename, pathname]=uigetfile([data_dir '*.tif'],'Select the mean projection .tiff file');
%             meanprojpic=loadtiffseq(pathname,filename);
%         end
%         
%         %ask user how much to nudge the ROIs
%         default_x = int2str(curr_x);
%         default_y = int2str(curr_y);
%         default_contrast = int2str(curr_contrast);
% 
%         prompt = {'x:','y:','Image contrast:'};
%         dlg_title = 'Nudging the ROIs with respect to the images';
%         num_lines = 1;
%         defaultans = {default_x,default_y,default_contrast};
%         answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
%         curr_x=str2num(answer{1});
%         curr_y=str2num(answer{2});
%         curr_contrast=str2num(answer{3});
%         
%         %below: show how the nudged ROIs align with the figure
%         close;
%         figure;
% 
%         %color map for the image, use a smooth gray scale
%         graymap=[linspace(0,1,255); linspace(0,1,255); linspace(0,1,255)]';
% 
%         %re-scale pixel values so they range from 0 to 255 
%         temppic=double(meanprojpic);    %convert to double so can multiple/divide with more precision
%         temppic=255*temppic./nanmax(temppic(:));    %re-scale pixel values so range 0 to 255
%         temppic=temppic*curr_contrast;  %if user desires enhanced contrast
%         temppic(temppic>255)=255;       %if pixel values exceeds max possible, then set to max
%         
%         image(temppic);
%         colormap(graymap);
%         axis tight; axis square;
%         hold on;
%         for j=1:numel(roifiles)
%             
%             %shifts it by x and y, pad the rest with zero
%             shifted_cellmask=shiftMask(cellmask(:,:,j),curr_x,curr_y);
%             
%             if (sum(shifted_cellmask(:))>0) %if the ROIs encompasses any pixels
%                 %draw ROI outline
%                 [B,L]=bwboundaries(shifted_cellmask,'noholes');
%                 plot(B{1}(:,2),B{1}(:,1),'r','LineWidth',1);
%             else
%                 disp(['ROI ' int2str(j) ' is completely out of the imaging frame']);
%             end
%         end
%         title(['Number of ROIs=' int2str(numel(roifiles)) '; x-shift=' int2str(curr_x) '; y-shift=' int2str(curr_y)]);
%         set(0,'defaultfigureposition',[40 40 800 1000]);
%         cd(data_dir);
%         print(gcf,'-dpng','loadxysavefluo.png');
%         
%         h=msgbox('Check the alignment between the nudged ROIs and projection image');
%         uiwait(h);
%     end
% end

%%
shifted_cellmask=nan(size(cellmask));
shifted_neuropilmask=nan(size(neuropilmask));
curr_x=0; curr_y=0;
for k=1:numel(roifiles)
    %shifts it by x and y, pad the rest with zero
    shifted_cellmask(:,:,k)=shiftMask(cellmask(:,:,k),curr_x,curr_y);
    shifted_neuropilmask(:,:,k)=shiftMask(neuropilmask(:,:,k),curr_x,curr_y);
end

%% get the signal from the reg image files
cd(data_dir);
cd(reg_subdir);
stacks=dir('*.tif');

f=[]; n=[];
for j=1:numel(stacks)
    disp(['Loading reg image file ' stacks(j).name]);
    cd([data_dir reg_subdir]);
    warning('off','all');   %scim_openTif generates warning    
    pic=loadtiffseq([],stacks(j).name);
    warning('on','all');   %scim_openTif generates warning
    [nY nX nZ]=size(pic);

    for k=1:numel(roifiles)
        tempf=[]; tempn=[];
        for i=1:1:nZ
            %get sum of pixel values within the ROI
            tempf(i)=sum(sum(pic(:,:,i).*uint16(shifted_cellmask(:,:,k))));
            tempn(i)=sum(sum(pic(:,:,i).*uint16(shifted_neuropilmask(:,:,k))));
        end
        if sum(sum(shifted_cellmask(:,:,k)))>0     %if there are pixels belonging the the ROI
            if j==1 %if this is the first reg image, then start new variables
                f{k}=tempf/sum(sum(shifted_cellmask(:,:,k)));   %per-pixel fluorescence
                n{k}=tempn/sum(sum(shifted_neuropilmask(:,:,k)));   %per-pixel fluorescence
            else
                f{k}=[f{k} tempf/sum(sum(shifted_cellmask(:,:,k)))];   %per-pixel fluorescence
                n{k}=[n{k} tempn/sum(sum(shifted_neuropilmask(:,:,k)))];   %per-pixel fluorescence
            end
        else %if the ROI is outside of the imaging field of view
            f{k}=nan(size(tempf));
            n{k}=nan(size(tempn));
        end
    end
    clear pic;
end

%% save the extracted signals
cd(data_dir);
cd(reg_subdir);
[~,~,~]=mkdir('ROI');
cd('ROI');
for k=1:numel(roifiles)
    cellf=f{k};
    neuropilf=n{k};
    bw=shifted_cellmask(:,:,k);
    subtractmask=shifted_neuropilmask(:,:,k);
    isRedCell=isred(k);
    
    temp = sprintf('%03d',k);
    save(strcat('cell',temp,'.mat'),'cellf','neuropilf','bw','subtractmask','isRedCell');
end
disp(['Processed ' int2str(numel(roifiles)) ' ROIs --- All done!']);

%%
% figure;
% subplot(2,1,1);
% plot(cellf);
% axis tight; title('downsampled');
% subplot(2,1,2);
% plot(f{numel(roifiles)});
% axis tight; title('extracted');


