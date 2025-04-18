source("Ridge_regress.R")
Ftype <- "Tone" # Choose 'Context' or 'Tone"
data <- read_excel("Freezing_opto_data.xlsx")

contex_df <- Ridge_regression(data, "Context")
Sys.sleep(0.1)
Tone_df <- Ridge_regression(data, "Tone")




