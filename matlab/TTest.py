from ij import IJ
import os


#this code should run following the command code to search for
#new directory and create registered/stitched folder

"""
running the motion correction automatically with input directory
"""

#dir_path = getArgument()

#prepare the reference image
dir_path = "/Users/phoenix/Documents/Kwanlab/learning/746/test/"
#find the path of the reference image (the first one in this case)

"""
root_path = dir_path+'raw/'
list_files = os.walk(root_path)
ImgPath = ''
for root, directory, files in list_files:
    for f in files:
        #print f
        path = os.path.join(root_path, f)
        if not ImgPath:
            ImgPath += path
            print path
            break

print ImgPath, "ddd"

"""
#use the stitched raw file as the reference file
root_path = dir_path + 'stitchedBeforeReg/'
ImgPath=''
list_files = os.walk(root_path)
for root, directory, files in list_files:
    for f in files:
        path = os.path.join(root_path, f)
        if not ImgPath:
            ImgPath += path
            break

print ImgPath
