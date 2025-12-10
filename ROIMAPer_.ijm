//Inspired by the FASTMAP plugin by Dylan Terstege from the Epp Lab, University of Calgary published on 12-07-2019
//
// Created 2025-09-15 by Julian Rodefeld
// Ciernia Lab, University of British Columbia, Vancouver

var map_to_control_channel = false;
var is_czi = newArray();
var one_roi_for_all = false;
var automatic_bounding_box = false;
var output_path = "";
var combined_output_path = "";
var control_channel = "";
var temp = "";
var atlas_directory = "";
var text_file = "";
var mapping_index_path = "";
var atlas_name = "";
var atlas_path = "";

showMessage("ROIMAPer", "<html>
    +"<h1><font color=black>ROIMAPer </h1>" 
    +"<p1>Version: 1.0 (Sep 2025)</p1>"
    +"<H2><font size=3>Created by Julian Rodefeld, Ciernia Lab, University of British Columbia</H2>" 
    +"<H2><font size=2>Inspired by the FASTMAP plugin by Dylan Terstege from the Epp Lab</H2>" 
    +"<h3>   <h3>"    
    +"<h1><font size=2> </h1>"  
	   +"<h0><font size=5> </h0>"
    +"");

//directory setup
default_directory = File.getDefaultDir;//to restore in the end
temp = getDirectory("temp");
home_directory = replace(getDirectory("imagej"), "\\" "/") + "scripts/Plugins/ROIMAPer/atlases/";
File.setDefaultDir(home_directory);

//get atlas specification
atlas_path = replace(File.openDialog("Please select which atlas you would like to work with (select a .tif file)."), "\\", "/"); //replace backslash with forwardslash
atlas_name = File.getNameWithoutExtension(atlas_path);
atlas_directory = home_directory + atlas_name + "_ROIs/";

//the atlas id to brain region information
text_file = substring(atlas_name, 0, indexOf(atlas_name, "-")) + "-brain_region_mapping.csv";
mapping_index_path = home_directory + "mapping_index.csv";
File.setDefaultDir(default_directory);
//restore default directory

//creates structure for the ROIs to be saved in, if it is run for the first time on this atlas
if (!File.exists(atlas_directory)) {
	File.makeDirectory(atlas_directory);
	for (i = 1; i <= slices; i++) {
		File.makeDirectory(atlas_directory + i + "/");
	}
}

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
month = month + 1;//because month is zero-based index

//get the directory
 of the analysis
image_directory = getDirectory("Please choose the directory that contains your images.");
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

