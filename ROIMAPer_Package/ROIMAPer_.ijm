//Inspired by the FASTMAP plugin by Dylan Terstege from the Epp Lab, University of Calgary published on 12-07-2019
//
// Created 2025-08-12 by Julian Rodefeld
// Ciernia Lab, University of British Columbia

var map_to_control_channel = false;
var is_czi = newArray();
var automatic_bounding_box = false;
//store flipping/rotation information
var rotate_array = newArray();
var flip_array = newArray();
var output_path = "";
var control_channel = "";

showMessage("ROIMAPer", "<html>
    +"<h1><font color=black>ROIMAPer </h1>" 
    +"<p1>Version: 0.9 (Sep 2025)</p1>"
    +"<H2><font size=3>Created by Julian Rodefeld, Ciernia Lab, University of British Columbia</H2>" 
    +"<H2><font size=2>Inspired by the FASTMAP plugin by Dylan Terstege from the Epp Lab</H2>" 
    +"<h3>   <h3>"    
    +"<h1><font size=2> </h1>"  
	   +"<h0><font size=5> </h0>"
    +"");


home_directory = getDirectory("In which directory is the \"ABA_v3\" folder located?");

temp = getDirectory("temp");
File.setDefaultDir(home_directory);
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
month = month + 1;//because month is zero-based index
//get the directory
image_directory = getDirectory("Please choosethe directory that contains your images.");
image_list = getFileList(image_directory);
image_list = Array.sort(image_list);
total_images = lengthOf(image_list);
higher_directory = File.getDirectory(image_directory);

Dialog.create("Image selection");
Dialog.addMessage("Which subrange of files would you like to analyze?");
Dialog.addNumber("Start of selection", 1);
Dialog.addNumber("End of selection", total_images);
Dialog.show();

image_selection_start = Dialog.getNumber() - 1; // minus one because arrays start counting at 0
image_selection_end = Dialog.getNumber();

image_selection_size = image_selection_end-image_selection_start;
Dialog.createNonBlocking("File confirmation");
length_limit = 20;
columns = Math.ceil(image_selection_size/length_limit);
Dialog.addMessage("These are the files you have chosen, please confirm.");
for (i = 0; i < image_selection_size; i++) {
	Dialog.addCheckbox(image_list[i + image_selection_start], true);
	for (j = 1; j < columns; j++) {
		if (i + 1 < image_list.length) {
			Dialog.addToSameRow();
			i++;
			Dialog.addCheckbox(image_list[i + image_selection_start], true);
		}
	}

}//making checkbox system to select/deselect individual files from the file-range
//displaying in columns, so the window doesn't get bigger than the screen
Dialog.show();

file_chosen = newArray(image_selection_size);
for (i = 0; i < image_selection_size; i++) { //retrieving the file confirmation info
	file_chosen[i] = Dialog.getCheckbox();
}

image_path = newArray();
image_name = newArray();
image_name_without_extension = newArray();

for (i = image_selection_start; i < image_selection_end; i++) {
	if (file_chosen[i]) {
	    image_path = Array.concat(image_path, replace(image_directory + image_list[i], "\\", "/"));
	    image_name = Array.concat(image_name, File.getName(image_directory + image_list[i]));
	    image_name_without_extension = Array.concat(image_name_without_extension, File.getNameWithoutExtension(image_directory + image_list[i]));
	}
}

output_path = higher_directory + "/ROIMAPer_results_" + year + "_" + month + "_" + dayOfMonth + "_" + hour + "_" + minute + "/";

//make empty array of roi-set names
xpixelnumber = newArray();//could re-sort the image_path index (and all others belonging to it) to start with smallest image or smthg
ypixelnumber = newArray(); 
slicenumber = newArray();
channelnumber = newArray();


