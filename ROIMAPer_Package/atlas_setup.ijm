download_directory = replace(getDirectory("Please supply the directory, of the downloaded atlas"), "\\", "/"); //because windows is stupid
atlas_name = File.getNameWithoutExtension(download_directory);
index_directory = File.getDirectory(download_directory);
Dialog.create("Halfbrain option");
Dialog.addCheckbox("Do you want to create an altas of the halfbrain?", false);
Dialog.show();

halfbrain_crop = Dialog.getCheckbox();

if (halfbrain_crop) {
	atlas_name = atlas_name + "_halfbrain";
}
setup_directory = index_directory + atlas_name + "_setup/";




File.makeDirectory(setup_directory);



image_counter = 0;

filelist = getFileList(download_directory); 
filelist = Array.sort(filelist);
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".png")) { 
        open(download_directory + File.separator + filelist[i]);
		run("RGB Color");
		
		if (halfbrain_crop) {
			getDimensions(width, height, channels, slices, frames);
			makeSelection("polygon", newArray(width/2, width/2, width, width), newArray(0,height,height,0));
			run("Crop");
			run("Select None");
		}
		image_counter++;
		save(setup_directory + File.separator + filelist[i]);
    } 
}

//creates structure for the ROIs to be saved in - might need to move this into the atlas_to_roi macro
for (i = 1; i <= image_counter; i++) {
	File.makeDirectory(setup_directory + i + "/");
}

run("Images to Stack", "fill=white use");
selectWindow("Stack");
getDimensions(width, height, channels, slices, frames);

save(index_directory + atlas_name + ".tif");
close("Stack");

overview_width = width / 10;
overview_height = height / 10;

//creating the most compact grid
divisor_image_number = newArray(image_counter);
result_image_number = newArray(image_counter);
combined_result_divisor = newArray(image_counter);
for (i = 0; i < image_counter; i++) {
	divisor_image_number[i] = i+1;	
	result_image_number[i] = Math.ceil(image_counter / (i+1));
	combined_result_divisor[i] = Math.ceil(image_counter / (i+1)) + i + 1;
}

index_of_equilibrium = Array.findMinima(combined_result_divisor,1);

grid_rows = divisor_image_number[index_of_equilibrium[0]];
grid_columns = result_image_number[index_of_equilibrium[0]];

for (i = image_counter + 1; i <= grid_rows * grid_columns; i++) {
	name = "slice" + IJ.pad(i, 3);
	newImage(name, "RGB white", width, height, slices); //because the stitching fails otherwise
	
	save(setup_directory + name + ".png" );
	close(name);
}

run("Grid/Collection stitching", "type=[Grid: column-by-column] order=[Down & Right                ] grid_size_x=" + grid_columns + " grid_size_y=" + grid_rows + " tile_overlap=0 first_file_index_i=1 directory=" + setup_directory + " file_names=slice{iii}.png output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 downsample_tiles computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display] x=0.1 y=0.1 width=" + overview_width + " height=" + overview_height + " interpolation=Bicubic average");
run("RGB Color");
close("Fused");

for (i = image_counter + 1; i <= grid_rows * grid_columns; i++) {
	name = "slice" + IJ.pad(i, 3);
	File.delete(setup_directory + name + ".png" );
}
File.delete(setup_directory + "TileConfiguration.txt");

textsize = 30;
setFont("SansSerif", textsize);
setColor("black");

for (x = 0; x < grid_rows + 1; x++) {
	for (y = 0; y < grid_columns + 1; y++) {
		if (x * grid_rows + y + 1 <= image_counter) {
			drawString("" + (x * grid_rows + y + 1), x * overview_width, y * overview_height + textsize);
		}
	}
}

save(index_directory + atlas_name + "_overview.tif");
close("Fused (RGB)");