for (i = 0; i < image_selection_size; i++) {//creating a grid-like dialog window of the files provided. Grid likeness enables the display of more file titles
	Dialog.addCheckbox(image_list[i + image_selection_start], true);
	for (j = 1; j < columns; j++) {
		if (i + 1 < image_selection_size) {
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

for (i = 0; i < image_selection_size; i++) {
	if (file_chosen[i]) {
	    image_path = Array.concat(image_path, replace(image_directory + image_list[i + image_selection_start], "\\", "/"));
	    image_name = Array.concat(image_name, File.getName(image_directory + image_list[i + image_selection_start]));
	    image_name_without_extension = Array.concat(image_name_without_extension, File.getNameWithoutExtension(image_directory + image_list[i + image_selection_start]));
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

	run("Bio-Formats Importer", "open=[" + image_path[i] + "] color_mode=Default display_metadata rois_import=[ROI manager] view=[Metadata only] stack_order=Default");
	
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
//using the line separator as a delimiter after the value atributed to the query
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
		//is not perfect yet
		selectWindow("Original Metadata - " + image_name[i]);
		
		for (j = 0; indexOf(metadata, "Series " + j + " Name") > 0; j++) {
			
		} //count how many entries with "Series 0 Name" there are, where 0 counts up until it doesn't find this expression any more
		
		
		if (indexOf(metadata, "label image") > 0) {//removing additional images in the czi file
			j = j-1;
		}
		
		if (indexOf(metadata, "macro image") > 0) {
			j = j-1;//this only works, if the macro image and the label image are the last in the series
		}
		
		slicenumber = Array.concat(slicenumber, j); //divide by six does not always work
	}
	channelnumber = Array.concat(channelnumber, metadata_answer[3]);

	close(table_name);
}
setBatchMode(false);

length_limit = 20;
columns = Math.ceil(image_path.length/length_limit);
Dialog.create("Slice selection");
Dialog.addCheckbox("Use one roi set for all", false);
//Dialog.addCheckbox("Images have consistent channel order", true);
Dialog.addCheckbox("Automatically create bounding box", false);
Dialog.addCheckbox("Save between images?", false);
Dialog.addCheckbox("Create additional combined result?", false);

Dialog.addMessage("Which slices would you like to use for each image?");
for (i = 0; i < image_path.length; i++) {//Grid likeness enables the display of more file titles
	checkboxitems = Array.deleteValue(Array.getSequence(slicenumber[i] + 1), 0);
	 //making an array of the numbers from 1 to slicenumber
	Dialog.addChoice(image_name_without_extension[i], checkboxitems);

	for (j = 1; j < columns; j++) {
		if (i + 1 < image_path.length) {
			Dialog.addToSameRow();
			i++;
			checkboxitems = Array.deleteValue(Array.getSequence(slicenumber[i] + 1), 0);
			 //making an array of the numbers from 1 to slicenumber
			Dialog.addChoice(image_name_without_extension[i], checkboxitems);
		}
	}

}

Dialog.show();


one_roi_for_all = Dialog.getCheckbox();
//one_channel_for_all = Dialog.getCheckbox();
automatic_bounding_box = Dialog.getCheckbox();
autosave = Dialog.getCheckbox();
combined_results = Dialog.getCheckbox();

/*
if(one_channel_for_all == false) {
	exit("Differing channels have not been implemented yet. Please analyze these images seperately.");
 //fix this at some point
}
*/
selected_slices = newArray();
for (i = 0; i < image_path.length; i++) {
	selected_slices = Array.concat(selected_slices, parseInt(Dialog.getChoice()));
 //choice puts out decimal figures as characters
}

Table.open(home_directory + text_file);

defaultchannels = "DAPI, Iba1, GFAP, mOC87, Temp";

if(one_roi_for_all) {
	//get roi set from user
	screen_height = screenHeight;
	screen_width = screenWidth;
	call("ij.gui.ImageWindow.setNextLocation", round(screen_height*0.4), round(screen_height*0.01));
	
	open(home_directory + atlas_name + "_overview.tif");
	Dialog.createNonBlocking("Template selection");
	Dialog.addMessage("What slice of the Allen Brain do you want to map to?");
	Dialog.addNumber("Slice", 1, 0, 3, "");
	Dialog.addMessage("Which brain regions do you want to map? Please add the region acronyms separated by a comma, like this: \"HY, BLA, CA1\".");
	Dialog.addString("Brain regions:", "", 35);
	Dialog.addMessage("These are the default channels, please add a channel, separated by a comma, if you use a custom one");
	Dialog.addString("Default channels:", defaultchannels, 50);
	
	Dialog.show();
	
	template_slice_number = Array.concat(newArray(),Dialog.getNumber());
	regions = split(Dialog.getString(), ",");
	channeloptions_return = Dialog.getString();
	
	for (i = 0; i < template_slice_number.length; i++) {
		template_slice_number[i] = parseInt(template_slice_number[i]); //because otherwise they get a decimal point, which messes up the folder system
	}
	close(atlas_name + "_overview.tif");
	

} else {
	//get roi set from user
	
	Dialog.createNonBlocking("Template selection");
	Dialog.addMessage("Which brain regions do you want to map? Please add the region acronyms separated by a comma, like this: \"HY, BLA, CA1\".");
	Dialog.addMessage("Please refer to the opened table for correct acronyms. They need to first be created with the atlas_to_roi.ijm script.");
	Dialog.addString("Brain regions:", "", 35);
	Dialog.addMessage("These are the default channels, please add a channel, separated by a comma, if you use a custom one");
	Dialog.addString("Default channels:", defaultchannels, 50);
	
	Dialog.show();
	regions = split(Dialog.getString(), ",");
	channeloptions_return = Dialog.getString();
	
}
close(text_file);

for (i = 0; i < regions.length; i++) {
	regions[i] = trim(regions[i]); //deal with whitespace in the brain region submission
}
//run through the ROIs requested, create those that have not been created yet
createROIs(atlas_name, mapping_index_path, regions);

//if there are channels, select which belongs to the respective fluorophor and only open those channels
//make the user create custom channels


//channeloptions_array is the array of all possible channels, but without the "do not use"
channeloptions_array = split(channeloptions_return, ", ");
//channeloptions is the finished possible options for the cannel menue
channeloptions = Array.concat(channeloptions_array, "do not use");

//now select labels for the individual channels 
Dialog.create("Channels");
Dialog.addMessage("Your image has " + channelnumber[0] + " channels. Please select, which ones to use.");
Dialog.addMessage("All images have to have the same channel order.");


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
if (combined_results) {
	combined_output_path = higher_directory + "/ROIMAPer_results_" + year + "_" + month + "_" + dayOfMonth + "_" + hour + "_" + minute + "_combined/";

	File.makeDirectory(combined_output_path);
}

//then run the roi adjusting function for each image
for (current_image = 0; current_image < image_path.length; current_image++) {

	if (one_roi_for_all) {
		atlas_slice = template_slice_number[0];
	} else {
		atlas_slice = 1; //gets changed in the image_processing function
	}
	image_processing(current_image, image_path[current_image], image_name_without_extension[current_image], control_channel_id, selected_slices[current_image], atlas_slice, regions, home_directory);

	if (autosave) {//if we want to save after every image
		saving(current_image, image_path[current_image], image_name_without_extension[current_image], channelchoices, channeloptions_array, selected_slices[current_image], home_directory);
	}
}

//then save the rois on tifs
if (!autosave) {
	for (current_image = 0; current_image < image_path.length; current_image++) {
		saving(current_image, image_path[current_image], image_name_without_extension[current_image], channelchoices, channeloptions_array, selected_slices[current_image], home_directory);
	}
}

close("ROI Manager");

Dialog.create("Command finished");
Dialog.addMessage("Your ROIMAPing has been completed. You can find your results in: " + output_path);
Dialog.show();


//all the previous stuff is done on the first image; now open each image individually



function image_processing(image_number, local_image_path, local_image_name_without_extension, control_channel_id, selectedslice, atlas_slice, regions, home_directory) { 
	
	proceed = false;
	if (one_roi_for_all) {
		roi_path = check_roi_availability(atlas_slice, regions, local_image_name_without_extension);
		if (roi_path.length > 0) {
			proceed = true;
		}
	} else {
		proceed = true;
	}
	
	if (proceed) { //only do this, if there are saved ROIs for this slice of the ABA
		if (!is_czi[image_number]) {
			run("Bio-Formats Importer", "open=[" + local_image_path + "] color_mode=Default specify_range view=Hyperstack stack_order=XYCZT c_begin=" + control_channel_id + " c_end=" + control_channel_id + " c_step=1 z_begin=" + selectedslice + " z_end=" + selectedslice + " z_step=1");
		} else {
			selectedslice = selectedslice;
			run("Bio-Formats Importer", "open=[" + local_image_path + "] color_mode=Default specify_range view=Hyperstack stack_order=XYCZT series_" + selectedslice + " c_begin_" + selectedslice + "=" + control_channel_id + " c_end_" + selectedslice + "=" + control_channel_id + " c_step_" + selectedslice + "=1");
		}
		rename(control_channel);
		getDimensions(width, height, channels, slices, frames);
		
		selectWindow(control_channel);
		
		/*
		//get feret diameters for rotation???? - this would be an autofitting process
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
		selectWindow(control_channel);
		run("Enhance Contrast", "saturated=0.35"); //better visibility
		
		if (automatic_bounding_box) {
			
			setAutoThreshold();
			run("Create Selection");
			run("Fit Rectangle");
			
			resetThreshold;
			
			Dialog.createNonBlocking("Automatic selection");
			Dialog.addMessage("Please adjust the created bounding rectangle if necessary.");
			if (!one_roi_for_all) {
				screen_height = screenHeight;
				screen_width = screenWidth;
				call("ij.gui.ImageWindow.setNextLocation", round(screen_height*0.7), round(screen_height*0.2));

				open(home_directory + atlas_name + "_overview.tif");
				selectWindow(control_channel);
				
				Dialog.addMessage("Which slice of the atlas does this brain slice correspond to?");
				Dialog.addNumber("Slice", 1, 0, 3, "");
			}
			Dialog.show();
			
			if (!one_roi_for_all) {
				close(atlas_name + "_overview.tif");
				atlas_slice = Dialog.getNumber();
				atlas_slice = parseInt(atlas_slice);//removing decimal points
			}
			
			getSelectionCoordinates(xbounding, ybounding);
			
		} else {//if not automatic bounding box
			
			atlas_slice = user_bounding_box(atlas_slice);
			
			getSelectionCoordinates(xbounding, ybounding);
			run("Select None");
		}
		
		//because rotated rectangles start in a different corner than normal rectangles
		xbounding = Array.rotate(xbounding, 1);
		ybounding = Array.rotate(ybounding, 1);
		
		//angle of the bounding box
		angle = atan((ybounding[1]-ybounding[0])/(xbounding[1]-xbounding[0]))*180/PI;
		//roll-over of the angle
		if (xbounding[1]-xbounding[0] < 0) {
			angle = angle + 180;
		} else {
			if (ybounding[1]-ybounding[0] < 0) {
				angle = angle + 360;
			}
		}
		widthbounding = sqrt(Math.pow(xbounding[1]-xbounding[0], 2) + Math.pow(ybounding[1]-ybounding[0], 2)); //pythagoras
		heightbounding = sqrt(Math.pow(xbounding[2]-xbounding[1], 2) + Math.pow(ybounding[2]-ybounding[1], 2));
		
		//have to check for availability of ROIs separately because these are per-image and not for the whole analysis
		if (!one_roi_for_all) {
			roi_path = check_roi_availability(atlas_slice, regions, local_image_name_without_extension);
		}
		
		atlas_combined_ids = open_rois(roi_path);
		atlas_start_id = atlas_combined_ids[0];
		atlas_end_id = atlas_combined_ids[1];
		
		
		if (atlas_start_id >= atlas_end_id) {//if no ROIs were opened
			print("Not found any of the specified regions in image " + local_image_name_without_extension);
			give_user_choice = false;
		} else {//only proceed, if ROIs were opened - could put this in a loop with a retry
			
			//go through the atlas, whichever entry is a rectangle is the bounding box 
			brain_region_roi_ids = newArray();
			for (i = atlas_start_id; i <= atlas_end_id; i++) {
				roiManager("select", i);
				roitype = Roi.getType;
				
				if (Roi.getName == "atlas_bounding_box") {
					atlas_bounding_box_id = i;
				} else {
					brain_region_roi_ids = Array.concat(brain_region_roi_ids, i);
				}
			}
			
			full_atlas_ids = Array.concat(brain_region_roi_ids, atlas_bounding_box_id);
			
			//this moves the ROIs in the right scaling and orientation inside the bounding box
			scaling(atlas_bounding_box_id, full_atlas_ids, angle, widthbounding, heightbounding, xbounding, ybounding);
			
			give_user_choice = true;
		}
		
		modifying_options = newArray("Do not modify" , "flip x", "flip y", "rotate by 90 degrees", "redo bounding box");
		modifying = true;
		
		while (modifying) {
			if (give_user_choice) {//only allow this if there were no problems in the previous round
				Dialog.createNonBlocking("Are the ROIs oriented correctly?");
				Dialog.addChoice("Modify orientation:", modifying_options, modifying_options[0]);
				Dialog.show();
				modifyer = Dialog.getChoice();
				
			} else {
				 modifyer = "redo bounding box";
				 Dialog.createNonBlocking("Error in ROI search");
				 Dialog.addMessage("Not found any of the specified regions in image " + local_image_name_without_extension + ". Please select a different atlas slice");
				 Dialog.addChoice("Retry mapping of this image with a new atlas slice?", newArray("Yes", "No, skip this image"), "Yes");
				 Dialog.show();
				 
				 error_action = Dialog.getChoice();
				 give_user_choice = true; //so the user can choose again in the next round
		
				 if (error_action == "No, skip this image") {
				 	proceed = false;
				 	break;
				 }
			}
			
			//the normal actions that can be performed on this image
			if (modifyer == "flip x") {
				flip_roi_x(full_atlas_ids, angle, atlas_bounding_box_id);
			}
			if (modifyer == "flip y") {
				flip_roi_y(full_atlas_ids, angle, atlas_bounding_box_id);
			}
			if (modifyer == "Do not modify") {
				modifying = false;
			} 
			if (modifyer == "rotate by 90 degrees") {
				rotate90(widthbounding, heightbounding, full_atlas_ids, angle, atlas_bounding_box_id);
				//modifying_options = Array.deleteValue(modifying_options, "rotate by 90 degrees - can only be performed once");
			}
			if (modifyer == "redo bounding box") {
				roiManager("reset");
				 //in case rotation was already attempted: restore the rotate option
				modifying_options = newArray("Do not modify" , "flip x", "flip y", "rotate by 90 degrees", "redo bounding box");
				
				atlas_slice = user_bounding_box(atlas_slice);
				
				getSelectionCoordinates(xbounding, ybounding);
				run("Select None");
				
				//because rotated rectangles start in a different corner than normal rectangles
				xbounding = Array.rotate(xbounding, 1);
				ybounding = Array.rotate(ybounding, 1);
				
				angle = atan((ybounding[1]-ybounding[0])/(xbounding[1]-xbounding[0]))*180/PI;
				//roll-over of the angle
				if (xbounding[1]-xbounding[0] < 0) {
					angle = angle + 180;
				} else {
					if (ybounding[1]-ybounding[0] < 0) {
						angle = angle + 360;
					}
				}
				widthbounding = sqrt(Math.pow(xbounding[1]-xbounding[0], 2) + Math.pow(ybounding[1]-ybounding[0], 2)); //pythagoras
				heightbounding = sqrt(Math.pow(xbounding[2]-xbounding[1], 2) + Math.pow(ybounding[2]-ybounding[1], 2));
				
				if (!one_roi_for_all) {//get the roi_paths of the possibly new slice
					roi_path = check_roi_availability(atlas_slice, regions, local_image_name_without_extension);
				}
				
				atlas_combined_ids = open_rois(roi_path);
				atlas_start_id = atlas_combined_ids[0];
				atlas_end_id = atlas_combined_ids[1];
				if (atlas_start_id >= atlas_end_id) {//if no ROIs were opened
					give_user_choice = false;
				} else {//allow scaling when there were ROIs opened
					
					//go through the atlas, whichever entry is a rectangle is the bounding box 
					brain_region_roi_ids = newArray();
					for (i = atlas_start_id; i <= atlas_end_id; i++) {
						roiManager("select", i);
						roitype = Roi.getType;
						
						if (Roi.getName == "atlas_bounding_box") {
							atlas_bounding_box_id = i;
						} else {
							brain_region_roi_ids = Array.concat(brain_region_roi_ids, i);
						}
					}
					
					full_atlas_ids = Array.concat(brain_region_roi_ids, atlas_bounding_box_id);
					
					scaling(atlas_bounding_box_id, full_atlas_ids, angle, widthbounding, heightbounding, xbounding, ybounding);
				}
			}
			
			roiManager("show all without labels");
		}
		
		if (proceed) {
			//put the new rois on top of the actual background image, check if this is okay
			
			brain_region_roi_ids = to_downsampled_selection(brain_region_roi_ids);
			
			//save the rois to the temp directory, named after the images
			if (brain_region_roi_ids.length > 0) {
				roiManager("select", brain_region_roi_ids);
				roiManager("save selected", temp + local_image_name_without_extension + "roi.zip"); //change the [0] to image_number later
			
			}
		}
		//delete these rois
		//roiManager("select", full);
		//roiManager("delete");
		roiManager("reset"); //not as elegant, but selection of atlas_bounding box after the downsampling gets tricky
		close(control_channel);
	} else {
		print("Not found any of the specified regions in image " + local_image_name_without_extension);	}
}




function check_roi_availability(atlas_slice, regions, local_image_name_without_extension) {
	roi_path = newArray();
	for (i = 0; i < regions.length; i++) {
		if(File.exists(home_directory + "ABA_v3/" + atlas_slice + "/" + regions[i] + ".zip")) {
			roi_path = Array.concat(roi_path, home_directory + "ABA_v3/" + atlas_slice + "/" + regions[i] + ".zip");
		} else {
			print("Not found the region " + regions[i] + " in image " + local_image_name_without_extension);
		}
	} //get the paths of individual ROIs 
	return roi_path;
}

function user_bounding_box(atlas_slice) {
	//get bounding box from user
	
	bounding_box_text = "Please create a bounding box around the tissue and click \"OK\" once you are satisfied with the selection.";
	before_bounding_box = roiManager("count");
	waiting_for_bounding_box = true;
	while (waiting_for_bounding_box) {//so there is no chance to procede without providing a bounding box
						
		setTool("rotatedrect");
		Dialog.createNonBlocking("Brain selection");
		Dialog.addMessage("Please create a rectangle that sits flush with the brain.");
		screen_height = screenHeight;
		screen_width = screenWidth;
		call("ij.gui.ImageWindow.setNextLocation", round(screen_height*0.7), round(screen_height*0.2));

		open(home_directory + "/atlas_overview.tif");
		selectWindow(control_channel);
		Dialog.addMessage("Which slice of the atlas does this brain slice correspond to?");
		Dialog.addNumber("Slice", atlas_slice, 0, 3, "");
		Dialog.show();
		
		//even when same ROI set for all is specified, allow for change of atlas slice here
		close("atlas_overview.tif");
		atlas_slice = Dialog.getNumber();
		atlas_slice = parseInt(atlas_slice);//removing decimal points
		
		
		if (selectionType() == 3 || selectionType() == 0 || selectionType() == 2) {
			waiting_for_bounding_box = false;
			
			
		} else {
			bounding_box_text = "No rectangular selection provided, please try again.";
		}
		
	}
	return atlas_slice;
}

function open_rois(roi_path) {
	
	//open the atlas and save the indices of the first and the last entry
	atlas_start_id = roiManager("count");
	for (i = 0; i < roi_path.length; i++) {
		roi_number_opening = roiManager("count");
		roiManager("open", roi_path[i]); //open all the rois in the specified folder
		roi_number_after_opening = roiManager("count");
		if (i < roi_path.length - 1) {//for all but the last roi
			if (roi_number_after_opening > roi_number_opening + 1) { //this checks, if the roi.zip was not empty
				for (j = roi_number_opening; j < roi_number_after_opening; j++) {//go through all newly opened ROIs and delete the bounding box (for all but the las ROI
					roiManager("select", j);
					roitype = Roi.getType;
					
					if (Roi.getName == "atlas_bounding_box") {//could add type requirement
						roiManager("delete");
					} 
				}
			}
		}
	}
	
	atlas_end_id = roiManager("count") - 1;
	return newArray(atlas_start_id, atlas_end_id);
}

function scaling(atlas_bounding_box_id, full_atlas_ids, angle, widthbounding, heightbounding, xbounding, ybounding) {

		//get coordinates of unscaled atlas 
		roiManager("select", atlas_bounding_box_id);
		
		getSelectionBounds(xatlas, yatlas, widthatlas, heightatlas);
		
		//calculate scaling factor
		xscale = widthbounding / widthatlas;
		yscale = heightbounding / heightatlas;
		
		
		//select all of the atlas
		roiManager("select", full_atlas_ids);
		
		//the actual scaling
		RoiManager.scale(xscale, yscale, false);
		
		//now do the same thing with translation (measure the coordinates again, because I do not want to bother with maths (maybe they do not even change, when scaling non-centered)
		roiManager("select", atlas_bounding_box_id);
		getSelectionCoordinates(xatlas, yatlas);
		
		xtrans = xbounding[0] - xatlas[0];
		ytrans = ybounding[0] - yatlas[0];
		
		roiManager("select", full_atlas_ids);
		roiManager("translate", xtrans, ytrans);
		
		roiManager("select", full_atlas_ids);
		RoiManager.rotate(angle, xbounding[0], ybounding[0]);
		roiManager("show all without labels");
		
}

function rotate90(widthbounding, heightbounding, full_atlas_ids, angle, atlas_bounding_box_id) {
	roiManager("select", atlas_bounding_box_id);
	getSelectionCoordinates(xatlas, yatlas);
	xcenter = (xatlas[2] - xatlas[0]) / 2 + xatlas[0]; //get center of the bounding box
	ycenter = (yatlas[2] - yatlas[0]) / 2 + yatlas[0];

	roi_indices_new = newArray();
	roi_indices_new = Array.concat(roi_indices_new,full_atlas_ids); //so it is an array if there is only one ID to modify
	roiManager("select", roi_indices_new);
	//normalize rotational axis so scaling is not skewed, rotate around the bounding box center
	RoiManager.rotate(-angle, xcenter, ycenter); 
	roiManager("select", atlas_bounding_box_id);
	getSelectionCoordinates(xatlas_trans, yatlas_trans); //get atlas coordinates after translation
	Array.print(xatlas_trans);
	Array.print(yatlas_trans);
	roiManager("select", roi_indices_new);
	getSelectionBounds(xroiold, yroiold, widthroiold, heightroiold);
	RoiManager.scale(heightbounding/widthbounding, widthbounding/heightbounding, false); //invert length and height scaling of all ROIs
	roiManager("select", roi_indices_new);
	getSelectionBounds(xroinew, yroinew, widthroinew, heightroinew);
	
	RoiManager.translate(xatlas_trans[0] - xroinew, yatlas_trans[0] - yroinew); //move to top right corner to allow for 90 degree turn around that corner
	roiManager("select", full_atlas_ids);
	
	RoiManager.rotate(90, xatlas_trans[0], yatlas_trans[0]); //rotate by 90 degrees
	//now rotate again to restore the original tilt
	RoiManager.rotate(angle, xcenter, ycenter); 
	
	//get distance of new center from old center - move back to old center
	roiManager("select", atlas_bounding_box_id);
	getSelectionCoordinates(xatlas_trans_rot, yatlas_trans_rot);
	xcenter_trans_rot = (xatlas_trans_rot[2] - xatlas_trans_rot[0]) / 2 + xatlas_trans_rot[0]; //get center of the bounding box
	ycenter_trans_rot = (yatlas_trans_rot[2] - yatlas_trans_rot[0]) / 2 + yatlas_trans_rot[0];

	roiManager("select", roi_indices_new);
	RoiManager.translate(xcenter - xcenter_trans_rot, ycenter - ycenter_trans_rot); //move to top right corner to allow for 90 degree turn around that corner
	
	roiManager("show all without labels");
}

function flip_roi_x(roi_indices, angle, atlas_bounding_box_id) {
	roiManager("select", atlas_bounding_box_id);
	getSelectionCoordinates(xatlas, yatlas);
	xcenter = (xatlas[2] - xatlas[0]) / 2 + xatlas[0]; //get center of the bounding box
	ycenter = (yatlas[2] - yatlas[0]) / 2 + yatlas[0];
	
	roi_indices_new = newArray();
	roi_indices_new = Array.concat(roi_indices_new,roi_indices);
	
	roiManager("select", roi_indices_new);
	RoiManager.rotate(-angle, xcenter, ycenter); //bring into neutral orientation
	
	roiManager("select", atlas_bounding_box_id);
	getSelectionBounds(x, y, width, height);
	
	roiManager("select", roi_indices_new);
	RoiManager.scale(-1, 1, false);//this is flipping the selection
	
	roiManager("select", atlas_bounding_box_id);
	getSelectionBounds(x_scale, y_scale, width_scale, height_scale); //get bounds after scale
	roiManager("select", roi_indices_new);
	RoiManager.translate(x - x_scale , y - y_scale); // move to original spot
	
	RoiManager.rotate(angle, xcenter, ycenter); //restore original orientation
	
	roiManager("show all without labels");
}

function flip_roi_y(roi_indices, angle, atlas_bounding_box_id) {
	roiManager("select", atlas_bounding_box_id);
	getSelectionCoordinates(xatlas, yatlas);
	xcenter = (xatlas[2] - xatlas[0]) / 2 + xatlas[0]; //get center of the bounding box
	ycenter = (yatlas[2] - yatlas[0]) / 2 + yatlas[0];
	
	roi_indices_new = newArray();
	roi_indices_new = Array.concat(roi_indices_new,roi_indices);
	
	roiManager("select", roi_indices_new);
	RoiManager.rotate(-angle, xcenter, ycenter); //bring into neutral orientation
	
	roiManager("select", atlas_bounding_box_id);
	getSelectionBounds(x, y, width, height);
	
	roiManager("select", roi_indices_new);
	RoiManager.scale(1, -1, false);//this is flipping the selection
	
	roiManager("select", atlas_bounding_box_id);
	getSelectionBounds(x_scale, y_scale, width_scale, height_scale); //get bounds after scale
	roiManager("select", roi_indices_new);
	RoiManager.translate(x - x_scale , y - y_scale); // move to original spot
	
	RoiManager.rotate(angle, xcenter, ycenter); //restore original orientation
	
	roiManager("show all without labels");
}

//prompts user, if they want to manually adjust any ROI. If yes:

//turns an roi into a set of points, reduces the amount of points and makes it an editable polygon selection
//then updates the array that stores the brain region ROIs
function to_downsampled_selection(roi_ids) {
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
			roiManager("show all without labels");
			
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
function saving(image_number, local_image_path, local_image_name_without_extension, channelchoices, channeloptions_array, selectedslice, home_directory) {
	//open the saved scaled rois of the respective image
	setBatchMode(true);
	save_roi_ids_start = roiManager("count");
	
	
	if (File.exists(temp + local_image_name_without_extension + "roi.zip")) {
		roiManager("open", temp + local_image_name_without_extension + "roi.zip");
		save_roi_ids_end = roiManager("count") -1;
		
		//get the array of selected channels to go through
		only_channelchoices = Array.deleteValue(channelchoices, "do not use");
		for (i = 1; i <= channelchoices.length; i++) {
			//open the channels specified for analysis (so everything in channeloptions, which does not include "do not use", other than the background image)
			for (j = 0; j < channeloptions_array.length; j++) {
				if (channelchoices[i-1] == channeloptions_array[j]) {
					if ((channelchoices[i-1] != control_channel && !map_to_control_channel) || only_channelchoices.length <= 1 || map_to_control_channel) {
						
						if (!is_czi[image_number]) {
							run("Bio-Formats Importer", "open=[" + local_image_path + "] color_mode=Default specify_range view=Hyperstack stack_order=XYCZT c_begin=" + i + " c_end=" + i + " c_step=1 z_begin=" + selectedslice + " z_end=" + selectedslice + " z_step=1");
						} else {
							
							run("Bio-Formats Importer", "open=[" + local_image_path + "] color_mode=Default specify_range view=Hyperstack stack_order=XYCZT series_" + selectedslice + " c_begin_" + selectedslice + "=" + i + " c_end_" + selectedslice + "=" + i + " c_step_" + selectedslice + "=1");
						}
						
						rename(channeloptions_array[j]);
						
						
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
		
		if (combined_results) {//opens the whole image and saves all ROIs combined
			
			if (!is_czi[image_number]) {
				run("Bio-Formats Importer", "open=" + local_image_path + " color_mode=Default specify_range view=Hyperstack stack_order=XYCZT z_begin=" + selectedslice + " z_end=" + selectedslice + " z_step=1");
			} else {
				run("Bio-Formats Importer", "open=" + local_image_path + " color_mode=Default specify_range view=Hyperstack stack_order=XYCZT series_" + selectedslice);
			}
			rename("current_image");
			
			roiManager("select", roi_closing_array);
			roiManager("show all without labels");
			save(combined_output_path + local_image_name_without_extension + "_combined.tif");
			
			close("current_image");
			File.copy(temp + local_image_name_without_extension + "roi.zip", combined_output_path + local_image_name_without_extension + "_combined_roi.zip");
		}
		
		roiManager("select", roi_closing_array);
		roiManager("delete");
	}
	setBatchMode(false);
}

//functions to create ROIs:
function createROIs(atlas_name, mapping_index_path, searchTerm) {
	
	for (i = 0; i < searchTerm.length; i++) {
		searchTerm[i] = trim(searchTerm[i]); //deal with whitespace in the brain region submission
	}
	open(atlas_path);
	title = getTitle();
	getDimensions(width, height, channels, slices, frames);

	print("Creating ROIs");
	setBatchMode(true);
	
	//open record of which ROIs have been saved already
	already_saved = newArray();
	if (File.exists(mapping_index_path)) {
		Table.open(mapping_index_path);
		//go through the table and get the regions corresponding to this specific atlas
		for (i = 0; i < Table.size; i++) {
			if (trim(Table.getString("Atlas", i)) == trim(atlas_name)) {
				already_saved = Array.concat(already_saved, Table.getString("Region", i));
			}
		}
	} else {
		Table.create("mapping_index.csv");
	}
	
	//delete values from the searchTerm array, if they have been saved as ROIs already
	for (i = 0; i < already_saved.length; i++) {
		searchTerm = Array.deleteValue(searchTerm, trim(already_saved[i]));
	}
	
	for (i = 0; i < searchTerm.length; i++) {
		print("Working on:  " + searchTerm[i]);
		roiManager("reset");
		run("Select None");
		//get the ID of the searchterm
		search_id = "none";
		selectWindow(text_file);
		nrows = Table.size;
		
		for (j = 0; j < nrows; j++) {
			
			if (searchTerm[i] == Table.getString("acronym", j)) {
				search_id = Table.getString("id", j);
			}
		}
		
		children = getRecursiveChildren(search_id);
		rows = getTableRowFromSearch(children);
		if (rows.length > 0) { //only do the stuff, when region was found
			thresholdfromtable(rows, title, search_id);
		
			savingRoi(title, atlas_directory, search_id, searchTerm[i]);
		
			close(search_id);
			
			//add, which region has just been mapped to the register
			selectWindow("mapping_index.csv");
			rownumber_mapping_index_table = Table.size;
			Table.set("Atlas", rownumber_mapping_index_table, atlas_name);
			Table.set("Region", rownumber_mapping_index_table, searchTerm[i]);
			
		} else {
			print(searchTerm[i] + " was not found");
		}
	}
	
	//save, which ROIs have been successfully mapped
	selectWindow("mapping_index.csv");
	saveAs("results", mapping_index_path);
	
	
	setBatchMode(false);
	close(title);
	close(text_file);
	File.setDefaultDir(default_directory);//restore default directory
	close("mapping_index.csv");
	print("ROIs created");
}


function getRecursiveChildren(parents) {
	//search the table to find children of the searchterm, add them to the list of all the regions to combine
	print("Getting sub-terms");
	parents = Array.concat(newArray(), parents);
	selectWindow(text_file);
	nrows = Table.size;
	
	children = newArray();
	for (i = 0; i < parents.length; i++) {
		
		for (j = 0; j < nrows; j++) {
			
			if (parents[i] == Table.getString("parent", j)) {
				children = Array.concat(children, Table.getString("id", j));
			}
		}
	}
	if (children.length > 0) {
		children = getRecursiveChildren(children);//calls itself when it finds children
	}
	return Array.concat(parents, children);
}


function getTableRowFromSearch(searchTerm) {
	//retrieve the rows of all entries in searchterm
	//not really necessary anymore, but was useful for rgb coded images
	print("Getting rows from table");
	selectWindow(text_file);
	searchTerm = Array.concat(newArray(), searchTerm);//to make sure that searchTerm is in array-form
	rows = newArray();
	for (i = 0; i < Table.size; i++) {
		for (j = 0; j < searchTerm.length; j++) {
			if (searchTerm[j] == Table.getString("id", i)) {
				rows = Array.concat(rows, i);//get the row of that entry of searchterm
			}
		}
	}
	return rows;
}

function thresholdfromtable(rows, image, searchTerm) { 
	rows = Array.concat(newArray(), rows); //if rows is a single number, still make it an array
	
	selectWindow(text_file);
	
	//every row is one child-term
	for (i = 0; i < rows.length; i++) {
		selectWindow(image);
		run("Duplicate...", "title=threshold" + i + " duplicate"); //duplicate the stack to threshold for one region
		print("Processing subregions " + (i + 1) + " out of " + rows.length + ".");
		threshold = Table.get("id", rows[i]);
		setThreshold(threshold, threshold);
		run("Convert to Mask", "background=Light");

		if (i > 0) {
			imageCalculator("OR stack", "threshold0", "threshold" + i); //calculate all subregions/children together
			close("threshold" + i); 
		}
	}
	selectWindow("threshold0");
	rename(searchTerm);
}

function savingRoi(image, atlas_directory, searchID, searchTerm) {
	print("Saving ROIs.");
	selectWindow(image);
	run("Duplicate...", "title=bw duplicate");
	run("8-bit");
	selectWindow(searchID);
	getDimensions(width, height, channels, slices, frames);
	
	for (i = 1; i <= nSlices; i++) {
		selectWindow(searchID);
	    setSlice(i);
	    setThreshold(1, 255);
	    run("Create Selection");
	    
	    if(selectionType() != -1) {
	    	
	    	roiManager("add");
	    	roiManager("select", roiManager("count") - 1);
	    	roiManager("rename", searchID);
	    }

	    
	    selectWindow("bw");
	    setSlice(i);
	    	
		//make bounding box to register where the brain was
		getStatistics(area, mean, min, max, std, histogram);
		//this is the background
	    setThreshold(0,0);
	    run("Create Selection");
	    //select everything but the background
	    run("Make Inverse");
	    //only run the following, if something was actually selected
	    if(selectionType() != -1) {
	    	run("To Bounding Box");
	    	roiManager("add");
	    	roiManager("select", roiManager("count") - 1);
	    	roiManager("rename", "atlas_bounding_box");
	    }
	    
	    if (roiManager("count") > 1) {
	    	
	    	roiManager("select", newArray(roiManager("count")-1, roiManager("count")-2));
	    	roiManager("save selected", atlas_directory + i + "/" + searchTerm + ".zip");
	    	//print(atlas_directory + i + "/" + searchTerm + ".zip");
	    	roiManager("select", newArray(roiManager("count")-1, roiManager("count")-2));
	    	roiManager("delete");
	    }
	    run("Select None");
	}
	close("bw");
}
