library(dplyr)
source(here::here("R/shapeyourcity.R"))

d<- get_all_projects()
ss <- "1JebPpgDoHpY39Omzu5KNffJlG2Ri2-F0jOTlyUCcVZs"
googlesheets4::write_sheet(d,ss,"shapeyourcity")

