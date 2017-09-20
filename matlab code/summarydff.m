% set up figure plotting
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

savefigpath = [newroot_dir 'figs-summary/'];
if ~exist(savefigpath,'dir')
    mkdir(savefigpath);
end

%% collect the analyzed data
numExpt=numel(datafiles);   %number of experiments to summarize
disp('---------------');
disp(['Loading ' int2str(numExpt) ' sets of data']);

trialavgZArray=[]; trialavgDiffArray=[]; peakdffTimeArray=[];
distBetTrajArray=[];
distRatioFromActionToSound=[]; distRatioFromSoundToAction=[];
trialCritSoundArray=[]; trialCritActionArray=[]; trialCritSoundExptIDArray=[]; trialCritActionExptIDArray=[];
corrSoundArray=[]; corrALArray=[]; corrARArray=[]; FPSoundArray=[]; FPALArray=[]; FPARArray=[];
rulePredEnsArray=[]; rulePredbyCellArray=[]; rulePredLowbyCellArray=[]; rulePredbyTimeArray=[];
pCoeffSoundArray=[]; choiceCells=[];

sstLabel=[]; pvLabel=[]; gabaLabel=[]; nongabaLabel=[];
avgdffSvsAArray=[];
pvaldffSvsAArray=[];

currCell=1;
for kk=1:numExpt
    
    cd(newroot_dir);
    if ~isempty(datafiles(kk).sub_dir)
        cd(datafiles(kk).sub_dir);
    end
    load('dffBehav.mat');
    
    dt=1/frameRate;
    numTrialArray(kk)=sum(trialMask.hit)+sum(trialMask.error);
    numMissArray(kk)=sum(trialMask.miss);
    numRewardArray(kk)=sum(trialMask.hit);
    roiArray(kk)=numel(roi);
    
    for i=1:numel(roi)
        if ~isempty(find(datafiles(kk).sstCells==i,1))
            sstLabel=[sstLabel currCell];
            gabaLabel=[gabaLabel currCell];
        elseif ~isempty(find(datafiles(kk).pvCells==i,1))
            pvLabel=[pvLabel currCell];
            gabaLabel=[gabaLabel currCell];
        else
            nongabaLabel=[nongabaLabel currCell];
        end
        currCell=currCell+1;
    end
    
    trialavgZArray=[trialavgZArray trialavgZ];
    trialavgDiffArray=[trialavgDiffArray trialavgDiff];
    peakdffTimeArray=[peakdffTimeArray; peakdffTime];
    
    pCoeffSoundArray=[pCoeffSoundArray pCoeffSound];
    %choice selective at t=3 s from response
    pvalThresh=0.01;
    choiceCells=[choiceCells (pCoeffSound(sum(RespRegtime<3),:,1)<pvalThresh)];
    
    
    if ~isempty(switchTrial)
        avgdffSvsAArray=[avgdffSvsAArray avgdffSvsA];
        pvaldffSvsAArray=[pvaldffSvsAArray pvaldffSvsA];
        
        distBetTrajArray=[distBetTrajArray; distBetTraj/trajRMSdist];
        
        %note: first switch is from sound --> ACTION, and assignment of first block is sound
        distRatioFromSoundToAction=[distRatioFromSoundToAction distRatio(:,blockMask.sound(1:end-1))]; %from sound -> ACTION
        distRatioFromActionToSound=[distRatioFromActionToSound distRatio(:,blockMask.action(1:end-1))]; %from action -> SOUND, define it as sound so it matches trial to criterion
        
        trialCrit=[switchTrial(1) diff(switchTrial)];
        trialCritSoundArray=[trialCritSoundArray trialCrit(blockMask.sound & blockMask.excludefirstblock)];
        trialCritActionArray=[trialCritActionArray trialCrit(blockMask.action)];
        
        corrSoundArray=[corrSoundArray nanmedian(corrSound)];
        corrALArray=[corrALArray nanmedian(corrAL)];
        corrARArray=[corrARArray nanmedian(corrAR)];
        FPSoundArray=[FPSoundArray nanmedian(FPSound)];
        FPALArray=[FPALArray nanmedian(FPAL)];
        FPARArray=[FPARArray nanmedian(FPAR)];
        rulePredEnsArray(:,kk)=rulePredEns;
        rulePredbyCellArray=[rulePredbyCellArray; rulePredbyCell];
        rulePredLowbyCellArray=[rulePredLowbyCellArray; rulePredLowbyCell];
        rulePredbyTimeArray(:,kk)=rulePredbyTime;
    end
