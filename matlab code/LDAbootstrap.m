function [corrPred,corrPredLow,corrPredHigh] = LDAbootstrap(projdffbyTrial, factors, fracLDA, numRepLDA, CI)
%LDABOOTSTRAP
%   Use dF/F or their projections from subset of trials to repeatedly
%   assess accuracy of linear discriminant classifier
%
%   [corrPred,corrPredLow,corrPredHigh] = LDAbootstrap(projdffbyTrial, factors, fracLDA, numRepLDA, CI)
%
%   Inputs:
%       projdffbyTrial:     dF/F or their projections
%       factors:       the behavioral parameters to be decoded
%       fracLDA:       fraction of trials used to find classifier (e.g. 0.8 for 5-fold cross-validation)
%       numRepLDA:      number of bootstrap repeats
%       CI:             confidence interval
%   Outputs:
%       corrPred:       classifier accuracy, median
%       corrPredLow:    classifier accuracy, low bound
%       corrPredHigh:    classifier accuracy, high bound

numStep=size(projdffbyTrial,1);

if size(factors,2)==2   %two-factor LDA
    projdffbyTrialSubset=projdffbyTrial(:,:,factors(:,1) | factors(:,2)); %take out all the other trials
    outcomebyTrial=factors(:,1);  %eg set 1 for hit
    outcomebyTrial=outcomebyTrial(factors(:,1) | factors(:,2)); %retain only relevant trials, so contain a subset of trials now
    numTrialLDA=round(fracLDA*numel(outcomebyTrial));   %use subset of trials to train classifier
    
    tempcorrPred=[]; corrPred=[]; corrPredLow=[]; corrPredHigh=[];
    for i=1:numStep
        for jj=1:numRepLDA
            drawNum=randsample(numel(outcomebyTrial),numTrialLDA,'false'); %each time draw another set without replacement
            drawIndex=zeros(1,numel(outcomebyTrial));
            drawIndex(drawNum)=1;   %convert the drawn numbers into zeros and ones
            drawIndex=logical(drawIndex);
            
            %k-fold validation
            outcomebyLDA=classify(squeeze(projdffbyTrialSubset(i,:,~drawIndex))',squeeze(projdffbyTrialSubset(i,:,drawIndex))',outcomebyTrial(drawIndex)');
            incorrPredict=sum(xor(outcomebyLDA,outcomebyTrial(~drawIndex)));   %number of the incorrect predictions
            tempcorrPred(i,jj)=1-incorrPredict/sum(~drawIndex);
        end
    end
    
    corrPred=mean(tempcorrPred,2);
    corrPredLow=quantile(tempcorrPred,(1-CI)/2,2);
    corrPredHigh=quantile(tempcorrPred,CI+(1-CI)/2,2);
end

