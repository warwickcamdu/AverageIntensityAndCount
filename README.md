# AverageIntensityAndCount
Laura Cooper, camdu@warwick.ac.uk

## InFocusAndMaxProjAverages.ijm
This script takes .nd2 files with filenames of the form 2024MMDD_text_CellLine_text_Sx_y.nd2, where x is 1,2,5 or 8 and y is 1 to 5. Two tif stacks are output: 1) the most in focus plane from each channel and a text file noting which plane was selected and 2) the max projection for each channel. Two tables are created one for each stack measuring the average intensity in the first and third channels, except for S8 files, where only channel 1 is measured. The number of nuclei is counted in the max projection image only but the value is included in both tables.

## MaxProjAverages.ijm
This script takes .nd2 files with filenames of the form 2024MMDD_text_CellLine_text_Sx_y.nd2, where x is 1,2 or 5 and y is 1 to 5. Two tables are created: "MaxProj Averages.csv" max, min, mean and standard deviation of the intensity in the first and third channels and MaxProj Thresholded Averages.csv measuring the max, min, mean and standard deviation of the instensity of the first and third channels after otsu thresholding.

## positiveNuclei.ijm
This script takes .nd2 files with filenames of the form 2024MMDD_text_CellLine_text_S8_y.nd2, where y is 1 to 5. It uses Stardist to find the nuclei and thresholds the alpha actin. It then states if the nuclei are positive for alpha actin if the nuclei region contains IntDen>2000 for the alpha actin channel. It output the ROIs and the counts and printed to the log.
