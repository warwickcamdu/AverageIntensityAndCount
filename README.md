# AverageIntensityAndCount
Laura Cooper, camdu@warwick.ac.uk

This script takes .nd2 files with filenames of the form 2024MMDD_text_CellLine_text_Sx_y.nd2, where x is 1,2,5 or 8 and y is 1 to 5. Two tif stacks are output: 1) the most in focus plane from each channel and a text file noting which plane was selected and 2) the max projection for each channel. Two tables are created one for each stack measuring the average intensity in the first and third channels, except for S8 files, where only channel 1 is measured. The number of nuclei is counted in the max projection image only but the value is included in both tables.
