library(dplyr)

## load data
big5_kag <- readr::read_delim("./raw_data/big5_kag.csv", 
                              "\t", escape_double = FALSE, trim_ws = TRUE) 
## prepare data
big5 <- big5_kag %>%
  # only select relevant variables
  dplyr::select(EXT1:OPN10) %>% 
  dplyr::select(matches("1$|2$|3$|4$|5$")) %>%
  # convert the char --to--> int
  mutate_if(is.character, as.integer) %>% 
  # filter incomplete cases
  na.omit() %>%
  # create subsample (my arbitrary choice: 100,000)
  sample_n(1e5) %>% 
  # recode reverse coded items
  mutate_at(c("EXT2","EXT4",
              'EST1','EST3',"EST5", 
              "AGR1","AGR3","AGR5",
              "CSN2","CSN4",
              "OPN2","OPN4"), 
            list(~ recode(., `1`= 5L, `2`= 4L, `4`= 2L, `5`= 1L, .default = 3L))) %>% 
  suppressWarnings()


## save the cleaned data as RDS
saveRDS(big5, file ="./data/big5.RDS")
