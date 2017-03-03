from ij import IJ
import os


#this code should run following the command code to search for
#new directory and create registered/stitched folder

"""
running the motion correction automatically with input directory
"""

Argument = getArgument()
Argument_list = Argument.split(',')
dir_path = Argument_list[0]
loop = Argument_list[1]
print dir_path
print loop
#prepare the reference image
#dir_path = "/Users/phoenix/Documents/Kwanlab/dataanalysis/discrimination/161013_try/"
#find the path of the reference image (the first one in this case)

#root_path = dir_path+'raw/'
#list_files = os.walk(root_path)
#ImgPath = ''
#for root, directory, files in list_files:
#    for f in files:
#        #print f
#        path = os.path.join(root_path, f)
#        if not ImgPath:
#            ImgPath += path
#            break

#print ImgPath

#use the stitched raw file as the reference file
ImgPath = ''
root_path = dir_path + 'stitched' + loop
print root_path
list_files = os.walk(root_path)
for root, directory, files in list_files:
    for f in files:
        path = os.path.join(root_path, f)
        if not ImgPath:
            ImgPath += path
            break

print ImgPath



imp = IJ.openImage(ImgPath)
IJ.run(imp,"32-bit", "")  #convert the image to 32 bit
ave_imp = IJ.run(imp, "Z Project...", "projection=[Average Intensity]")  #acquire average intensity
IJ.run(imp,"Close","")
IJ.run("Save", "save=["+dir_path+"refFrame"+loop+".tif]")
#save the reference file to be used later
IJ.run(ave_imp,"Close","")  #close all the files and open the reference file in the batchTurboReg_forPy.ijm file

#run the ijm (modified to a little to suit the python code
macroFileDir = "/Users/phoenix/Documents/Kwanlab/dataanalysis/batchTurboReg_forPy.ijm"
IJ.runMacroFile(macroFileDir, Argument)

#add a line to save the record
IJ.saveAs("Results",dir_path+"Results"+loop+".xls");
#IJ.saveAs("Results","/Users/phoenix/Documents/Kwanlab/dataanalysis/discrimination/161013_try/Results1.xls");

#quit the Fiji GUI
IJ.run("Quit")