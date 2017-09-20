clear all;
tic;
refFrame='/Users/phoenix/Documents/Kwanlab/learning/746/test/refFrame0.tif';

%% load directory
data_dir = '/Users/phoenix/Documents/Kwanlab/learning/746/test/';
image_subdir = 'raw';
cd(data_dir);
        
cd(image_subdir);
stacks=dir('*.tif');
stack_frames=zeros(1,numel(stacks));

% check acquisition time
disp('----Acquiring header information from the images...');
for n=1:numel(stacks)
    img_fileID = stacks(n).name; 
    
    warning('off','all');   %scim_openTif generates warning
    [header]=scim_openTif(img_fileID);
    
    %get the number of frames of each tif file
    info = imfinfo(img_fileID);
    stack_frames(n) = length(info);
    
    %get the header string
    hTif = Tiff(img_fileID);
    headerString  = hTif.getTag('ImageDescription');
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

if ~isempty (header.acq.nextTrigInputTerminal)
    nextTrigMode=1;     %acquired using nextTrigger
else
    nextTrigMode=0;
end

[trigTime,index] = sort(trigTime);  %order the files based on acquisition time
trigTime = trigTime(index);
trigDelay = trigDelay(index);
stacks = stacks(index);

%% calculate cross correlation

%initiate the correlation coefficient vector
CorrCoef=zeros(1, sum(stack_frames));


disp('----calculating cross correlations...');
j=1;
refFrametif=imread(refFrame);


%norm correlation matrix, containing the raw correlation matrix
NormCorrList=cell(1,sum(stack_frames));

jj=1; %count the frames
for n=1:numel(stacks)
    img_fileID = stacks(n).name;
    [pathstr, FileName, ext] = fileparts(img_fileID); 
   
    cd(data_dir);
    cd(image_subdir);
   
    CrossCorr=0;
    disp(['------calculating ',img_fileID]);
    for k = 1:stack_frames(n) %add on subsequent frames; stitches on every (num_chan)-th frame 
        curr_frame = imread(img_fileID, 'Index', k);
        
        warning('off','all');
        
        CrossCorrMat=normxcorr2(curr_frame, refFrametif);
        NormCorrList(jj)={CrossCorrMat};
        CorrCoef(jj)=CrossCorrMat(256,256);
        
        warning('on','all');
        
        jj=jj+1;
        
    end

    

end


figure;
plot(CorrCoef);title('Correlation coefficient');

cd(data_dir);
mkdir('coefficient');
cd('coefficient');
%the data size of the whole correlation coefficient matrix is too large
%(~1 GB for 10 tiffs....)
%csvwrite('correlation_coefficient_data_stitch0.csv',NormCorrList);
csvwrite('correlation_coefficient_data.csv',CorrCoef);
toc

disp('Done!');
beep
