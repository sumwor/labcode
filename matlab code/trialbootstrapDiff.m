function [trialboottime,bootavg,bootlow,boothigh] = trialbootstrapDiff(t,dff,trigEventTime1,trigEventTime2,winStart,winEnd,windt,numBootstrapRep,CI)
%TRIALBOOTSTRAPDIFF
%   Given dF/F time series and times of 2 types of behavioral events, find
%   trial-averaged fluorescence difference by binning -- with bootstrap and CI
%
%   [trialboottime,bootavg,bootlow,boothigh] = trialbootstrap(t,dff,trigEventTime,winStart,winEnd,windt,numBootstrapRep,CI)
%
%   Inputs:
%       t:              time
%       dff:            fluorescence vector
%       trigEventTime1:      the behavioral time points to be aligned,event1
%       trigEventTime2:      the behavioral time points to be aligned,event2
%       winStart, winEnd:   the time window around which to align dF/F
%       numBootstrapRep:    number of bootstrap repeats
%       CI:             confidence interval
%   Outputs:
%       trialboottime:   time
%       trialbootavg:    the bootstrapped fluoresence - median
%       trialbootlow:    the bootstrapped fluoresence - low bound of CI
%       trialboothigh:    the bootstrapped fluoresence - high bound of CI
t=t(:); dff=dff(:); %make sure they are row vectors

winNumStep=floor((winEnd-winStart)/windt);
trialboottime=[winStart:windt:winStart+(winNumStep-1)*windt];
for i=1:numBootstrapRep
    tempdff1=[]; tempTime1=[]; tempEvent1=[];
    for j=1:numel(trigEventTime1)
        relTime=t-trigEventTime1(j);
        
        %store the df/f and relative time if it's around the event time
        tempdff1=[tempdff1; dff(relTime>=winStart & relTime<=winEnd)];
        tempTime1=[tempTime1; relTime(relTime>=winStart & relTime<=winEnd)];
        tempEvent1=[tempEvent1; j*ones(sum(relTime>=winStart & relTime<=winEnd),1)];
    end
    
    %draw a subset for bootstrap
    drawIndex=randsample(numel(trigEventTime1),numel(trigEventTime1),'true'); %each time draw another set with replacement
    drawdff1=[]; drawTime1=[];
    for k=1:numel(drawIndex)
        drawdff1=[drawdff1; tempdff1(tempEvent1==drawIndex(k))];
        drawTime1=[drawTime1; tempTime1(tempEvent1==drawIndex(k))];
    end
    
    %go through each time bin, and average
    for j=1:numel(trialboottime)
        trialavgdff1(j,i)=mean(drawdff1(drawTime1>=trialboottime(j) & drawTime1<=(trialboottime(j)+windt)));
    end
    
    tempdff2=[]; tempTime2=[]; tempEvent2=[];
    for j=1:numel(trigEventTime2)
        relTime=t-trigEventTime2(j);
        
        %store the df/f and relative time if it's around the event time
        tempdff2=[tempdff2; dff(relTime>=winStart & relTime<=winEnd)];
        tempTime2=[tempTime2; relTime(relTime>=winStart & relTime<=winEnd)];
        tempEvent2=[tempEvent2; j*ones(sum(relTime>=winStart & relTime<=winEnd),1)];
    end
    
    %draw a subset for bootstrap
    drawIndex=randsample(numel(trigEventTime2),numel(trigEventTime2),'true'); %each time draw another set with replacement
    drawdff2=[]; drawTime2=[];
    for k=1:numel(drawIndex)
        drawdff2=[drawdff2; tempdff2(tempEvent2==drawIndex(k))];
        drawTime2=[drawTime2; tempTime2(tempEvent2==drawIndex(k))];
    end
    
    %go through each time bin, and average
    for j=1:numel(trialboottime)
        trialavgdff2(j,i)=mean(drawdff2(drawTime2>=trialboottime(j) & drawTime2<=(trialboottime(j)+windt)));
    end
end
trialboottime=[winStart:windt:winStart+(winNumStep-1)*windt]+windt; %use the end of the bin as the time, so there is no causality issues

%bootstrap mean and 95% confidence interval
bootavg=squeeze(nanmean((trialavgdff1-trialavgdff2)./(trialavgdff1+trialavgdff2),2));
bootlow=quantile((trialavgdff1-trialavgdff2)./(trialavgdff1+trialavgdff2),0.5*(1-CI),2);
boothigh=quantile((trialavgdff1-trialavgdff2)./(trialavgdff1+trialavgdff2),1-0.5*(1-CI),2);