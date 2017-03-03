clear all;

t_conv=zeros(1,500);
t_corr=zeros(1,500);
t_normcorr=zeros(1,500);
t_SQ=zeros(1,500);
refFrame='/Users/phoenix/Documents/Kwanlab/learning/746/746_02_26/raw_stitched/746_02_26__images_1-501_dsRatio_4.tif';
testFrame='/Users/phoenix/Documents/Kwanlab/learning/746/746_02_26/raw/746_02_26_001.tif';
refFrametif=imread(refFrame);
testFrametif=imread(testFrame);

for n=1:500
    disp(['calculating..',num2str(n)]);
    warning('off','all');
    tic
    normxcorr2(testFrametif,refFrametif);
    t1=toc;
    t_normcorr(n)=t1;
    
    tic
    conv2(testFrametif,refFrametif);
    t2=toc;
    t_conv(n)=t2;
    
    tic
    xcorr2(testFrametif,refFrametif);
    t4=toc;
    t_corr(n)=t4;
    warning('on','all');
    
    meanref=mean(mean(refFrametif));
    stdref=std2(refFrametif);
    normref=(double(refFrametif)-meanref)/(stdref);
    tic 
    meantest=mean(mean(testFrametif));
    stdtest=std2(testFrametif);
    normtest=(double(testFrametif)-meantest)/(stdtest);
    SquareDifference=sum(sum((normref-normtest).^2));
    t3=toc;
    t_SQ(n)=t3;
    
    
end

figure;
subplot(2,2,1); plot(t_conv);
subplot(2,2,2); plot(t_corr);
subplot(2,2,3);plot(t_SQ);
subplot(2,2,4);plot(t_normcorr);
AVG_t_conv=mean(t_conv)
AVG_t_corr=mean(t_corr)
AVG_t_SQ=mean(t_SQ)
AVG_t_normcorr=mean(t_normcorr)

