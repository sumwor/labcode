%% ----- summarybeh: summarize a set of .mat outputs from readDiscrimLogfile.m

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

%% ----- load the analyzed data

CODE_CUE=0; CODE_ACTIONLEFT=1; CODE_ACTIONRIGHT=2; %the current strategy

CODE_HITLEFT=1; CODE_INCORRECTLEFT=0; CODE_MISSLEFT=4; CODE_HITRIGHT=2; CODE_INCORRECTRIGHT=3; CODE_MISSRIGHT=5; CODE_PERSEVERLEFT=6; CODE_PERSEVERRIGHT=7; CODE_PERSEVERHITLEFT=8; CODE_PERSEVERHITRIGHT=9;
CODE_RIGHTSET_LEFTSTIM_HIT=11; CODE_RIGHTSET_LEFTSTIM_MISS=10; CODE_RIGHTSET_PERSEVERERR=12; CODE_RIGHTSET_INCORRECT=13; CODE_RIGHTSET_RIGHTSTIM_HIT=14; CODE_RIGHTSET_RIGHTSTIM_MISS=15;
CODE_LEFTSET_LEFTSTIM_HIT=21; CODE_LEFTSET_LEFTSTIM_MISS=20; CODE_LEFTSET_PERSEVERERR=22; CODE_LEFTSET_INCORRECT=23; CODE_LEFTSET_RIGHTSTIM_HIT=24; CODE_LEFTSET_RIGHTSTIM_MISS=25;

CODE_HITLEFTDOUBLE=-1; CODE_HITRIGHTDOUBLE=-2; CODE_HITLEFTZERO=-3; CODE_HITRIGHTZERO=-4;

disp('---------------');
disp(['Loading ' int2str(numel(datafiles)) ' sets of data']);

numTrial=[]; numHit=[]; numError=[]; numMiss=[]; numSwitch=[]; numSwitchTrials=[];
hitmissArray=[]; hitmissSoundArray=[]; hitmissActionArray=[];
meantrialCritSoundArray=[]; meantrialCritActionArray=[];
meantrialPErrSoundArray=[]; meantrialPErrActionArray=[]; meantrialOErrSoundArray=[]; meantrialOErrActionArray=[];
firstLickTimePreSwitchActionLeftArray=[]; firstLickTimePreSwitchActionRightArray=[];
firstLickTimeArray=[];
nLeftUpsweepArray=[]; nRightUpsweepArray=[]; nLeftDownsweepArray=[]; nRightDownsweepArray=[];

