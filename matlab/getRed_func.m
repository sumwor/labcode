function getRed_func(filepath)
tic;
batchLen=1000;   %every x trials, combine into 1 tiff

%% load directory
image_subdir = 'raw';
save_subdir = 'stitched_redChan';

%data_dir = uigetdir('C:\Desktop\Image Analysis', 'Choose Data Directory');
cd(data_dir);
mkdir(save_subdir);
        
cd(image_subdir);
stacks=dir('*.tif');

%% check acquisition time
disp('----Acquiring header information from the images...');
for n=1:numel(stacks)
    img_fileID = stacks(n).name; 
    
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
end

frameRate=header.acq.frameRate;
num_chans=header.acq.numberOfChannelsSave;
redChan=num_chans-1;

if ~isempty (header.acq.nextTrigInputTerminal)
    nextTrigMode=1;     %acquired using nextTrigger
else
    nextTrigMode=0;
end

[trigTime,index] = sort(trigTime);  %order the files based on acquisition time
trigTime = trigTime(index);
trigDelay = trigDelay(index);
stacks = stacks(index);

%% stitch tiff
disp('----Processing images...');
j=1;
for n=1:numel(stacks)
    img_fileID = stacks(n).name;
    [pathstr, FileName, ext] = fileparts(img_fileID); 
    disp(FileName);
    
    info = imfinfo(img_fileID);
    stack_frames(n) = length(info);
    
    tagstruct.ImageLength=info(1).Height;
    tagstruct.ImageWidth=info(1).Width;
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample = 16;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.RowsPerStrip = info(1).Height;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB';
    
%     if mod(n,batchLen)==1    %for every x trials, start a new .tiff file
%         if (n+batchLen-1) <= numel(stacks)  %if end of stack, use the final trial as savefile-name
%             savFile_name{j}=[FileName(1:end-3) '_trials_' int2str(n) '-' int2str(n+batchLen-1) 'red' ext];
%         else
%             savFile_name{j}=[FileName(1:end-3) '_trials_' int2str(n) '-' int2str(numel(stacks)) 'red' ext]; 
%         end
%         if n>1  %if it is not the first trial, close the previous file
%             t.close();
%         end
    cd(data_dir);
    cd(save_subdir);
    t = Tiff(img_fileID,'w');
        
    cd(data_dir);
    cd(image_subdir);
                                                               
    curr_frame = imread(img_fileID, 'Index', redChan, 'Info', info); %last chan (chan2) is GCaMP channel; redChan:chan1
  
    t.setTag(tagstruct);
    t.write(curr_frame); %write first frame
    for k = 2*num_chans-1:num_chans:stack_frames(n) %add on subsequent frames; stitches on every (num_chan)-th frame 
        curr_frame = imread(img_fileID, 'Index', k, 'Info', info);    
        t.writeDirectory();
        t.setTag(tagstruct);
        t.write(curr_frame);
    end        
%     else
%        for k = redChan:num_chans:stack_frames(n) %add on subsequent frames; stitches on every (num_chan)-th frame 
%             curr_frame = imread(img_fileID, 'Index', k, 'Info', info);    
%             t.writeDirectory();
%             t.setTag(tagstruct);
%             t.write(curr_frame);
%         end
%     end
end
t.close();

nX=info(1).Width;
nY=info(1).Height;

num_frames=stack_frames/num_chans;

%% save header info
cd(data_dir);
cd(save_subdir);
%save('stackinfo.mat','frameRate','nextTrigMode','trigTime','trigDelay','num_frames','stacks','batchLen','savFile_name','nX','nY');
toc

disp('Done!');
beep
