library(tcltk)

destination <-  ""

dir.create(paste0(destination, "ABA_v3_download/"))

for (i in 1:132) {
  url = paste0("https://scalablebrainatlas.incf.org/services/rgbslice.php?template=ABA_v3&slice=",i,"&size=L&format=png")
  
  slicenumber <-  sprintf("%03d", i)
  
  download.file(url, destfile = paste0(destination, "ABA_v3_download/slice", slicenumber, ".png"), mode = "wb")
  
}

brain_region_indices <- read.csv("https://scalablebrainatlas.incf.org/services/listregions.php?template=ABA_v3", sep = "\t", header = FALSE, col.names = c("hex", "acronym", "region", "parent", "type"))

brain_region_indices[, c("r","g","b")] <- t(col2rgb(brain_region_indices$hex))
write.csv(brain_region_indices, file = paste0(destination, "brain_region_mapping.csv"))
#https://scalablebrainatlas.incf.org/templates/ABA_v3/source/P56_Annotation.nii.gz sagital