setBatchMode(true);
roiManager("reset");
for (i = 0; i < image_path.length; i++) {
	is_czi = Array.concat(is_czi, endsWith(image_name[i], ".czi"));
	//get metadata, so we do not have to open big stacks of images

	run("Bio-Formats Importer", "open=" + image_path[i] + " color_mode=Default display_metadata rois_import=[ROI manager] view=[Metadata only] stack_order=Default");
	
	//selectWindow("Original Metadata - " + image_name[i]); //not sure if this is needed
	//get the metadata as a string
	metadata = getInfo("window.contents");
	
	//close metadata table immediately
	table_name = getInfo("window.title");
	
	//make a text search for dimension-specific identifiers
	metadata_length = lengthOf(metadata);
	metadata_queries = newArray("SizeX", "SizeY", "SizeZ", "SizeC");
	metadata_answer = newArray();
	for (j = 0; j < metadata_queries.length; j++) {
		metadata_location = indexOf(metadata, metadata_queries[j]) + 5; 
		metadata_line_separator_location = indexOf(metadata, "\n", metadata_location);
		if (metadata_line_separator_location < 0) {
			metadata_line_separator_location = metadata_length;
		}
		local_metadata_answer = String.trim(substring(metadata, metadata_location, metadata_line_separator_location));
		metadata_answer = Array.concat(metadata_answer,parseInt(local_metadata_answer));
	}
	
	//these are the image dimensions (useful, because we can now select, which channels and slices to use, without opening the image itself (saves time/processing power) 
	xpixelnumber = Array.concat(xpixelnumber, metadata_answer[0]);
	ypixelnumber = Array.concat(ypixelnumber, metadata_answer[1]);
	if (!is_czi[i]) {
		slicenumber = Array.concat(slicenumber, metadata_answer[2]);
	}
	if (is_czi[i]) { //because .czi files have different metadata layout than .tif
		selectWindow("Original Metadata - " + image_name[i]);
		
		for (j = 0; indexOf(metadata, "Series " + j + " Name") > 0; j++) {
			
		} //count how many entries with "Series 0 Name" there are, where 0 counts up until it doesn't find this expression any more
		
		
		if (indexOf(metadata, "label image") > 0) {//removing additional images in the czi file
			j = j-1;
		}
		
		if (indexOf(metadata, "macro image") > 0) {
			j = j-1;//this only works, if the macro image aand the label image are the last in the series
		}
		
		slicenumber = Array.concat(slicenumber, j); //divide by six does not always work
	}
	channelnumber = Array.concat(channelnumber, metadata_answer[3]);

	close(table_name);
}
setBatchMode(false);

Dialog.create("Slice selection");
Dialog.addMessage("Which slices would you like to use for each image?");
for (i = 0; i < image_path.length; i++) {
	checkboxitems = Array.deleteValue(Array.getSequence(slicenumber[i] + 1), 0); //making an array of numbers 1-slicenumber
	Dialog.addChoice(image_name_without_extension[i], checkboxitems);
}
Dialog.addCheckbox("Use one roi set for all", true);
Dialog.addCheckbox("Images have consistent channel order", true);
Dialog.addCheckbox("Automatically create bounding box", false);

Dialog.show();

selected_slices = newArray();
for (i = 0; i < image_path.length; i++) {
	selected_slices = Array.concat(selected_slices, parseInt(Dialog.getChoice()));
}
one_roi_for_all = Dialog.getCheckbox();
one_channel_for_all = Dialog.getCheckbox();
automatic_bounding_box = Dialog.getCheckbox();

if(one_channel_for_all == false) {
	exit("Differing channels have not been implemented yet. Please analyze these images seperately."); //fix this at some point
}

