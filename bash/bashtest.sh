#/bin/bash

dataDir="/Users/phoenix/Documents/Kwanlab/dataanalysis/discrimination/161013_try/"
cd $dataDir
mkdir raw
for file in ./*.tif
do
  #if [ -f $file ]
  #echo $file
  mv $file raw
  #fi
done

mkdir registered
mkdir stitch
