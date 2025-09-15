index_directory = replace(getDirectory("Please supply the directory, in which the folder \"ABA_v3_download\" was created"), "\\", "/"); //because windows is stupid
download_directory = index_directory + "ABA_v3_download/";
aba_v3_directory = index_directory + "ABA_v3/";
File.makeDirectory(aba_v3_directory);

for (i = 1; i <= 132; i++) {
	File.makeDirectory(aba_v3_directory + i + "/");
}

filelist = getFileList(download_directory); 
filelist = Array.sort(filelist);
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".png")) { 
        open(download_directory + File.separator + filelist[i]);
		run("RGB Color");
		getDimensions(width, height, channels, slices, frames);
		makeSelection("polygon", newArray(width/2, width/2, width, width), newArray(0,height,height,0));
		run("Crop");
		run("Select None");
		save(aba_v3_directory + File.separator + filelist[i]);
    } 
}

run("Images to Stack", "use");
selectWindow("Stack");
getDimensions(width, height, channels, slices, frames);

save(index_directory + "aba_v3.tif");
close("Stack");

overview_width = width / 10;
overview_height = height / 10;

run("Grid/Collection stitching", "type=[Grid: column-by-column] order=[Down & Right                ] grid_size_x=12 grid_size_y=11 tile_overlap=0 first_file_index_i=1 directory=" + aba_v3_directory + " file_names=slice{iii}.png output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 downsample_tiles computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display] x=0.1 y=0.1 width=" + overview_width + " height=" + overview_height + " interpolation=Bicubic average");
run("RGB Color");
close("Fused");

textsize = 30;
setFont("SansSerif", textsize);
setColor("black");

for (x = 0; x < 12; x++) {
	for (y = 0; y < 13; y++) {
		drawString("" + (x * 11 + y + 1), x * overview_width, y * overview_height + textsize);
	}
}

save(index_directory + "atlas_overview.tif");
close("Fused (RGB)");