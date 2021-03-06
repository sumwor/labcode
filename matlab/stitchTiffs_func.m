function stitchTiffs_func(data_dir,scim_ver, raw_subdir,image_subdir,save_subdir,batchLen, dsFreq)
% input arguments:
%input all the parameters, no easy way to set default input in matlab

% This is Step 2 for processing calcium imaging data.
%
% After Step 1: motion correction -->
% Downsample the image files to ~1 Hz
% Stitch them into one .tiff file
% --> in preparation for Step 3: ROI selection
%
% AC Kwan, 6/15/2016
% this file is modified to be function file rather than script--used to
% batch processing multiple stitch tasks

tic;

%% create directory structure for loading and saving files
%default values

%As of 05/18/2017, the rig with the galvonometer runs ScanImage 3.81
%   the rig with the resonant scanner runs ScanImage 5.1
%default scim_ver = '3';


%take in arguments and overwrite those different from the default value


% create directories
cd(data_dir);
mkdir(save_subdir);        



%% get acquisition time from the raw files

if (scim_ver==5)
    frameTime=[];
    fileAcqTime=[];
    fileNextTime=[];
end

%grab names of all the image files in the directory
cd(data_dir);
cd(raw_subdir);
stacks=dir('*.tif');

for n=1:numel(stacks)
    img_fileID = stacks(n).name; 
    
    %load the header info from the .tiff file
    %----- if file was from ScanImage 3.x ----
    if scim_ver==3
        warning('off','all');   %scim_openTif generates warning
        [header]=scim_openTif(img_fileID);
        warning('on','all');

        idx=find(header.internal.triggerTimeString=='/');
        if strcmp(header.internal.triggerTimeString(idx(2)-2),'/')
            day=str2double(header.internal.triggerTimeString(idx(2)-1));
        else
            day=str2double(header.internal.triggerTimeString(idx(2)-2:idx(2)-1));
        end
        hr=str2double(header.internal.triggerTimeString(end-11:end-10));
        min=str2double(header.internal.triggerTimeString(end-8:end-7));
        sec=str2double(header.internal.triggerTimeString(end-5:end));
        trigTime(n)=day*24*60*60+hr*60*60+min*60+sec;    %in seconds
        trigDelay(n)=header.internal.triggerFrameDelayMS/1000;      %in seconds
        frameRate=header.acq.frameRate;
        %num_chans=header.acq.numberOfChannelsSave;
        num_chans=1;
        if ~isempty (header.acq.nextTrigInputTerminal)
            nextTrigMode=1;     %acquired using nextTrigger
        else
            nextTrigMode=0;
        end

    %----- if file was from ScanImage 5.x -----
    elseif scim_ver==5
        header=scanimage.util.opentif(img_fileID);
        
        frameTime=[frameTime header.frameTimestamps];       
        fileAcqTime=[fileAcqTime header.acqTriggerTimestamps(1)];
        fileNextTime=[fileNextTime header.nextFileMarkerTimestamps(1)];
        frameRate=1/nanmean(diff(header.frameTimestamps));
        num_chans=header.scanimage.SI.hChannels.channelSave;
        nextTrigMode=1; %always next trigger mode
    else
        error('ERROR - The dialog box asked for ScanImage version, should enter 3 or 5');
    end

end

%% stitch tiff
disp('----Processing images...');
j=1;    %stitched image file count
l=0;    %frame count for current stitched image file
num_totalframes=zeros(1,numel(stacks)); %number of frames in each file (include all channels)
num_frames=zeros(1,numel(stacks)); %number of green-channel frames in each file

if frameRate>dsFreq
    dsRatio=round(frameRate/dsFreq);    %amount to downsample
else
    dsRatio=1;
end

cd(data_dir);
cd(image_subdir);
stacks=dir('*.tif');

for n=1:numel(stacks)
    img_fileID = stacks(n).name;
    [pathstr, FileName, ext] = fileparts(img_fileID); 

    %get info about image, pre-allocate to speed up loading .tiff file
    info = imfinfo(img_fileID);
    num_totalframes(n) = length(info);     %number of frames
    tagstruct.ImageLength=info(1).Height;
    tagstruct.ImageWidth=info(1).Width;
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample = 16;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.RowsPerStrip = info(1).Height;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB';
    
    num_frames(n) = num_totalframes(n)/num_chans;
    
    %give user a status update at command line
    disp([FileName ' (' num2str(num_frames(n)) ' frames)']);

    if mod(n,batchLen)==1    %for first raw file in every x trials, start a new stitched .tiff file
        if (n+batchLen-1) <= numel(stacks)  %if end of stack, use the final trial as savefile-name
            savFile_name{j}=[FileName(1:end-3) '_images_' int2str(n) '-' int2str(n+batchLen-1) '_dsRatio_' int2str(dsRatio) ext];
        else
            savFile_name{j}=[FileName(1:end-3) '_images_' int2str(n) '-' int2str(numel(stacks)) '_dsRatio_' int2str(dsRatio) ext]; 
        end
        if n>1  %if it is not the first trial, close the previous file
            t.close();
        end
        cd(data_dir);
        cd(save_subdir);
        t = Tiff(savFile_name{j},'w');
        j=j+1;  %advance stitched file counter
        
        %if it is first frame of the file, then do the next three lines
        cd(data_dir);
        cd(image_subdir);
        curr_frame = uint16(imread(img_fileID, 'Index', num_chans, 'Info', info));
        t.setTag(tagstruct);
        t.write(curr_frame); %write first frame
        
        %multiply by num_chans - ASSSUMING green channel is the last recorded channel
        startIdx=1+dsRatio;
        for k = startIdx*num_chans:dsRatio*num_chans:num_frames(n)*num_chans %add on subsequent frames
            curr_frame = uint16(imread(img_fileID, 'Index', k, 'Info', info));
            t.writeDirectory();
            t.setTag(tagstruct);
            t.write(curr_frame);
        end
        l=l+num_frames(n);  %advance frame counter
    else
        startIdx=1+ceil(l/dsRatio)*dsRatio-l;
        for k = startIdx*num_chans:dsRatio*num_chans:num_frames(n)*num_chans %add on subsequent frames
            curr_frame = uint16(imread(img_fileID, 'Index', k, 'Info', info));
            t.writeDirectory();
            t.setTag(tagstruct);
            t.write(curr_frame);
        end
        l=l+num_frames(n);  %advance frame counter
    end
end
t.close();

%% save header info
nX=info(1).Width;
nY=info(1).Height;

cd(fullfile(data_dir,save_subdir));
if (scim_ver==3)
    save('stackinfo.mat','scim_ver','frameRate','nextTrigMode','trigTime','trigDelay','num_frames','stacks','batchLen','savFile_name','nX','nY');
elseif (scim_ver==5)
    save('stackinfo.mat','scim_ver','frameRate','nextTrigMode','frameTime','fileAcqTime','fileNextTime','num_frames','stacks','batchLen','savFile_name','nX','nY');
end

disp(['Original frame rate ' num2str(frameRate) ' Hz']);
disp(['Downsample to frame rate of ' num2str(frameRate/dsRatio) ' Hz']);
toc
disp('Done!');
beep
