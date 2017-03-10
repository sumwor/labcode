
rem do not show every command in the command prompt
@echo off

:: -----------------------set the parameters------------------------------------------------------
rem specify the working disk
set disk=F:
rem dataDir: path of raw data (tif files)
set dataDir=F:\kwan\learning\\test\
rem these paths should better be in the same disk since batch cannot cd to another disk directly
set stitchFile="StitchforBash"
set matlabWorkingPath="F:\kwan\labcode\matlab"
set IJPath="F:\Fiji.app\ImageJ-win64.exe"
set JythonPath="F:\kwan\labcode\ImageJ\motionCorrection.py"

rem set the iteration times (motion correction running times)
rem theoretically the more you run motion correction, the better the data should be
rem however, I tested one dataset, after 2 iterations it seems that motion correction
rem cannot do any better... but it was only one dataset...
set iterationTimes=4

::-----------------------------running the file clean up-----------------------
rem make raw;registered;stitch folder and move the raw data into raw folder
rem as well as in registered0 folder
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
    rem not sure why we should do these.....batch is anti-human.........
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

rem call matlab for stitch (create a single tiff file for reference frame)
    cd $matlabWorkingPath
    call echo "running the first stitch for refence No. "%%i%%" .................."
    call matlab -wait -nodesktop -nosplash -r "loop=%%i%%;"%stitchFile%
    cd %dataDir%

rem ImageJ motion correction part
rem Jython module (os) cannot be import in ImageJ, so we need to use Fiji here
rem why they programmers like to have such recursive acronym name? (Fiji and GNU)

    call echo "running the registeration No. "%%i%%" ................."

rem run the motion correction from the command line
    call set arg=%dataDir%,%%i%%
    call echo %%arg%%
    call %IJPath% -macro %JythonPath% %%arg%%
)

::--------------running the final stitch after the whole motion correction ---------------
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
