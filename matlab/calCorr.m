clear all;
tic;
refFrame='/Users/phoenix/Documents/Kwanlab/learning/746/746_02_26/raw_stitched/746_02_26__images_1-501_dsRatio_4.tif';

%% load directory
image_subdir = 'raw';
%save_subdir = 'raw_green';
data_dir = '/Users/phoenix/Documents/Kwanlab/learning/746/746_02_26/'
%data_dir = uigetdir('C:\Desktop\Image Analysis', 'Choose Data Directory');
cd(data_dir);
%mkdir(save_subdir);
        
cd(image_subdir);
stacks=dir('*.tif');

%% check acquisition time
disp('----Acquiring header information from the images...');
for n=1:numel(stacks)
    img_fileID = stacks(n).name; 
    
    warning('off','all');   %scim_openTif generates warning
    [header]=scim_openTif(img_fileID);
    
    
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
disp('----calculating cross correlations...');
j=1;
refFrametif=imread(refFrame);

meanref=mean(mean(refFrametif));
stdref=std2(refFrametif);
normref=(double(refFrametif)-meanref)/(256*256*stdref);

CorrList=zeros(1, numel(stacks));
ConvList=zeros(1, numel(stacks));
NormCorrList=zeros(1,numel(stacks));
CorrCoefList=zeros(1,numel(stacks));
pseudoCorrList=zeros(1, numel(stacks));
peakxList=zeros(1,numel(stacks));
peakyList=zeros(1,numel(stacks));
maxCorrCoef=zeros(1,numel(stacks));
CorrCoefMat=zeros(511,511,numel(stacks));

SquareDifferenceList=zeros(1,numel(stacks));

for n=1:numel(stacks)
    img_fileID = stacks(n).name;
    [pathstr, FileName, ext] = fileparts(img_fileID); 
    %disp(FileName);
    
    info = imfinfo(img_fileID);
    stack_frames(n) = length(info);
   
    cd(data_dir);
    cd(image_subdir);
    %curr_frame = imread(img_fileID, 'Index', 1, 'Info', info);
   
    %t.setTag(tagstruct);
    %t.write(curr_frame); %write first frame
    CrossCorr=0;
    %Convo=0;
    SumFrame=zeros(length(refFrametif));
    disp(['------calculating ',img_fileID]);
    for k = 1:stack_frames(n) %add on subsequent frames; stitches on every (num_chan)-th frame 
        %disp('----stack frames ');
        curr_frame = imread(img_fileID, 'Index', k);
        SumFrame = SumFrame + double(curr_frame);
        
    end
    AVGFrame = SumFrame / stack_frames(n);
    
     %calculate the square difference
     %square difference is equal to the correlation coefficient,
     %mathematically (although I did not prove it!)
     %yet calculate the square difference is 100 times faster (which makes
     %sence since normcorr2 calculate 511*511 coefficients...
     %thus we can just use the square difference to measure the deviation
     %of the images (althought it is not between [0,1], I haven't figure
     %out how to restrict it between [0,1] interval
    meanAVG=mean(mean(AVGFrame));
    stdAVG=std2(AVGFrame);
    normAVG=(double(AVGFrame)-meanAVG)/(256*256*stdAVG);
    SquareDifference=sum(sum((normref-normAVG).^2));
    SquareDifferenceList(n)=SquareDifference;
  
    
    
    
    warning('off','all');
    CrossCorr = sum(sum(xcorr2(AVGFrame, refFrametif)));  %seems like convolution is slightly faster than correlation
    %Convo = sum(sum(conv2(AVGFrame, refFrametif)));  %based on the testspeed.m, 0.01 s faster on average of 100 trials
    CrossCorrMat=normxcorr2(AVGFrame,refFrametif);
    CorrCoefMat(:,:,n)=CrossCorrMat; %record the raw normalized coefficient data
    maxCoef=max(CrossCorrMat(:));
    maxCorrCoef(n)=maxCoef; 
    
    [peaky,peakx]=find(CrossCorrMat==maxCoef);
    peakxList(n)=peakx;
    peakyList(n)=peaky;
    NormCrossCorr=sum(sum(CrossCorrMat));
    warning('on','all');
    pseudoCorr=sum(sum(((AVGFrame-double(refFrametif)).^2)));
    
    %this part is calculating the square
    CorrList(n) = CrossCorr;
    %ConvoList(n) = Convo;
    NormCorrList(n)=NormCrossCorr;
    pseudoCorrList(n)=pseudoCorr;
    CorrCoefList(n)=CrossCorrMat(256,256);
end

% figure;
% %subplot(2,1,1); plot(CorrList);
% subplot(2,3,1); 
% plot(CorrList);title('Correlation')
% subplot(2,3,2);
% plot(NormCorrList);title('norm correlation');
% subplot(2,3,3);
% plot(pseudoCorrList);title('pseudo correlation');
% subplot(2,3,4);
% plot(CorrCoefList);title('Correlation coefficient');
% subplot(2,3,5);
% plot(peakxList,peakyList,'.');title('maximum coefficient coordinates');
% subplot(2,3,6);
% plot(maxCorrCoef);title('maximum coefficient value');
% %CorrList
% %ConvoList
csvwrite('raw_normalized_coefficient_data.csv',CorrCoefMat);
toc

figure;
plot(SquareDifferenceList);
disp('Done!');
beep
