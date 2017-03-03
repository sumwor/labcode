from ij import IJ


#this code should run following the command code to search for
#new directory and create registered/stitched folder

"""
running the motion correction automatically with input directory
"""

#dir_path = getArgument()

#prepare the reference image
dir_path = "/Users/phoenix/Documents/Kwanlab/dataanalysis/discrimination/161013_try/"
imp = IJ.openImage(dir_path + "raw/161013_task3079.tif")
IJ.run(imp,"32-bit", "")  #convert the image to 32 bit
ave_imp = IJ.run(imp, "Z Project...", "projection=[Average Intensity]")  #acquire average intensity
IJ.run(imp,"Close","")
IJ.run("Save", "save=["+dir_path+"refFrame.tif]") #save the reference file to be used later
IJ.run(ave_imp,"Close","")  #close all the files and open the reference file in the batchTurboReg_forPy.ijm file

#run the ijm (modified to a little to suit the python code
macroFileDir = "/Users/phoenix/Documents/Kwanlab/dataanalysis/batchTurboReg_forPy.ijm"
IJ.runMacroFile(macroFileDir, dir_path)