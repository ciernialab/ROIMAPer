//from scalablebrainatlas
var text_file = "";
default_directory = File.getDefaultDir;//to restore in the end
home_directory = replace(getDirectory("imagej"), "\\" "/") + "scripts/Plugins/ROIMAPer/atlases/";

File.setDefaultDir(home_directory);
atlas_path = replace(File.openDialog("Please select which atlas you would like to work with"), "\\", "/"); //replace backslash with forwardslash

atlas_name = File.getNameWithoutExtension(atlas_path);
atlas_directory = home_directory + atlas_name + "_ROIs/";

open(atlas_path);
getDimensions(width, height, channels, slices, frames);
title = getTitle();

//get the corresponding ID to region info
//the actual name of the atlas is only the part before the first dash
text_file = substring(atlas_name, 0, indexOf(atlas_name, "-")) + "-brain_region_mapping.csv";


if (!File.exists(atlas_directory)) {
	//creates structure for the ROIs to be saved in
	File.makeDirectory(atlas_directory);
	for (i = 1; i <= slices; i++) {
		File.makeDirectory(atlas_directory + i + "/");
	}
}

Table.open(home_directory + text_file);
Dialog.createNonBlocking("Select brain region(s) to map");
Dialog.addMessage("Which brain regions do you want to map? Please add the region acronyms separated by a comma, like this: \"HY, BLA, CA1\".");
Dialog.addString("Brain regions:", "", 35);
Dialog.show();

template_slice_number = Array.concat(newArray(),Dialog.getNumber());
searchTerm = split(Dialog.getString(), ",");
for (i = 0; i < searchTerm.length; i++) {
	searchTerm[i] = trim(searchTerm[i]); //deal with whitespace in the brain region submission
}
print("Creating ROIs");
setBatchMode(true);

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
	} else {
		print(searchTerm[i] + " was not found");
	}
}



setBatchMode(false);
close(title);
close(text_file);
File.setDefaultDir(default_directory);//restore default directory
print("Macro finished");


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
	    setThreshold(1, max);
	    run("Create Selection");
	    run("To Bounding Box");
	    
	    if(selectionType() != -1) {
	    	roiManager("add");
	    	roiManager("select", roiManager("count") - 1);
	    	roiManager("rename", "atlas_bounding_box");
	    }
	    
	    if (roiManager("count") > 1) {
	    	
	    	roiManager("select", newArray(roiManager("count")-1, roiManager("count")-2));
	    	roiManager("save selected", atlas_directory + i + "/" + searchTerm + ".zip");
	    	print(atlas_directory + i + "/" + searchTerm + ".zip");
	    	roiManager("select", newArray(roiManager("count")-1, roiManager("count")-2));
	    	roiManager("delete");
	    }
 else {//if no brain region was found, delete the bounding box again
	    	roiManager("select", roiManager("count")-1);
			roiManager("delete");
	    }
	}
	close("bw");
}