Table.open(home_directory + "brain_region_mapping.csv");
open(home_directory + "/atlas_overview.tif");
if(one_roi_for_all) {
	//get roi set from user
	Dialog.createNonBlocking("Template selection");
	Dialog.addMessage("What slice of the Allen Brain do you want to map to?");
	Dialog.addNumber("Slice", 1, 0, 3, "");
	Dialog.addMessage("Which brain regions do you want to map? Please add the region acronyms separated by a comma, like this: \"HY, BLA, CA1\".");
	Dialog.addString("Brain regions:", "", 35);
	Dialog.show();
	
	template_slice_number = Array.concat(newArray(),Dialog.getNumber());
	regions = split(Dialog.getString(), ",");

} else {
	//get roi set from user
	
	Dialog.createNonBlocking("Template selection");
	Dialog.addMessage("Which image do you want to map to which slice of the Allen Brain?");
	for (i = 0; i < image_name_without_extension.length; i++) {
		Dialog.addNumber(image_name_without_extension[i], 1, 0, 3, "");
	}
	Dialog.addMessage("Which brain regions do you want to map? Please add the region acronyms separated by a comma, like this: \"HY, BLA, CA1\".");
	Dialog.addMessage("Please refer to the opened table for correct acronyms. They need to first be created with the atlas_to_roi.ijm script.");
	Dialog.addString("Brain regions:", "", 35);
	Dialog.show();
	template_slice_number = newArray();
	for (i = 0; i < image_name_without_extension.length; i++) {
		template_slice_number = Array.concat(template_slice_number, Dialog.getNumber());
	}
	regions = split(Dialog.getString(), ",");
	
}
close("atlas_overview.tif");
close("brain_region_mapping.csv");

for (i = 0; i < template_slice_number.length; i++) {
	template_slice_number[i] = parseInt(template_slice_number[i]); //because otherwise they get a decimal point, which messes up the folder system
}

for (i = 0; i < regions.length; i++) {
	regions[i] = trim(regions[i]); //deal with whitespace in the brain region submission
}

//if there are channels, select which belongs to the respective fluorophor and only open those channels
//make the user create custom channels
defaultchannels = "DAPI, Iba1, GFAP, mOC87, Temp";

Dialog.create("Channel types");
Dialog.addMessage("These are the default channels, please add a channel, separated by a comma, if you use a custom one");
Dialog.addString("Default channels:", defaultchannels, 50);
Dialog.show();
channeloptions_return = Dialog.getString();

//channeloptions_array is the array of all possible channels, but without the "do not use"
channeloptions_array = split(channeloptions_return, ", ");
//channeloptions is the finished possible options for the cannel menue
channeloptions = Array.concat(channeloptions_array, "do not use");

//now select labels for the individual channels 
Dialog.create("Channels");
Dialog.addMessage("Your image has " + channelnumber[0] + " channels. Please select, which ones to use");

for (i = 1; i <= channelnumber[0]; i++) {
	Dialog.addChoice("Channel " + i, channeloptions, "do not use");
}

Dialog.addChoice("Which is the control channel?", channeloptions_array, channeloptions_array[0]);
Dialog.addCheckbox("Also map ROIs to control channel?", false);
Dialog.show();

//get the selected labels and make them into an array (this is an array of the length of channels, with the channel-label in each entry)
channelchoices = newArray();
for (i = 1; i <= channelnumber[0]; i++) {
	channelchoices = Array.concat(channelchoices,Dialog.getChoice());
}

control_channel = Dialog.getChoice();
map_to_control_channel = Dialog.getCheckbox();

//go through this array
for (i = 1; i <= channelchoices.length; i++) {
	if (channelchoices[i-1] == control_channel) {
		control_channel_id = i;
	}
}

File.makeDirectory(output_path);

//then run the roi adjusting function for each image
for (current_image = 0; current_image < image_path.length; current_image++) {

	if (one_roi_for_all) {
		atlas_slice = template_slice_number[0];
	} else {
		atlas_slice = template_slice_number[current_image];
	}
	scaling(current_image, image_path[current_image], image_name_without_extension[current_image], control_channel_id, selected_slices[current_image], atlas_slice, regions, home_directory);
}

//then save the rois on tifs
for (current_image = 0; current_image < image_path.length; current_image++) {
	if (one_roi_for_all) {
		atlas_slice = template_slice_number[0];
	} else {
		atlas_slice = template_slice_number[current_image];
	}
	saving(current_image, image_path[current_image], image_name_without_extension[current_image], channelchoices, channeloptions_array, selected_slices[current_image], home_directory, atlas_slice, regions);
}

close("ROI Manager");

Dialog.create("Command finished");
Dialog.addMessage("Your ROIMAPing has been completed. You can find your results in: " + output_path);
Dialog.show();


