/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output

Table.create("InFocusPlane Averages");
Table.create("MaxProj Averages");
processFolder(input);
selectWindow("InFocusPlane Averages");
Table.save(output+File.separator+"InFocusPlane Averages.csv");
selectWindow("MaxProj Averages");
Table.save(output+File.separator+"MaxProj Averages.csv");

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	file_count=0;
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if (endsWith(list[i], ".nd2")){
		if (startsWith(list[i], "2024")){
				meta=split(list[i], "_");
				if((endsWith(meta[5],"1")) || (endsWith(meta[5],"2")) || (endsWith(meta[5],"5")) || (endsWith(meta[5],"8"))) {
					processFile(input, output, list[i], file_count, meta);
					file_count++;
				}
			}
		}
	}
}

function processFile(input, output, filename, file_num, meta) {
	setBatchMode(true);
	run("Bio-Formats Importer", "open=["+input+File.separator+filename+"] color_mode=Default split_channels rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
name=split(filename, ".");
image_list = getList("image.titles"); 
merge_string = "";
merge_plane_string = "";
for (i = 0; i < lengthOf(image_list); i++) {
	selectWindow(filename + " - C="+i);
    max_std = 0;
	for (j = 1; j <= nSlices; j++) {
    	setSlice(j);
    	getStatistics(area, mean, min, max, std, histogram);
    	if (std > max_std) {
    		max_std = std;
    		slc=j;
    	}
	}
	setSlice(slc);
	print("C="+i + ": " + slc);
	run("Duplicate...", " ");
	merge_plane_string = merge_plane_string + "c" + i+1 + "=[" 
		+ filename + " - C="+i+ "-1] ";
	merge_string = merge_string + "c" + i+1 + "=[" 
		+ filename + " - C="+i+ "] ";
}
selectWindow("Log");
saveAs("Text", output +File.separator +name[0]+"_InFocusPlanes.txt");
run("Close");
run("Merge Channels...", merge_plane_string +"create");
rename("inFocusPlanes");
for (i = 1; i <= nSlices; i=i+2) {
	selectWindow("inFocusPlanes");
    setSlice(i);
    getStatistics(area, mean, min, max, std);
	selectWindow("InFocusPlane Averages");
	Table.set("Date", file_num, meta[0]);
	Table.set("Cell Line", file_num, meta[2]);
	Table.set("Day", file_num, meta[4]);
	Table.set("Stain", file_num, meta[5]);
	Table.set("Sample", file_num, substring(meta[6],0,lengthOf(meta[6])-4));
	Table.set("Ch"+i+" Mean", file_num, mean);
	Table.set("Ch"+i+" StdDev", file_num, std);
	
}
selectWindow("inFocusPlanes");
saveAs("tif", output + File.separator + name[0]+"_inFocusPlanes");
close();

run("Merge Channels...", merge_string +"create");
run("Z Project...", "projection=[Max Intensity]");
saveAs("tif", output + File.separator + name[0]+"_MaxProj");
rename("Max");
selectWindow("Composite");
close();
selectWindow("Max");
for (i = 1; i <= nSlices; i=i+2) {
	selectWindow("Max");
    setSlice(i);
    getStatistics(area, mean, min, max, std);
	selectWindow("MaxProj Averages");
	Table.set("Date", file_num, meta[0]);
	Table.set("Cell Line", file_num, meta[2]);
	Table.set("Day", file_num, meta[4]);
	Table.set("Stain", file_num, meta[5]);
	Table.set("Sample", file_num, substring(meta[6],0,lengthOf(meta[6])-4));
	Table.set("Ch"+i+" Mean", file_num, mean);
	Table.set("Ch"+i+" StdDev", file_num, std);
}
if(endsWith(meta[5], "8")){
	nuclei_channel=3;	
} else {
	nuclei_channel=4;
}
setSlice(nuclei_channel);
run("Duplicate...", "title=Nuclei");
run("Auto Threshold", "method=Huang white");
//run("Watershed");
run("Analyze Particles...", "size=30-Infinity exclude include summarize");
selectWindow("Summary");
nuclei_count=Table.get("Count",0);
run("Close");
selectWindow("Nuclei");
close();
selectWindow("InFocusPlane Averages");
Table.set("Nuclei", file_num, nuclei_count);
Table.update;
selectWindow("MaxProj Averages");
Table.set("Nuclei", file_num, nuclei_count);
Table.update;
selectWindow("Max");
close();
setBatchMode(false);
}
