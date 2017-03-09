#/bin/bash

#set the parameters here
#dataDir: path of raw data (tif files)
dataDir="/Users/phoenix/Documents/Kwanlab/learning/746/test/"
#this path should be find automatically at around 12 am everyday and run the following analysis


#mkdir registered
#mkdir stitched

#create the reference file

#set the code path
matlabPath="/Applications/MATLAB_R2016b.app/bin/matlab"
stitchFile="StitchforBash"
matlabWorkingPath="/Users/phoenix/Documents/Kwanlab/dataanalysis"
IJPath="/Applications/Fiji.app/Contents/MacOS/ImageJ-macosx"
JythonPath="/Users/phoenix/Documents/Kwanlab/imageJ/motionCorrection.py"

iterationTimes=4

#make raw;registered;stitch folder and move the raw data into raw folder
cd $dataDir
mkdir raw
mkdir registered0
for file in ./*.tif
do
  cp $file raw
  mv $file registered0
done


i=0
while ((i<$iterationTimes))
    do
    let j=i+1
    mkdir registered$j
    mkdir stitched$i
    mkdir StitchedParam
    cd StitchedParam
    #gonna add some code to manage those stitch parameter files
    echo scim_ver '3' > stitchParamFor$i.txt
    echo data_dir $dataDir >> stitchParamFor$i.txt
    echo raw_subdir 'raw' >> stitchParamFor$i.txt
    echo image_subdir 'registered'$i >> stitchParamFor$i.txt
    echo save_subdir 'stitched'$i >> stitchParamFor$i.txt
    echo batchLen '1000' >> stitchParamFor$i.txt
    echo dsFreq '1' >> stitchParamFor$i.txt

    cd $matlabWorkingPath
    echo "running the first stitch for refence No. "$i" .................."
    $matlabPath -nodesktop -nosplash -r "loop=$i;"$stitchFile
    cd $dataDir
#ImageJ motion correction part
#IJPath: path of ImageJ, different on different computers
#JythonPath: path of the Jython code to run the motion correction automatically
#different on different computers
#Jython module (os) cannot be import in ImageJ, so we need to use Fiji here
#why they programmers like to have such name? (Fiji and GNU linux)

    echo "running the registeration No. "$i" ................."

#run the motion correction from the command line
    arg=${dataDir}','${i}
    $IJPath -macro $JythonPath $arg


#then run the matlab stitch tiff part

#matlabpath: path of matlab, different on different computers
#stitchcodepath: path of the stitch code, this is slightly modified from the stitchTiff.m
#to achieve automatically running
#the path of the stitch file is "/Users/phoenix/Documents/Kwanlab/dataanalysis/StitchforBash.m"
#but to run this you only need the name "StitchforBash"

    #echo "running the stitch after registeration No. "$i" .........."
    #stitchFile="StitchforBash"

    #write the neccessary parameters for stitch file, change it here if needed
    #cd $matlabWorkingPath

    #echo scim_ver '3' > stitchParam.txt
    #echo data_dir $dataDir >> stitchParam.txt
    #echo raw_subdir 'raw' >> stitchParam.txt
    #echo image_subdir 'registered' >> stitchParam.txt
    #echo save_subdir 'stitched' >> stitchParam.txt
    #echo batchLen '1000' >> stitchParam.txt
    #echo dsFreq '1' >> stitchParam.txt

#running matlab stitch
#maybe read the argument from the file is easier to adjust
    #$matlabPath -nodesktop -nosplash -r $stitchFile
    let i=i+1
done

echo "running final stitch..........."

mkdir stitched$i
cd $matlabWorkingPath
echo scim_ver '3' > stitchParamFor$i.txt
echo data_dir $dataDir >> stitchParamFor$i.txt
echo raw_subdir 'raw' >> stitchParamFor$i.txt
echo image_subdir 'registered'$i >> stitchParamFor$i.txt
echo save_subdir 'stitched'$i >> stitchParamFor$i.txt
echo batchLen '1000' >> stitchParamFor$i.txt
echo dsFreq '1' >> stitchParamFor$i.txt

$matlabPath -nodesktop -nosplash -r "loop=$i;"$stitchFile

echo "ALL DONE!!!!!!"