//all the previous stuff is done on the first image; now open each image individually




function scaling(imagenumber, local_image_path, local_image_name_without_extension, control_channel_id, selectedslice, atlas_slice, regions, home_directory) { 
	roi_path = newArray();
	for (i = 0; i < regions.length; i++) {
		if(File.exists(home_directory + "ABA_v3/" + atlas_slice + "/" + regions[i] + ".zip")) {
			roi_path = Array.concat(roi_path, home_directory + "ABA_v3/" + atlas_slice + "/" + regions[i] + ".zip");
		}
	} //get the paths of individual ROIs 
	
	if (roi_path.length > 0) { //only do this, if there are saved ROIs for this slice of the ABA
		if (!is_czi[imagenumber]) {
			run("Bio-Formats Importer", "open=" + local_image_path + " color_mode=Default specify_range view=Hyperstack stack_order=XYCZT c_begin=" + control_channel_id + " c_end=" + control_channel_id + " c_step=1 z_begin=" + selectedslice + " z_end=" + selectedslice + " z_step=1");
		} else {
			selectedslice = selectedslice;
			run("Bio-Formats Importer", "open=" + local_image_path + " color_mode=Default specify_range view=Hyperstack stack_order=XYCZT series_" + selectedslice + " c_begin_" + selectedslice + "=" + control_channel_id + " c_end_" + selectedslice + "=" + control_channel_id + " c_step_" + selectedslice + "=1");
		}
		rename(control_channel);
		getDimensions(width, height, channels, slices, frames);
		
		selectWindow(control_channel);
		
		rotation_flip = rotate(home_directory, atlas_slice);
		
		rotate_array = Array.concat(rotate_array, rotation_flip[0]);
		flip_array = Array.concat(flip_array, rotation_flip[1]);
		
		
		if (rotation_flip[1]) {
			run("Flip Vertically");
		}
		
		run("Rotate... ", "angle=" + rotation_flip[0] + " interpolation=Bilinear enlarge");
		/*
		
		
		/*
		//get feret diameters for rotation????
		Roi.getFeretPoints(x,y);
		
		bigferetangle = atan2(y[1] - y[0], x[1] - x[0]) * 180 / PI;
		smallferetangle = atan2(y[2] - y[3], x[2] - x[3]) * 180 / PI;
		
		makeSelection(5, newArray(x[0], x[1]), newArray(y[0], y[1]));
		roiManager("add");
		roiManager("select",roi_id_brain + 1);
		roiManager("rename", "bigferet");
		makeSelection(5, newArray(x[3], x[2]), newArray(y[3], y[2]));
		roiManager("add");
		roiManager("select",roi_id_brain + 2);
		roiManager("rename", "smallferet");
		*/
		
		//select the original background image again, for the user
		
		if (!automatic_bounding_box) {
			selectWindow(control_channel);
			run("Enhance Contrast", "saturated=0.35"); //better visibility
			
			bounding_box_text = "Please create a bounding box around the tissue and click \"OK\" once you are satisfied with the selection.";
			before_bounding_box = roiManager("count");
			waiting_for_bounding_box = true;
			while (waiting_for_bounding_box) {//so there is no chance to procede without providing a bounding box
				setTool(0);
				waitForUser(bounding_box_text);
				
				if (selectionType() == 0) {
					roiManager("add");
					waiting_for_bounding_box = false;
				} else {
					bounding_box_text = "No rectangular selection provided, please try again.";
				}
			}
		} else { //automatically create a bounding box by thersholding
			
			run("Duplicate...", " ");
			working_background_copy_name = getTitle();
			run("8-bit");
			
			setAutoThreshold("Default dark");
			run("Convert to Mask");
			
			
			//get the roi of the tissue detection
			roi_id_brain = roiManager("count");
			setThreshold(1, 255);
			run("Create Selection");
			roiManager("add");
			
			//do not need working copy anymore, because Rois are added to manager
			close(working_background_copy_name);
			
			selectWindow(control_channel);
			run("Enhance Contrast", "saturated=0.35"); //better visibility
			
			roiManager("select",roi_id_brain);
			roiManager("rename", "tissue");
			//make the bounding box around the tissue and assure correctness
			roiManager("select", roi_id_brain);
			run("To Bounding Box");
			roiManager("add");
			roiManager("select", roi_id_brain);
			roiManager("delete");
		}
		
		roi_id_bounding_box = roiManager("count") - 1;
		roiManager("select", roi_id_bounding_box);
		roiManager("rename", "bounding_box");
		
		
		//open the atlas and save the indices of the first and the last entry
		atlas_start_id = roiManager("count");
		for (i = 0; i < roi_path.length; i++) {
			roiManager("open", roi_path[i]); //open all the rois in the specified folder
			if (i < roi_path.length - 1) {//for all but the last roi
				roiManager("select", roiManager("count") - 1); //delete bounding box (which is the last entry in every individual roi set
				roiManager("delete");
			}
		}
		
		atlas_end_id = roiManager("count") - 1;
		
		//go through the atlas, whichever entry is a rectangle is the bounding box (could add a "biggest rectangle" test to avoid mixups in case of multiple rois of type 0)
		brain_region_roi_ids = newArray();
		for (i = atlas_start_id; i <= atlas_end_id; i++) {
			roiManager("select", i);
			roitype = Roi.getType;
			
			if (roitype == "rectangle") {
				atlas_bounding_box_id = i;
			} else {
				brain_region_roi_ids = Array.concat(brain_region_roi_ids, i);
			}
		}
		
		full_atlas_ids = Array.concat(brain_region_roi_ids, atlas_bounding_box_id);
		
		
		
		//get coordinates of unscaled atlas 
		roiManager("select", atlas_bounding_box_id);
		getSelectionBounds(xtemplate, ytemplate, widthtemplate, heighttemplate);
		//get coords of bounding box around tissue
		roiManager("select", roi_id_bounding_box);
		getSelectionBounds(xsample, ysample, widthsample, heightsample);
		
		//calculate scaling factor
		xscale = widthsample / widthtemplate;
		yscale = heightsample / heighttemplate;
		
		
		//select all of the atlas
		roiManager("select", full_atlas_ids);
		
		//the actual scaling
		RoiManager.scale(xscale, yscale, false);
		
		
		//now do the same thing with translation (measure the coordinates again, because I do not want to bother with maths (maybe they do not even change, when scaling non-centered)
		roiManager("select", atlas_bounding_box_id);
		getSelectionBounds(xtemplate, ytemplate, widthtemplate, heighttemplate);
		roiManager("select", roi_id_bounding_box);
		getSelectionBounds(xsample, ysample, widthsample, heightsample);
		
		xtrans = xsample - xtemplate;
		ytrans = ysample - ytemplate;
		
		
		roiManager("select", full_atlas_ids);
		roiManager("translate", xtrans, ytrans);
		
		//put the new rois on top of the actual background image, check if this is okay
		brain_region_roi_ids = to_downsampled_selection(brain_region_roi_ids);
		
		//save the rois to the temp directory, named after the images
		roiManager("select", brain_region_roi_ids);
		roiManager("save selected", temp + local_image_name_without_extension + "roi.zip"); //change the [0] to image_number later
		//delete these rois
		//roiManager("select", Array.concat(brain_region_roi_ids, atlas_bounding_box_id, roi_id_bounding_box, roi_id_brain));
		//roiManager("delete");
		roiManager("reset"); //not as elegant, but just selecting 
		close(control_channel);

	} else {
		print("Not found any of the specified regions in image " + local_image_name_without_extension);
		rotate_array = Array.concat(rotate_array, 0);
		flip_array = Array.concat(flip_array, 0); //still lengthen the rotation arrays, even if there were no ROIs for this image, because the saving process breaks otherwise
	}
	
	
}