for kk=1:numel(datafiles)
    cd(newroot_dir);
    if ~isempty(datafiles(kk).sub_dir)
        cd(datafiles(kk).sub_dir);
    end
    
    load([datafiles(kk).logfile(1:end-4) '.mat']);
    
    numTrial(kk)=sum(trialMask.hit)+sum(trialMask.error);
    numHit(kk)=sum(trialMask.hit);
    numError(kk)=sum(trialMask.error);
    numPerError(kk)=sum(trialMask.pererror);
    numMiss(kk)=sum(trialMask.miss);
    
    numSwitch(kk)=numel(switchTrial);
    if ~isempty(switchTrial)
        numSwitchTrials(kk)=switchTrial(end)-1; %# trials, exclude last block
    else
        numSwitchTrials(kk)=numel(hit_miss);
    end
    switchTrialArray{kk}=switchTrial;
    currSetArray{kk}=currSet;
    currTrialArray{kk}=currTrial;
    startexptTime=startexptTime(1:numel(hit_miss));
    
    if ~isempty(switchTrial)        
        %trial to criterion, perseverative error, and other error per block        
        trialCrit=[switchTrial(1) diff(switchTrial)];
        meantrialCritSoundArray=[meantrialCritSoundArray nanmean(trialCrit(blockMask.sound & blockMask.excludefirstblock))];   
        meantrialCritActionArray=[meantrialCritActionArray nanmean(trialCrit(blockMask.action & blockMask.excludefirstblock))];
        meantrialPErrSoundArray=[meantrialPErrSoundArray sum(trialMask.pererror & trialMask.sound & trialMask.excludefirstblock & trialMask.excludelastblock)/sum(blockMask.sound & blockMask.excludefirstblock)];
        meantrialPErrActionArray=[meantrialPErrActionArray sum(trialMask.pererror & trialMask.action & trialMask.excludefirstblock & trialMask.excludelastblock)/sum(blockMask.action & blockMask.excludefirstblock)];
        meantrialOErrSoundArray=[meantrialOErrSoundArray sum(trialMask.otherror & trialMask.sound & trialMask.excludefirstblock & trialMask.excludelastblock)/sum(blockMask.sound & blockMask.excludefirstblock)];
        meantrialOErrActionArray=[meantrialOErrActionArray sum(trialMask.otherror & trialMask.action & trialMask.excludefirstblock & trialMask.excludelastblock)/sum(blockMask.action & blockMask.excludefirstblock)];
        
        %aligning hit_miss to switches, later to generate mean hit/error rates around switches
        hitmisstemp=[]; %trials from switch x #switches
        CODE_END=99;
        for jj=1:numel(switchTrial)-1
            tempSeg=hit_miss(switchTrial(jj)-20:switchTrial(jj+1)-1);
            hitmisstemp(:,jj+1)=[tempSeg CODE_END*ones(1,200-numel(tempSeg))]';     %save hit_miss record per block, fill the rest with nan
        end
        hitmissArray=[hitmissArray hitmisstemp(:,2:end)];
        hitmissSoundArray=[hitmissSoundArray hitmisstemp(:,blockMask.sound & blockMask.excludefirstblock)];
        hitmissActionArray=[hitmissActionArray hitmisstemp(:,blockMask.action)];
         
        %determine response time in various conditions
        %only considering the direction with the faster response for each animal
        firstLickTimeLeftArray(kk)=nanmean(firstLickTime(trialMask.soundAfterLeftPreSwitch & trialMask.left & trialMask.hit));
        firstLickTimeRightArray(kk)=nanmean(firstLickTime(trialMask.soundAfterRightPreSwitch & trialMask.right & trialMask.hit));
        if firstLickTimeLeftArray(kk)<firstLickTimeRightArray(kk)
            %use the left direction
            firstLickTimeArray(kk,1)=nanmean(firstLickTime(trialMask.left & trialMask.soundAfterLeftPreSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,2)=nanmean(firstLickTime(trialMask.left & trialMask.soundAfterRightPreSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,3)=nanmean(firstLickTime(trialMask.left & trialMask.actionPreSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,4)=nanmean(firstLickTime(trialMask.left & trialMask.actionPreSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,5)=nanmean(firstLickTime(trialMask.left & trialMask.soundAfterLeftPostSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,6)=nanmean(firstLickTime(trialMask.left & trialMask.soundAfterRightPostSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,7)=nanmean(firstLickTime(trialMask.left & trialMask.actionPostSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,8)=nanmean(firstLickTime(trialMask.left & trialMask.actionPostSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,9)=nanmean(firstLickTime(trialMask.left & trialMask.soundPostSwitch & trialMask.pererror));
            firstLickTimeArray(kk,10)=nanmean(firstLickTime(trialMask.left & trialMask.actionPostSwitch & trialMask.pererror));
        else
            firstLickTimeArray(kk,1)=nanmean(firstLickTime(trialMask.right & trialMask.soundAfterRightPreSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,2)=nanmean(firstLickTime(trialMask.right & trialMask.soundAfterLeftPreSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,3)=nanmean(firstLickTime(trialMask.right & trialMask.actionPreSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,4)=nanmean(firstLickTime(trialMask.right & trialMask.actionPreSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,5)=nanmean(firstLickTime(trialMask.right & trialMask.soundAfterRightPostSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,6)=nanmean(firstLickTime(trialMask.right & trialMask.soundAfterLeftPostSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,7)=nanmean(firstLickTime(trialMask.right & trialMask.actionPostSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,8)=nanmean(firstLickTime(trialMask.right & trialMask.actionPostSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,9)=nanmean(firstLickTime(trialMask.right & trialMask.soundPostSwitch & trialMask.pererror));
            firstLickTimeArray(kk,10)=nanmean(firstLickTime(trialMask.right & trialMask.actionPostSwitch & trialMask.pererror));
        end     
    end
    
    %the lick rates for different situations
    nLeftUpsweepArray(:,:,kk)=nLeftUpsweep;
    nRightUpsweepArray(:,:,kk)=nRightUpsweep;
    nLeftDownsweepArray(:,:,kk)=nLeftDownsweep;
    nRightDownsweepArray(:,:,kk)=nRightDownsweep;
end

%% ----- summary performance numbers
figure;

for kkk=[1:4 6:12]
    switch kkk
        case 1
            temp=numTrial;
            yrange=[0 max(numTrial)];
            tlabel={'Trials performed'};
        case 2
            temp=numHit;
            yrange=[0 max(numTrial)];
            tlabel={'Hits'};
        case 3
            temp=numError;
            yrange=[0 max(numTrial)];
            tlabel={'Errors'};
        case 4
            temp=numMiss;
            yrange=[0 max(numTrial)];
            tlabel={'Miss'};
    
        case 6
            temp=numSwitch./(numSwitchTrials/100);
            yrange=[0 5];
            tlabel={'Blocks per 100 trials'};
        case 7
            temp=meantrialCritSoundArray;
            yrange=[0 100];
            tlabel={'Trials to criterion (S)'};
        case 8
            temp=meantrialPErrSoundArray;
            yrange=[0 30];
            tlabel={'Per-errors per block (S)'};
        case 9
            temp=meantrialOErrSoundArray;
            yrange=[0 30];
            tlabel={'Oth-errors (S)'};
        case 10
            temp=meantrialCritActionArray;
            yrange=[0 100];
            tlabel={'Trials to criterion (A)'};
        case 11
            temp=meantrialPErrActionArray;
            yrange=[0 30];
            tlabel={'Per-errors per block (A)'};
        case 12
            temp=meantrialOErrActionArray;
            yrange=[0 30];
            tlabel={'Oth-errors per block (A)'};
    end
    
    subplot(2,6,kkk); hold on;
    for kk=1:numel(temp)
        plot(1+(rand-0.5),temp(kk),'^','Color',[0.7 0.7 0.7],'MarkerSize',10,'LineWidth',2);
    end
    plot(2.5,nanmean(temp),'k^','MarkerSize',10,'LineWidth',2,'MarkerFaceColor','k');
    plot(2.5*[1 1],nanmean(temp)+nanstd(temp)./sqrt(numel(temp))*[-1 1],'k','LineWidth',2);
    ylim([yrange]); xlim([0 3]); set(gca, 'XTick', []);
    ylabel(tlabel);
end

set(gcf,'Position',[40 40 1350 900]);  %laptop
set(gcf, 'PaperPositionMode', 'auto');
export_fig(gcf, 'FigS1', '-jpg', '-painters', '-r200', '-transparent');
saveas(gcf, 'FigS1', 'fig'); %fig format

%% ----- below only pertains to flexibility task
if ~isempty(switchTrial)
    %% ----- mean response time for different trial types
    edges=[0:0.025:2];
    
    figure;
    
    subplot(1,9,1); hold on;
    plot([0 3],[0 0],'k--');
    plot(0.3*ones(size(firstLickTimeLeftArray))+1*rand(size(firstLickTimeLeftArray)),firstLickTimeLeftArray-firstLickTimeRightArray,'k^','MarkerSize',10,'LineWidth',3);
    plot(2*[1 1],nanmean(firstLickTimeLeftArray-firstLickTimeRightArray),'k^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','k');
    plot(2*[1 1],nanmean(firstLickTimeLeftArray-firstLickTimeRightArray)+nanstd(firstLickTimeLeftArray-firstLickTimeRightArray)/sqrt(numel(firstLickTimeLeftArray))*[-1 1],'k-','LineWidth',3);
    xlim([0 3]); ylim([-0.6 0.6]);
    set(gca, 'XTick', []);
    ylabel({'Mean first lick time difference';'between left and right ports (s)'});
    
    subplot(1,9,[3 4 5]); hold on;
    for jj=1:size(firstLickTimeArray,1)
        plot([1 2],[firstLickTimeArray(:,1) firstLickTimeArray(:,2)],'-','Color',[0.7 0.7 0.7],'LineWidth',1);
        plot([4 5],[firstLickTimeArray(:,3) firstLickTimeArray(:,4)],'-','Color',[0.7 0.7 0.7],'LineWidth',1);
    end
    errorbar(1,nanmean(firstLickTimeArray(:,1)),nanstd(firstLickTimeArray(:,1))/sqrt(size(firstLickTimeArray,1)),'k^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','k');
    errorbar(2,nanmean(firstLickTimeArray(:,2)),nanstd(firstLickTimeArray(:,2))/sqrt(size(firstLickTimeArray,1)),'k^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','k');
    errorbar(4,nanmean(firstLickTimeArray(:,3)),nanstd(firstLickTimeArray(:,3))/sqrt(size(firstLickTimeArray,1)),'r^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','r');
    errorbar(5,nanmean(firstLickTimeArray(:,4)),nanstd(firstLickTimeArray(:,4))/sqrt(size(firstLickTimeArray,1)),'r^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','r');
    xlim([0 7]); ylim([0.1 0.6]);
    title('Pre-switch, fast-dir');
    ylabel('Mean first lick time (s)');
    set(gca,'xticklabel',{'pHit' 'oHit' '{\color{red}pHit}' '{\color{red}oHit}'},'xtick',[1 2 4 5]);
    disp('Fast-dir, Pre-switch, S vs A');
    p=signrank(firstLickTimeArray(:,1),firstLickTimeArray(:,3))
    disp('Fast-dir, Pre-switch, S-incong vs A-incong');
    p=signrank(firstLickTimeArray(:,2),firstLickTimeArray(:,4))
    disp('Fast-dir, Pre-switch, S vs S-incong');
    p=signrank(firstLickTimeArray(:,1),firstLickTimeArray(:,2))
    disp('Fast-dir, Pre-switch, A vs A-incong');
    p=signrank(firstLickTimeArray(:,3),firstLickTimeArray(:,4))
    
    subplot(1,9,[7 8 9]); hold on;
    for jj=1:size(firstLickTimeArray,1)
        plot([1 2 3],[firstLickTimeArray(:,5) firstLickTimeArray(:,6) firstLickTimeArray(:,9)],'-','Color',[0.7 0.7 0.7],'LineWidth',1);
        plot([4 5 6],[firstLickTimeArray(:,7) firstLickTimeArray(:,8) firstLickTimeArray(:,10)],'-','Color',[0.7 0.7 0.7],'LineWidth',1);
    end
    errorbar(1,nanmean(firstLickTimeArray(:,5)),nanstd(firstLickTimeArray(:,5))/sqrt(size(firstLickTimeArray,1)),'k^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','k');
    errorbar(2,nanmean(firstLickTimeArray(:,6)),nanstd(firstLickTimeArray(:,6))/sqrt(size(firstLickTimeArray,1)),'k^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','k');
    errorbar(3,nanmean(firstLickTimeArray(:,9)),nanstd(firstLickTimeArray(:,9))/sqrt(size(firstLickTimeArray,1)),'k^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','k');
    
    errorbar(4,nanmean(firstLickTimeArray(:,7)),nanstd(firstLickTimeArray(:,7))/sqrt(size(firstLickTimeArray,1)),'r^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','r');
    errorbar(5,nanmean(firstLickTimeArray(:,8)),nanstd(firstLickTimeArray(:,8))/sqrt(size(firstLickTimeArray,1)),'r^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','r');
    errorbar(6,nanmean(firstLickTimeArray(:,10)),nanstd(firstLickTimeArray(:,10))/sqrt(size(firstLickTimeArray,1)),'r^','MarkerSize',10,'LineWidth',3,'MarkerFaceColor','r');
    xlim([0 7]); ylim([0.1 0.6]);
    title('Post-switch, fast-dir');
    ylabel('Mean first lick time (s)');
    set(gca,'xticklabel',{'pHit' 'oHit' 'pErr' '{\color{red}pHit}' '{\color{red}oHit}' '{\color{red}pErr}'},'xtick',[1 2 3 4 5 6]);
    disp('Fast-dir, Post-switch, S vs A');
    p=signrank(firstLickTimeArray(:,5),firstLickTimeArray(:,7))
    disp('Fast-dir, Post-switch, S-incong vs A-incong');
    p=signrank(firstLickTimeArray(:,6),firstLickTimeArray(:,8))
    disp('Fast-dir, Post-switch, S-perror vs A-perror');
    p=signrank(firstLickTimeArray(:,9),firstLickTimeArray(:,10))
    disp('Fast-dir, Post-switch, S vs S-incong');
    p=signrank(firstLickTimeArray(:,5),firstLickTimeArray(:,6))
    disp('Fast-dir, Post-switch, S vs S-perror');
    p=signrank(firstLickTimeArray(:,5),firstLickTimeArray(:,9))
    disp('Fast-dir, Post-switch, A vs A-incong');
    p=signrank(firstLickTimeArray(:,7),firstLickTimeArray(:,8))
    disp('Fast-dir, Post-switch, A vs A-perror');
    p=signrank(firstLickTimeArray(:,7),firstLickTimeArray(:,10))
    
    set(gcf,'Position',[40 40 1400 400]);  %laptop
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'FigS2a-S2c-S2d', '-jpg', '-painters', '-r100', '-transparent');
    saveas(gcf, 'FigS2a-S2c-S2d', 'fig'); %fig format
    
    %% ----- plot mean hit/error rates around rule block transitions
    figure;
    
    Linterval=[-20:1:60];
    
    for jj=1:2
        if jj==1
            tempArray=hitmissSoundArray; titlelabel='{\color{red}Action} to Sound'; col='k';
        elseif jj==2
            tempArray=hitmissActionArray; titlelabel='Sound to {\color{red}Action}'; col='r';
        end
        
        subplot(1,2,jj); hold on;
        hitArray=(tempArray==CODE_END | tempArray==CODE_HITLEFT | tempArray==CODE_PERSEVERHITLEFT | tempArray==CODE_HITRIGHT | tempArray==CODE_PERSEVERHITRIGHT | tempArray==CODE_LEFTSET_LEFTSTIM_HIT | tempArray==CODE_RIGHTSET_LEFTSTIM_HIT | tempArray==CODE_LEFTSET_RIGHTSTIM_HIT | tempArray==CODE_RIGHTSET_RIGHTSTIM_HIT);
        pererrorArray=(tempArray==CODE_PERSEVERLEFT | tempArray==CODE_PERSEVERRIGHT | tempArray==CODE_LEFTSET_PERSEVERERR | tempArray==CODE_RIGHTSET_PERSEVERERR);
        otherrorArray=(tempArray==CODE_INCORRECTLEFT | tempArray==CODE_INCORRECTRIGHT | tempArray==CODE_LEFTSET_INCORRECT | tempArray==CODE_RIGHTSET_INCORRECT);
        missArray=(tempArray==CODE_MISSLEFT | tempArray==CODE_MISSRIGHT | tempArray==CODE_RIGHTSET_LEFTSTIM_MISS | tempArray==CODE_RIGHTSET_RIGHTSTIM_MISS | tempArray==CODE_LEFTSET_LEFTSTIM_MISS | tempArray==CODE_LEFTSET_RIGHTSTIM_MISS);
        validtrialArray=(hitArray | pererrorArray | otherrorArray | missArray);
        for kk=1:numel(Linterval)
            meantempHit=sum(hitArray(Linterval(kk)+21,:),2)./sum(validtrialArray(Linterval(kk)+21,:),2);
            semtempHit=std(hitArray(Linterval(kk)+21,:),[],2)./sqrt(sum(validtrialArray(Linterval(kk)+21,:),2));
            meantempPerError=sum(pererrorArray(Linterval(kk)+21,:),2)./sum(validtrialArray(Linterval(kk)+21,:),2);
            semtempPerError=std(pererrorArray(Linterval(kk)+21,:),[],2)./sqrt(sum(validtrialArray(Linterval(kk)+21,:),2));
            meantempOthError(kk)=sum(otherrorArray(Linterval(kk)+21,:),2)./sum(validtrialArray(Linterval(kk)+21,:),2);
            plot(Linterval(kk),meantempHit,[col 'o'],'MarkerFaceColor',col,'MarkerSize',7,'LineWidth',1);
            plot(Linterval(kk),meantempPerError,[col 'o'],'MarkerFaceColor','w','MarkerSize',7,'LineWidth',1);
            plot(Linterval(kk)*[1 1],meantempHit+semtempHit*[-1 1],[col '-'],'LineWidth',1);
            plot(Linterval(kk)*[1 1],meantempPerError+semtempPerError*[-1 1],[col '-'],'LineWidth',1);
            plot(Linterval(kk),meantempHit,[col 'o'],'MarkerFaceColor',col,'MarkerSize',7,'LineWidth',1);
            plot(Linterval(kk),meantempPerError,[col 'o'],'MarkerFaceColor','w','MarkerSize',7,'LineWidth',1);
        end
        plot(Linterval,meantempOthError,[col '--'],'LineWidth',2);
        plot([0 0],[0 1],'k','LineWidth',1);
        xlabel('Trial from switch');
        ylabel('Fraction of trials');
        title(titlelabel);
        xlim([Linterval(1) Linterval(end)]); ylim([0 1]);
    end
    
    set(gcf,'Position',[40 40 950 280]);  %laptop
    set(gcf, 'PaperPositionMode', 'auto');
    cd(savefigpath);
    export_fig(gcf, 'Fig1c', '-jpg', '-painters', '-r250', '-transparent');
    saveas(gcf, 'Fig1c', 'fig'); %fig format
    
    %% ----- plot lick rate for different conditions
    
    for jj=1:3
        if jj==1
            jjj=1;  %all trials
            titlelabel='All, correct trials';
        elseif jj==2
            jjj=4;  %pre-switch
            titlelabel='Pre-switch, correct trials';
        elseif jj==3
            jjj=7;  %post-switch
            titlelabel='Post-switch, correct trials';
        end
        figure;
        for kk=1:3
            if kk==1
                col='k';
            elseif kk==2
                col='r';
            elseif kk==3
                col='b';
            end
            
            subplot(2,6,1+(kk-1)*2); hold on;
            y=nanmean(nLeftUpsweepArray(:,jjj+(kk-1),:),3);
            ysem=nanstd(nLeftUpsweepArray(:,jjj+(kk-1),:),[],3)./sqrt(size(nLeftUpsweepArray,3));
            errorshade(nedges,y',y'+ysem',y'-ysem',[0.8 0.8 0.8]);
            plot(nedges,y,col,'LineWidth',2);
            plot([0 0],[0 12],'k--','LineWidth',1); xlim([-3 5]); ylim([0 12]);
            if kk==1
                ylabel('Lick rate (Hz)');
            end
            if kk==2
                title(titlelabel);
            end
            if kk==2 %plotting p=0.01 significance
                cond1=1; cond2=2; sig=nan(size(nedges));
                for ll=1:size(nLeftUpsweepArray,1)
                    [h,p]=ttest(nLeftUpsweepArray(ll,jjj+(cond1-1),:),nLeftUpsweepArray(ll,jjj+(cond2-1),:));
                    sig(ll)=p;
                end
                for ll=1:numel(sig)
                    if sig(ll)<0.01
                        plot([nedges(ll) nedges(ll+1)],[11 11],'k-','LineWidth',5);
                    end
                end
            end
            
            subplot(2,6,2+(kk-1)*2); hold on;
            y=nanmean(nRightUpsweepArray(:,jjj+(kk-1),:),3);
            ysem=nanstd(nRightUpsweepArray(:,jjj+(kk-1),:),[],3)./sqrt(size(nRightUpsweepArray,3));
            errorshade(nedges,y',y'+ysem',y'-ysem',[0.8 0.8 0.8]);
            plot(nedges,y,col,'LineWidth',2);
            plot([0 0],[0 12],'k--','LineWidth',1); xlim([-3 5]); ylim([0 12]);
            if kk==3 %plotting p=0.01 significance
                cond1=1; cond2=3; sig=nan(size(nedges));
                for ll=1:size(nRightUpsweepArray,1)
                    [h,p]=ttest(nRightUpsweepArray(ll,jjj+(cond1-1),:),nRightUpsweepArray(ll,jjj+(cond2-1),:));
                    sig(ll)=p;
                end
                for ll=1:numel(sig)
                    if sig(ll)<0.01
                        plot([nedges(ll) nedges(ll+1)],[11 11],'k-','LineWidth',5);
                    end
                end
            end
            
            subplot(2,6,7+(kk-1)*2); hold on;
            y=nanmean(nLeftDownsweepArray(:,jjj+(kk-1),:),3);
            ysem=nanstd(nLeftDownsweepArray(:,jjj+(kk-1),:),[],3)./sqrt(size(nLeftDownsweepArray,3));
            errorshade(nedges,y',y'+ysem',y'-ysem',[0.8 0.8 0.8]);
            plot(nedges,y,col,'LineWidth',2);
            plot([0 0],[0 12],'k--','LineWidth',1); xlim([-3 5]); ylim([0 12]);
            if kk==1
                ylabel('Lick rate (Hz)');
            end
            if kk==2
                xlabel('Time from auditory cue (s)');
            end
            if kk==2 %plotting p=0.01 significance
                cond1=1; cond2=2; sig=nan(size(nedges));
                for ll=1:size(nLeftDownsweepArray,1)
                    [h,p]=ttest(nLeftDownsweepArray(ll,jjj+(cond1-1),:),nLeftDownsweepArray(ll,jjj+(cond2-1),:));
                    sig(ll)=p;
                end
                for ll=1:numel(sig)
                    if sig(ll)<0.01
                        plot([nedges(ll) nedges(ll+1)],[11 11],'k-','LineWidth',5);
                    end
                end
            end
            
            subplot(2,6,8+(kk-1)*2); hold on;
            y=nanmean(nRightDownsweepArray(:,jjj+(kk-1),:),3);
            ysem=nanstd(nRightDownsweepArray(:,jjj+(kk-1),:),[],3)./sqrt(size(nRightDownsweepArray,3));
            errorshade(nedges,y',y'+ysem',y'-ysem',[0.8 0.8 0.8]);
            plot(nedges,y,col,'LineWidth',2);
            plot([0 0],[0 12],'k--','LineWidth',1); xlim([-3 5]); ylim([0 12]);
            if kk==3 %plotting p=0.01 significance
                cond1=1; cond2=3; sig=nan(size(nedges));
                for ll=1:size(nRightDownsweepArray,1)
                    [h,p]=ttest(nRightDownsweepArray(ll,jjj+(cond1-1),:),nRightDownsweepArray(ll,jjj+(cond2-1),:));
                    sig(ll)=p;
                end
                for ll=1:numel(sig)
                    if sig(ll)<0.01
                        plot([nedges(ll) nedges(ll+1)],[11 11],'k-','LineWidth',5);
                    end
                end
            end
        end
        
        set(gcf,'Position',[40 40 1300 550]);  %laptop
        export_fig(gcf, ['Fig1e-S2e-S2f-' int2str(jj)], '-jpg', '-painters', '-r100', '-transparent');
        saveas(gcf, ['Fig1e-S2e-S2f-' int2str(jj)], 'fig'); %fig format
    end
end