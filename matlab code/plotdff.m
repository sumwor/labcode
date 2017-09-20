%% ----- plotdff: read extracted signals from cellROI, and plot neural activity

% which figures are we going to generate
plotFig1=1;     %plot the spatial locations of the ROIs

plotFig2=1;     %plot the dF/F for all cells
startExptDur=1;   %time between onset of startExpt and onset of cue in our behavioral task

plotFig3a=1;     %heat map of dF/F, aligned to response time
plotFig3b=1;     %heat map of dF/F-difference, aligned to response time
plotFig3c=1;     %scatter plot of dF/F for sound vs action rule
binWidth=0.25;
trigRespWindow=[-3 6];  %the window around response to analyze
sortCueTime=[-1 1];
sortRespTime=[1 3];  %time used to assess choice preference for sorting cells in heatmap plots

plotFig4=0;      %plot trial-averaged dF/F for each cell
numBootstrapRep=100;     %how many repeats to generate CI, should run more >1000 repeats for actual figure
CI=0.95;                 %confidence interval for the bootstrap
plotBinWidth=0.5;
plotRespWindow=[-3 6];  %the window around response to analyze

plotFig5a=1;    % Multiple linear regression:  C(t), C(t-1), C(t)xC(t-1), C(t-2) for sound-guided trialsFigF
RegMovingWinDur=0.5;   %moving window - duration
RegMovingStep=0.5;      %moving window - step
RegpvalThresh=0.01;     %p-value for significance

plotFig6a=1;     %ensemble analysis -- dPCA
plotFig6b=1;    %ensemble analysis -- distance between trajectories pre vs post switch, and between blocks
plotFig6c=1;    %ensemble analysis -- compare single-cell and ensemble decoding of rule
plotFig6d=1;    %single-cell decoding analysis -- decoding of choice
stateRespWindow=[0 6];
numRepLDA=100;  %how many repeats to generate the correct confidence intervals, should run >1000 repeats for actual figure
fracLDA=0.8;    %use this portion of trials to make classifier to test on remainder of trials
choiceRespWindow=[-2 6];

%% ----- set up figure plotting
set(groot, ...
    'DefaultFigureColor', 'w', ...
    'DefaultAxesLineWidth', 2, ...
    'DefaultAxesXColor', 'k', ...
    'DefaultAxesYColor', 'k', ...
    'DefaultAxesFontUnits', 'points', ...
    'DefaultAxesFontSize', 18, ...
    'DefaultAxesFontName', 'Helvetica', ...
    'DefaultLineLineWidth', 1, ...
    'DefaultTextFontUnits', 'Points', ...
    'DefaultTextFontSize', 18, ...
    'DefaultTextFontName', 'Helvetica', ...
    'DefaultAxesBox', 'off', ...
    'DefaultAxesTickLength', [0.02 0.025]);

% set the tickdirs to go out - need this specific order
set(groot, 'DefaultAxesTickDir', 'out');
set(groot, 'DefaultAxesTickDirMode', 'manual');
set(0,'defaultfigureposition',[40 40 1000 1000]);

savefigpath = [newroot_dir 'figs-fluo/'];
if ~exist(savefigpath,'dir')
    mkdir(savefigpath);
end

%% ----- load fluorescence data extracted using cellROI, calculate dF/F

cd(newroot_dir);
cd('stitched');
load('stackinfo.mat');  %load stats about the image files, generated from StitchTiffs.m
cd(roiDir);
flist=dir('*cell*.mat');
roi=[1:1:length(flist)];    %number of ROIs = number of .mat files generated from cellROI.m

%diagnostic - plot the number of frames per image file to make sure it's stable, and no image acquisition trigger is missed
figure;
subplot(2,2,1);
plot(num_frames,'k');
xlabel('.tiff file #');
ylabel('# frames in each .tiff');
axis tight;

if (recalcdff)
    f=[]; cellmask=[];
    for i=1:length(roi)
        cd(newroot_dir);
        cd('stitched');
        cd(roiDir);
        
        %for each cell, extract the time-lapse fluoresence
        tempFile_name=char(savFile_name{1});
        imagefname=['cell' num2str(roi(i),'%03i') '.mat'];
        load(imagefname);
        
        cellmask(:,:,i)=bw;
        f(:,i)=cellf;
        
        %correct neuronal F(t) by subtracting neuropil fluorescence
        if alphacorrfactor>0
            f(:,i)=f(:,i)-alphacorrfactor*neuropilf';
        end
    end
    
    disp('...Calculating baseline fluorescence to calculate dF/F...');
    baselinedff=[];
%     dff=[];
    for i=1:length(roi)
        %---calculate dF/F, baseline is 10th percentile, from first 10 min
        %         baselineWin=round(600*frameRate);   %number of image frames correpsonding to 10 minutes
        %         baselinedff=prctile(f(1:baselineWin,i),10);
        %         dff(:,i)=(f(:,i)-baselinedff)./baselinedff;
        
        %---calculate dF/F, baseline is 10th percentile, moving window
        movWin=600*frameRate;   %10 minutes
        for jj=1:size(f,1)
            idx1=max(1,round(jj-movWin/2));
            idx2=min(size(f,1),round(jj+movWin/2));
            baselinedff(jj,i)=prctile(f(idx1:idx2,i),10);
        end
        dff(:,i)=(f(:,i)-baselinedff(:,i))./baselinedff(:,i);
    end
    
    dff(isinf(dff))=nan;    %there should not be entries with infinite values
    
    save([newroot_dir 'dff.mat'],...
        'dff','cellmask');
else
    cd(newroot_dir);
    load('dff.mat');
end

%% which cells are GABAergic, labeled with tomato protein
gabaLabel=[]; nongabaLabel=[];
for i=1:numel(roi)
    if ~isempty(find(sstLabel==i,1))
        gabaLabel=[gabaLabel i];
    elseif ~isempty(find(pvLabel==i,1))
        gabaLabel=[gabaLabel i];
    else
        nongabaLabel=[nongabaLabel i];
    end
end

%% load the analyzed behavior data

%Code for different behavioral events
CODE_HITLEFT=1; CODE_INCORRECTLEFT=0; CODE_MISSLEFT=4; CODE_HITRIGHT=2; CODE_INCORRECTRIGHT=3; CODE_MISSRIGHT=5; CODE_PERSEVERLEFT=6; CODE_PERSEVERRIGHT=7; CODE_PERSEVERHITLEFT=8; CODE_PERSEVERHITRIGHT=9;
CODE_RIGHTSET_LEFTSTIM_HIT=11; CODE_RIGHTSET_LEFTSTIM_MISS=10; CODE_RIGHTSET_PERSEVERERR=12; CODE_RIGHTSET_INCORRECT=13; CODE_RIGHTSET_RIGHTSTIM_HIT=14; CODE_RIGHTSET_RIGHTSTIM_MISS=15;
CODE_LEFTSET_LEFTSTIM_HIT=21; CODE_LEFTSET_LEFTSTIM_MISS=20; CODE_LEFTSET_PERSEVERERR=22; CODE_LEFTSET_INCORRECT=23; CODE_LEFTSET_RIGHTSTIM_HIT=24; CODE_LEFTSET_RIGHTSTIM_MISS=25;

CODE_HITLEFTDOUBLE=-1; CODE_HITRIGHTDOUBLE=-2; CODE_HITLEFTZERO=-3; CODE_HITRIGHTZERO=-4;

CODE_CUE=0; CODE_ACTIONLEFT=1; CODE_ACTIONRIGHT=2; %the current strategy

%load the behavioral analysis generated with readDiscrimLogfile.m
cd(newroot_dir);
load([behavFile(1:end-4) '.mat']);

%synchronize the time for start of each .tiff to the time for start of each behavioral trial
if (nextTrigMode)   %if using nextTrig mode in ScanImage: trigTime is the startexptTime, but new image sometimes delayed
    if ~(length(startexptTime)==length(trigDelay))
        if (length(trigDelay)-length(startexptTime))==1 %sometimes values off by 1 because last behavior trial was incomplete and cropped
                trigDelay=trigDelay(1:end-1);
                trigTime=trigTime(1:end-1);        
        elseif length(startexptTime)<length(trigDelay) %behavior stopped but imaging keeps going, beyond expectation
                disp(['!!! Behavior stopped but imaging keeps going. ' num2str(length(startexptTime)) '<' num2str(length(trigDelay))]);
                waitfor(errordlg('!!! Behavior/image duration not consistent! Behavior stopped but imaging keeps going; will try to continue by cropping imaging data.'));
                trigDelay=trigDelay(1:length(startexptTime));
                trigTime=trigTime(1:length(startexptTime));
        elseif length(startexptTime)>length(trigDelay) %behavior keeps going when imaging stopped
            disp(['!!! Behavior keeps going when imaging stopped. ' num2str(length(startexptTime)) '>' num2str(length(trigDelay))]);
            waitfor(errordlg(['!!! Behavior/image duration not consistent! Behavior keeps going when imaging stopped. Please re-run readDiscrimLogfile, with manually set trialEndIndex to ' num2str(length(trigDelay))]));
        end
    end
    scanimageTime=startexptTime-trigDelay';
else    %if not using next trigger, then must be in start trigger mode
    scanimageTime=startexptTime;
end

