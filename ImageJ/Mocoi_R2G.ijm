// For automated batch movement correction of GCaMP  based on static red signal using moco.
// Author: Michael J. Siniscalchi
// Last Revision: 161103

// Settings
nFrames_seed = 100; 	// nFrames to AVG for for ref image
max_error = 1;		// threshold abs(dx)+abs(dy) per frame
err_tolerance = 0.001;	// threshold cumulative error (pixels) for repeat
max_rep = 10;		// threshold for considering only max_error for repeat


// Define Directories
root_dir = "E:\\MJData\\";
//root_dir = "C:\\Users\\Michael\\Desktop\\Analysis\\for mocoMacro\\test\\";

//root_dir = getDirectory("Choose a Directory");
data_dir = getFileList(root_dir);

fs = File.separator;
//i =1;
for (i=0; i<data_dir.length; i++){
	run("Close All");
	lenString=lengthOf(data_dir[i]);
	//data_dir[i]=replace(data_dir[i],"/","\"");
	data_dir[i]=data_dir[i]+"\\";
	//print("data_dir"+data_dir[i]);
	redpath = root_dir+data_dir[i]+"stitchedRed"+fs;
	greenpath = root_dir+data_dir[i]+"stitchedGreen"+fs;
	results_path = root_dir+data_dir[i]+"moco results"+fs;
	reg_path =  root_dir+data_dir[i]+"registered"+fs;

	// DELETE PREVIOUS RESULTS
	//del_path = newArray(results_path,reg_path);
	//for (k=0;k<del_path.length;k++){
	//	if (File.exists(del_path[k])) {
		//	print("\n"); print("------------------------------------------------------------------------------------------------------------------------------"); print("\n");
		//	print("Results directory exists.");
		//	f_names = getFileList(del_path[k]);
		//	for (j=0;j<f_names.length;j++){
		//		path_name = del_path[k]+f_names[j];
		//		File.delete(path_name); print("file deleted: "+f_names[j]);
		//	};
		//	if (File.delete(del_path[k])){ print("Previous results deleted."); };
		//};
	//};

	//File.makeDirectory(results_path);
	//File.makeDirectory(reg_path);

	print("\n"); print("------------------------------------------------------------------------------------------------------------------------------"); print("\n");
	print("Directory for raw stacks:");
	print("(red channel):        "+redpath);
	print("(green channel):     "+greenpath); print("\n");
	print("Results Directory:");
	print(results_path);
	print("Directory for Registered Stack:");
	print(reg_path);

	// GET STITCHED RED STACK
	f_names = getFileList(redpath);
	for(j=0; j<f_names.length; j++){
		print("j="+j);
		if(endsWith(f_names[j],".tif")){
 			fname_red = f_names[j];
			print("Red Stack for moco:");
			print(fname_red); print("\n");
        		};
	};

	// load raw stack
	red_stack = redpath+fname_red;
	open(red_stack);
	h_rawStack =  getImageID();

	// get avg z-projection
	run("Z Project...", "stop=[&nFrames_seed] projection=[Average Intensity]");
	h_zProj = getImageID();
	str_zProj = getTitle();

	// MAKE REFERENCE IMAGE:	get substack-->avg-->moco-->avg-->moco-->avg to make reference image
	selectImage(h_rawStack);
	run("Make Substack...", "  slices=1-1000");
	h_newStack = getImageID();
	str_newStack = getTitle();

	num_repeats = 0;
	do {	sum_err = 0; error_xy =0; row = 0;
		run("moco ", "value=10 downsample_value=0 template=[&str_zProj] stack=[&str_newStack] log=[Generate log file] plot=[Plot RMS]");
		do {	dx = getResult("x",row);
			dy = getResult("y",row);
			error_xy = abs(dx) + abs(dy);
			sum_err += error_xy;
			row++;
		//scan for translation > (e.g., 1 pixel) until > (tolerance) mean translations are found
		} while (error_xy<=max_error && sum_err<=(err_tolerance*nResults) && row<nResults);
		num_repeats++;

		selectImage(h_newStack); close();
		selectImage(h_zProj); close();

		selectImage("New Stack");
		h_newStack = getImageID();
		str_newStack = getTitle();
		close("\\Others");

		run("Z Project...", "projection=[Average Intensity]");
		h_zProj = getImageID();
		str_zProj = getTitle();

	} while (error_xy>max_error  || (sum_err>(err_tolerance*nResults) && num_repeats<=max_rep));

	//SAVE REF IMAGE
	selectImage(h_zProj);
	ref_img = reg_path+"ref_img.tif";
	saveAs("Tiff", ref_img);

	print("# reps for ref_img: "+num_repeats);
	print("# Open Images (debug): "+nImages); //debug

	run("Close All");

	// moco raw stack (RED) using zProj(1-1000moco) as reference **FUNCTIONALIZE, maybe make into independent macro mocoi++(h_zProj, h_stack, results_path)
	open(red_stack);
	h_newStack = getImageID();
	str_newStack = getTitle();

	open(ref_img);
	h_zProj = getImageID();
	str_zProj = getTitle();

	num_repeats = 0;
	do {	sum_err = 0; error_xy =0; row = 0;
		run("moco ", "value=50 downsample_value=0 template=[&str_zProj] stack=[&str_newStack] log=[Generate log file] plot=[Plot RMS]");
		do {	dx = getResult("x",row);
			dy = getResult("y",row);
			error_xy = abs(dx) + abs(dy);
			sum_err += error_xy;
			row++;
		//scan for translation > (e.g., 1 pixel) until > (tolerance) mean translations are found
		} while (error_xy<=max_error && sum_err<=(err_tolerance*nResults) && row<nResults);

		print("Repeat #: "+(++num_repeats));

		selectImage(h_newStack);  close();
		selectImage(h_zProj); close();

		selectImage("New Stack");
		h_newStack = getImageID();
		str_newStack = getTitle();
		close("\\Others");

		run("Z Project...", "projection=[Average Intensity]");
		h_zProj = getImageID();
		str_zProj = getTitle();

		saveAs("results" , results_path+"Results"+num_repeats+".txt");
	} while (error_xy>max_error  || (sum_err>(err_tolerance*nResults) && num_repeats<=max_rep));
	run("Close All");

	// USE CUMULATIVE TRANSLATION OF RED FOR CORRECTING GREEN CHANNEL
	// 1. get results tables and create array for accumulated frame-by-frame errors
	print("Loading translation results...");
	results_files = getFileList(results_path);
	path_name = results_path+results_files[0];
	run("Results... ", "open=[&path_name]");
	results_vector = newArray(2*nResults); //1D array for x- and y- translations

	// 2. store cumulative errors in array, and sum cumulatively with prior tables
	for (j=0; j<results_files.length; j++){
		path_name = results_path+results_files[j];
		run("Results... ","open=[&path_name]");
		for (k=0; k<nResults; k++){
			results_vector[k] += getResult("x", k);
			results_vector[nResults+k] += getResult("y", k);
		};
		print(results_files[j]);
	};

	// 3. generate summary results table that defines total translation (x,y) summed from all moco repeats for each frame
	dx = Array.slice(results_vector,0,nResults); 	//array.slice is [begin, end)
	dy = Array.slice(results_vector,nResults,2*nResults);
	Array.show("Results (row numbers)", dx, dy);
	path_name = reg_path+"mocoi_Results.txt";
	saveAs("results" , path_name);

	// 3b. apply to raw red stack for proofread
	open(red_stack);
	str_rawStack = getTitle();

	open(ref_img);
	str_ref =  getTitle();

	run("moco ", "value=50 downsample_value=0 template=[&str_ref] stack=[&str_rawStack] log=[Choose log file] plot=[Plot RMS] choose=[&path_name]");
	path_name = reg_path+"reg_"+fname_red;
	saveAs("Tiff", path_name);
	run("Close All");

	// 4. apply transformation to green channel
	f_names = getFileList(greenpath);
	for(j=0; j<f_names.length; j++){
		if(endsWith(f_names[j],".tif")){
 			path_name = greenpath+f_names[j];
			open(path_name);
			str_rawStack = getTitle();
			print("\n");
			print("Green Stack for Movement Correction:");
			print(path_name);

			open(ref_img);
			str_ref =  getTitle();

			path_name = reg_path+"mocoi_Results.txt";
			run("moco ", "value=50 downsample_value=0 template=[&str_ref] stack=[&str_rawStack] log=[Choose log file] plot=[Plot RMS] choose=[&path_name]");

			path_name = reg_path+"reg_"+f_names[j];
			saveAs("tiff" , path_name);
			print("\n");
			print("Movement-Corrected Stack:");
			print(path_name);

		};
	};

//Save Logfile
	file_path = reg_path+"Log.txt";
	selectWindow("Log");
	saveAs("text" , file_path);
	print("\\Clear");
};




