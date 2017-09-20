%% ----- summarymuscimol: summarize a set of .mat outputs from readDiscrimLogfile.m
% specifically comparing saline vs muscimol experiments

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

%% ----- set up to load the analyzed data
CODE_SAL=1; CODE_MUS=2;

CODE_CUE=0; CODE_ACTIONLEFT=1; CODE_ACTIONRIGHT=2; %the current strategy

CODE_HITLEFT=1; CODE_INCORRECTLEFT=0; CODE_MISSLEFT=4; CODE_HITRIGHT=2; CODE_INCORRECTRIGHT=3; CODE_MISSRIGHT=5; CODE_PERSEVERLEFT=6; CODE_PERSEVERRIGHT=7; CODE_PERSEVERHITLEFT=8; CODE_PERSEVERHITRIGHT=9;
CODE_RIGHTSET_LEFTSTIM_HIT=11; CODE_RIGHTSET_LEFTSTIM_MISS=10; CODE_RIGHTSET_PERSEVERERR=12; CODE_RIGHTSET_INCORRECT=13; CODE_RIGHTSET_RIGHTSTIM_HIT=14; CODE_RIGHTSET_RIGHTSTIM_MISS=15;
CODE_LEFTSET_LEFTSTIM_HIT=21; CODE_LEFTSET_LEFTSTIM_MISS=20; CODE_LEFTSET_PERSEVERERR=22; CODE_LEFTSET_INCORRECT=23; CODE_LEFTSET_RIGHTSTIM_HIT=24; CODE_LEFTSET_RIGHTSTIM_MISS=25;

disp('-------------------------------------------------------------');
disp('------------- Making Saline vs. CNO comparisons -------------');
disp('-------------------------------------------------------------');

savefigpath = [newroot_dir 'figs-summary/'];
if ~exist(savefigpath,'dir')
    mkdir(savefigpath);
end

%% ----- check to see if there are 2 treatments for paired conditions, anything else will stop program
behavcond=[]; behavsubject=[];
for jj=1:numel(datafiles)
    behavcond(jj)=datafiles(jj).behavcond;
    behavsubject{jj}=datafiles(jj).behavsubject;
end

condList=unique(behavcond);
if numel(condList)==2
    disp('Data supplied have exactly 2 conditions -- Good to go!');
else
    disp('Data supplied have less than 2 or more than 2 conditions. Check file list.');
    error('User aborted the program. See last comment in command line.');
end

idSubject=unique(behavsubject);
numSubject=numel(idSubject);
for kk=1:numel(idSubject)
    if sum(strcmp(behavsubject,idSubject(kk)))~=2
        disp(['For the subject ' idSubject(kk) ', number of files included should be 2 or 4, but it is not.']);
        error('User aborted the program. See last comment in command line.');
    end
    if numel(unique(behavcond(strcmp(behavsubject,idSubject(1)))))~=2
        disp(['For the subject ' idSubject(kk) ', files should be labeled as coming from exactly 2 conditions.']);
        error('User aborted the program. See last comment in command line.');
    end
end
disp('Data supplied consist of 2 or 4 files per subject -- Good to go!');

% re-arrange data so it is loaded as paired data
reorderedDataList=nan(numSubject,numel(condList));

for kk=1:numSubject
    tempFileID=find(strcmp(behavsubject,idSubject(kk))==1);
    if behavcond(tempFileID(1))==condList(1)
        reorderedDataList(kk,1)=tempFileID(1);
        reorderedDataList(kk,2)=tempFileID(2);
    else
        reorderedDataList(kk,1)=tempFileID(2);
        reorderedDataList(kk,2)=tempFileID(1);
    end
end
if sum(isnan(reorderedDataList))>0
    disp(['When compiling the matrix of files, one or more subject/treatment/repeat is missing.']);
    error('User aborted the program. See last comment in command line.');
end

%% ----- load the analyzed data
disp('---------------');
disp(['Loading ' int2str(numel(datafiles)) ' sets of data']);