t=[];
dt=1/frameRate;
for i=1:numel(scanimageTime)
    t=[t scanimageTime(i)+(0:dt:dt*(num_frames(i)-1))]; %add time of each frame, knowing when start time of each image file is
end
dff=dff(1:numel(t),:);

%diagnostic: behavioral trials vary in duration, and the duration of .tiff should match
subplot(2,2,2); hold on;
plot(diff(trigTime),diff(startexptTime),'k.','MarkerSize',15);
minX=min([min(diff(scanimageTime)) min(diff(startexptTime))]);
maxX=max([max(diff(scanimageTime)) max(diff(startexptTime))]);
plot([minX maxX],[minX maxX],'k');
xlabel('Time between .tiff file');
ylabel('Time between behav trial');
axis([minX maxX minX maxX]);

%diagnostic: time difference between successive frames should be roughly equal to the imaging frame rate, no large jumps >10%
subplot(2,2,[3 4]);
plot(diff(t),'k');
xlabel('Frame');
ylabel('Time between frame (s)');
axis tight;

set(gcf,'Position',[40 40 1000 1000]);  %laptop
set(gcf, 'PaperPositionMode', 'auto');
cd(savefigpath);
export_fig(gcf, 'Fig0', '-jpg', '-painters', '-r100', '-transparent');

%first save, do not append to overwrite the old analysis save file
save([newroot_dir 'dffBehav.mat'],'subject','startDate',...
    'hit_miss','switchTrial','currTrial','startexptTime',...
    't','frameRate','roi',...
    'trialMask','blockMask');

clear trigTime;

%% ----- plot locations of ROI
if (plotFig1)
    figure; hold on;
    for i=1:numel(roi)
        [B,L]=bwboundaries(cellmask(:,:,i),'noholes');
        %draw outline
        plot(B{1}(:,2),B{1}(:,1),'k','LineWidth',1);
        if sum(gabaLabel==roi(i))==1  %if it is SST cell, fill the polygon
            fill(B{1}(:,2),B{1}(:,1),'r','LineWidth',1);
        end
        %label the cell
        [column,row]=find(cellmask(:,:,i)==1);
        cellx(i)=mean(row);     %cell location centroid, x
        celly(i)=mean(column);  %cell location centroid, y
        text(cellx(i),celly(i),int2str(i),'Color',[0 0 0],'FontSize',16,'FontWeight','bold');
    end
    axis tight; axis square; axis off;
    
    set(gcf,'Position',[40 40 800 600]);  %laptop
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig1', '-jpg', '-painters', '-r130', '-transparent');
    saveas(gcf, 'Fig1', 'fig'); %fig format
end

%% ----- plot dF/F of each cell as a function of time
if (plotFig2)
    
    if ~isempty(gabaLabel)
        numPlot=2;
    else
        numPlot=1;
    end
    
    for ll=1:numPlot
        if ll==1
            specialCells=1:numel(roi); %plot all cells
        elseif ll==2
            specialCells=gabaLabel; %plot only GABAergic cells
        end
        
        figure; hold on;
        totalspacingDff=sum(nanmax(dff(:,specialCells),[],1))+1;     %range of vertical axis encompassing dF/F for this plot
        
        %plot behavioral events (choices) as vertical lines
        %     for i=1:length(hit_miss)
        %         %add tick mark for lick responses associated with particular behavioral events
        %         tempTime=startexptTime+startExptDur;   %cue onset time
        %         tempEvent(1)=CODE_HITLEFT; tempColor{1}='k-';
        %         tempEvent(2)=CODE_HITRIGHT; tempColor{2}='k--';
        %         tempEvent(3)=CODE_PERSEVERHITLEFT; tempColor{3}='k';
        %         tempEvent(4)=CODE_PERSEVERHITRIGHT; tempColor{4}='k--';
        %         tempEvent(5)=CODE_INCORRECTLEFT; tempColor{5}='m';
        %         tempEvent(6)=CODE_INCORRECTRIGHT; tempColor{6}='m--';
        %         tempEvent(7)=CODE_PERSEVERLEFT; tempColor{7}='m';
        %         tempEvent(8)=CODE_PERSEVERRIGHT; tempColor{8}='m--';
        %
        %         for jj=1:numel(tempEvent)
        %             if hit_miss(i)==tempEvent(jj)
        %                 plot(tempTime(i)*[1 1],[-totalspacingDff 0],tempColor{jj},'LineWidth',2);
        %             end
        %         end
        %     end
        
        %plot behavioral events (rules) as color patches
        if ~isempty(switchTrial)
            tempTime=startexptTime+startExptDur;   %cue time
            for i=1:numel(switchTrial)
                if currTrial(i)==CODE_ACTIONLEFT
                    patch([tempTime(switchTrial(i-1)) tempTime(switchTrial(i)) tempTime(switchTrial(i)) tempTime(switchTrial(i-1))],totalspacingDff*[0 0 -1 -1],[1 0.7 0.7],'EdgeColor','none');
                elseif currTrial(i)==CODE_ACTIONRIGHT
                    patch([tempTime(switchTrial(i-1)) tempTime(switchTrial(i)) tempTime(switchTrial(i)) tempTime(switchTrial(i-1))],totalspacingDff*[0 0 -1 -1],[0.7 0.7 1],'EdgeColor','none');
                end
                plot(tempTime(switchTrial(i))*[1 1],[-totalspacingDff 0],'k','LineWidth',1);
            end
            if currTrial(end)==CODE_ACTIONLEFT
                patch([tempTime(switchTrial(end)) tempTime(end) tempTime(end) tempTime(switchTrial(end))],totalspacingDff*[0 0 -1 -1],[1 0.7 0.7],'EdgeColor','none');
            elseif currTrial(end)==CODE_ACTIONRIGHT
                patch([tempTime(switchTrial(end)) tempTime(end) tempTime(end) tempTime(switchTrial(end))],totalspacingDff*[0 0 -1 -1],[0.7 0.7 1],'EdgeColor','none');
            end
        end
        
        %plot dF/F
        spacingDff=0;
        for jj=1:numel(specialCells)
            spacingDff=spacingDff+nanmax(dff(:,specialCells(jj)));
            plot(t,dff(:,specialCells(jj))-spacingDff,'k','LineWidth',3);
        end
        
        axis([t(1),t(end),-totalspacingDff,0]);
        if ll==1
            title('Each row is a cell'); 
        elseif ll==2
            title('Each row is a cell (GABAergic neurons only)'); 
        end
        ylabel('dF/F (offset for each row is shifted)');
        xlabel('Time (s)');
        
        set(gcf,'Position',[40 40 1500 800]);  %laptop
        set(gcf, 'PaperPositionMode', 'auto');
        cd(savefigpath);
        export_fig(gcf, ['Fig2-' num2str(ll)], '-jpg', '-painters', '-r130', '-transparent');
        saveas(gcf, ['Fig2-' num2str(ll)], 'fig'); %fig format
        
        clear tempEvent tempColor totalspacingDff spacingDff;
    end
end

%% ----- preparing dF/F for future analyses