end

disp(['Total number of ROIs = ' int2str(sum(roiArray)) '; range of #ROI per session: ' int2str(min(roiArray)) '-' int2str(max(roiArray))]);

%% plot heatmap of dF/F z-score for left vs right choice
figure;
for kk=1:4
    minZ=-1; maxZ=2;
    
    %sort GABAergic cells first, then unidentified cells
    idx=[];
    [val,tempidx]=sort(peakdffTimeArray(gabaLabel,kk));
    idx=gabaLabel(tempidx);
    [val,tempidx]=sort(peakdffTimeArray(nongabaLabel,kk));
    idx=[idx nongabaLabel(tempidx)];
    
    subplot(1,5,kk);
    image(trialavgtime,[1:1:sum(roiArray)],trialavgZArray(:,idx,kk)','CDataMapping','scaled');
    hold on; plot([0 0],[0 sum(roiArray)+1],'w','LineWidth',3);
    plot([trialavgtime(1) trialavgtime(end)],(numel(gabaLabel)+0.5)*[1 1],'w','LineWidth',3); %plot white line to separate GABA from non-GABA cells
    colormap(jet);
    caxis([minZ maxZ]);      %normalize dF/F heatmap to max of all conditions
    
    if kk==1
        title('S/L/Hit');
        ylabel('Cells, sorted');
        xlabel('Time from cue (s)');
    elseif kk==2
        title('S/R/Hit');
        set(gca,'ytick',[]);
    elseif kk==3
        title('AL/Hit');
        set(gca,'ytick',[]);
    elseif kk==4
        title('AR/Hit');
        set(gca,'ytick',[]);
    end
end

%plot color bar for legend
subplot(3,8,16);
image([0],linspace(minZ,maxZ,100),linspace(minZ,maxZ,100)','CDataMapping','scaled');
colormap(jet);
caxis([minZ maxZ]);
title('z-score');
set(gca,'YDir','normal');
set(gca,'xtick',[]);

set(gcf,'Position',[40 40 1000 1000]);  %laptop
set(gcf, 'PaperPositionMode', 'auto');
cd(savefigpath);
export_fig(gcf, 'Fig1', '-jpg', '-painters', '-r100', '-transparent');
saveas(gcf, 'Fig1', 'fig'); %fig format

%% plot heatmap of choice preference (L-R)/(L+R) for sound vs action rules
sortRespTime=[1 3];

figure;
for kk=1:2
    temp=trialavgDiffArray;
    
    %sort by amplitude at specified time
    tIdx=[sum(trialavgtime<=sortRespTime(1)):sum(trialavgtime<=sortRespTime(2))];
    %sort GABAergic cells first, then unidentified cells
    idx=[];
    [val,tempidx]=sort(nanmean(temp(tIdx,gabaLabel,kk),1));
    idx=gabaLabel(tempidx);
    [val,tempidx]=sort(nanmean(temp(tIdx,nongabaLabel,kk),1));
    idx=[idx nongabaLabel(tempidx)];
    
    maxFluo=0.7;
    minFluo=-maxFluo;
    
    subplot(1,5,kk);
    image(trialavgtime,[1:1:size(temp,2)],temp(:,idx,kk)','CDataMapping','scaled');
    hold on; plot([0 0]-binWidth/2,[0 size(temp,2)+1],'w','LineWidth',3);
    plot([trialavgtime(1) trialavgtime(end)],(numel(gabaLabel)+0.5)*[1 1],'w','LineWidth',3); %plot white line to separate GABA from non-GABA cells
    colormap(jet);
    caxis([minFluo maxFluo]);      %normalize dF/F heatmap to max of all conditions
    if kk==1
        ylabel('Cells, sorted');
        title(['S/(L-R)/Hit']);
        xlabel('Time from cue (s)');
    else
        title(['A/(L-R)/Hit']);
        set(gca,'ytick',[]);
    end
    ylim([0 size(temp,2)+1]);
end

subplot(3,8,16);
image([0],linspace(minFluo,maxFluo,100),linspace(minFluo,maxFluo,100)','CDataMapping','scaled');
colormap(jet);
caxis([minFluo maxFluo]);
title(['Norm. diff.']);
set(gca,'YDir','normal');
set(gca,'xtick',[]);

set(gcf,'Position',[40 40 1000 1000]);  %laptop
set(gcf, 'PaperPositionMode', 'auto');
cd(savefigpath);
export_fig(gcf, 'Fig2', '-jpg', '-painters', '-r300', '-transparent');
saveas(gcf, 'Fig2', 'fig'); %fig format

%% summary of multiple linear regression analysis
figure;
subplot(1,3,1); hold on;
patch([trigRespWindow(1) trigRespWindow(2) trigRespWindow(2) trigRespWindow(1)]',[0 0 100*pvalThresh 100*pvalThresh]',[0.8 0.8 0.8],'EdgeColor','none');
plot(RespRegtime+RegMovingWinDur/2,100*sum(pCoeffSoundArray(:,:,1)<pvalThresh,2)/sum(roiArray),'k.-','LineWidth',2,'MarkerSize',20);
plot([0 0],[0 100],'k','LineWidth',1);
xlim([trigRespWindow(1) trigRespWindow(2)]);
ylim([0 40]);
ylabel('Fraction of cells (%)');
sig=[];
for ll=1:numel(RespRegtime) %plotting significant segments found via binomial test
    [p]=myBinomTest(sum(pCoeffSoundArray(ll,:,1)<pvalThresh,2),sum(roiArray),pvalThresh);
    sig(ll)=p;
end
for ll=1:numel(sig)
    if sig(ll)<0.01
        plot(RespRegtime(ll)+RegMovingWinDur*[-0.5 0.5],[35 35],'k-','LineWidth',3);
    end
end
title('C(n)');

subplot(1,3,2); hold on;
patch([trigRespWindow(1) trigRespWindow(2) trigRespWindow(2) trigRespWindow(1)]',[0 0 100*pvalThresh 100*pvalThresh]',[0.8 0.8 0.8],'EdgeColor','none');
plot(RespRegtime+RegMovingWinDur/2,100*sum(pCoeffSoundArray(:,:,2)<pvalThresh,2)/sum(roiArray),'k.-','LineWidth',2,'MarkerSize',20);
plot(RespRegtime+RegMovingWinDur/2,100*sum(pCoeffSoundArray(:,:,3)<pvalThresh,2)/sum(roiArray),'k:','LineWidth',2);
plot([0 0],[0 100],'k','LineWidth',1);
xlim([trigRespWindow(1) trigRespWindow(2)]);
ylim([0 40]);
xlabel('Time from cue (s)');
sig=[];
for ll=1:numel(RespRegtime) %plotting significant segments found via binomial test
    [p]=myBinomTest(sum(pCoeffSoundArray(ll,:,2)<pvalThresh,2),sum(roiArray),pvalThresh);
    sig(ll)=p;
end
for ll=1:numel(sig)
    if sig(ll)<0.01
        plot(RespRegtime(ll)+RegMovingWinDur*[-0.5 0.5],[35 35],'k-','LineWidth',3);
    end
end
title('C(n-1)');

subplot(1,3,3); hold on;
patch([trigRespWindow(1) trigRespWindow(2) trigRespWindow(2) trigRespWindow(1)]',[0 0 100*pvalThresh 100*pvalThresh]',[0.8 0.8 0.8],'EdgeColor','none');
plot(RespRegtime+RegMovingWinDur/2,100*sum(pCoeffSoundArray(:,:,4)<pvalThresh,2)/sum(roiArray),'k.-','LineWidth',2,'MarkerSize',20);
plot([0 0],[0 100],'k','LineWidth',1);
xlim([trigRespWindow(1) trigRespWindow(2)]);
ylim([0 40]);
sig=[];
for ll=1:numel(RespRegtime) %plotting significant segments found via binomial test
    [p]=myBinomTest(sum(pCoeffSoundArray(ll,:,4)<pvalThresh,2),sum(roiArray),pvalThresh);
    sig(ll)=p;
end
for ll=1:numel(sig)
    if sig(ll)<0.01
        plot(RespRegtime(ll)+RegMovingWinDur*[-0.5 0.5],[35 35],'k-','LineWidth',3);
    end
end
title('C(n-2)');

set(gcf,'Position',[40 40 750 300]);  %laptop
set(gcf, 'PaperPositionMode', 'auto');
cd(savefigpath);
export_fig(gcf, 'Fig3', '-jpg', '-painters', '-r250', '-transparent');
saveas(gcf, 'Fig3', 'fig'); %fig format

%% the code starting from this line --- only applies to flexibility task
if ~isempty(switchTrial)
    %% scatter plots of context-dependence activity
    for jj=1:2
        if jj==1
            tempLabel=nongabaLabel; celltitlelabel='Unidentified cells'; col='k';
        else
            tempLabel=gabaLabel; celltitlelabel='GABAergic neurons'; col='g';
        end
        
        if ~isempty(tempLabel)
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
                temp=avgdffSvsAArray(:,tempLabel,:);
                maxFluo=max(temp(:));
                
                subplot(2,3,kk); hold on;
                plot([0 maxFluo],[0 maxFluo],'k','LineWidth',1);
                plot(avgdffSvsAArray(1,tempLabel,kk),avgdffSvsAArray(2,tempLabel,kk),'.','Color',[0.5 0.5 0.5],'MarkerSize',15);
                for ll=1:2
                    tempmean(ll)=mean(avgdffSvsAArray(ll,tempLabel,kk));
                    tempsem(ll)=std(avgdffSvsAArray(ll,tempLabel,kk))/sqrt(numel(tempLabel));
                end
                plot(tempmean(1)*[1 1],tempmean(2)+tempsem(2)*[-1 1],col,'LineWidth',3);
                plot(tempmean(1)+tempsem(2)*[-1 1],tempmean(2)*[1 1],col,'LineWidth',3);
                axis([0 maxFluo 0 maxFluo]); axis square;
                title({titlelabel;celltitlelabel});
                if kk==1 | kk==2 | kk==4 | kk==5
                    xlabel('dF/F, sound trials');
                    ylabel('dF/F, action trials');
                end
            end
            
            set(gcf,'Position',[40 40 1400 1000]);
            set(gcf, 'PaperPositionMode', 'auto');
            cd(savefigpath);
            export_fig(gcf, ['Fig4-' int2str(jj)], '-jpg', '-painters', '-r130', '-transparent');
            saveas(gcf, ['Fig4-' int2str(jj)], 'fig'); %fig format
        end
    end
    
    %% plot summary of separation between neural trajectories from different trial blockt ype
    figure;
    
    subplot(2,5,[1:4]); hold on;
    for kk=1:6
        plot(kk*ones(1,numExpt)-0.2*rand(1,numExpt),distBetTrajArray(:,kk),'k^','MarkerSize',10,'LineWidth',2);
        errorbar(kk+0.3,nanmean(distBetTrajArray(:,kk)),nanstd(distBetTrajArray(:,kk))./sqrt(sum(~isnan(distBetTrajArray(:,kk)))),'k^','MarkerSize',10,'LineWidth',2,'MarkerFaceColor','k');
    end
    xlim([0.5 6.5]); ylim([0 2.5]);
    set(gca,'xticklabel',{'S-S' '{\color{red}AL}-{\color{red}AL}' '{\color{blue}AR}-{\color{blue}AR}' 'S-{\color{red}AL}' 'S-{\color{blue}AR}' '{\color{red}AL}-{\color{blue}AR}' 'All'},'xtick',1:1:6);
    ylabel({'Normalized distance';'between trajectories'});
    
    set(gcf,'Position',[40 40 900 750]);  %laptop
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig5', '-jpg', '-painters', '-r270', '-transparent');
    saveas(gcf, 'Fig5', 'fig'); %fig format
    
    disp('Wilcoxon signed rank test of differences in neural trajectories:');
    [p,h,stats]=signrank(distBetTrajArray(:,1),distBetTrajArray(:,2))
    [p,h,stats]=signrank(distBetTrajArray(:,1),distBetTrajArray(:,3))
    [p,h,stats]=signrank(distBetTrajArray(:,1),distBetTrajArray(:,4))
    [p,h,stats]=signrank(distBetTrajArray(:,1),distBetTrajArray(:,5))
    [p,h,stats]=signrank(distBetTrajArray(:,1),distBetTrajArray(:,6))
    
    %% the mahal distances of neural transitions around block switches
    
    %do the logistic fit on individual transitions
    endSound=[]; steepSound=[]; midvalSound=[];
    endAction=[]; steepAction=[]; midvalAction=[];
    startTrial=15;
    for j=1:size(distRatioFromActionToSound,2)
        y=distRatioFromActionToSound(startTrial:end,j); %crop using data from startTrial to end
        x=[-(20-startTrial)+1:1:sum(~isnan(y))-(20-startTrial)]'; %the corresponding trial #'s
        y=y(~isnan(y));
        baseline=nanmean(y(1:(20-startTrial))); %the corresponding pre-switch baseline
        sigfunc = @(A, x)(A(1) ./ (1 + exp(-A(2)*(x-A(3)))));
        A0(1) = max(y);  %curve's max value, L
        A0(2) = 0.5;     %steepness, k (larger value, more steep)
        A0(3) = 10;      %transition trial, xo
        A_fit = nlinfit(x, y-baseline, sigfunc, A0);
        endSound(j)=A_fit(1);
        steepSound(j)=A_fit(2);
        midvalSound(j)=A_fit(3);
    end
    for j=1:size(distRatioFromSoundToAction,2)
        y=distRatioFromSoundToAction(startTrial:end,j); %from -5 trial to end
        x=[-(20-startTrial)+1:1:sum(~isnan(y))-(20-startTrial)]';
        y=y(~isnan(y));
        baseline=nanmean(y(1:(20-startTrial)));
        sigfunc = @(A, x)(A(1) ./ (1 + exp(-A(2)*(x-A(3)))));
        A0(1) = max(y);  %curve's max value, L
        A0(2) = 0.5;     %steepness, k
        A0(3) = 10;      %transition trial, xo
        A_fit = nlinfit(x, y-baseline, sigfunc, A0);
        endAction(j)=A_fit(1);
        steepAction(j)=A_fit(2);
        midvalAction(j)=A_fit(3);
    end
    
    % define transition trial as 75% point on logistic curve
    neuraltransDef=0.75;
    transvalSound=-1./steepSound*log((1-neuraltransDef)/neuraltransDef)+midvalSound;
    transvalAction=-1./steepAction*log((1-neuraltransDef)/neuraltransDef)+midvalAction;
    
    %if mid-value trial value <-5 or >300, not realistic so exclude
    excludeCrit=[-5 300];
    idxSound=(transvalSound>=excludeCrit(1)) & (transvalSound<excludeCrit(2));
    disp(['total ' int2str(numel(transvalSound)) ' -> sound switches; keep ' int2str(sum(idxSound)) 'trials after logistic fitting']);
    
    idxAction=(transvalAction>=excludeCrit(1)) & (transvalAction<excludeCrit(2));
    disp(['total ' int2str(numel(transvalAction)) ' ->action switches; keep ' int2str(sum(idxAction)) 'trials after logistic fitting']);
    
    %neural: sound vs. action
    disp(['--- neural: sound vs. action']);
    disp('median transition x-value for switch to sound');
    median(midvalSound(idxSound))
    disp('median transition x-value for switch to action');
    median(midvalAction(idxAction))
    disp('p-value, ranksum, transition x-value for switch to sound vs to action');
    [p,h,stats]=ranksum(midvalAction(idxAction),midvalSound(idxSound))
    
    disp('median steepness for switch to sound');
    median(steepSound(idxSound))
    disp('median steepness for switch to action');
    median(steepAction(idxAction))
    disp('p-value, ranksum, steepness for switch to sound vs to action');
    [p,h,stats]=ranksum(steepAction(idxAction),steepSound(idxSound))
    
    disp('median range for switch to sound');
    median(endSound(idxSound))
    disp('median range for switch to action');
    median(endAction(idxAction))
    disp('p-value, ranksum, range for switch to sound vs to action');
    [p,h,stats]=ranksum(endAction,endSound)
    
    %neural vs. behavior
    disp(['--- neural vs. behavior']);
    disp(['signed rank test, ' int2str(neuraltransDef*100) '% L vs behavior']);
    [p,h,stat]=signrank(round(transvalSound(idxSound)),round(trialCritSoundArray(idxSound)-20))
    [p,h,stat]=signrank(round(transvalAction(idxAction)),round(trialCritActionArray(idxAction)-20))
    
    disp('p-value, ranksum, trial to criterion for switch to sound vs to action');
    [p,h,stats]=ranksum(trialCritActionArray(idxAction)-20,trialCritSoundArray(idxSound)-20)
    
    %%
    figure;
    % make the scatter plot of behavioral vs neural transition trials
    maxTrial=60;
    subplot(1,2,1); hold on;
    plot([0 maxTrial],[0 maxTrial],'k');
    plot(transvalSound(idxSound),trialCritSoundArray(idxSound)-20,'.','Color',[0.7 0.7 0.7],'MarkerSize',20);
    plot(nanmedian(transvalSound(idxSound)),nanmedian(trialCritSoundArray(idxSound)-20),'ko','MarkerSize',15,'LineWidth',3);
    xlabel('Neural transition trial');
    ylabel('Behavioral transition trial');
    axis square;
    xlim([0 maxTrial]); ylim([0 maxTrial]);
    set(gca,'xtick',[0:20:maxTrial]); set(gca,'ytick',[0:20:maxTrial]);
    
    subplot(1,2,2); hold on;
    plot([0 maxTrial],[0 maxTrial],'k');
    plot(transvalAction(idxAction),trialCritActionArray(idxAction)-20,'.','Color',[0.7 0.7 0.7],'MarkerSize',20);
    plot(nanmedian(transvalAction(idxAction)),nanmedian(trialCritActionArray(idxAction)-20),'ro','MarkerSize',15,'LineWidth',3);
    xlabel('Neural transition trial');
    ylabel('Behavioral transition trial');
    axis square;
    xlim([0 maxTrial]); ylim([0 maxTrial]);
    set(gca,'xtick',[0:20:maxTrial]); set(gca,'ytick',[0:20:maxTrial]);
    
    set(gcf,'Position',[40 40 600 300]);  %laptop
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig6', '-jpg', '-painters', '-r275', '-transparent');
    saveas(gcf, 'Fig6', 'fig'); %fig format
    
    %% the mahal distances around block switches, fitting individual switches to logistic function
    figure;
    
    edges=[-1:2:19 100];
    subplot(2,6,[1 2]); hold on;
    nSound=histc(midvalSound(idxSound),edges)';
    bar([edges(1:end-1)+(edges(2)-edges(1))/2 edges(end-1)+3/2*(edges(2)-edges(1))],100*[nSound/nansum(nSound)],'k');
    plot(nanmedian(midvalSound(idxSound))*[1 1],[30 35],'k');
    xlim([edges(1) edges(end-1)+2*(edges(2)-edges(1))]);
    ylim([0 35]);
    xlabel('Midpoint trial, {\itx_o}');
    ylabel({'Fraction of';'transitions (%)'});
    
    subplot(2,6,[1 2]+6); hold on;
    nAction=histc(midvalAction(idxAction),edges)';
    bar([edges(1:end-1)+(edges(2)-edges(1))/2 edges(end-1)+3/2*(edges(2)-edges(1))],100*[nAction/nansum(nAction)],'r');
    plot(nanmedian(midvalAction(idxAction))*[1 1],[30 35],'r');
    plot(nanmedian(midvalSound(idxSound))*[1 1],[30 35],'k');
    xlim([edges(1) edges(end-1)+2*(edges(2)-edges(1))]);
    ylim([0 35]);
    xlabel('Midpoint trial, {\itx_o}');
    ylabel({'Fraction of';'transitions (%)'});
    
    edges=[-0.1:0.2:1.5 100];
    subplot(2,6,[3 4]); hold on;
    nSound=histc(steepSound(idxSound),edges)';
    b=bar([edges(1:end-1)+(edges(2)-edges(1))/2 edges(end-1)+3/2*(edges(2)-edges(1))],100*[nSound/nansum(nSound)],'k');
    plot(nanmedian(steepSound(idxSound))*[1 1],[45 50],'k');
    xlim([edges(1) edges(end-1)+2*(edges(2)-edges(1))]);
    ylim([0 50])
    xlabel('Steepness, {\itk}');
    
    subplot(2,6,[3 4]+6); hold on;
    nAction=histc(steepAction(idxAction),edges)';
    b=bar([edges(1:end-1)+(edges(2)-edges(1))/2 edges(end-1)+3/2*(edges(2)-edges(1))],100*[nAction/nansum(nAction)],'r');
    plot(nanmedian(steepAction(idxAction))*[1 1],[45 50],'r');
    plot(nanmedian(steepSound(idxSound))*[1 1],[45 50],'k');
    xlim([edges(1) edges(end-1)+2*(edges(2)-edges(1))]);
    ylim([0 50]);
    xlabel('Steepness, {\itk}');
    
    edges=[0:0.1:1 100];
    subplot(2,6,[5 6]); hold on;
    nSound=histc(endSound(idxSound),edges)';
    b=bar([edges(1:end-1)+(edges(2)-edges(1))/2 edges(end-1)+3/2*(edges(2)-edges(1))],100*[nSound/nansum(nSound)],'k');
    plot(nanmedian(endSound(idxSound))*[1 1],[45 50],'k');
    xlim([edges(1) edges(end-1)+2*(edges(2)-edges(1))]);
    ylim([0 50])
    xlabel('Range, {\itL}');
    
    subplot(2,6,[5 6]+6); hold on;
    nAction=histc(endAction(idxAction),edges)';
    b=bar([edges(1:end-1)+(edges(2)-edges(1))/2 edges(end-1)+3/2*(edges(2)-edges(1))],100*[nAction/nansum(nAction)],'r');
    plot(nanmedian(endAction(idxAction))*[1 1],[45 50],'r');
    plot(nanmedian(endSound(idxSound))*[1 1],[45 50],'k');
    xlim([edges(1) edges(end-1)+2*(edges(2)-edges(1))]);
    ylim([0 50]);
    xlabel('Range, {\itL}');
    
    set(gcf,'Position',[40 40 600 500]);  %laptop
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig7', '-jpg', '-painters', '-r300', '-transparent');
    saveas(gcf, 'Fig7', 'fig'); %fig format
    
    %% summary on accuracy of trial type classifier
    figure;
    
    subplot(2,2,1); hold on;
    plot(1*ones(size(corrSoundArray))-0.1*rand(size(corrSoundArray)),100*corrSoundArray,'k^','MarkerSize',10,'LineWidth',2);
    errorbar(1.2,nanmean(100*corrSoundArray),nanstd(100*corrSoundArray)/sqrt(numel(corrSoundArray)),'k^-','MarkerSize',10,'LineWidth',2,'MarkerFaceColor','k');
    plot(2*ones(size(corrALArray))-0.1*rand(size(corrALArray)),100*corrALArray,'r^','MarkerSize',10,'LineWidth',2);
    errorbar(2.2,nanmean(100*corrALArray),nanstd(100*corrALArray)/sqrt(numel(corrALArray)),'r^-','MarkerSize',10,'LineWidth',2,'MarkerFaceColor','r');
    plot(3*ones(size(corrARArray))-0.1*rand(size(corrARArray)),100*corrARArray,'b^','MarkerSize',10,'LineWidth',2);
    errorbar(3.2,nanmean(100*corrARArray),nanstd(100*corrARArray)/sqrt(numel(corrARArray)),'b^-','MarkerSize',10,'LineWidth',2,'MarkerFaceColor','b');
    plot([0.5 3.5],[33.3 33.3],'k--','LineWidth',1);
    xlim([0.5 3.5]); ylim([0 100]);
    ylabel({'Trial type classification';'accuracy (%)'});
    set(gca,'xticklabel',{'Sound' '{\color{red}AL}' '{\color{blue}AR}'},'xtick',1:1:3);
    temp=corrSoundArray; [mean(temp) nanstd(temp)/sqrt(numel(temp))]
    temp=corrALArray; [mean(temp) nanstd(temp)/sqrt(numel(temp))]
    temp=corrARArray; [mean(temp) nanstd(temp)/sqrt(numel(temp))]
    [h,p,ci,stats]=ttest(corrSoundArray-0.333)
    [h,p,ci,stats]=ttest(corrALArray-0.333)
    [h,p,ci,stats]=ttest(corrARArray-0.333)
    
    subplot(2,2,2); hold on;
    plot(1*ones(size(FPSoundArray))-0.1*rand(size(FPSoundArray)),100*FPSoundArray,'k^','MarkerSize',10,'LineWidth',2);
    errorbar(1.2,nanmean(100*FPSoundArray),nanstd(100*FPSoundArray)/sqrt(numel(FPSoundArray)),'k^-','MarkerSize',10,'LineWidth',2,'MarkerFaceColor','k');
    plot(2*ones(size(FPALArray))-0.1*rand(size(FPALArray)),100*FPALArray,'r^','MarkerSize',10,'LineWidth',2);
    errorbar(2.2,nanmean(100*FPALArray),nanstd(100*FPALArray)/sqrt(numel(FPALArray)),'r^-','MarkerSize',10,'LineWidth',2,'MarkerFaceColor','r');
    plot(3*ones(size(FPARArray))-0.1*rand(size(FPARArray)),100*FPARArray,'b^','MarkerSize',10,'LineWidth',2);
    errorbar(3.2,nanmean(100*FPARArray),nanstd(100*FPARArray)/sqrt(numel(FPARArray)),'b^-','MarkerSize',10,'LineWidth',2,'MarkerFaceColor','b');
    plot([0.5 3.5],[33.3 33.3],'k--','LineWidth',1);
    xlim([0.5 3.5]); ylim([0 100]);
    ylabel({'Mean false positive rate (%)'});
    set(gca,'xticklabel',{'Sound' '{\color{red}AL}' '{\color{blue}AR}'},'xtick',1:1:3);
    
    actualRule=[ones(1,100000) 2*ones(1,100000) 3*ones(1,100000)];
    randomPred=ceil(3*rand(1,300000));
    disp(['Given random rule decoding, accuracy = ' num2str(sum(randomPred==1 & actualRule==1)/sum(actualRule==1))]);
    disp(['Given random rule decoding, false positive rate = ' num2str(sum(randomPred==1 & actualRule~=1)/sum(actualRule~=1))]);
    
    %single-cell vs ensemble classifier accuracy
    subplot(2,2,3); hold on;
    for i=1:numel(roiArray)
        plot([1 sum(roiArray)],mean(100*rulePredEnsArray)*[1 1],'k-','LineWidth',3);
    end
    [val,idx]=sort(rulePredbyCellArray,'descend');
    for jj=1:sum(roiArray)
        if rulePredLowbyCellArray(idx(jj))>0.333
            plot(jj,100*rulePredbyCellArray(idx(jj)),'g.','MarkerSize',15);
        else
            plot(jj,100*rulePredbyCellArray(idx(jj)),'k.','MarkerSize',15);
        end
    end
    plot([1 sum(roiArray)],[33.3 33.3],'k--','LineWidth',1);
    axis([1 sum(roiArray) 0 100]);
    ylabel({'Trial type classification';'accuracy (%)'});
    xlabel('Cells');
    
    selCell=(rulePredLowbyCellArray>0.333);
    disp(['% cells rule-selective: ' num2str(sum(selCell)/numel(selCell))]);
    
    %ensemble classifier accuracy over time
    numStep=size(rulePredbyTimeArray,1);
    subplot(2,2,4); hold on;
    plot([stateRespWindow(1) stateRespWindow(1)+(numStep-1)*dt],[33.3 33.3],'k--','LineWidth',1);
    for kk=1:size(rulePredbyTimeArray,2)
        plot([stateRespWindow(1):dt:stateRespWindow(1)+(numStep-1)*dt],100*rulePredbyTimeArray(:,kk),'Color',[0.7 0.7 0.7],'LineWidth',2);
    end
    plot([stateRespWindow(1):dt:stateRespWindow(1)+(numStep-1)*dt],nanmean(100*rulePredbyTimeArray,2),'k','LineWidth',3);
    ylabel({'Trial type classification';'accuracy (%)'});
    xlabel('Time from response (s)');
    xlim([stateRespWindow(1) stateRespWindow(1)+(numStep-1)*dt]);
    ylim([0 100]);
    
    set(gcf,'Position',[40 40 600 600]);  %laptop
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig8', '-jpg', '-painters', '-r300', '-transparent');
    saveas(gcf, 'Fig8', 'fig'); %fig format
end