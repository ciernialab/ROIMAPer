# ROIMAPer


Semi-automatic FIJI macro to map an atlas of ROIs to tissue images. 
Comes with the 2017 version of the adult mouse Allen Brain Atlas CCFv3 and version 4 of the Waxholm Space Atlas of the Sprague Dawley Rat Brain.

Created by Julian Rodefeld in the Ciernia lab, University of British Columbia, Vancouver, in Sep 2025.

### Installation


Either download all files from github, or clone the repository using **git clone https://github.com/ciernialab/ROIMAPer**


Place the ROIMAPer-main folder in scripts/plugins/ in your FIJI folder (you can find the fiji folder under File>Show Folder>ImageJ in FIJI)

The scripts in ROIMAPer_Utilities are not necessary for ROI mapping. They were used to create the atlas and can be used to create ROIs outside of the main program.


### Image Prerequisits 

1. Know your images
    2. Do they have multiple slices?
    3. Which slice do you want to analyze?
    4.  Which channel corresponds to which label/stain/wavelength?

3. Ideally: save your images as one-slice TIFF files. This ensures high image quality. 

4. When working with .czi files from Zen (Zeiss):
    - Every scene gets saved multiple times at different resolutions (often times 6 duplicates in total).
    - To make processing easier, batch convert your scenes to tiffs instead.
    - Czi files can currently not be a Z-stack.



### Mapping the ROIs 



1. Start the ROIMAPer plugin and select the .tif file that corresponds to your atlas (e.g. "aba_v3-Coronal_halfbrain.tif" if you want to work with a coronal slice of one hemisphere of a mouse-brain).

2. Choose the directory in which the images that you wish to map are located. 

3. Specify the first and the last image of your analysis; you can exclude images between those in the next window. After this step, the metadata of every image is scanned. This might take a while for large/many files.

4. Select the settings for this run

    5. Specify, whether or not to use the same slice of the ABA for each image or not.
    6. Do you want a combined result, meaning all ROIs and all channels of one image saved within one file. 
    8. There is a rudimentary algorithm that automatically detects the tissue, called "automatic bounding box". 
    9. If you are worried about having to terminate the work midway, you can save after every image instead of saving all images at the end.
    10. Do you want to select individual slices for each image, or can the first slice be used in each image?

9. Reference, which regions you want to map to your images. A list of available regions will open. Enter the value in the "acronym" column, seperated by commas, and press OK. The first time new ROIs are used in a new atlas they are created from the reference images, depending on the region this might take a while.

7. Channels: first add any custom channel names to the pop-up (separated by commas), then select which channel in your images belongs to which label. Select which of the channels is staining all of your tissue (usually DAPI) as the "control channel". If you want to create a result for the control channel, too, check the corresponding chechmark The channel order needs to be consistent between all images.

8. Now each image will open one by one to allow for manual correction of the ROI scaling.
    1. Create a rotated rectangle (called the bounding box) that sits flush with the image and contains the brain as straight as possible.

    2. Rotate and flip the ROIs if necessary.

    3. The ROIs will be set onto the tissue, adjust them manually (by double clicking the ROI or clicking the label in the ROI manager), if the location or scale is off.

    4. If an ROI is not aligned with the actual region in the brain, this is often an issue of the atlas slice selection or the bounding box. You can choose to redo these. If you choose not to do this, you can convert any ROI into an editable point-selection. Enter a downscaling factor - the default is 10, which means that every 10th point of the original selection is kept.

9. Do this for all images, and then let the plugin save your ROIs. 
    - They will be stored in a folder next to the one your images are in, titled with the date and time when you started the mapping process.


---



Thank you for using this plugin. 



The Allen Brain Atlas adult mouse brain was obtained from: [https://download.alleninstitute.org/informatics-archive/current-release/mouse_ccf/annotation/ccf_2017/] at a resolution of 10 µm.  
Allen Reference Atlas – Mouse Brain \[adult mouse\]. Available from [https://atlas.brain-map.org/].

The Waxholm Space Atlas of the Sprague Dawley Rat Brain version 4 was obtained from: [www.nitrc.org](https://www.nitrc.org/projects/whs-sd-atlas).

This plugin was inspired by the FASTMAP plugin by Dylan Terstege from the Epp lab, University of Calgary, published on 12-07-2019 [doi.org/10.1523/ENEURO.0325-21.2022](https://doi.org/10.1523/ENEURO.0325-21.2022), available at [github.com/dterstege/FASTMAP](https://github.com/dterstege/FASTMAP)

Atlas files were compressed using the Bio-Formats plugin suite: Linkert, M., Rueden, C. T., Allan, C., Burel, J.-M., Moore, W., Patterson, A., … Swedlow, J. R. (2010). Metadata matters: access to image data in the real world. Journal of Cell Biology, 189(5), 777–782. [doi.org/10.1083/jcb.201004104](https://doi.org/10.1083/jcb.201004104)



