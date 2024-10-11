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
open(input+file);
title=getTitle();
noext = split(title, ".");
print(title);
run("Split Channels");
run("Set Measurements...", "mean shape redirect=C1-"+title+" decimal=3");
selectImage("C3-"+title);
run("Gaussian Blur...",2);
run("Auto Threshold", "method=Huang white");
run("Analyze Particles...", "size=30.00-Infinity display exclude include add");
selectImage("C1-" + title);
count=roiManager("count");
positive_rois=0;
used_rois=Array.getSequence(count);
for (i = 0; i < nResults(); i++) {
    if (getResult('Solidity', i) > 0.97) {
    	roiManager("select", i);
    	if (getResult('Mean', i) > 3.5) {
    		positive_rois++;
    	}
    } else {
    	used_rois[i]=count+1;
    }
}
used_rois=Array.deleteValue(used_rois, count+1);
nuclei_measured=lengthOf(used_rois);
roiManager("select",used_rois);
roiManager("save selected", output+File.separator+noext[0]+"_measured_nuclei.zip");
roiManager("delete");
roiManager("deselect");
if (roiManager("count") > 0) {
	roiManager("save", output+File.separator+noext[0]+"_unmeasured_regions.zip");
}

print("Regions found: "+count);
print("Nuclei measured: "+nuclei_measured);
print("Positive nuclei: "+positive_rois);

selectWindow("Results");
run("Close");
selectWindow("ROI Manager");
run("Close");
close("*");
}
