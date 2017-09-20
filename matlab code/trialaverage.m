function [trialavgtime,trialavgdff,trialavgdffsem] = trialaverage(t,dff,trigTime,trigRespWindow,binWidth)
%TRIALAVERAGE
%   Given dF/F time series and event time, find trial-averaged fluorescence
%   by binning
%
%   [trialavgtime,trialavgdff] = trialaverage(t,dff,trigTime,trigRespWindow,binWidth)
%
%   Inputs:
%       t:              time
%       dff:            fluorescence vector
%       trigTime:       the behavioral time points to be aligned
%       trigRespWindow: the time window around which to align dF/F
%       binWidth:       the bin width for averaging
%   Outputs:
%       trialavgtime:   time
%       trialavgdff:    the trial-averaged fluoresence

t=t(:); dff=dff(:); %make sure they are row vectors

tempdff=[]; tempTime=[];
for j=1:numel(trigTime)
    relTime=t-trigTime(j);
    
    %store the df/f and relative time if it's around the event time
    tempdff=[tempdff; dff(relTime>=trigRespWindow(1) & relTime<=trigRespWindow(2))];
    tempTime=[tempTime; relTime(relTime>=trigRespWindow(1) & relTime<=trigRespWindow(2))];
end

%go through each time bin, and average
winNumStep=floor((trigRespWindow(2)-trigRespWindow(1))/binWidth);
trialavgtime=[trigRespWindow(1):binWidth:trigRespWindow(1)+(winNumStep-1)*binWidth];
for j=1:numel(trialavgtime)
    trialavgdff(j)=nanmean(tempdff(tempTime>=trialavgtime(j) & tempTime<=(trialavgtime(j)+binWidth)));
    trialavgdffsem(j)=nanstd(tempdff(tempTime>=trialavgtime(j) & tempTime<=(trialavgtime(j)+binWidth)))/sqrt(numel((tempdff(tempTime>=trialavgtime(j) & tempTime<=(trialavgtime(j)+binWidth)))));
end    
trialavgtime=[trigRespWindow(1):binWidth:trigRespWindow(1)+(winNumStep-1)*binWidth]+binWidth;  %use the end of the bin as time so there is no causality issues

end