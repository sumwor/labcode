/////batch motion corrects series of .tif images in input directory with Turboreg, and outputs results to output directory/////

//user-defined parameters for input/output directories
//input=getDirectory("Choose a directory with images to be motion corrected");   //directory with images to be motion corrected
//output=getDirectory("Choose an output directory");   //directory for output motion corrected images
//trying to get directory from command line
arg = getArgument();
arg_list=split(arg, ',');
data_dir=arg_list[0];
loop=arg_list[1];
//print(data_dir);
//print(loop);
loop_number=parseInt(loop);
new_loop=d2s(loop_number+1,0);
input = data_dir + "registered"+loop+"/";
output = data_dir + "registered"+new_loop+"/";
//print(input);
//print(output);


if (input==output) {
	exit("Input and output directories need to be different.");
}

//check if have reference frame to use. If not, get parameters to create one.
//waitForUser( "Pause","Open your reference frame and press OK when ready");
//rename("refFrame");
open(data_dir+"refFrame"+loop+".tif");
rename("refFrame");

/////////////////////////////////////////////

//Turboreg all files in input dir

list=getFileList(input);
tiffiles=newArray(0);
for (listind=0; listind<list.length; listind++){
     if(endsWith(list[listind],".tif")) tiffiles=Array.concat(tiffiles,list[listind]);
}

fileind=0;
for (fileind=0; fileind<tiffiles.length; fileind++){

   open(input+tiffiles[fileind]);
   rename("currentStack");
   run("Grays");
   run("32-bit");
//   run("16-bit");

   numSlice=nSlices;
   width=getWidth();
   height=getHeight();
   run("Conversions..."," ");		// don't re-scale pixel values when converting to 16-bit
   setBatchMode(true);	// hide output during the loop to speed up processing

		for (j=1; j<=numSlice; j++) { // for each frame
			selectWindow("currentStack");
			setSlice(j);
			run("Duplicate...", "title=currentFrame");   // get the current frame
			run("TurboReg ", "-align "
				+ "-window currentFrame" + " "// Source
				+ "0 0 " + (width - 1) + " " + (height - 1) + " " // No cropping.
				+ "-window refFrame" + " "// Target
				+ "0 0 " + (width - 1) + " " + (height - 1) + " " // No cropping.
				+ "-rigidBody " // This corresponds to rotation and translation.
				+ (width / 2) + " " + (height / 2) + " " // Source translation landmark.
				+ (width / 2) + " " + (height / 2) + " " // Target translation landmark.
				+ "0 " + (height / 2) + " " // Source first rotation landmark.
				+ "0 " + (height / 2) + " " // Target first rotation landmark.
				+ (width - 1) + " " + (height / 2) + " " // Source second rotation landmark.
				+ (width - 1) + " " + (height / 2) + " " // Target second rotation landmark.
				+ "-showOutput");

			run("Duplicate...","title=registered");
//			run("16-bit");
			if (j==1) {		// if this is first slice
				rename("registeredStack");
			} else {
				run("Concatenate...", " title=registeredStack image1=registeredStack image2=registered image3=[-- None --]");
			}

			selectWindow("currentFrame");
			close();
			selectWindow("Output");
			close();
		}
   setBatchMode("exit and display");

   selectWindow("registeredStack");
   run("16-bit");
   saveAs("tiff",output+"reg_"+tiffiles[fileind]);

   close("reg_"+tiffiles[fileind]);
   close("currentStack");

}
