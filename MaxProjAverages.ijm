/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output

Table.create("MaxProj Thresholded Averages")
Table.create("MaxProj Averages");
processFolder(input);
selectWindow("MaxProj Thresholded Averages");
Table.save(output+File.separator+"MaxProj Thresholded Averages.csv");
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
				if((endsWith(meta[5],"1")) || (endsWith(meta[5],"2")) || (endsWith(meta[5],"5"))) {
					processFile(input, output, list[i], file_count, meta);
					file_count++;
				}
			}
		}
	}
}

function writeTable(tableName, file_num, meta, i, area, mean, min, max, std) {
	selectWindow(tableName);
	Table.set("Date", file_num, meta[0]);
	Table.set("Cell Line", file_num, meta[2]);
	Table.set("Day", file_num, meta[4]);
	Table.set("Stain", file_num, meta[5]);
	Table.set("Sample", file_num, substring(meta[6],0,lengthOf(meta[6])-4));
	Table.set("Ch"+i+" Area", file_num, area);
	Table.set("Ch"+i+" Mean", file_num, mean);
	Table.set("Ch"+i+" StdDev", file_num, std);
	Table.set("Ch"+i+" Min", file_num, min);
	Table.set("Ch"+i+" Max", file_num, max);
	Table.update;
}

function processFile(input, output, filename, file_num, meta) {
	setBatchMode(true);
	run("Bio-Formats Importer", "open=["+input+File.separator+filename+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
name=split(filename, ".");
run("Z Project...", "projection=[Max Intensity]");
saveAs("tif", output + File.separator + name[0]+"_MaxProj");
rename("Max");
for (i = 1; i <= nSlices; i=i+2) {
	selectWindow("Max");
    setSlice(i);
    getStatistics(area, mean, min, max, std);
	writeTable("MaxProj Averages", file_num, meta, i, area, mean, min, max, std);
}
selectWindow("Max");
run("Duplicate...", "title=binary duplicate");
setOption("ScaleConversions", true);
run("Auto Threshold", "method=Otsu white stack");
run("Set Measurements...", "area mean standard min redirect=Max decimal=3");
for (i = 1; i <= nSlices; i=i+2) {
	selectWindow("binary");
	setSlice(i);
	run("Analyze Particles...", "display clear summarize composite");
	selectWindow("Results");
	run("Summarize");
	wait(1000);
	max=Table.get("Max", nResults()-1);
	min=Table.get("Min", nResults()-2);
	mean=Table.get("Mean", nResults()-4);
	std=Table.get("Mean", nResults()-3);
	selectWindow("Summary of binary");
	area=Table.get("Total Area",0);
	writeTable("MaxProj Thresholded Averages", file_num, meta, i, area, mean, min, max, std);
	if (isOpen("Summary of binary")){
		selectWindow("Summary of binary");
		run("Close");
	}
}
close("*");
if (isOpen("Results")){
	selectWindow("Results");
		run("Close");
	}
setBatchMode(false);
}
