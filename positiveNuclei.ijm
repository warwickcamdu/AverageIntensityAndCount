/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".nd2") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if((endsWith(list[i], suffix)) && (matches(list[i], ".*_S8_.*")))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
run("Bio-Formats Importer", "open=["+input+File.separator+file+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
title=getTitle();
subtitle=split(title, ".");
//Do 3D
run("Split Channels");
// Threshold actin in 3D
selectWindow("C2-"+title);
run("Auto Threshold", "method=Shanbhag white stack");
//Converts 0-255 to 0-1
for (i = 1; i <= nSlices; i++) {
    setSlice(i);
    run("Divide...", "value=255");
}
//Mask alphaactin with actin
imageCalculator("Multiply create 32-bit stack", "C2-"+title,"C1-"+title);
mult_result=getTitle();
//Directional filter to keep long thin objects (remove noise)
for (i = 1; i <= nSlices; i++) {
    setSlice(i);
    //2D filter
    run("Directional Filtering", "type=Max operation=Opening line=30 direction=16");
    filt_result=getTitle();
    if (i>1){
    	//Puts filtered images back into a stack
    	run("Concatenate...", "  title=filtered open image1=filtered image2=["+filt_result+"] image3=[-- None --]");
    } else {
    	rename("filtered");
    }
    selectWindow(mult_result);
}

selectWindow("filtered");
//Max project to 2D
run("Z Project...", "projection=[Max Intensity]");
setOption("ScaleConversions", false);
run("16-bit");
//Threshold alphaactin
run("Auto Threshold", "method=Default white");
save(output+File.separator+subtitle[0]+"_filtered_max.tif");
run("Set Measurements...", "area mean standard redirect=C1-"+title+" decimal=3");
//Select non-circular areas larger than 10
//Change for different resolution
run("Analyze Particles...", "size=10-Infinity circularity=0.00-0.50 show=Masks summarize");
//Segment nuclei
selectWindow("C3-"+title);
run("Z Project...", "projection=[Max Intensity]");
run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'MAX_C3-"+title+"', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.479071', 'nmsThresh':'0.3', 'outputType':'Label Image', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
//Filter nuclei by size and ignore on borders
//Change for different resolution
run("Label Size Filtering", "operation=Greater_Than size=1500");
run("Remove Border Labels", "left right top bottom");
run("Remap Labels");
run("Label Map to ROIs", "connectivity=C4 vertex_location=Corners name_pattern=r%03d");
total_nuclei=roiManager("count");
selectWindow("MAX_filtered");
run("Set Measurements...", "mean integrated redirect=MAX_filtered decimal=3");
roiManager("measure");
//Filter nuclei by alpha actin
//Change for different resolution
positive_nuclei=0;
for (i = 0; i < nResults(); i++) {
    v = getResult('IntDen', i);
    if (v> 2000) {
    	positive_nuclei++;
    }
}
print(title);
//save everything!
print("Total nuclei found: "+total_nuclei);
print("Positive nuclei found: "+positive_nuclei);
close("*");
if ((positive_nuclei > 0) || (total_nuclei > 0)) {
selectWindow("Results");
run("Close");
}
if (total_nuclei>0) {
roiManager("save", output+File.separator+subtitle[0]+"_nuclei.zip");
roiManager("reset");
}
}
