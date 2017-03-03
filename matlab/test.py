import os


dir_path = "/Users/phoenix/Documents/Kwanlab/dataanalysis/discrimination/161013_try/"
#find the path of the reference image (the first one in this case)

rootpath = dir_path+'raw/'
list_files = os.walk(rootpath)
ImgPath = ''
for root, directory, files in list_files:
    for f in files:
        #print f
        path = os.path.join(dir_path, f)
        if not ImgPath:
            ImgPath += path
            break

print ImgPath
