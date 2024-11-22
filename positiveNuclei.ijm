/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = "MaxProj.tif") suffix

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
open(input+File.separator+file);
title=getTitle();
//Do 3D
run("Split Channels");
selectWindow("C2-"+title);
run("Auto Threshold", "method=Percentile white");
run("Divide...", "value=255");
imageCalculator("Multiply create 32-bit", "C2-"+title,"C1-"+title);
//Check if dectional beofre/after max proj: compare the results
run("Directional Filtering", "type=Max operation=Opening line=30 direction=32");
setOption("ScaleConversions", false);
run("16-bit");
run("Auto Threshold", "method=Default white");
positive=getTitle();
save(output+File.separator+positive+".tif");
//max proj
//save max proj
run("Set Measurements...", "area mean standard redirect=C1-"+title+" decimal=3");
run("Analyze Particles...", "size=10-Infinity circularity=0.00-0.50 summarize");
//Add mask output
selectWindow("C3-"+title);
run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'C3-"+title+"', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.479071', 'nmsThresh':'0.3', 'outputType':'Label Image', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
run("Label Size Filtering", "operation=Greater_Than size=1500");
run("Remove Border Labels", "left right top bottom");
run("Remap Labels");
run("Label Map to ROIs", "connectivity=C4 vertex_location=Corners name_pattern=r%03d");
total_nuclei=roiManager("count");
selectWindow(positive);
run("Set Measurements...", "mean integrated redirect="+positive+" decimal=3");
roiManager("measure");
positive_nuclei=0;
for (i = 0; i < nResults(); i++) {
    v = getResult('RawIntDen', i);
    if (v/255 > 1000) {//higher?
    	positive_nuclei++;
    }
}
//cEDS_14d_S8_3 2/3 nuclei positive
print(title);
print("Total nuclei found: "+total_nuclei);
print("Positive nuclei found: "+positive_nuclei);
waitForUser;
close("*");
selectWindow("Results");
run("Close");
roiManager("save", output+File.separator+title+"_nuclei.zip");
roiManager("reset");
}
