# ROIMAPer



Semi-automatic FIJI macro to map an atlas of ROIs to tissue images. Currently setup to also download a coronal version of the P65 ABA\_v3.







This project is composed of four scripts that are used in three different situations:



\* atlas\\\_download.R \\\& atlas\\\_setup.ijm: downloading the coronal ABA\\\_v3 and making it accessible for the other scripts; run once upon first install

\* atlas\\\_to\\\_roi.ijm: creating regions of interest (ROI) for specific brain regions from the atlas; run whenever you need access to a new brain region that is not yet stored

\* ROIMAPer\\\_.ijm: map the stored brain regions to brain slices; this is the day-to-day script







---- INSTALLING ----



Either download all files from github, or clone the repository using \*\*git clone https://github.com/ciernialab/ROIMAPer\*\*







1\. run atlas\\\_download.R (specify the directory of installation for the atlas, or it will use the current working directory)







2\\. Install the .ijm scripts as Plugins in FIJI, by placing the folder ROIMAPer\\\_Package in Fiji.app/scripts/plugins







3\\. run atlas\\\_setup.ijm (specify the same directory as in 1.)







---- Obtaining ROIs ----



1\. Run atlas\\\_to\\\_roi.ijm and specifiy the same directory as in the installation (this is where the folder ABA\\\_v3\\\\ and the files brain\\\_region\\\_mapping.csv, aba\\\_v3.tif and atlas\\\_overview.tif should be located)

2\. Specify the brain regions you want to save as ROIs, use the brain region acronyms as specified by https://atlas.brain-map.org

3\. When creating templates for multiple regions at the same time, separate the individual acronyms by commas, any whitespace will be trimmed







---- Mapping the ROIs ----



1\. Start the ROIMAPer plugin and specify the directory in which the folder ABA\\\_v3\\\\ and the files brain\\\_region\\\_mapping.csv, aba\\\_v3.tif and atlas\\\_overview.tif are located (the installation folder from above)

2\. Choose the directory in which the images, which you wish to map, are located

3\. Specify the first and the last image of your analysis; these and all images inbetween will be mapped

4\. For each image, specify which slice you want to use, only this slice will be opened to save processing power. Also specify, whether or not to use the same slice of the ABA for each image or not

5\. Reference, which slice of the ABA should be used for \*\*A)\*\* all images or \*\*B)\*\* every image individually. A reference overview of the ABA slices will open

6\. Channels: first add any custom channel names to the pop-up (separated by commas), then select which channel in your images belongs to which label. Select which of the channels is staining all of your tissue (usually DAPI) as the "background channel"

7\. Now each image will open one by one to allow for manual correction of the ROI scaling. 



8.1 First rotate the image, so it matches the orientation of the right hemisphere. Uncheck "continue rotation" to proceed to the next step



8.2 A rectangular selection will be created around your tissue, adjust it until it sits flush with the tissue



8.3 The ROIs will be set onto the tissue, adjust them, if the location or scale is off.



9\\. Do this for all images, and then let the plugin save your ROIs. They will be stored in a folder next to the one your images are in, titled with the date and time you started the mapping process.







---



Thank you for using this plugin. 



The RGB representation of the Allen Brain Atlas was obtained from \[The Scalable Brain Atlas](https://scalablebrainatlas.incf.org/).



This plugin was inspired by the FASTMAP plugin by Dylan Terstege from the Epp lab, University of Calgary, published on 12-07-2019 \[https://doi.org/10.1523/ENEURO.0325-21.2022](https://doi.org/10.1523/ENEURO.0325-21.2022), available at \[https://github.com/dterstege/FASTMAP](https://github.com/dterstege/FASTMAP)





