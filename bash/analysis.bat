
rem do not show every command in the command prompt
@echo off




:: -----------------------set the parameters------------------------------------------------------
rem specify the working disk
set disk=F:
rem dataDir: path of raw data (tif files)
set dataDir=F:\kwan\learning\\test\
rem this path should be find automatically at around 12 am everyday and run the following analysis
rem set the code path
rem set matlabPath="E:\MatlabPat\bin\matlab.exe"
rem these path should better in the same disk since batch cannot cd to another disk directly
set stitchFile="StitchforBash"
set matlabWorkingPath="F:\kwan\labcode\matlab"
set IJPath="F:\Fiji.app\ImageJ-win64.exe"
set JythonPath="F:\kwan\labcode\ImageJ\motionCorrection.py"

rem set the iteration times
set iterationTimes=4

::-----------------------------running the file clean up-----------------------
rem make raw;registered;stitch folder and move the raw data into raw folder
%disk%
cd %dataDir%
mkdir raw
mkdir registered0
for /R %%s in (*) do (
copy %%s raw
move %%s registered0
)



::----------------------iterating for motion correction--------------------------

for /l %%i in (0,1,%iterationTimes%) do (
    rem not sure why we should do these.....batch is anti-humanity.........
    call set /A j="%%i%% + 1"
    call mkdir registered%%j%%
    call mkdir stitched%%i%%
    mkdir StitchedParam
    cd StitchedParam

    call echo stitchParamFile, stitchParamFor%%i%.txt
    call echo stitchParamfile, stitchParamFor%%i%.txt
    call echo scim_ver 3 > stitchParamFor%%i%.txt
    call echo data_dir %dataDir% >> stitchParamFor%%i%.txt
    call echo raw_subdir raw >> stitchParamFor%%i%.txt
    call echo image_subdir registered%%i%% >> stitchParamFor%%i%.txt
    call echo save_subdir stitched%%i%% >> stitchParamFor%%i%.txt
    call echo batchLen 1000 >> stitchParamFor%%i%.txt
    call echo dsFreq 1 >> stitchParamFor%%i%.txt

    cd $matlabWorkingPath
    call echo "running the first stitch for refence No. "%%i%%" .................."
    rem seems that windows can directly use matlab.....
    rem need to add the code folders to matlab search path automatically
    call matlab -wait -nodesktop -nosplash -r "loop=%%i%%;"%stitchFile%
    cd %dataDir%

rem ImageJ motion correction part
rem IJPath: path of ImageJ, different on different computers
rem JythonPath: path of the Jython code to run the motion correction automatically
rem different on different computers
rem Jython module (os) cannot be import in ImageJ, so we need to use Fiji here
rem why they programmers like to have such name? (Fiji and GNU linux)

    call echo "running the registeration No. "%%i%%" ................."

rem run the motion correction from the command line
    call set arg=%dataDir%,%%i%%
    call echo %%arg%%
    call %IJPath% -macro %JythonPath% %%arg%%


rem then run the matlab stitch tiff part

rem matlabpath: path of matlab, different on different computers
rem stitchcodepath: path of the stitch code, this is slightly modified from the stitchTiff.m
rem to achieve automatically running
rem the path of the stitch file is "/Users/phoenix/Documents/Kwanlab/dataanalysis/StitchforBash.m"
rem but to run this you only need the name "StitchforBash"

)

::--------------running the final stitch after the motion correction ---------------
echo "running final stitch..........."

mkdir stitched%iterationTimes%
cd %matlabWorkingPath%
echo scim_ver 3 > stitchParamFor%iterationTimes%.txt
echo data_dir %dataDir% >> stitchParamFor%iterationTimes%.txt
echo raw_subdir raw >> stitchParamFor%iterationTimes%.txt
echo image_subdir registered%iterationTimes% >> stitchParamFor%iterationTimes%.txt
echo save_subdir stitched%iterationTimes% >> stitchParamFor%iterationTimes%.txt
echo batchLen 1000 >> stitchParamFor%iterationTimes%.txt
echo dsFreq 1 >> stitchParamFor%iterationTimes%.txt

matlab -wait -nodesktop -nosplash -r "loop=%iterationTimes%;"%stitchFile%

echo "ALL DONE!!!!!!"

pause
