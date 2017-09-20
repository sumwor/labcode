jj=1;

%--for single-cell dF/F example
% root_subdir = 'Data M2/';
% datafiles(jj).sub_dir = '140605 L4 Somata Setshift (517 stitched reg 83 ROI)/';
% datafiles(jj).logfile = 'L4-phase3_setshifting.log';
% datafiles(jj).sstCells = []; 
% datafiles(jj).pvCells = []; 
% datafiles(jj).alphacorr = 0.2;
% 
% jj=jj+1;
% %--for ensemble example
% root_subdir = 'Data M2/';
% datafiles(jj).sub_dir = '140809 M7 SetShift (535 stch reg 56 ROI)/';
% datafiles(jj).logfile = 'M7-phase3_setshifting2.log';
% datafiles(jj).sstCells = []; 
% datafiles(jj).pvCells = []; 
% datafiles(jj).alphacorr = 0.6;

%--example SST imaging
% root_subdir = 'Data M2 SST/';
% datafiles(jj).sub_dir = '141025 R7/';
% datafiles(jj).logfile = 'R7-phase3_setshifting5.log';
% datafiles(jj).sstCells = [1:14]; 
% datafiles(jj).pvCells = []; 
% datafiles(jj).alphacorr = 0;

%--for discrimination-only example
root_subdir = '161014/';
datafiles(jj).sub_dir = 'raw_200/';%'140603 L4/';
datafiles(jj).logfile = '641_161014-skm_phase2_v3_discrim_.log';
datafiles(jj).sstCells = []; 
datafiles(jj).pvCells = []; 
datafiles(jj).alphacorr = 0;
datafiles(jj).roiDir='ROI';