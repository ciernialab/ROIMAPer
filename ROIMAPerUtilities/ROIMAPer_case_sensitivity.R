path <- "ROIMAPer/ROIMAPerUtilities/"

files <- list.files(path)

txt_files <- grep("brain_region_mapping.txt", files, value = T)

evaluate_case_duplicates <- function(file) {
  df <- read.csv2(paste0(path, file), sep = "\t", header = T)
  
  acronym_duplicated <- unique(sort(
    df$acronym[
      df$acronym %in% 
        unique(df$acronym)[(duplicated(tolower(unique(df$acronym))) | 
                                 duplicated(tolower(unique(df$acronym)), 
                                            fromLast = T)
                               )
                              ]
      ]
  ))
  
  acronym_duplicated_not_first <- unique(
    sort(
      df$acronym[
        df$acronym %in% 
          unique(df$acronym)[duplicated(tolower(unique(df$acronym)))]
      ]
    )
  )
  
  acronym_unambiguous <- df$acronym
  
  #this adjusts the name of replicates in the acronym list
  #prepends an ascending number with a dash, this gets recognized by the ImageJ
  #macro and gets (and acronym search requests in ImageJ that aren't found are
  #tried with the prepended number) - also gets removed in the final save
  
  for (acronym in unique(tolower(acronym_duplicated_not_first))) {
    for (j in 1:length(
      acronym_duplicated_not_first[
        tolower(acronym_duplicated_not_first)==acronym])) {
      candidate <-  acronym_duplicated_not_first[tolower(acronym_duplicated_not_first)==acronym][j]
      acronym_unambiguous[acronym_unambiguous==candidate] <- paste0(j, "-", candidate)
    }
  }
  
  acronym_unambiguous_duplicated <- unique(sort(
    acronym_unambiguous[
      acronym_unambiguous %in% 
        unique(acronym_unambiguous)[
          (duplicated(tolower(unique(acronym_unambiguous))) |
             duplicated(tolower(unique(acronym_unambiguous)), 
                        fromLast = T))]]
    ))
  
  replaced <- sort(unique(acronym_unambiguous[
    df$acronym %in% 
      unique(df$acronym)[(duplicated(tolower(unique(df$acronym))) | 
                            duplicated(tolower(unique(df$acronym)), 
                                       fromLast = T)
                          )
      ]
  ]))
  df$acronym <- acronym_unambiguous
  
  write.table(x = df, 
             file = paste0(path, file), 
             sep = "\t", quote = F)
  return(replaced)
}

lapply(txt_files, function(x) evaluate_case_duplicates(x))