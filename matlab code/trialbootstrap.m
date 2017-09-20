function [trialboottime,bootavg,bootlow,boothigh] = trialbootstrap(t,dff,trigEventTime,winStart,winEnd,windt,numBootstrapRep,CI)
%TRIALBOOTSTRAP
%   Given dF/F time series and event time, find trial-averaged fluorescence
%   by binning -- with bootstrap and CI
%
%   [trialboottime,bootavg,bootlow,boothigh] = trialbootstrap(t,dff,trigEventTime,winStart,winEnd,windt,numBootstrapRep,CI)
%
%   Inputs:
%       t:              time
%       dff:            fluorescence vector
%       trigEventTime:      the behavioral time points to be aligned
%       winStart, winEnd:   the time window around which to align dF/F
%       numBootstrapRep:    number of bootstrap repeats
%       CI:             confidence interval
%   Outputs:
%       trialboottime:   time
%       trialbootavg:    the bootstrapped fluoresence - median
%       trialbootlow:    the bootstrapped fluoresence - low bound of CI
%       trialboothigh:    the bootstrapped fluoresence - high bound of CI

%given df/f time-series, and the event time, find trial-averaged
%fluorescence + 95% confidence intervals based on bootstrap

t=t(:); dff=dff(:); %make sure they are row vectors

winNumStep=floor((winEnd-winStart)/windt);
trialboottime=[winStart:windt:winStart+(winNumStep-1)*windt];
for i=1:numBootstrapRep
    tempdff=[]; tempTime=[]; tempEvent=[];
    for j=1:numel(trigEventTime)
        relTime=t-trigEventTime(j);
        
        %store the df/f and relative time if it's around the event time
        tempdff=[tempdff; dff(relTime>=winStart & relTime<=winEnd)];
        tempTime=[tempTime; relTime(relTime>=winStart & relTime<=winEnd)];
        tempEvent=[tempEvent; j*ones(sum(relTime>=winStart & relTime<=winEnd),1)];
    end
    
    %draw a subset for bootstrap
    drawIndex=randsample(numel(trigEventTime),numel(trigEventTime),'true'); %each time draw another set with replacement
    drawdff=[]; drawTime=[];
    for k=1:numel(drawIndex)
        drawdff=[drawdff; tempdff(tempEvent==drawIndex(k))];
        drawTime=[drawTime; tempTime(tempEvent==drawIndex(k))];
    end
    
    %go through each time bin, and average
    for j=1:numel(trialboottime)
        trialavgdff(j,i)=mean(drawdff(drawTime>=trialboottime(j) & drawTime<=(trialboottime(j)+windt)));
    end
end
trialboottime=[winStart:windt:winStart+(winNumStep-1)*windt]+windt; %use the end of the bin as the time, so there is no causality issues

%bootstrap mean and 95% confidence interval
bootavg=squeeze(nanmean(trialavgdff,2));
bootlow=quantile(trialavgdff,0.5*(1-CI),2);
boothigh=quantile(trialavgdff,1-0.5*(1-CI),2);