%interpolate dF/F to span a finer time scale, used for finding time of peak dF/F and multiple regression
interdff=[];
interdt=0.01;
intert=[trigRespWindow(1):interdt:t(end)+trigRespWindow(2)];    %time to interpolate to, including small bits before and after actual imaging time
for i=1:numel(roi)
    interdff(:,i)=interp1(t,dff(:,i)',intert);
end

%break down dF/F by each trial, aligned to cue onset
trigCueTime=startexptTime+startExptDur;
trigRespTime=startexptTime+startExptDur+firstRespTime';
dffbyTrial=aligndffByTime(t,dff,trigCueTime,trigRespWindow);
timebyTrial=[round(trigRespWindow(1)/dt):1:round(trigRespWindow(2)/dt)]*dt; %time corresponding to the dffbyTrial
interdffbyTrial=aligndffByTime(intert,interdff,trigCueTime,trigRespWindow);

%% ----- plot dF/F heatmap triggered on certain behavioral event
if (plotFig3a)
    tempTrialMask=false(numel(hit_miss),4);
    tempTrialMask(:,1)=trialMask.sound & trialMask.left & trialMask.hit;
    tempTrialMask(:,2)=trialMask.sound & trialMask.right & trialMask.hit;
    tempTrialMask(:,3)=trialMask.action & trialMask.left & trialMask.hit;
    tempTrialMask(:,4)=trialMask.action & trialMask.right & trialMask.hit;
    
    %find trial-averaged fluorescence and z-score by binning
    baselineWindow=[-2 -1];  %baseline used to estimate mean and std for z-score calculation
    baselineIdx=(timebyTrial>baselineWindow(1) & timebyTrial<baselineWindow(2));
    
    peakdffTime=[]; trialavgdff=[]; trialavgZ=[];
    for kk=1:size(tempTrialMask,2)
        %find trial-averaged dF/F and then z-score
        for i=1:length(roi)
            [trialavgtime,trialavgdff(:,i,kk)]=trialaverage(t,dff(:,i),trigCueTime((tempTrialMask(:,kk)==1)),trigRespWindow,binWidth);
            
            temp=dffbyTrial(baselineIdx,i,tempTrialMask(:,kk)); %sampling distribution of dF/F during baseline period
            temp=temp(:);
            trialavgZ(:,i,kk)=(trialavgdff(:,i,kk)-nanmean(temp))/nanstd(temp);
        end
        
        %find the time of peak dF/F response
        intertrialRespavgdff=nanmean(interdffbyTrial(:,:,logical(tempTrialMask(:,kk))),3);
        [peakVal,peakBin]=nanmax(intertrialRespavgdff);
        peakdffTime(:,kk)=trigRespWindow(1)+interdt*(peakBin-1);
    end
    
    figure;
    minZ=-1; maxZ=2;
    
    kk=1;   %plot for this behavioral condition
    [val,idx]=sort(peakdffTime(:,kk));      %sort the cells by peak dF/F
    subplot(2,6,[1 2 7 8]);
    image(trialavgtime,[1:1:numel(roi)],trialavgZ(:,idx,kk)','CDataMapping','scaled');
    hold on; plot([0 0],[0 numel(roi)+1],'w','LineWidth',3);
    %    plot(peakdffTime(idx,kk),1:numel(roi),'w','LineWidth',3);
    colormap(jet);
    caxis([minZ maxZ]);      %normalize dF/F heatmap to max of all conditions
    ylabel('Cells, sorted');
    xlabel('Time from cue (s)');
    title(['Sound rule+left; ' int2str(sum(tempTrialMask(:,kk))) ' trials']);
    
    kk=2;   %plot for this behavioral condition
    %    [val,idx]=sort(peakdffTime(:,kk));        %sort the cells by peak dF/F
    subplot(2,6,[4 5 10 11]);
    image(trialavgtime,[1:1:numel(roi)],trialavgZ(:,idx,kk)','CDataMapping','scaled');
    hold on; plot([0 0],[0 numel(roi)+1],'w','LineWidth',3);
    colormap(jet);
    caxis([minZ maxZ]);      %normalize dF/F heatmap to max of all conditions
    ylabel('Cells, sorted');
    xlabel('Time from cue (s)');
    title(['Sound rule+right; ' int2str(sum(tempTrialMask(:,kk))) ' trials']);
    
    %plot color bar for legend
    subplot(2,6,12);
    image([0],linspace(minZ,maxZ,100),linspace(minZ,maxZ,100)','CDataMapping','scaled');
    colormap(jet);
    caxis([minZ maxZ]);
    title('z-score');
    set(gca,'YDir','normal');
    set(gca,'xtick',[]);
    
    set(gcf,'Position',[40 40 700 1000]);
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig3a', '-jpg', '-painters', '-r100', '-transparent');
    saveas(gcf, 'Fig3a', 'fig'); %fig format
end

save([newroot_dir 'dffBehav.mat'],...
    'trigRespWindow','binWidth','peakdffTime','trialavgtime','trialavgdff','trialavgZ',...
    '-append');

%% -----  plot dF/F-difference heatmap triggered on 2 types of behavioral event
if (plotFig3b)
    tempTrialMask=[];
    tempTrialMask(:,1,1)=trialMask.sound & trialMask.hit & trialMask.left;
    tempTrialMask(:,1,2)=trialMask.sound & trialMask.hit & trialMask.right;
    tempTrialMask(:,2,1)=trialMask.action & trialMask.hit & trialMask.left;
    tempTrialMask(:,2,2)=trialMask.action & trialMask.hit & trialMask.right;
    tempTrialMask(:,3,1)=trialMask.miss & trialMask.lastmiss & trialMask.upsweep;
    tempTrialMask(:,3,2)=trialMask.miss & trialMask.lastmiss & trialMask.downsweep;
    
    %find trial-averaged fluorescence by binning
    trialavgDiff=[];
    for kk=1:3
        temp=[];
        for i=1:length(roi)
            [trialavgtime,temp(:,i,1)]=trialaverage(t,dff(:,i),trigCueTime(squeeze(tempTrialMask(:,kk,1))==1),trigRespWindow,binWidth);
            [trialavgtime,temp(:,i,2)]=trialaverage(t,dff(:,i),trigCueTime(squeeze(tempTrialMask(:,kk,2))==1),trigRespWindow,binWidth);
        end
        trialavgDiff(:,:,kk)=(temp(:,:,1)-temp(:,:,2))./(temp(:,:,1)+temp(:,:,2));
    end
    
    figure;
    
    kk=1;   %plot for this behavioral condition
    
    %sort by amplitude at specified time
    tIdx=[sum(trialavgtime<=sortRespTime(1)):sum(trialavgtime<=sortRespTime(2))];
    %sort GABAergic cells first, then unidentified cells
    idx=[];
    [val,tempidx]=sort(nanmean(trialavgDiff(tIdx,gabaLabel,kk),1));
    idx=gabaLabel(tempidx);
    [val,tempidx]=sort(nanmean(trialavgDiff(tIdx,nongabaLabel,kk),1));
    idx=[idx nongabaLabel(tempidx)];
    %        [val,idx]=sort(nanmean(trialavgDiff(end/2:end,:,kk),1));
    
    temp=trialavgDiff(:,:,kk);
    maxFluo=max(temp(:));
    minFluo=-maxFluo;
    subplot(2,6,[1 2 7 8]);
    image(trialavgtime,[1:1:numel(roi)],trialavgDiff(:,idx,kk)','CDataMapping','scaled');
    hold on; plot([0 0]-binWidth/2,[0 numel(roi)+1],'w','LineWidth',3);
    plot([trialavgtime(1) trialavgtime(end)],(numel(gabaLabel)+0.5)*[1 1],'w','LineWidth',3); %plot white line to separate GABA from non-GABA cells
    colormap(jet);
    caxis([minFluo maxFluo]);      %normalize dF/F heatmap to max of all conditions
    ylabel('Cells, sorted');
    xlabel('Time from cue (s)');
    title(['Sound, L minus R; ' int2str(sum(tempTrialMask(:,kk,1))) '/' int2str(sum(tempTrialMask(:,kk,2))) ' trials']);
    subplot(2,6,9);
    image([0],linspace(minFluo,maxFluo,100),linspace(minFluo,maxFluo,100)','CDataMapping','scaled');
    colormap(jet);
    caxis([minFluo maxFluo]);
    title(['Norm. diff.']);
    set(gca,'YDir','normal');
    
    set(gcf,'Position',[40 40 700 1000]);
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig3b', '-jpg', '-painters', '-r100', '-transparent');
    saveas(gcf, 'Fig3b', 'fig'); %fig format
    
    save([newroot_dir 'dffBehav.mat'],...
        'trigRespWindow','binWidth','trialavgtime','trialavgDiff',...
        '-append');
end

%% plot scatterplot of sound vs action dF/F at t=0
if (plotFig3c) && ~isempty(switchTrial)
    
    avgdffSvsA=[];  %cell-by-cell, averaged dF/F around cue peruiod
    pvaldffSvsA=[]; %cell-by-cell, Wilcoxon rank-sum test to test diff of dF/F around cue period
    for kk=1:6
        tempMask=[];
        if kk==1
            tempMask(:,1)=trialMask.soundAfterAR & (trialMask.hit & trialMask.left & trialMask.upsweep) & (trialMask.lasthit & trialMask.lastleft);
            tempMask(:,2)=trialMask.actionleft & (trialMask.hit & trialMask.left & trialMask.upsweep) & (trialMask.lasthit & trialMask.lastleft);
        elseif kk==2
            tempMask(:,1)=trialMask.soundAfterAL & (trialMask.hit & trialMask.left & trialMask.upsweep) & (trialMask.lasthit & trialMask.lastleft);
            tempMask(:,2)=trialMask.actionleft & (trialMask.hit & trialMask.left & trialMask.upsweep) & (trialMask.lasthit & trialMask.lastleft);
        elseif kk==3
            tempMask(:,1)=trialMask.soundAfterAR & (trialMask.hit & trialMask.left & trialMask.upsweep) & (trialMask.lasthit & trialMask.lastleft);
            tempMask(:,2)=trialMask.soundAfterAL & (trialMask.hit & trialMask.left & trialMask.upsweep) & (trialMask.lasthit & trialMask.lastleft);
            
        elseif kk==4
            tempMask(:,1)=trialMask.soundAfterAL & (trialMask.hit & trialMask.right & trialMask.downsweep) & (trialMask.lasthit & trialMask.lastright);
            tempMask(:,2)=trialMask.actionright & (trialMask.hit & trialMask.right & trialMask.downsweep) & (trialMask.lasthit & trialMask.lastright);
        elseif kk==5
            tempMask(:,1)=trialMask.soundAfterAR & (trialMask.hit & trialMask.right & trialMask.downsweep) & (trialMask.lasthit & trialMask.lastright);
            tempMask(:,2)=trialMask.actionright & (trialMask.hit & trialMask.right & trialMask.downsweep) & (trialMask.lasthit & trialMask.lastright);
        elseif kk==6
            tempMask(:,1)=trialMask.soundAfterAL & (trialMask.hit & trialMask.right & trialMask.downsweep) & (trialMask.lasthit & trialMask.lastright);
            tempMask(:,2)=trialMask.soundAfterAR & (trialMask.hit & trialMask.right & trialMask.downsweep) & (trialMask.lasthit & trialMask.lastright);
        end
        
        % calculate the mean signals for the different conditions
        for i=1:length(roi)
            [~,avgdffSvsA(1,i,kk)]=trialaverage(t,dff(:,i),trigCueTime(squeeze(tempMask(:,1))==1),sortCueTime,range(sortCueTime));
            [~,avgdffSvsA(2,i,kk)]=trialaverage(t,dff(:,i),trigCueTime(squeeze(tempMask(:,2))==1),sortCueTime,range(sortCueTime));
        end
        
        % calculate whether rule-dependent modulation is stat. sig. for each cell
        trialIdx1=find(tempMask(:,1)==1);
        tempdff=[];
        for j=1:numel(trialIdx1)
            tIdx1=sum((trigCueTime(trialIdx1(j))+sortCueTime(1))>=t);
            tIdx2=sum((trigCueTime(trialIdx1(j))+sortCueTime(2))>=t);
            tempdff1(j,:)=nanmean(dff(tIdx1:tIdx2,:),1); %per-trial dF/F around cue period
        end
        trialIdx2=find(tempMask(:,2)==1);
        tempdff=[];
        for j=1:numel(trialIdx2)
            tIdx1=sum((trigCueTime(trialIdx2(j))+sortCueTime(1))>=t);
            tIdx2=sum((trigCueTime(trialIdx2(j))+sortCueTime(2))>=t);
            tempdff2(j,:)=nanmean(dff(tIdx1:tIdx2,:),1); %per-trial dF/F around cue period
        end
        for jj=1:numel(roi)
            pvaldffSvsA(kk,jj)=ranksum(tempdff1(:,jj),tempdff2(:,jj));
        end
    end
    
    for jj=1:2
        if jj==1
            tempLabel=nongabaLabel; celltitlelabel='Unidentified cells'; col='k';
        else
            tempLabel=gabaLabel; celltitlelabel='GABAergic neurons'; col='g';
        end
        
        figure;
        for kk=1:6
            if kk==1
                titlelabel='Sound-before-AL vs AL (L)';
            elseif kk==2
                titlelabel='Sound-after-AL vs AL (L)';
            elseif kk==3
                titlelabel='Sound-before-AL vs Sound-after-AR (L)';
            elseif kk==4
                titlelabel='Sound-before-AR vs AR (R)';
            elseif kk==5
                titlelabel='Sound-after-AR vs AR (R)';
            elseif kk==6
                titlelabel='Sound-before-AR vs Sound-after-AR (R)';
            end
            
            % plot the scatter plots
            temp=avgdffSvsA(:,tempLabel,:);
            maxFluo=max(temp(:));
            
            subplot(2,3,kk); hold on;
            plot([0 maxFluo],[0 maxFluo],'k','LineWidth',1);
            plot(avgdffSvsA(1,tempLabel,kk),avgdffSvsA(2,tempLabel,kk),'.','Color',[0.5 0.5 0.5],'MarkerSize',15);
            for ll=1:2
                tempmean(ll)=mean(avgdffSvsA(ll,tempLabel,kk));
                tempsem(ll)=std(avgdffSvsA(ll,tempLabel,kk))/sqrt(numel(tempLabel));
            end
            plot(tempmean(1)*[1 1],tempmean(2)+tempsem(2)*[-1 1],col,'LineWidth',3);
            plot(tempmean(1)+tempsem(2)*[-1 1],tempmean(2)*[1 1],col,'LineWidth',3);
            axis([0 maxFluo 0 maxFluo]); axis square;
            title({titlelabel;celltitlelabel});
            xlabel('dF/F, sound trials');
            ylabel('dF/F, action trials');
        end
        
        set(gcf,'Position',[40 40 1400 1000]);
        set(gcf, 'PaperPositionMode', 'auto');
        cd(savefigpath);
        export_fig(gcf, ['Fig3b-' int2str(jj)], '-jpg', '-painters', '-r130', '-transparent');
        saveas(gcf, ['Fig3b-' int2str(jj)], 'fig'); %fig format
    end
    
    save([newroot_dir 'dffBehav.mat'],...
        'avgdffSvsA','pvaldffSvsA',...
        '-append');
end

%% plot fluorescence averaged across certain trials for a specific cell
if (plotFig4)
    
    %to plot every cell, one by one
    specialCells=[1:numel(roi)];
    
    tempTrialMask=[];
    if ~isnan(specialCells)
        bootavgCell=[]; bootlowCell=[]; boothighCell=[];
        for i=1:numel(specialCells)
            for kk=1:4
                switch kk
                    case 1
                        tempTrialMask{kk}=trialMask.sound & trialMask.left & trialMask.upsweep & trialMask.hit & trialMask.excludelastblock;
                    case 2
                        tempTrialMask{kk}=trialMask.sound & trialMask.right & trialMask.downsweep & trialMask.hit & trialMask.excludelastblock;
                    case 3
                        tempTrialMask{kk}=trialMask.action & trialMask.left & trialMask.upsweep & trialMask.hit & trialMask.excludelastblock;
                    case 4
                        tempTrialMask{kk}=trialMask.action & trialMask.right & trialMask.downsweep & trialMask.hit & trialMask.excludelastblock;
                end
                [bootavgtime,bootavgCell(:,kk),bootlowCell(:,kk),boothighCell(:,kk)] = trialbootstrap(t,dff(:,specialCells(i)),trigCueTime(tempTrialMask{kk}),plotRespWindow(1),plotRespWindow(2),plotBinWidth,numBootstrapRep,CI);
                if mod(kk,2)==0
                    [bootavgtime,bootdiffavgCell(:,round(kk/2)),bootdifflowCell(:,round(kk/2)),bootdiffhighCell(:,round(kk/2))]=trialbootstrapDiff(t,dff(:,specialCells(i)),trigCueTime(tempTrialMask{kk-1}),trigCueTime(tempTrialMask{kk}),plotRespWindow(1),plotRespWindow(2),plotBinWidth,numBootstrapRep,CI);
                end
            end
            
            minFluo=min(bootlowCell(:));
            maxFluo=max(boothighCell(:));
            
            close;
            figure;
            
            %plot emphasizing choice-dependent differences
            subplot(2,4,1); hold on;
            for kk=[1 2]
                errorshade(bootavgtime,bootavgCell(:,kk)',bootlowCell(:,kk)',boothighCell(:,kk)',[0.7 0.7 0.7]);
            end
            plot(bootavgtime,bootavgCell(:,1),'k','LineWidth',3);
            plot(bootavgtime,bootavgCell(:,2),'k--','LineWidth',3);
            plot([0 0],[minFluo maxFluo],'k');
            xlabel('Time from cue (s)'); ylabel('dF/F');
            ylim([minFluo maxFluo]);
            xlim([plotRespWindow(1) plotRespWindow(2)]);
            if ~isempty(find(sstLabel==specialCells(i),1))
                title(['Cell ' int2str(specialCells(i)) ', SST']);
            elseif ~isempty(find(pvLabel==specialCells(i),1))
                title(['Cell ' int2str(specialCells(i)) ', PV']);
            else
                title(['Cell ' int2str(specialCells(i)) ', putative exc']);
            end
            
            subplot(2,4,2); hold on;
            for kk=[3 4]
                errorshade(bootavgtime,bootavgCell(:,kk)',bootlowCell(:,kk)',boothighCell(:,kk)',[0.7 0.7 0.7]);
            end
            plot(bootavgtime,bootavgCell(:,3),'r','LineWidth',3);
            plot(bootavgtime,bootavgCell(:,4),'b','LineWidth',3);
            plot([0 0],[minFluo maxFluo],'k');
            xlabel('Time from cue (s)');
            ylim([minFluo maxFluo]);
            xlim([plotRespWindow(1) plotRespWindow(2)]);
            
            %plot just the legend
            h1=[];
            subplot(2,4,3); hold on;
            h1(1)=plot([0 1],[0 0],'k','LineWidth',3);
            h1(2)=plot([0 1],[0 0],'k--','LineWidth',3);
            h1(3)=plot([0 1],[0 0],'r','LineWidth',3);
            h1(4)=plot([0 1],[0 0],'b','LineWidth',3);
            legend(h1,'Up/L/Hit/Sound','Down/R/Hit/Sound','Up/L/Hit/Action','Down/R/Hit/Action','Location','northwest');
            legend('boxoff');
            ylim([0 3]);
            xlim([0 1]);
            
            %plot emphasizing the choice selectivity
            kk=1;
            subplot(2,4,5); hold on;
            errorshade(bootavgtime,bootdiffavgCell(:,kk)',bootdifflowCell(:,kk)',bootdiffhighCell(:,kk)',[0.7 0.7 0.7]);
            plot(bootavgtime,bootdiffavgCell(:,kk),'k','LineWidth',3);
            plot([0 0],[-1 1],'k');
            plot([plotRespWindow(1) plotRespWindow(2)],[0 0],'k');
            xlabel('Time from cue (s)'); ylabel('Norm. diff. (L-R)');
            ylim([-1 1]);
            xlim([plotRespWindow(1) plotRespWindow(2)]);
            
            kk=2;
            subplot(2,4,6); hold on;
            errorshade(bootavgtime,bootdiffavgCell(:,kk)',bootdifflowCell(:,kk)',bootdiffhighCell(:,kk)',[0.7 0.7 0.7]);
            plot(bootavgtime,bootdiffavgCell(:,kk),'r','LineWidth',3);
            plot([0 0],[-1 1],'k');
            plot([plotRespWindow(1) plotRespWindow(2)],[0 0],'k');
            xlabel('Time from cue (s)');
            ylim([-1 1]);
            xlim([plotRespWindow(1) plotRespWindow(2)]);
            
            tempavgleft=[]; tempavgright=[];
            if ~isempty(switchTrial)
                %calculate per-block, average dF/F for left or right pre-switch hit trials
                for kk=1:numel(currTrial)
                    tempMask=false(size(hit_miss));
                    if kk==1
                        tempMask(1:switchTrial(kk)-1)=true;
                    elseif kk==numel(currTrial)
                        tempMask(switchTrial(kk-1):numel(hit_miss))=true;
                    else
                        tempMask(switchTrial(kk-1):switchTrial(kk)-1)=true;
                    end
                    tempMaskLeft=trialMask.left & trialMask.upsweep & trialMask.hit & tempMask;
                    tempMaskRight=trialMask.right & trialMask.downsweep & trialMask.hit & tempMask;
                    
                    [temptime,tempavgleft(:,kk)]=trialaverage(t,dff(:,specialCells(i)),trigCueTime(tempMaskLeft),plotRespWindow,plotBinWidth);
                    [temptime,tempavgright(:,kk)]=trialaverage(t,dff(:,specialCells(i)),trigCueTime(tempMaskRight),plotRespWindow,plotBinWidth);
                end
                
                subplot(2,4,4); hold on;
                plot(temptime,tempavgleft(:,blockMask.sound),'k','LineWidth',2);
                plot(temptime,tempavgright(:,blockMask.sound),'k--','LineWidth',2);
                plot(temptime,tempavgleft(:,blockMask.actionleft),'r','LineWidth',2);
                plot(temptime,tempavgright(:,blockMask.actionright),'b','LineWidth',2);
                
                plot([0 0],[min(([tempavgleft(:); tempavgright(:)])) max(([tempavgleft(:); tempavgright(:)]))],'k');
                xlabel('Time from cue (s)'); ylabel('dF/F, per block');
                ylim([min(([tempavgleft(:); tempavgright(:)])) max(([tempavgleft(:); tempavgright(:)]))]);
                xlim([plotRespWindow(1) plotRespWindow(2)]);
                
                for jj=1:2
                    if jj==1
                        sortTime=sortCueTime;
                    elseif jj==2
                        sortTime=sortRespTime;
                    end
                    
                    subplot(2,4,6+jj); hold on;
                    tIdx=[sum(temptime<=sortTime(1)) sum(temptime<=sortTime(2))];
                    
                    validIdx=~isnan(tempavgleft(1,:));
                    plot(find(validIdx),nanmean(tempavgleft(tIdx,validIdx),1),'k-','LineWidth',3);
                    for kk=find(validIdx)
                        if currTrial(kk)==CODE_CUE
                            col='k';
                        elseif currTrial(kk)==CODE_ACTIONLEFT
                            col='r';
                        end
                        plot(kk,nanmean(tempavgleft(tIdx,kk),1),[col '.'],'MarkerSize',45);
                    end
                    
                    validIdx=~isnan(tempavgright(1,:));
                    plot(find(validIdx),nanmean(tempavgright(tIdx,validIdx),1),'k--','LineWidth',3);
                    for kk=find(validIdx)
                        if currTrial(kk)==CODE_CUE
                            col='k';
                        elseif currTrial(kk)==CODE_ACTIONRIGHT
                            col='b';
                        end
                        plot(kk,nanmean(tempavgright(tIdx,kk),1),[col 'o'],'MarkerSize',15,'LineWidth',2);
                    end
                    
                    ylim([min(([tempavgleft(:); tempavgright(:)])) max(([tempavgleft(:); tempavgright(:)]))]);
                    xlim([0 numel(switchTrial)+1]);
                    ylabel(['dF/F [' int2str(sortTime(1)) ', ' int2str(sortTime(2)) ']']);
                    xlabel('Block');
                end
            end
            
            set(gcf,'Position',[40 40 1300 600]);  %laptop
            set(gcf, 'PaperPositionMode', 'auto');
            cd(savefigpath);
            
            print(gcf,'-dpng',['Fig4-cell' int2str(specialCells(i))]);
            %            saveas(gcf, ['Fig4-cell' int2str(specialCells(i))], 'fig'); %fig format
            %            export_fig(gcf, ['Fig4-cell' int2str(specialCells(i))], '-jpg', '-painters', '-r240', '-transparent');
            
            clear cidx colors compareCase compareLabel;
        end
        clear bootavgCell bootlowCell boothighCell bootavgCell bootlowCell boothighCell;
    end
end

%% ----- Multiple linear regression: C(t), C(t-1), interactions for sound guided trials

%NOTE: would be interesting to look for reward coding, but regression
%would be unbalanced because not all choice x reward combinations are
%experienced by the animal, e.g. few errors

if (plotFig5a)
    
    %using sound trials; R(t-1)=1; R(t)=1
    trialSubset=(trialMask.sound & trialMask.hit & trialMask.lasthit);
    
    factorActionSound=trialMask.left(trialSubset);  %get rid of miss trials; left=1, right=0
    factorLastActionSound=trialMask.lastleft(trialSubset);
    factorLastLastActionSound=trialMask.lastlastleft(trialSubset);
    factorsSound = [2*(factorActionSound-0.5)' 2*(factorLastActionSound-0.5)' 2*(factorLastLastActionSound-0.5)'];     %1 if left, -1 if right
    terms=[[0 0 0]; [1 0 0]; [0 1 0]; [1 1 0]; [0 0 1]];
    
    pCoeffSound=[]; %pvalue for the fitted slope
    betaSound=[];   %slope
    warning('off','MATLAB:singularMatrix');
    warning('off','stats:pvaluedw:ExactUnavailable');
    for i=1:numel(roi)    %for each cell
        
        %multiple linear regression with moving window to see which behavioral variables explain dF/F variability
        trigRespinterdffSound=squeeze(interdffbyTrial(:,i,trialSubset));
        trigRespintert=[trigRespWindow(1):interdt:trigRespWindow(2)];
        RespRegtime=[trigRespWindow(1):RegMovingStep:trigRespWindow(2)-RegMovingWinDur];
        for jj=1:numel(RespRegtime)
            idx1=sum(trigRespintert<=RespRegtime(jj));
            idx2=sum(trigRespintert<=(RespRegtime(jj)+RegMovingWinDur));
            tempdff=squeeze(nanmean(trigRespinterdffSound(idx1:idx2,:),1));
            
            stats=regstats(tempdff',factorsSound,terms);
            for kk=1:size(terms,1)-1
                pCoeffSound(jj,i,kk)=stats.tstat.pval(kk+1);
                betaSound(jj,i,kk)=stats.beta(kk+1);
            end
        end
    end
    warning('on','MATLAB:singularMatrix');
    warning('on','stats:pvaluedw:ExactUnavailable');
    
    %plot results
    figure; hold on;
    patch([trigRespWindow(1) trigRespWindow(2) trigRespWindow(2) trigRespWindow(1)]',[0 0 RegpvalThresh RegpvalThresh]',[0.8 0.8 0.8],'EdgeColor','none');
    plot(RespRegtime+RegMovingWinDur,sum(pCoeffSound(:,:,1)<RegpvalThresh,2)/numel(roi),'b','LineWidth',3);
    plot(RespRegtime+RegMovingWinDur,sum(pCoeffSound(:,:,2)<RegpvalThresh,2)/numel(roi),'k','LineWidth',3);
    plot(RespRegtime+RegMovingWinDur,sum(pCoeffSound(:,:,3)<RegpvalThresh,2)/numel(roi),'k--','LineWidth',3);
    plot(RespRegtime+RegMovingWinDur,sum(pCoeffSound(:,:,4)<RegpvalThresh,2)/numel(roi),'k:','LineWidth',3);
    plot([0 0],[0 1],'k','LineWidth',1);
    legend('binomial test p=0.01','C(n)','C(n-1)','C(n) x C(n-1)','C(n-2)');
    legend('boxoff');
    xlim([trigRespWindow(1)-0.5 trigRespWindow(2)+0.5]);
    ylim([0 1]);
    title('Sound rule, multiple linear regression');
    xlabel('Time from cue (s)');
    ylabel('Fraction of neurons');
    
    set(gcf,'Position',[40 40 500 500]);
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig5', '-jpg', '-painters', '-r100', '-transparent');
    saveas(gcf, 'Fig5', 'fig'); %fig format
    
    save([newroot_dir 'dffBehav.mat'],...
        'RespRegtime','RegMovingWinDur','pCoeffSound','betaSound',...
        '-append');
end

%% ensemble analysis, dPCA
if (plotFig6a) && ~isempty(switchTrial)
    dffbyTrial=aligndffByTime(t,dff,trigRespTime,stateRespWindow);
    dffbyTrial=permute(dffbyTrial,[2 1 3]); %becomes -> cell x time x trials
    
    %classify function does not handle nan; nan occurs if dffbytrial refers to time < 0 before imaging actually starts
    dffbyTrial(isnan(dffbyTrial))=0;
    
    %demixed PCA, calling code from Brendel and Machens, NIPS, 2011 paper
    numPCAcomp=3;   %number of PCA components to save
    Y=[];
    Y(:,:,1)=nanmean(dffbyTrial(:,:,trialMask.left & trialMask.soundPreSwitch & trialMask.hit),3);
    Y(:,:,2)=nanmean(dffbyTrial(:,:,trialMask.right & trialMask.soundPreSwitch & trialMask.hit),3);
    Y(:,:,3)=nanmean(dffbyTrial(:,:,trialMask.left & trialMask.actionPreSwitch & trialMask.hit),3);
    Y(:,:,4)=nanmean(dffbyTrial(:,:,trialMask.right & trialMask.actionPreSwitch & trialMask.hit),3);
    %adding evalc wrapper to prevent disp from [evect]=dpca(Y,numPCAcomp,1000,[]);
    [T,evect]=evalc('dpca(Y,numPCAcomp,1000,[]);');
    disp(['Demixed PCA, using ' num2str(numPCAcomp) ' principal components.']);
    
    %all variance (those due to task that can be captured, plus those not due to task like variability of Poisson spike train)
    temp=reshape(dffbyTrial,numel(roi),size(dffbyTrial,2)*size(dffbyTrial,3));   %cell x time-trials
    temp(isnan(temp))=0;
    covMat=cov(temp');
    totalVar=sum(diag(covMat));
    %find variance captured by plain-vanilla PCA
    [V1,D1] = eig(covMat);
    pcaeval=diag(D1);     %pick out the eigenvalues
    [pcaeval,pcaevalidx]=sort(pcaeval,'descend');
    pcaevect=V1(:,pcaevalidx);    %pick out eigenvectors
    clear V1 D1;
    projtemp=[];
    for i=1:size(temp,2)
        for j=1:numPCAcomp
            projtemp(j,i)=dot(temp(:,i)',pcaevect(:,j));
        end
    end
    pcaprojVar=diag(cov(projtemp'));
    pcavarcaptured=sum(pcaprojVar/totalVar)*100;
    disp(['Variance captured by PCA, ' int2str(numPCAcomp) ' dimensions : ' num2str(pcavarcaptured) '%']);
    %find variance captured by dPCA
    projtemp=[];
    for i=1:size(temp,2)
        for j=1:numPCAcomp
            projtemp(j,i)=dot(temp(:,i)',evect(:,j));
        end
    end
    projVar=diag(cov(projtemp'));
    varcaptured=sum(projVar/totalVar)*100;
    disp(['Variance captured by demixed PCA, ' int2str(numPCAcomp) ' dimensions : ' num2str(varcaptured) '%']);
    
    dffbyTrial=permute(dffbyTrial,[2 1 3]); %reverts back to -> time x cell x trials
    
    %% project trial-averaged ensemble activity onto the reduced dimensional space
    projdff=[];     %for every time point, project onto PCA space
    for i=1:size(dff,1)
        for j=1:numPCAcomp
            projdff(i,j)=dot(dff(i,:),evect(:,j));
        end
    end
    projdffbyTrial=aligndffByTime(t,projdff,trigRespTime,stateRespWindow); %divide the projections by trials, time x dim x trial
    
    % plot the trial-averaged ensemble trajectory along each dimensions
    figure;
    numStep=size(projdffbyTrial,1);
    
    factors=[]; col=[];
    factors(:,1)=trialMask.left & trialMask.soundPreSwitch & trialMask.hit; col{1}='k';
    factors(:,2)=trialMask.right & trialMask.soundPreSwitch & trialMask.hit; col{2}='k--';
    factors(:,3)=trialMask.left & trialMask.actionPreSwitch & trialMask.hit; col{3}='r';
    factors(:,4)=trialMask.right & trialMask.actionPreSwitch & trialMask.hit; col{4}='r--';
    
    % Project the trial-averaged ensemble activity onto each principal component
    for jj=1:size(factors,2)
        trialIdx=find(factors(:,jj)==1);   %find trial with outcome desired
        if ~isempty(trialIdx) %if there are those trials..
            
            %find projection of trial-averaged activity
            temptrigdff=mean(dffbyTrial(:,:,trialIdx),3);   %trial-averaged fluorescence
            meanprojtrigdffpos=[];
            for i=1:size(temptrigdff,1)    %for every time point, project onto PCA space
                for j=1:numPCAcomp
                    meanprojtrigdffpos(i,j)=dot(temptrigdff(i,:),evect(:,j));
                end
            end
            
            %go to each subplot, plot along the relevant PC dimension
            for j=1:numPCAcomp
                subplot(2,3,j); hold on;
                plot([stateRespWindow(1):dt:stateRespWindow(1)+(numStep-1)*dt],meanprojtrigdffpos(:,j),col{jj},'LineWidth',3);
                xlabel('Time from response (s)'); ylabel(['PC' int2str(j)]);
                xlim([stateRespWindow(1) stateRespWindow(1)+(numStep-1)*dt]);
            end
            
            %also plot in 3D
            subplot(2,3,4); hold on;
            plot3(meanprojtrigdffpos(:,1),meanprojtrigdffpos(:,2),meanprojtrigdffpos(:,3),col{jj},'LineWidth',3);
            xlabel('{\color{black}PC1}'); ylabel('{\color{black}PC2}'); zlabel('{\color{black}PC3}');
            view([90 90 90]);
            axis tight; axis square;
            grid on; set(gca,'XColor',[0.5 0.5 0.5]); set(gca,'YColor',[0.5 0.5 0.5]); set(gca,'ZColor',[0.5 0.5 0.5]);
        end
    end
    subplot(2,3,3);
    legend('Left, Sound','Right, Sound','Left, Action','Right, Action');
    legend('boxoff');
    
    %how well can the projected ensemble activity decode animal's choice?
    factors=[];
    factors(:,1)=trialMask.left & trialMask.soundPreSwitch & trialMask.hit;
    factors(:,2)=trialMask.right & trialMask.soundPreSwitch & trialMask.hit;
    [choicePredbyEns,choicePredbyEnsLow,choicePredbyEnsHigh]=LDAbootstrap(projdffbyTrial, factors, fracLDA, numRepLDA, CI); %linear classifier
    subplot(2,3,6); hold on;
    errorshade([stateRespWindow(1):dt:stateRespWindow(1)+(numStep-1)*dt],choicePredbyEns',choicePredbyEnsLow',choicePredbyEnsHigh',[0.7 0.7 0.7]);
    plot([stateRespWindow(1) stateRespWindow(1)+(numStep-1)*dt],[0.5 0.5],'k','LineWidth',1);
    plot([stateRespWindow(1):dt:stateRespWindow(1)+(numStep-1)*dt],choicePredbyEns,'k','LineWidth',3);
    xlabel('Time from response (s)'); ylabel('Classifier accuracy');
    title(['L vs R in Sound (' int2str(sum(factors(:,1))) '/' int2str(sum(factors(:,2))) ')']);
    xlim([stateRespWindow(1) stateRespWindow(1)+(numStep-1)*dt]);
    ylim([0.3 1]);
    
    set(gcf,'Position',[40 40 1200 600]);  %laptop
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig6a', '-jpg', '-painters', '-r100', '-transparent');
    saveas(gcf, 'Fig6a', 'fig'); %fig format
end

%% compare distance between ensemble trajectories across blocks
if (plotFig6b) && ~isempty(switchTrial)
    
    % quantify distance between ensemble trajectories for different types of rule blocks
    trajPreSwitch=[]; %per-block ensemble trajectories, averaging pre-switch trials belonging to each block
    for kk=1:size(dffbyTrial,1)
        for k=1:numel(switchTrial)
            trialIdx=false(1,numel(hit_miss));
            trialIdx(switchTrial(k)-20:switchTrial(k)-1)=true;
            trialIdx=trialIdx & trialMask.hit;        %pre-switch & hit trials
            temp=mean(dffbyTrial(kk,:,trialIdx),3);   %the average of these trials
            for j=1:numPCAcomp
                trajPreSwitch(j,kk,k)=dot(temp,evect(:,j));  %projection x time x block
            end
        end
    end
    
    %estimate spread for this experiment by calculating root-mean-square distance
    centroid=nanmean(nanmean(trajPreSwitch,3),2);
    xdist=trajPreSwitch(1,:,:)-centroid(1); ydist=trajPreSwitch(2,:,:)-centroid(2); zdist=trajPreSwitch(3,:,:)-centroid(3);
    trajRMSdist=sqrt(mean(xdist(:).^2+ydist(:).^2+zdist(:).^2));
    
    %calculate Euclidean distance between one block and another block
    distBetTraj=[];
    for kkk=1:7
        if kkk==1
            blockList1=find(blockMask.sound==1);
            blockList2=find(blockMask.sound==1);
        elseif kkk==2
            blockList1=find(blockMask.actionleft==1);
            blockList2=find(blockMask.actionleft==1);
        elseif kkk==3
            blockList1=find(blockMask.actionright==1);
            blockList2=find(blockMask.actionright==1);
        elseif kkk==4
            blockList1=find(blockMask.sound==1);
            blockList2=find(blockMask.actionleft==1);
        elseif kkk==5
            blockList1=find(blockMask.sound==1);
            blockList2=find(blockMask.actionright==1);
        elseif kkk==6
            blockList1=find(blockMask.actionleft==1);
            blockList2=find(blockMask.actionright==1);
        elseif kkk==7
            blockList1=find(blockMask.all==1);
            blockList2=find(blockMask.all==1);
        end
        
        dist=[nan];
        for j=1:numel(blockList1)
            for jj=1:numel(blockList2)
                if blockList1(j)~=blockList2(jj) %comparing across different blocks, skip if it's the same block in both lists
                    temp=[];
                    for kk=1:size(trajPreSwitch,2)
                        temp(kk)=sqrt(sum((trajPreSwitch(:,kk,blockList1(j))-trajPreSwitch(:,kk,blockList2(jj))).^2));
                    end
                    dist=[dist mean(temp)];
                end
            end
        end
        distBetTraj(kkk)=nanmean(dist);
    end
    
    %% calculate how ensemble trajectory moves after block switch, as animal adapts
    distFromOrigin=nan(1000,numel(switchTrial)-1); %distance between current trajectory and pre-switch trajectory of last rule block
    distFromDest=nan(1000,numel(switchTrial)-1);   %distance between current trajectory and pre-switch trajectory of current rule block
    distRatio=nan(1000,numel(switchTrial)-1); %the ratio of the above distances
    
    for kkk=1:numel(switchTrial)-1
        
        %references are the individual ensemble patterns (not averaged) before switch
        origintrialIdx=false(1,numel(hit_miss));
        origintrialIdx(switchTrial(kkk)-20:switchTrial(kkk)-1)=true;    %20 trials pre-switch, last rule block
        origintrialIdx=origintrialIdx & trialMask.hit;
        desttrialIdx=false(1,numel(hit_miss));
        desttrialIdx(switchTrial(kkk+1)-20:switchTrial(kkk+1)-1)=true;  %20 trials pre-switch, current rule block
        desttrialIdx=desttrialIdx & trialMask.hit;
        trajOrigin=[]; trajDest=[];
        for kk=1:size(dffbyTrial,1) %for each time point
            temp=squeeze(dffbyTrial(kk,:,origintrialIdx));
            for ii=1:size(temp,2)
                for jjj=1:numPCAcomp
                    trajOrigin(kk,jjj,ii)=dot(temp(:,ii),evect(:,jjj)); %time x projection x #trial pre switch
                end
            end
            temp=squeeze(dffbyTrial(kk,:,desttrialIdx));
            for ii=1:size(temp,2)
                for jjj=1:numPCAcomp
                    trajDest(kk,jjj,ii)=dot(temp(:,ii),evect(:,jjj));
                end
            end
        end
        
        %for each trial from switch, calculate distances to origin and destination, and their ratio
        distorigin=[]; distdest=[];
        for trialIdx=switchTrial(kkk)-20:1:switchTrial(kkk+1)-1    %from 20 trial pre-switch to next switch
            %projection of the current trial
            temptrigdff=mean(dffbyTrial(:,:,trialIdx),3);   %trial-averaged fluorescence
            for i=1:size(temptrigdff,1)    %for every time point, project onto PCA space
                for j=1:numPCAcomp
                    projtrigdff(i,j)=dot(temptrigdff(i,:),evect(:,j));
                end
            end
            
            %calculate the Mahalanobis distance from origin, for each time point
            temp=[];
            for kk=1:size(trajPreSwitch,1)    %at specific time point
                temp(kk)=sqrt(mahal(projtrigdff(kk,:),squeeze(trajOrigin(kk,:,:))'));
            end
            distorigin=[distorigin median(temp)];
            
            %calculate the Mahalanobis distance from dest, for each time point
            temp=[];
            for kk=1:size(trajPreSwitch,1)    %at specific time point
                temp(kk)=sqrt(mahal(projtrigdff(kk,:),squeeze(trajDest(kk,:,:))'));
            end
            distdest=[distdest median(temp)];
        end
        
        distFromOrigin(1:numel(distorigin),kkk)=distorigin;
        distFromDest(1:numel(distdest),kkk)=distdest;
        distRatio(1:numel(distorigin),kkk)=(distorigin)./(distorigin+distdest);
    end
    
    save([newroot_dir 'dffBehav.mat'],...
        'stateRespWindow','trajRMSdist','distBetTraj',...
        'distFromOrigin','distFromDest','distRatio','-append');
end

%% compare single-cell and ensemble decoding of rule
if (plotFig6c) && ~isempty(switchTrial)
    
    %% decoding rule using ensemble or single-cell dF/F
    % i.e. if I pick dF/F value(s) from any one imaging frame pre-switch, what is the predicted rule?
    factors=[];
    factors(:,1)=trialMask.soundPreSwitch & trialMask.hit;
    factors(:,2)=trialMask.actionPreSwitch & trialMask.left & trialMask.hit;
    factors(:,3)=trialMask.actionPreSwitch & trialMask.right & trialMask.hit;
    
    outcomebyTrial=1*factors(:,1)+2*factors(:,2)+3*factors(:,3);
    outcomebyTrial=outcomebyTrial(factors(:,1) | factors(:,2) | factors(:,3)); %retain only relevant trials, so contain a subset of trials now
    
    %the dF/F (for decoding using single cells)
    dffbyTrialSubset=dffbyTrial(:,:,factors(:,1) | factors(:,2) | factors(:,3));
    %the projection (for decoding using ensemble activity)
    projdffbyTrialSubset=projdffbyTrial(:,:,factors(:,1) | factors(:,2) | factors(:,3));
    %the behavioral outcomes, reformat matrix so behavioral outcome has same matrix dimension as dF/F
    outcomebyTrialSubset=repmat(outcomebyTrial,1,size(projdffbyTrialSubset,1))';
    
    numTrialLDA=round(fracLDA*numel(outcomebyTrial));   %use subset of trials to train classifier
    
    temprulePred=[]; %correct % overall, decoding using ensemble
    corrSound=[]; corrAL=[]; corrAR=[]; %correct % for classifying into these rule types, decoding using ensemble
    FPSound=[]; FPAL=[]; FPAR=[]; %false positive % for classifying into these rule types, decoding using ensemble
    temprulePredbyCell=[]; %correct % overall, decoding using single cells
    for jj=1:numRepLDA
        %draw a random subset of TRIALS (not imaging frames) to construct the classifier
        drawNum=randsample(numel(outcomebyTrial),numTrialLDA,'false'); %each time draw another set without replacement
        drawIndex=zeros(1,numel(outcomebyTrial));
        drawIndex(drawNum)=1;   %convert the drawn numbers into zeros and ones
        drawIndex=logical(drawIndex);
        
        %k-fold validation, use ensemble activity to predict rule of trials not drawn
        LDAset=reshape(permute(projdffbyTrialSubset(:,:,drawIndex),[2 1 3]),3,numel(projdffbyTrialSubset(:,:,drawIndex))/3);
        testset=reshape(permute(projdffbyTrialSubset(:,:,~drawIndex),[2 1 3]),3,numel(projdffbyTrialSubset(:,:,~drawIndex))/3);
        LDAoutcome=reshape(outcomebyTrialSubset(:,drawIndex),1,numel(outcomebyTrialSubset(:,drawIndex)));
        testoutcome=reshape(outcomebyTrialSubset(:,~drawIndex),1,numel(outcomebyTrialSubset(:,~drawIndex)));
        
        outcomebyLDA=classify(testset',LDAset',LDAoutcome','mahalanobis');
        temprulePred(jj)=sum(outcomebyLDA==testoutcome')/numel(outcomebyLDA);
        corrSound(jj)=sum(outcomebyLDA==1 & testoutcome'==1)/sum(testoutcome'==1);
        corrAL(jj)=sum(outcomebyLDA==2 & testoutcome'==2)/sum(testoutcome'==2);
        corrAR(jj)=sum(outcomebyLDA==3 & testoutcome'==3)/sum(testoutcome'==3);
        FPSound(jj)=sum(outcomebyLDA==1 & testoutcome'~=1)/sum(testoutcome'~=1);
        FPAL(jj)=sum(outcomebyLDA==2 & testoutcome'~=2)/sum(testoutcome'~=2);
        FPAR(jj)=sum(outcomebyLDA==3 & testoutcome'~=3)/sum(testoutcome'~=3);
        
        %k-fold validation, ensemble, predict pre-shift trials, using dF/F of each cell
        for i=1:numel(roi)
            LDAset=reshape(squeeze(dffbyTrialSubset(:,i,drawIndex)),1,numel(dffbyTrialSubset(:,i,drawIndex)));
            testset=reshape(squeeze(dffbyTrialSubset(:,i,~drawIndex)),1,numel(dffbyTrialSubset(:,i,~drawIndex)));
            LDAoutcome=reshape(outcomebyTrialSubset(:,drawIndex),1,numel(outcomebyTrialSubset(:,drawIndex)));
            testoutcome=reshape(outcomebyTrialSubset(:,~drawIndex),1,numel(outcomebyTrialSubset(:,~drawIndex)));
            outcomebyLDA=classify(testset',LDAset',LDAoutcome','mahalanobis');
            temprulePredbyCell(i,jj)=sum(outcomebyLDA==testoutcome')/numel(outcomebyLDA);
        end
    end
    rulePredEns=mean(temprulePred);
    rulePredbyCell=mean(temprulePredbyCell,2);
    rulePredLowbyCell=quantile(temprulePredbyCell,0.025,2);
    rulePredHighbyCell=quantile(temprulePredbyCell,0.975,2);
    
    figure;
    subplot(2,2,1); hold on;
    plot(1,100*nanmedian(corrSound),'k.','MarkerSize',30);
    plot([1 1],100*[prctile(corrSound,25) prctile(corrSound,75)],'k-','LineWidth',3);
    plot(2,100*nanmedian(corrAL),'k.','MarkerSize',30);
    plot([2 2],100*[prctile(corrAL,25) prctile(corrAL,75)],'k-','LineWidth',3);
    plot(3,100*nanmedian(corrAR),'k.','MarkerSize',30);
    plot([3 3],100*[prctile(corrAR,25) prctile(corrAR,75)],'k-','LineWidth',3);
    xlim([0.5 3.5]); ylim([0 105]);
    ylabel('Correct (%)'); xlabel('Actual rule');
    set(gca,'xticklabel',{'Sound' 'ActionL' 'ActionR'},'xtick',1:1:3);
    title('Rule classification, using ensemble');
    
    subplot(2,2,2); hold on;
    plot(1,100*nanmedian(FPSound),'k.','MarkerSize',30);
    plot([1 1],100*[prctile(FPSound,25) prctile(FPSound,75)],'k-','LineWidth',3);
    plot(2,100*nanmedian(FPAL),'k.','MarkerSize',30);
    plot([2 2],100*[prctile(FPAL,25) prctile(FPAL,75)],'k-','LineWidth',3);
    plot(3,100*nanmedian(FPAR),'k.','MarkerSize',30);
    plot([3 3],100*[prctile(FPAR,25) prctile(FPAR,75)],'k-','LineWidth',3);
    xlim([0.5 3.5]); ylim([0 105]);
    ylabel('False positive (%)'); xlabel('Actual rule');
    set(gca,'xticklabel',{'Sound' 'ActionL' 'ActionR'},'xtick',1:1:3);
    title('Rule classification, using ensemble');
    
    subplot(2,2,3); hold on;
    plot([1 numel(roi)],100*rulePredEns*[1 1],'r--','LineWidth',3);
    bar([1:1:numel(roi)],100*rulePredbyCell,'k');
    plot([1 numel(roi)],[33.3 33.3],'k','LineWidth',1);
    axis([1 numel(roi) 0 100]);
    ylabel('Classifier accuracy (%)'); xlabel('Cells');
    title('Rule classification, ensemble vs single-cell');
    
    %compute trial type classifier accuracy over time
    rulePredbyTime=[]; rulePredLowdbyTime=[]; rulePredHighdbyTime=[];
    
    projdffbyTrialSubset=projdffbyTrial(:,:,factors(:,1) | factors(:,2) | factors(:,3)); %take out all the other trials
    outcomebyTrial=1*factors(:,1)+2*factors(:,2)+3*factors(:,3);  %eg set 1 for sound trials
    outcomebyTrial=outcomebyTrial(factors(:,1) | factors(:,2) | factors(:,3)); %retain only relevant trials, so contain a subset of trials now
    numTrialLDA=round(fracLDA*numel(outcomebyTrial));   %use subset of trials to train classifier
    temprulePred=[];
    for i=1:numStep
        for jj=1:numRepLDA
            drawNum=randsample(numel(outcomebyTrial),numTrialLDA,'false'); %each time draw another set without replacement
            drawIndex=zeros(1,numel(outcomebyTrial));
            drawIndex(drawNum)=1;   %convert the drawn numbers into zeros and ones
            drawIndex=logical(drawIndex);
            
            %k-fold validation
            outcomebyLDA=classify(squeeze(projdffbyTrialSubset(i,:,~drawIndex))',squeeze(projdffbyTrialSubset(i,:,drawIndex))',outcomebyTrial(drawIndex)');
            temprulePred(i,jj)=sum(outcomebyLDA==outcomebyTrial(~drawIndex))/numel(outcomebyLDA);
        end
    end
    rulePredbyTime=mean(temprulePred,2);
    rulePredLowbyTime=quantile(temprulePred,0.05,2);
    rulePredHighbyTime=quantile(temprulePred,0.95,2);
    
    subplot(2,2,4); hold on;
    errorshade([stateRespWindow(1):dt:stateRespWindow(1)+(numStep-1)*dt],100*rulePredbyTime',100*rulePredLowbyTime',100*rulePredHighbyTime',[0.7 0.7 0.7]);
    plot([stateRespWindow(1) stateRespWindow(1)+(numStep-1)*dt],[33.3 33.3],'k','LineWidth',1);
    plot([stateRespWindow(1):dt:stateRespWindow(1)+(numStep-1)*dt],100*rulePredbyTime,'k','LineWidth',3);
    xlabel('Time from response (s)'); ylabel('Classifier accuracy (%)');
    title('Rule classification, using ensemble');
    xlim([stateRespWindow(1) stateRespWindow(1)+(numStep-1)*dt]);
    ylim([0 100]);
    
    set(gcf,'Position',[40 40 1200 700]);  %laptop
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig6d', '-jpg', '-painters', '-r100', '-transparent');
    saveas(gcf, 'Fig6d', 'fig'); %fig format
    
    save([newroot_dir 'dffBehav.mat'],...
        'rulePredEns','rulePredbyCell','rulePredLowbyCell','rulePredHighbyCell',...
        'rulePredbyTime','rulePredLowbyTime','rulePredHighbyTime',...
        'corrSound','corrAL','corrAR','FPSound','FPAL','FPAR',...
        '-append');
end

%% single-cell decoding of choice (can do on discrimination task too)
if (plotFig6d)
    % choice coding is expected to be time-dependent, so need to calculate as function of time
    dffbyTrial=aligndffByTime(t,dff,trigCueTime,choiceRespWindow); %time x cell x trials
    
    factors=[];
    notfirstTrial=[0 ones(1,numel(trialMask.hit)-1)]; %the choiceRespWindow goes <0, so exclude first trial when there is no data for t<0
    notlastTrial=[ones(1,numel(trialMask.hit)-1) 0];%the choiceRespWindow goes out of range, so exclude last trial
    
    factors(:,1)=trialMask.sound & trialMask.left & trialMask.hit & notfirstTrial & notlastTrial; %left hit
    factors(:,2)=trialMask.sound & trialMask.right & trialMask.hit & notfirstTrial & notlastTrial; %right hit
    
    dffbyTrialSubset=dffbyTrial(:,:,factors(:,1) | factors(:,2)); %take out all the other trials, %error and miss trials
    outcomebyTrial=1*factors(:,1)+2*factors(:,2);  %eg set 1 for left
    outcomebyTrial=outcomebyTrial(factors(:,1) | factors(:,2)); %retain only relevant trials, so contain a subset of trials now %pick out hit trials
    numTrialLDA=round(fracLDA*numel(outcomebyTrial));   %use subset of trials to train classifier
    
    %compute trial type classifier accuracy over time
    choicePredbyCell=[];
    tempchoicePred=[];
    
    numStep=size(dffbyTrial,1);
    for i=1:numStep
        for jj=1:numRepLDA
            drawNum=randsample(numel(outcomebyTrial),numTrialLDA,'false'); %each time draw another set without replacement
            drawIndex=zeros(1,numel(outcomebyTrial));
            drawIndex(drawNum)=1;   %convert the drawn numbers into zeros and ones
            drawIndex=logical(drawIndex);
            
            %k-fold validation, predict pre-shift trials, using dF/F of each cell
            for ii=1:numel(roi)
                outcomebyLDA=classify(squeeze(dffbyTrialSubset(i,ii,~drawIndex)),squeeze(dffbyTrialSubset(i,ii,drawIndex)),outcomebyTrial(drawIndex)'); %training sample contains NaN
                tempchoicePred(i,ii,jj)=sum(outcomebyLDA==outcomebyTrial(~drawIndex))/numel(outcomebyLDA);
            end
        end
    end
    choicePredbyCell=mean(tempchoicePred,3);
    
    figure;
    subplot(1,2,1); hold on;
    plot([choiceRespWindow(1) choiceRespWindow(1)+(numStep-1)*dt],[0.5 0.5],'k','LineWidth',1);
    for ii=1:numel(roi)
        plot([choiceRespWindow(1):dt:choiceRespWindow(1)+(numStep-1)*dt],choicePredbyCell(:,ii),'LineWidth',1);
    end
    xlabel('Time from cue (s)'); ylabel('Classifier accuracy');
    title('Choice classification - each line is a cell');
    xlim([choiceRespWindow(1) choiceRespWindow(1)+(numStep-1)*dt]);
    ylim([0 1]);
    
    subplot(1,2,2); hold on;
    plot([choiceRespWindow(1) choiceRespWindow(1)+(numStep-1)*dt],[0.5 0.5],'k','LineWidth',1);
    plot([choiceRespWindow(1):dt:choiceRespWindow(1)+(numStep-1)*dt],median(choicePredbyCell,2),'k','LineWidth',3);
    plot([choiceRespWindow(1):dt:choiceRespWindow(1)+(numStep-1)*dt],max(choicePredbyCell,[],2),'k','LineWidth',3);
    plot([choiceRespWindow(1):dt:choiceRespWindow(1)+(numStep-1)*dt],min(choicePredbyCell,[],2),'k','LineWidth',3);
    xlabel('Time from cue (s)'); ylabel('Classifier accuracy');
    title('Choice classification - median, max, and min');
    xlim([choiceRespWindow(1) choiceRespWindow(1)+(numStep-1)*dt]);
    ylim([0 1]);
    
    set(gcf,'Position',[40 40 1000 400]);  %laptop
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig6g', '-jpg', '-painters', '-r100', '-transparent');
    saveas(gcf, 'Fig6g', 'fig'); %fig format
    
    save([newroot_dir 'dffBehav.mat'],...
        'choiceRespWindow','choicePredbyCell',...
        '-append');
end