//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------















// **to apply transformation to green channel**
// if iterative process is used, results will have to be summed first...
// run("moco ", "value=51 downsample_value=0 template=[AVG_Substack (1-1000)] stack=[Substack (1-1000)] log=[Choose log file] plot=[Plot RMS] choose=[coord_Trans]");

// **populate array with results, then get stats and test for whether to do another round...
//  for (i=0; i<nResults; i++){... getResult("Column", row[i]);
// Array.getStatistics(array, min, max, mean, stdDev) - Returns the min, max, mean, and stdDev of array, which must contain all numbers.
// 2D indexing from 1D array: value=a[x+y*xmax]

//function myFunction(arg1, arg2. arg3) {
//      statement(s)
//   }

//**FUNCTIONALIZE the loops; maybe make into independent macro mocoi++(h_zProj, h_stack, results_path)

// (OLD) MAKE REFERENCE IMAGE:	get substack-->avg-->moco-->avg-->moco-->avg to make reference image
	//selectImage(h_rawStack);
	//run("Make Substack...", "  slices=1-1000");
	//h_newStack = getTitle();
	//for (j=0; j<1; j++){ // test proc; example data converged @ 7th iteration for 1-500f ref, 150930 M14
	//	run("moco ", "value=10 downsample_value=0 template=[&h_zProj] stack=[&h_newStack] log=[Generate log file] plot=[Plot RMS]");
	//									//saveAs("results" , redpath+"Results"+j+".txt");
	//	selectImage(h_newStack); close(); 				//print("close newStack:   "+h_newStack);
	//	selectImage(h_zProj); close(); 					//print("close zProj:   "+h_zProj);
//
//		selectImage("New Stack");
//		h_newStack = getTitle();  					//print("select newStack:   "+h_newStack);
//		run("Z Project...", "projection=[Average Intensity]");
//		h_zProj = getTitle(); 						//print("title zProj:   "+h_zProj);
//	};

// (OLD) delete previous
//if (File.exists(results_path)) {
//		print("\n"); print("------------------------------------------------------------------------------------------------------------------------------"); print("\n");
//		print("Results directory exists.");
//		f_names = getFileList(results_path);
//		for (j=0;j<f_names.length;j++){
//			path_name = results_path+f_names[j];
//			File.delete(path_name); print("file deleted: "+f_names[j]);
//		};
//		if (File.delete(results_path)){ print("Previous results deleted."); };
//	};