sessionExperience=[];
numTrial=[]; numSwitch=[]; numSwitchTrials=[]; 
trialCritSoundArray=[]; trialCritActionArray=[];
meantrialCritSoundArray=[]; meantrialCritActionArray=[];
meantrialPErrSoundArray=[]; meantrialPErrActionArray=[]; meantrialOErrSoundArray=[]; meantrialOErrActionArray=[];
firstLickTimeLeftArray=[]; firstLickTimeRightArray=[]; firstLickTimeArray=[];
nLeftUpsweepArray=[]; nRightUpsweepArray=[]; nLeftDownsweepArray=[]; nRightDownsweepArray=[];

for jj=1:numel(condList)
    for kk=1:numSubject
        cd(newroot_dir);
        cd(datafiles(reorderedDataList(kk,jj)).sub_dir);
        filename=datafiles(reorderedDataList(kk,jj)).logfile;
        load([filename(1:end-4) '.mat']);
        disp(['loading set ' int2str(reorderedDataList(kk,jj)) '...']);
        
        sessionExperience(kk,jj)=datafiles(reorderedDataList(kk,jj)).sessionExp;                     
        
        numTrial(kk,jj)=sum(trialMask.hit)+sum(trialMask.error);
        numSwitch(kk,jj)=numel(switchTrial);
        numSwitchTrials(kk,jj)=max(switchTrial);

        %trial to criterion, perseverative error, and other error per block        
        trialCrit=[switchTrial(1) diff(switchTrial)];
        meantrialCritSoundArray(kk,jj)=nanmean(trialCrit(blockMask.sound & blockMask.excludefirstblock));   
        meantrialCritActionArray(kk,jj)=nanmean(trialCrit(blockMask.action & blockMask.excludefirstblock));
        meantrialPErrSoundArray(kk,jj)=sum(trialMask.pererror & trialMask.sound & trialMask.excludefirstblock & trialMask.excludelastblock)/sum(blockMask.sound & blockMask.excludefirstblock);
        meantrialPErrActionArray(kk,jj)=sum(trialMask.pererror & trialMask.action & trialMask.excludefirstblock & trialMask.excludelastblock)/sum(blockMask.action & blockMask.excludefirstblock);
        meantrialOErrSoundArray(kk,jj)=sum(trialMask.otherror & trialMask.sound & trialMask.excludefirstblock & trialMask.excludelastblock)/sum(blockMask.sound & blockMask.excludefirstblock);
        meantrialOErrActionArray(kk,jj)=sum(trialMask.otherror & trialMask.action & trialMask.excludefirstblock & trialMask.excludelastblock)/sum(blockMask.action & blockMask.excludefirstblock);
         
        %determine response time in various conditions
        %only considering the direction with the faster response for each animal
        firstLickTimeLeftArray(kk,jj)=nanmean(firstLickTime(trialMask.soundAfterLeftPreSwitch & trialMask.left & trialMask.hit));
        firstLickTimeRightArray(kk,jj)=nanmean(firstLickTime(trialMask.soundAfterRightPreSwitch & trialMask.right & trialMask.hit));
        if firstLickTimeLeftArray(kk)<firstLickTimeRightArray(kk)
            %use the left direction
            firstLickTimeArray(kk,jj,1)=nanmean(firstLickTime(trialMask.left & trialMask.soundAfterLeftPreSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,2)=nanmean(firstLickTime(trialMask.left & trialMask.soundAfterRightPreSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,3)=nanmean(firstLickTime(trialMask.left & trialMask.actionPreSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,4)=nanmean(firstLickTime(trialMask.left & trialMask.actionPreSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,5)=nanmean(firstLickTime(trialMask.left & trialMask.soundAfterLeftPostSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,6)=nanmean(firstLickTime(trialMask.left & trialMask.soundAfterRightPostSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,7)=nanmean(firstLickTime(trialMask.left & trialMask.actionPostSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,8)=nanmean(firstLickTime(trialMask.left & trialMask.actionPostSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,9)=nanmean(firstLickTime(trialMask.left & trialMask.soundPostSwitch & trialMask.pererror));
            firstLickTimeArray(kk,jj,10)=nanmean(firstLickTime(trialMask.left & trialMask.actionPostSwitch & trialMask.pererror));
        else
            firstLickTimeArray(kk,jj,1)=nanmean(firstLickTime(trialMask.right & trialMask.soundAfterRightPreSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,2)=nanmean(firstLickTime(trialMask.right & trialMask.soundAfterLeftPreSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,3)=nanmean(firstLickTime(trialMask.right & trialMask.actionPreSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,4)=nanmean(firstLickTime(trialMask.right & trialMask.actionPreSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,5)=nanmean(firstLickTime(trialMask.right & trialMask.soundAfterRightPostSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,6)=nanmean(firstLickTime(trialMask.right & trialMask.soundAfterLeftPostSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,7)=nanmean(firstLickTime(trialMask.right & trialMask.actionPostSwitch & trialMask.downsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,8)=nanmean(firstLickTime(trialMask.right & trialMask.actionPostSwitch & trialMask.upsweep & trialMask.hit));
            firstLickTimeArray(kk,jj,9)=nanmean(firstLickTime(trialMask.right & trialMask.soundPostSwitch & trialMask.pererror));
            firstLickTimeArray(kk,jj,10)=nanmean(firstLickTime(trialMask.right & trialMask.actionPostSwitch & trialMask.pererror));
        end   
    end
end

%was muscimol tested before saline or vice versa
sessionOrder=nan(size(sessionExperience));
for kk=1:numSubject
    if sessionExperience(kk,1)<sessionExperience(kk,2)
        sessionOrder(kk,1)=1;
        sessionOrder(kk,2)=2;
    elseif sessionExperience(kk,1)>sessionExperience(kk,2)
        sessionOrder(kk,1)=2;
        sessionOrder(kk,2)=1;
    end
end

%% ----- mean response time for different trial types

edges=[0:0.025:2];

figure;

subplot(1,9,1); hold on;
plot([0 6],[0 0],'k--');
cond=CODE_SAL;
plot(0.3*ones(size(firstLickTimeLeftArray(:,cond)))+1*rand(size(firstLickTimeLeftArray(:,cond))),firstLickTimeLeftArray(:,cond)-firstLickTimeRightArray(:,cond),'k^','MarkerSize',10,'LineWidth',3);
plot(2*[1 1],nanmean(firstLickTimeLeftArray(:,cond)-firstLickTimeRightArray(:,cond)),'k^','MarkerSize',10,'LineWidth',3);
plot(2*[1 1],nanmean(firstLickTimeLeftArray(:,cond)-firstLickTimeRightArray(:,cond))+nanstd(firstLickTimeLeftArray(:,cond)-firstLickTimeRightArray(:,cond))/sqrt(numel(firstLickTimeLeftArray(:,cond)))*[-1 1],'k-','LineWidth',3);
cond=CODE_MUS;
plot(3+0.3*ones(size(firstLickTimeLeftArray(:,cond)))+1*rand(size(firstLickTimeLeftArray(:,cond))),firstLickTimeLeftArray(:,cond)-firstLickTimeRightArray(:,cond),'g^','MarkerSize',10,'LineWidth',3);
plot(3+2*[1 1],nanmean(firstLickTimeLeftArray(:,cond)-firstLickTimeRightArray(:,cond)),'g^','MarkerSize',10,'LineWidth',3);
plot(3+2*[1 1],nanmean(firstLickTimeLeftArray(:,cond)-firstLickTimeRightArray(:,cond))+nanstd(firstLickTimeLeftArray(:,cond)-firstLickTimeRightArray(:,cond))/sqrt(numel(firstLickTimeLeftArray(:,cond)))*[-1 1],'g-','LineWidth',3);
xlim([0 6]); ylim([-0.8 0.8]);
set(gca, 'XTick', []);
ylabel({'Mean first lick time difference';'between left and right ports (s)'});

subplot(1,9,[3 4 5]); hold on;
cond=CODE_SAL;
errorbar(1,nanmean(firstLickTimeArray(:,cond,1)),nanstd(firstLickTimeArray(:,cond,1))/sqrt(size(firstLickTimeArray,1)),'k^','MarkerSize',10,'LineWidth',3);
errorbar(2,nanmean(firstLickTimeArray(:,cond,2)),nanstd(firstLickTimeArray(:,cond,2))/sqrt(size(firstLickTimeArray,1)),'k^','MarkerSize',10,'LineWidth',3);
errorbar(4,nanmean(firstLickTimeArray(:,cond,3)),nanstd(firstLickTimeArray(:,cond,3))/sqrt(size(firstLickTimeArray,1)),'r^','MarkerSize',10,'LineWidth',3);
errorbar(5,nanmean(firstLickTimeArray(:,cond,4)),nanstd(firstLickTimeArray(:,cond,4))/sqrt(size(firstLickTimeArray,1)),'r^','MarkerSize',10,'LineWidth',3);
cond=CODE_MUS;
errorbar(0.5+1,nanmean(firstLickTimeArray(:,cond,1)),nanstd(firstLickTimeArray(:,cond,1))/sqrt(size(firstLickTimeArray,1)),'g^','MarkerSize',10,'LineWidth',3);
errorbar(0.5+2,nanmean(firstLickTimeArray(:,cond,2)),nanstd(firstLickTimeArray(:,cond,2))/sqrt(size(firstLickTimeArray,1)),'g^','MarkerSize',10,'LineWidth',3);
errorbar(0.5+4,nanmean(firstLickTimeArray(:,cond,3)),nanstd(firstLickTimeArray(:,cond,3))/sqrt(size(firstLickTimeArray,1)),'g^','MarkerSize',10,'LineWidth',3);
errorbar(0.5+5,nanmean(firstLickTimeArray(:,cond,4)),nanstd(firstLickTimeArray(:,cond,4))/sqrt(size(firstLickTimeArray,1)),'g^','MarkerSize',10,'LineWidth',3);
xlim([0 7]); ylim([0 0.6]);
title('Pre-switch, fast-dir');
ylabel('Mean first lick time (s)');
set(gca,'xticklabel',{'pHit' 'oHit' '{\color{red}pHit}' '{\color{red}oHit}'},'xtick',[1 2 4 5]);

subplot(1,9,[7 8 9]); hold on;
cond=CODE_SAL;
errorbar(1,nanmean(firstLickTimeArray(:,cond,5)),nanstd(firstLickTimeArray(:,cond,5))/sqrt(size(firstLickTimeArray,1)),'k^','MarkerSize',10,'LineWidth',3);
errorbar(2,nanmean(firstLickTimeArray(:,cond,6)),nanstd(firstLickTimeArray(:,cond,6))/sqrt(size(firstLickTimeArray,1)),'k^','MarkerSize',10,'LineWidth',3);
errorbar(3,nanmean(firstLickTimeArray(:,cond,9)),nanstd(firstLickTimeArray(:,cond,9))/sqrt(size(firstLickTimeArray,1)),'k^','MarkerSize',10,'LineWidth',3);
errorbar(4,nanmean(firstLickTimeArray(:,cond,7)),nanstd(firstLickTimeArray(:,cond,7))/sqrt(size(firstLickTimeArray,1)),'r^','MarkerSize',10,'LineWidth',3);
errorbar(5,nanmean(firstLickTimeArray(:,cond,8)),nanstd(firstLickTimeArray(:,cond,8))/sqrt(size(firstLickTimeArray,1)),'r^','MarkerSize',10,'LineWidth',3);
errorbar(6,nanmean(firstLickTimeArray(:,cond,10)),nanstd(firstLickTimeArray(:,cond,10))/sqrt(size(firstLickTimeArray,1)),'r^','MarkerSize',10,'LineWidth',3);
cond=CODE_MUS;
errorbar(0.5+1,nanmean(firstLickTimeArray(:,cond,5)),nanstd(firstLickTimeArray(:,cond,5))/sqrt(size(firstLickTimeArray,1)),'g^','MarkerSize',10,'LineWidth',3);
errorbar(0.5+2,nanmean(firstLickTimeArray(:,cond,6)),nanstd(firstLickTimeArray(:,cond,6))/sqrt(size(firstLickTimeArray,1)),'g^','MarkerSize',10,'LineWidth',3);
errorbar(0.5+3,nanmean(firstLickTimeArray(:,cond,9)),nanstd(firstLickTimeArray(:,cond,9))/sqrt(size(firstLickTimeArray,1)),'g^','MarkerSize',10,'LineWidth',3);
errorbar(0.5+4,nanmean(firstLickTimeArray(:,cond,7)),nanstd(firstLickTimeArray(:,cond,7))/sqrt(size(firstLickTimeArray,1)),'g^','MarkerSize',10,'LineWidth',3);
errorbar(0.5+5,nanmean(firstLickTimeArray(:,cond,8)),nanstd(firstLickTimeArray(:,cond,8))/sqrt(size(firstLickTimeArray,1)),'g^','MarkerSize',10,'LineWidth',3);
errorbar(0.5+6,nanmean(firstLickTimeArray(:,cond,10)),nanstd(firstLickTimeArray(:,cond,10))/sqrt(size(firstLickTimeArray,1)),'g^','MarkerSize',10,'LineWidth',3);
xlim([0 7]); ylim([0 0.6]);
title('Post-switch, fast-dir');
ylabel('Mean first lick time (s)');
set(gca,'xticklabel',{'pHit' 'oHit' 'pErr' '{\color{red}pHit}' '{\color{red}oHit}' '{\color{red}pErr}'},'xtick',[1 2 3 4 5 6]);

disp('Saline vs muscimol, fast-dir');
for jj=1:10
    [p,h,stats]=signrank(firstLickTimeArray(:,1,jj),firstLickTimeArray(:,2,jj));
    disp(['Param #' int2str(jj) '; p-val=' num2str(p)]);
    stats
end

set(gcf,'Position',[40 40 1400 400]);  %laptop
set(gcf, 'PaperPositionMode', 'auto');
cd(savefigpath);
export_fig(gcf, 'FigS5b', '-jpg', '-painters', '-r200', '-transparent');
saveas(gcf, 'FigS5b', 'fig'); %fig format

%% ----- summary performance numbers
figure;

for kkk=[1 2 4:9]
    switch kkk
        case 1
            temp=numTrial;
            yrange=[0 1000];
            tlabel={'Trials performed'};
        case 2
            temp=numSwitch./(numSwitchTrials/100);
            yrange=[0 6];
            tlabel={'Blocks per 100 trials'};
        case 4
            temp=meantrialCritSoundArray;
            yrange=[0 100];
            tlabel={'Trials to criterion'};
        case 5
            temp=meantrialPErrSoundArray;
            yrange=[0 30];
            tlabel={'Perseverative errors'};
        case 6
            temp=meantrialOErrSoundArray;
            yrange=[0 30];
            tlabel={'Other errors'};
        case 7
            temp=meantrialCritActionArray;
            yrange=[0 100];
            tlabel={'Trials to criterion'};
        case 8
            temp=meantrialPErrActionArray;
            yrange=[0 30];
            tlabel={'Perseverative errors'};
        case 9
            temp=meantrialOErrActionArray;
            yrange=[0 30];
            tlabel={'Other errors'};
    end
            
    subplot(2,6,kkk); hold on;
    for kk=1:numSubject
        plot([1 2],[temp(kk,1) temp(kk,2)],'-','Color',[0.5 0.5 0.5],'LineWidth',2);
    end
    bar(1,nanmean(temp(:,1)),0.6,'EdgeColor','k','LineWidth',5,'FaceColor','none');
    plot(1*[1 1],nanmean(temp(:,1))+nanstd(temp(:,1))./sqrt(numel(temp(:,1)))*[-1 1],'k','LineWidth',5);
    bar(2,nanmean(temp(:,2)),0.6,'EdgeColor',[0 0.6 0],'LineWidth',5,'FaceColor','none');
    plot(2*[1 1],nanmean(temp(:,2))+nanstd(temp(:,2))./sqrt(numel(temp(:,2)))*[-1 1],'Color',[0 0.6 0],'LineWidth',5);
    ylim(yrange); xlim([0 3]); set(gca, 'XTick', []);
    set(gca,'xticklabel',{'Veh' '{\color[rgb]{0,0.6,0}Mus}'},'xtick',[0.9 2.1]);
    %title(tlabel);
    [p,h,stats]=signrank(temp(:,1),temp(:,2)); 
    %title(['p = ' num2str(p)]);
    stats
    ylabel(tlabel);
end

set(gcf,'Position',[40 40 1300 700]);  %laptop
set(gcf, 'PaperPositionMode', 'auto');
cd(savefigpath);
export_fig(gcf, 'Fig2b-2c', '-jpg', '-painters', '-r200', '-transparent');
saveas(gcf, 'Fig2b-2c', 'fig'); %fig format

%% ----- effect of experience on performance
conds=[]; days=[];
for jj=1:numel(condList)
    for kk=1:numSubject
        conds(kk,jj)=jj;
    end
end
groups={sessionOrder(:);conds(:)};
terms=[1 0; 0 1; 1 1];

disp('----- ANOVA with subject as random effect');
temp=numTrial; disp('Number of trials');
[p,tbl]=anovan(temp(:),groups,'model',terms,'varnames',{'experience','treatment'},'display','off'); %first group is between-subj; second group is within-sub; last group is a random variable
disp(['- effect of experience, p=' num2str(p(1))]);
disp(['- effect of treatment, p=' num2str(p(2))]);
disp(['- effect of experience X treatment, p=' num2str(p(3))]);

figure;
subplot(2,4,1); hold on; xlabel('Sessions of experience'); ylabel('Trials');
plot(sessionExperience(:,1),temp(:,1),'k^','MarkerSize',10); xlim([0 7]);
stats=regstats(temp(:,1),sessionExperience(:,1),'linear');
plot([0:1:7],stats.tstat.beta(1)+[0:1:7].*stats.tstat.beta(2),'k-','LineWidth',2);
title(['p = ' num2str(stats.tstat.pval(2))]); %t-stat for finding significant slope

temp=numSwitch./(numSwitchTrials/100); disp('Number of blocks per 100 trials');
[p,tbl]=anovan(temp(:),groups,'model',terms,'varnames',{'experience','treatment'},'display','off'); %first group is between-subj; second group is within-sub; last group is a random variable
disp(['- effect of experience, p=' num2str(p(1))]);
disp(['- effect of treatment, p=' num2str(p(2))]);
disp(['- effect of experience X treatment, p=' num2str(p(3))]);
subplot(2,4,2); hold on; xlabel('Sessions of experience'); ylabel('Blocks per 100 trials');
plot(sessionExperience(:,1),temp(:,1),'k^','MarkerSize',10); xlim([0 7]);
stats=regstats(temp(:,1),sessionExperience(:,1),'linear');
plot([0:1:7],stats.tstat.beta(1)+[0:1:7].*stats.tstat.beta(2),'k-','LineWidth',2);
title(['p = ' num2str(stats.tstat.pval(2))]); %t-stat for finding significant slope

temp=meantrialCritSoundArray; disp('Number of trials to crit, -->Sound');
[p,tbl]=anovan(temp(:),groups,'model',terms,'varnames',{'experience','treatment'},'display','off'); %first group is between-subj; second group is within-sub; last group is a random variable
disp(['- effect of experience, p=' num2str(p(1))]);
disp(['- effect of treatment, p=' num2str(p(2))]);
disp(['- effect of experience X treatment, p=' num2str(p(3))]);
subplot(2,4,3); hold on; xlabel('Sessions of experience'); ylabel('Trials to Crit, -> Sound');
plot(sessionExperience(:,1),temp(:,1),'k^','MarkerSize',10); xlim([0 7]);
stats=regstats(temp(:,1),sessionExperience(:,1),'linear');
plot([0:1:7],stats.tstat.beta(1)+[0:1:7].*stats.tstat.beta(2),'k-','LineWidth',2);
title(['p = ' num2str(stats.tstat.pval(2))]); %t-stat for finding significant slope

temp=meantrialPErrSoundArray; disp('Number of per error, -->Sound');
[p,tbl]=anovan(temp(:),groups,'model',terms,'varnames',{'experience','treatment'},'display','off'); %first group is between-subj; second group is within-sub; last group is a random variable
disp(['- effect of experience, p=' num2str(p(1))]);
disp(['- effect of treatment, p=' num2str(p(2))]);
disp(['- effect of experience X treatment, p=' num2str(p(3))]);
subplot(2,4,4); hold on; xlabel('Sessions of experience'); ylabel('P-Err, -> Sound');
plot(sessionExperience(:,1),temp(:,1),'k^','MarkerSize',10); xlim([0 7]);
stats=regstats(temp(:,1),sessionExperience(:,1),'linear');
plot([0:1:7],stats.tstat.beta(1)+[0:1:7].*stats.tstat.beta(2),'k-','LineWidth',2);
title(['p = ' num2str(stats.tstat.pval(2))]); %t-stat for finding significant slope

temp=meantrialCritActionArray; disp('Number of trials to crit, -->Action');
[p,tbl]=anovan(temp(:),groups,'model',terms,'varnames',{'experience','treatment'},'display','off'); %first group is between-subj; second group is within-sub; last group is a random variable
disp(['- effect of experience, p=' num2str(p(1))]);
disp(['- effect of treatment, p=' num2str(p(2))]);
disp(['- effect of experience X treatment, p=' num2str(p(3))]);
subplot(2,4,5); hold on; xlabel('Sessions of experience'); ylabel('Trials to Crit, -> Action');
plot(sessionExperience(:,1),temp(:,1),'k^','MarkerSize',10); xlim([0 7]);
stats=regstats(temp(:,1),sessionExperience(:,1),'linear');
plot([0:1:7],stats.tstat.beta(1)+[0:1:7].*stats.tstat.beta(2),'k-','LineWidth',2);
title(['p = ' num2str(stats.tstat.pval(2))]); %t-stat for finding significant slope

temp=meantrialPErrActionArray; disp('Number of per error, -->Action');
[p,tbl]=anovan(temp(:),groups,'model',terms,'varnames',{'experience','treatment'},'display','off'); %first group is between-subj; second group is within-sub; last group is a random variable
disp(['- effect of experience, p=' num2str(p(1))]);
disp(['- effect of treatment, p=' num2str(p(2))]);
disp(['- effect of experience X treatment, p=' num2str(p(3))]);
subplot(2,4,6); hold on; xlabel('Sessions of experience'); ylabel('P-Err, -> Action');
plot(sessionExperience(:,1),temp(:,1),'k^','MarkerSize',10); xlim([0 7]);
stats=regstats(temp(:,1),sessionExperience(:,1),'linear');
plot([0:1:7],stats.tstat.beta(1)+[0:1:7].*stats.tstat.beta(2),'k-','LineWidth',2);
title(['p = ' num2str(stats.tstat.pval(2))]); %t-stat for finding significant slope

set(gcf,'Position',[40 40 1200 800]);  %laptop
cd(savefigpath);
export_fig(gcf, 'ExtraFig2', '-jpg', '-painters', '-r100', '-transparent');
saveas(gcf, 'ExtraFig2', 'fig'); %fig format
