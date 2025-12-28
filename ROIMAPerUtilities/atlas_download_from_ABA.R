brain_region_indices_ABA <- read.csv("http://api.brain-map.org/api/v2/data/query.csv?criteria=model::Structure,rma::criteria,[ontology_id$eq1],rma::options[order$eq%27structures.graph_order%27][num_rows$eqall]")
brain_region_indices_ABA[, c("r","g","b")] <- t(col2rgb(paste0("#",brain_region_indices_ABA$color_hex_triplet)))
brain_region_indices_ABA$parent <- c(
  NA,
  unlist(
    sapply(
      brain_region_indices_ABA$parent_structure_id, 
       function(x) brain_region_indices_ABA[as.integer(
         rownames(brain_region_indices_ABA[brain_region_indices_ABA$id == x[!is.na(x)], ])), "acronym"])))

#imagej can not have values over 2^24, so replace those with smaller values
#get modulo, so only the part that is smaller than 100,000
#see allen_atlas_float_conversion.py for replacing of values
float_correct_ids <- brain_region_indices_ABA$id %% 100000

roimaper_aba <- data.frame(
  id = float_correct_ids,
  acronym = stringr::str_replace_all(brain_region_indices_ABA$acronym,
                                     pattern = "/", replacement = "-"),
  name = brain_region_indices_ABA$name,
  parent = brain_region_indices_ABA$parent_structure_id)

write.csv(roimaper_aba, file = "ROIMAPer/atlases/aba_v3-brain_region_mapping.csv")
