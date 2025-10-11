

destination <-  "ABA_API_"

dir.create(paste0(destination, "coronal/"))
dir.create(paste0(destination, "sagittal/"))
slice_ids_coronal <- unlist(read.csv("http://api.brain-map.org/api/v2/data/query.csv?criteria=+model::AtlasImage,rma::criteria,atlas_data_set(atlases[id$eq1]),graphic_objects(graphic_group_label[id$eq28]),rma::options[tabular$eq%27sub_images.id%27][order$eq%27sub_images.section_number%27]+&num_rows=all&start_row=0"))
slice_ids_sagittal <- unlist(read.csv("http://api.brain-map.org/api/v2/data/query.csv?criteria=+model::AtlasImage,rma::criteria,atlas_data_set(atlases[id$eq2]),graphic_objects(graphic_group_label[id$eq28]),rma::options[tabular$eq%27sub_images.id%27][order$eq%27sub_images.section_number%27]+&num_rows=all&start_row=0"))

save_and_modify_svgs <- function(urls, prefix, suffix, destination, width, height) {
  for (i in 1:length(urls)) {
    url <-  paste0(prefix, urls[i], suffix)
    path <- paste0(destination, "slice", sprintf("%03d", i), ".svg")
    download.file(url, destfile = path, mode = "wb")
    svg_string <- readLines(path, warn = FALSE)
    svg_string <- stringr::str_replace_all(svg_string, "stroke:black",  "stroke:none")
    writeLines(svg_string,path)
  }
}

save_and_modify_svgs(slice_ids_coronal, 
                     "http://api.brain-map.org/api/v2/svg/", "?groups=28,159226751&downsample=0", 
                     paste0(destination, "coronal/"), 
                     2700,
                     1968)

save_and_modify_svgs(slice_ids_sagittal, 
                     "http://api.brain-map.org/api/v2/svg/", 
                     "?groups=28,159226751&downsample=0", 
                     paste0(destination, "sagittal/"), 
                     3744,
                     1904)

brain_region_indices <- read.csv("http://api.brain-map.org/api/v2/data/query.csv?criteria=model::Structure,rma::criteria,[ontology_id$eq1],rma::options[order$eq%27structures.graph_order%27][num_rows$eqall]")
brain_region_indices[, c("r","g","b")] <- t(col2rgb(paste0("#",brain_region_indices$color_hex_triplet)))
brain_region_indices$parent <- c(
  NA,
  unlist(
    sapply(
      brain_region_indices$parent_structure_id, 
       function(x) brain_region_indices[as.integer(
         rownames(brain_region_indices[brain_region_indices$id == x[!is.na(x)], ])), "acronym"])))
write.csv(brain_region_indices, file = paste0(destination, "coronal_brain_region_mapping.csv"))
write.csv(brain_region_indices, file = paste0(destination, "sagittal_brain_region_mapping.csv"))

