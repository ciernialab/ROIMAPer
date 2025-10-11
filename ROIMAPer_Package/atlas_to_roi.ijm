//from scalablebrainatlas
var text_file = "";
setup_directory = replace(getDirectory("Please supply the directory, of the downloaded atlas"), "\\", "/"); //because windows is stupid
atlas_name = File.getNameWithoutExtension(setup_directory);
atlas_name = substring(atlas_name, 0, lastIndexOf(atlas_name, "_setup"));
index_directory = File.getDirectory(setup_directory);



open(index_directory + atlas_name + ".tif");
title = getTitle();
if (endsWith(atlas_name, "_halfbrain") {
	text_file = substring(atlas_name, 0, lastIndexOf(atlas_name, "_halfbrain")) + "_brain_region_mapping.csv";
} else {
	text_file = atlas_name + "_brain_region_mapping.csv";
}

Table.open(index_directory + text_file);
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
	children = getRecursiveChildren(searchTerm[i]);
	rows = getTableRowFromSearch(children);
	if (rows.length > 0) { //only do the stuff, when region was found
		thresholdfromtable(rows, title);
	
		savingRoi(title, setup_directory, searchTerm[i]);
	
		close("finished");
	} else {
		print(searchTerm[i] + " was not found");
	}
}



setBatchMode(false);
close(title);
close(text_file);
print("Macro finished");


function getRecursiveChildren(parents) {
	print("Getting sub-terms");
	parents = Array.concat(newArray(), parents);
	selectWindow(text_file);
	nrows = Table.size;
	
	children = newArray();
	for (i = 0; i < parents.length; i++) {
		
		for (j = 0; j < nrows; j++) {
			
			if (parents[i] == Table.getString("parent", j)) {
				children = Array.concat(children, Table.getString("acronym", j));
			}
		}
	}
	if (children.length > 0) {
		children = getRecursiveChildren(children);//calls itself when it finds children
	}
	return Array.concat(parents, children);
}


function getTableRowFromSearch(searchTerm) {
	print("Getting rows from table");
	selectWindow(text_file);
	searchTerm = Array.concat(newArray(), searchTerm);
	rows = newArray();
	for (i = 0; i < Table.size; i++) {
		for (j = 0; j < searchTerm.length; j++) {
			if (searchTerm[j] == Table.getString("acronym", i)) {
				rows = Array.concat(rows, i);
			}
		}
	}
	return rows;
}

function thresholdfromtable(rows, image) { 
	rows = Array.concat(newArray(), rows); //if rows is a single number, still make it an array
	
	selectWindow(text_file);
	
	for (i = 0; i < rows.length; i++) {
		print("Processing subregions " + (i + 1) + " out of " + rows.length + ".");
		r = Table.get("r", rows[i]);
		g = Table.get("g", rows[i]);
		b = Table.get("b", rows[i]);
		thresholding(r,g,b, image, i); //this is the within-stack thresholding based on exact rgb values
		if (i > 0) {
			imageCalculator("OR stack", "threshold0", "threshold" + i); //calculate all subregions/children together
			close("threshold" + i); 
		}
	}
	selectWindow("threshold0");
	rename("finished");
}

function thresholding(r,g,b, image, name) { 
	
	selectWindow(image);
	getDimensions(width, height, channels, slices, frames);
	
	run("Duplicate...", "title=color_threshold duplicate");
	run("RGB Stack");
	
	
	selectWindow("color_threshold");
	run("Duplicate...", "title=Red duplicate channels=1");
	selectWindow("Red");
	setThreshold(r, r);
	run("Convert to Mask", "background=Light");
	
	selectWindow("color_threshold");
	run("Duplicate...", "title=Green duplicate channels=2");
	selectWindow("Green");
	setThreshold(g, g);
	run("Convert to Mask", "background=Light");
	
	selectWindow("color_threshold");
	run("Duplicate...", "title=Blue duplicate channels=3");
	selectWindow("Blue");
	setThreshold(b, b);
	run("Convert to Mask", "background=Light");
	
	
	imageCalculator("AND create stack", "Red", "Green");
	close("Green");
	imageCalculator("AND stack", "Result of Red", "Blue");
	close("Blue");
	close("Red");
	selectWindow("Result of Red");
	rename("threshold" + name);
	close("color_threshold");
}

function savingRoi(image, setup_directory, searchTerm) {
	print("Saving ROIs.");
	selectWindow(image);
	run("Duplicate...", "title=bw duplicate");
	run("8-bit");
	selectWindow("finished");
	getDimensions(width, height, channels, slices, frames);
	
	for (i = 1; i <= nSlices; i++) {
		selectWindow("finished");
	    setSlice(i);
	    setThreshold(1, 255);
	    run("Create Selection");
	    
	    if(selectionType() != -1) {
	    	
	    	roiManager("add");
	    	roiManager("select", roiManager("count") - 1);
	    	roiManager("rename", searchTerm);
	    }

	    
	    selectWindow("bw");
	    setSlice(i);

	    setThreshold(0, 254);
	    run("Create Selection");
	    run("To Bounding Box");
	    
	    if(selectionType() != -1) {
	    	roiManager("add");
	    	roiManager("select", roiManager("count") - 1);
	    	roiManager("rename", "atlas_bounding_box");
	    }
	    
	    if (roiManager("count") > 1) {
	    	
	    	roiManager("select", newArray(roiManager("count")-1, roiManager("count")-2));
	    	roiManager("save selected", setup_directory + i + "/" + searchTerm + ".zip");
	    	print(setup_directory + i + "/" + searchTerm + ".zip");
	    	roiManager("select", newArray(roiManager("count")-1, roiManager("count")-2));
	    	roiManager("delete");
	    } else {//if no brain region was found, delete the bounding box again
	    	roiManager("select", roiManager("count")-1);
			roiManager("delete");
	    }
	}
	close("bw");
}
