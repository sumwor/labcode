%% ----- plotdffWrapper: run this!

close all;
clear all;

root_dir = '/Users/phoenix/Documents/Kwanlab/learning/';

runplotbeh = 1;    %if 1, run the loop for behavior analysis for individual sessions

runplotdff = 1;    %if 1, run the loop for dF/F analysis for individual sessions
recalcdff = 1;       %if 1, re-calculate dF/F from raw F, otherwise load from .mat

%--- uses one M2 imaging data set -- ensemble dynamics example in paper
%fileListM2Test;
%--- uses all M2 imaging data sets
%fileListM2;
%--- imaging SST interneurons in M2
%fileListM2SST;
%--- muscimol analysis, behavior only
%fileListMus;
%--- dsicrimination task
fileListM2Test;

%% run analysis on individual experiments
if (runplotbeh)
    for jjjj=1:numel(datafiles)
        disp('------------------------------------------------');
        disp(['--- Processing ' int2str(jjjj) ' of ' int2str(numel(datafiles)) ' behavioral data... ']);
        disp('------------------------------------------------');
        
        behavFile=datafiles(jjjj).logfile;
        newroot_dir=[root_dir root_subdir datafiles(jjjj).sub_dir];
        cd(newroot_dir);
        readDiscrimLogfile;
        
        close all;
        clearvars -except runplotbeh recalcdff runplotdff jjjj root_dir root_subdir regionSet datafiles;
    end
end

if (runplotdff)
    for jjjj=1:numel(datafiles)
        disp('------------------------------------------------');
        disp(['--- Processing ' int2str(jjjj) ' of ' int2str(numel(datafiles)) ' fluorescence data... ']);
        disp('------------------------------------------------');
        
        behavFile=datafiles(jjjj).logfile;
        sstLabel=datafiles(jjjj).sstCells;
        pvLabel=datafiles(jjjj).pvCells;
        alphacorrfactor=datafiles(jjjj).alphacorr;
        newroot_dir=[root_dir root_subdir datafiles(jjjj).sub_dir];
        roiDir=datafiles(jjjj).roiDir;
        cd(newroot_dir);
        plotdff;
        
        close all;
        clearvars -except runplotbeh recalcdff runplotdff jjjj root_dir root_subdir regionSet datafiles;
    end
end

%% run analysis to summarize results
newroot_dir=[root_dir root_subdir];
cd(newroot_dir);

summarybeh; 
summarydff; 

%summarymuscimol;