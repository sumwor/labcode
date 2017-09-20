function [dffbyTrial] = aligndffByTime(t,dff,trigTime,trigRespWindow)
%ALIGNDFFBYTIME
%   Align a dF/F trace to behavioral time points
%
%   [dffbyTrial] = aligndffByTime(t,dff,trigTime,trigRespWindow)
%
%   Inputs:
%       t:              time
%       dff:            fluorescence vector
%       trigTime:       the behavioral time points to be aligned
%       trigRespWindow: the time window around which to align dF/F
%   Outputs:
%       dffbyTrial:     fluorescence aligned by behavioral time points

dt=nanmean(diff(t));

if isempty(trigTime)
    dffbyTrial(:,:,1)=nan(round(trigRespWindow(2)/dt)-round(trigRespWindow(1)/dt)+1,size(dff,2));
else
    for j=1:numel(trigTime)
        if ~isnan(trigTime(j))  %if there is a response, find dF/F aligned to time of response
            respIndex=sum(trigTime(j)>t);
            if (respIndex+round(trigRespWindow(1)/dt))>0 && (respIndex+round(trigRespWindow(2)/dt))<=size(dff,1)
                dffbyTrial(:,:,j)=dff(respIndex+round(trigRespWindow(1)/dt):respIndex+round(trigRespWindow(2)/dt),:);
            else
                dffbyTrial(:,:,j)=nan(round(trigRespWindow(2)/dt)-round(trigRespWindow(1)/dt)+1,size(dff,2));
            end
        else   %miss trials, no response
            dffbyTrial(:,:,j)=nan(round(trigRespWindow(2)/dt)-round(trigRespWindow(1)/dt)+1,size(dff,2));
        end
    end
end