function rotate(home_directory, atlas_slice) {
	name = getTitle();
	getDimensions(width, height, channels, slices, frames);
	run("Scale...", "x=0.1 y=0.1 width=" + width/10 + " height=" + height/10 + " interpolation=Bilinear create");
	run("Enhance Contrast", "saturated=0.35"); //better visibility
	rename("rotation");
	rotating = true;
	flipping = true;
	final_rotation = 0;
	final_flip = false;
	open(home_directory + "ABA_v3/slice" + IJ.pad(atlas_slice, 3) + ".png");
	
	while(flipping) {
		selectWindow("rotation");
		Dialog.createNonBlocking("Flipping");
		Dialog.addMessage("Does your image need to be flipped?");
		Dialog.addMessage("The reference image has been opened, please compare.");
		Dialog.addMessage("Once your are satisfied with the state of your image, uncheck the \"Continue flipping?\" checkmark");
		
		
		Dialog.addCheckbox("Flip vertically?", false);
		Dialog.addCheckbox("Continue flipping?", true);
		Dialog.show();
		
		flip = Dialog.getCheckbox();
		flipping = Dialog.getCheckbox();
		if (flipping) {
			if (flip == true) {
				selectWindow("rotation");
				run("Flip Vertically");
				final_flip = !final_flip;
			}
		}
	}

	
	while(rotating) {
		selectWindow("rotation");
		Dialog.createNonBlocking("Rotation");
		Dialog.addMessage("Please adjust the rotation of your image to match the template.");
		Dialog.addSlider("Rotation", -179.9, 179.9, 0);
		Dialog.addCheckbox("Continue rotation?", true);
		Dialog.show();
		
		rotation = Dialog.getNumber();
		rotating = Dialog.getCheckbox();
		if (rotating) {
			if (rotation != 0) {
				final_rotation = final_rotation + rotation;
				selectWindow("rotation");
				run("Rotate... ", "angle=" + rotation + " interpolation=Bilinear enlarge");
			}
			
		}
	} 
	close("rotation");
	
	close("slice" + IJ.pad(atlas_slice, 3) + ".png");
	
	selectWindow(name);
	return newArray(final_rotation, final_flip);
}

