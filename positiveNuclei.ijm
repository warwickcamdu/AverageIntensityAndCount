
title=getTitle();
print(title);
run("Split Channels");
run("Set Measurements...", "mean shape redirect=C1-"+title+" decimal=3");
selectImage("C3-"+title);
setAutoThreshold("Huang dark");
setOption("BlackBackground", true);
run("Convert to Mask");
run("Analyze Particles...", "size=30.00-Infinity display exclude include add");
selectImage("C1-" + title)
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
roiManager("save selected", output+File.separator+"measured_nuclei.zip");
roiManager("delete");
roiManager("deselect");
roiManager("save", output+File.separator+"unmeasured_regions.zip");

print("Regions found: "count);
print("Nuclei measured: "nuclei_measured);
print("Positive nuclei: "positive_rois);

selectWindow("Results");
run("Close");
selectWindow("ROI Manager");
run("Close");

