require(tcltk)
require(XML)

destination <-  "ABA_API/"

dir.create(destination)
dir.create(paste0(destination, "coronal/"))
dir.create(paste0(destination, "sagittal/"))
slice_ids_coronal <- unlist(read.csv("http://api.brain-map.org/api/v2/data/query.csv?criteria=+model::AtlasImage,rma::criteria,atlas_data_set(atlases[id$eq1]),graphic_objects(graphic_group_label[id$eq28]),rma::options[tabular$eq%27sub_images.id%27][order$eq%27sub_images.section_number%27]+&num_rows=all&start_row=0"))
slice_ids_sagittal <- unlist(read.csv("http://api.brain-map.org/api/v2/data/query.csv?criteria=+model::AtlasImage,rma::criteria,atlas_data_set(atlases[id$eq2]),graphic_objects(graphic_group_label[id$eq28]),rma::options[tabular$eq%27sub_images.id%27][order$eq%27sub_images.section_number%27]+&num_rows=all&start_row=0"))

save_and_modify_svgs <- function(urls, prefix, suffix, destination, name, width, height) {
  for (i in 1:length(urls)) {
    url <-  paste0(prefix, urls[i], suffix)
    path <- paste0(destination, name, i, "_", urls[i], ".svg")
    download.file(url, destfile = path, mode = "wb")
    svg_string <- readLines(path, warn = FALSE)
    svg_string <- stringr::str_replace_all(svg_string, "stroke:black", "stroke:none")
    writeLines(svg_string,path)
    rsvg::rsvg_png(path, paste0(destination, name, i, "_", urls[i], ".png"), width, height)
    file.remove(path)
  }
}

save_and_modify_svgs(slice_ids_coronal, 
                     "http://api.brain-map.org/api/v2/svg/", "?groups=28,159226751&downsample=0", 
                     paste0(destination, "coronal/"), 
                     "ABA_slice_", 
                     2700,
                     1968)

save_and_modify_svgs(slice_ids_sagittal, 
                     "http://api.brain-map.org/api/v2/svg/", 
                     "?groups=28,159226751&downsample=0", 
                     paste0(destination, "sagittal/"), 
                     "ABA_slice_",
                     3744,
                     1904)

brain_region_indices_xml <- xmlParse("http://api.brain-map.org/api/v2/structure_graph_download/1.xml")
brain_region_indices <- xmlToList(brain_region_indices_xml)[[1]]
write.csv(brain_region_indices, file = paste0(destination, "brain_region_mapping.csv"))