//prompts user, if they want to manually adjust any ROI. If yes:
//turns an roi into a set of points, reduces the amount of points and makes it an editable polygon selection
//then updates the array that stores the brain region ROIs
function to_downsampled_selection(roi_ids) {
	roiManager("select", roi_ids);
	roiManager("show all without labels");
	
	Dialog.createNonBlocking("Brain region selection");
	Dialog.addMessage("Is the brain region selection okay? If yes, click \"OK\"");
	Dialog.addMessage("Otherwise please select an roi to adjust, uncheck the following box, and enter a downsampling factor for the amount of points in the ROI");
	Dialog.addCheckbox("Change an ROI", false);
	Dialog.addToSameRow();
	Dialog.addNumber("Downsampling", 10, 0, 2, "");
	Dialog.show();
	
	do_downsampling = Dialog.getCheckbox();
	downsample_factor = Dialog.getNumber();
	
	
	if (do_downsampling) {
	
		changing_roi = roiManager("index");
		if (changing_roi >= 0) { //test, if an roi was selected
			
			old_name = Roi.getName;//transfer this to the new, downsampled ROI
			getSelectionCoordinates(xpoints, ypoints);
			
			new_xpoints = newArray();
			new_ypoints = newArray();
			
			for (i = 0; i < maxOf(Math.floor(xpoints.length / downsample_factor), 1); i++) {//only adding downsample_factor few points to the new selection (this is the downsampling
				new_xpoints = Array.concat(new_xpoints,xpoints[i*downsample_factor]);
				new_ypoints = Array.concat(new_ypoints,ypoints[i*downsample_factor]);
			}
			makeSelection("polygon", new_xpoints, new_ypoints);
			
			roiManager("add");//this is the new version of the roi
			
			roi_ids = Array.delete(roi_ids, changing_roi);//so we have to delete the former one from the archive of ROIs that will be saved in the end
			roiManager("select", changing_roi);
			roiManager("delete");
			for (i = 0; i < roi_ids.length; i++) {//after deletion, the index of all higher ROIs will change, so have to adjust all higher ones
				if (roi_ids[i] > changing_roi) {
					roi_ids[i] = roi_ids[i]-1;
				}
			}
			
			roiManager("select", roiManager("count")-1);//select the newly added roi
			roiManager("rename", old_name);
			new_roi_index = roiManager("index");
			
			roi_ids = Array.concat(roi_ids, new_roi_index);//and update the brain_region selection that will be saved to reflect this change
			
			waitForUser("Please adjust the ROI you have selected.");
			roiManager("update");
			
			roi_ids = to_downsampled_selection(roi_ids);
			
			
		} else {
			waitForUser("No ROI selected. Please do so. Press OK to try again");
			to_downsampled_selection(roi_ids);
		}
	}
	return roi_ids;
}


//saving the results
//make this a seperate function that runs on all images after all the adjustment is done
function saving(imagenumber, local_image_path, local_image_name_without_extension, channelchoices, channeloptions_array, selectedslice, home_directory, atlas_slice, regions) {
	//open the saved scaled rois of the respective image
	setBatchMode(true);
	save_roi_ids_start = roiManager("count");
	roi_path = newArray();
	for (i = 0; i < regions.length; i++) {
		if(File.exists(home_directory + "ABA_v3/" + atlas_slice + "/" + regions[i] + ".zip")) {
			roi_path = Array.concat(roi_path, home_directory + "ABA_v3/" + atlas_slice + "/" + regions[i] + ".zip");
		}
	}
	
	if (roi_path.length > 0) {
		roiManager("open", temp + local_image_name_without_extension + "roi.zip");
		save_roi_ids_end = roiManager("count") -1;
		
		//get the array of selected channels to go through
		only_channelchoices = Array.deleteValue(channelchoices, "do not use");
		for (i = 1; i <= channelchoices.length; i++) {
			//open the channels specified for analysis (so everything in channeloptions, which does not include "do not use", other than the background image)
			for (j = 0; j < channeloptions_array.length; j++) {
				if (channelchoices[i-1] == channeloptions_array[j]) {
					if ((channelchoices[i-1] != control_channel && !map_to_control_channel) || only_channelchoices.length <= 1 || map_to_control_channel) {
						
						if (!is_czi[imagenumber]) {
							run("Bio-Formats Importer", "open=" + local_image_path + " color_mode=Default specify_range view=Hyperstack stack_order=XYCZT c_begin=" + i + " c_end=" + i + " c_step=1 z_begin=" + selectedslice + " z_end=" + selectedslice + " z_step=1");
						} else {
							
							run("Bio-Formats Importer", "open=" + local_image_path + " color_mode=Default specify_range view=Hyperstack stack_order=XYCZT series_" + selectedslice + " c_begin_" + selectedslice + "=" + i + " c_end_" + selectedslice + "=" + i + " c_step_" + selectedslice + "=1");
						}
						
						rename(channeloptions_array[j]);
						
						if (flip_array[imagenumber]) {
							run("Flip Vertically");
						}

						run("Rotate... ", "angle=" + rotate_array[imagenumber] + " interpolation=Bilinear enlarge");
		
						/*
						//and save the rois on the individual channels
						roiManager("show all without labels");
						
						save(output_path + image_name_without_extension + "_" + channeloptions[j] + ".tif");
						close(channeloptions[j]);
						*/
						//go through all the individual rois of the atlas that are not the bounding box and save them as individual images on each of the selected channels
						for (k = save_roi_ids_start; k <= save_roi_ids_end; k++) {
							roiManager("select", k);
							save(output_path + local_image_name_without_extension + "_" + channeloptions[j] + "_" + getInfo("selection.name") + ".tif");
						}
						close(channeloptions_array[j]);
					}
				}
			}
		}
		roi_closing_array = newArray();
		
		for (i = save_roi_ids_start; i <= save_roi_ids_end; i++) {
			roi_closing_array = Array.concat(roi_closing_array, i);
		}
		roiManager("select", roi_closing_array);
		roiManager("delete");
	}
	setBatchMode(false);
}