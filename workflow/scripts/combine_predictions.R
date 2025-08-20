# Load necessary libraries
library(dplyr)

# Get arguments from the command line
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 5) {
  stop("Usage: Rscript combine_predictions.R <anticp2_file> <cacp_file> <acpred_file> <output_file> <min_columns>")
}

anticp2_file <- args[1]
conacp_file <- args[2]
acpred_file <- args[3]
output_file <- args[4]
min_columns <- as.integer(args[5])

if (!min_columns %in% c(1, 2, 3)) {
  stop("min_columns must be either 1, 2 or 3")
}

# Read the first file
first_file <- readLines(anticp2_file)
data_first <- do.call(rbind, lapply(first_file, function(line) {
  if (startsWith(line, ">")) {
    info <- strsplit(line, ",")[[1]]
    sequence <- info[2]
    prediction <- info[4]
    return(data.frame(Sequence = sequence, prediction_by_anticp2 = as.numeric(prediction)))
  }
}))

# Read the second file
second_file <- read.delim(conacp_file, header = TRUE, stringsAsFactors = FALSE)
colnames(second_file) <- gsub("[^[:alnum:]]", "_", colnames(second_file))
data_second <- second_file %>%
  mutate(prediction_by_conacp = ifelse(Pred_res == "ACP", 1, 0)) %>%
  select(prediction_by_conacp)

# Read the third file
third_file <- read.csv(acpred_file, header = TRUE)
data_third <- third_file %>% select(Sequence = sequence, prediction_by_acpred = prediction)

# Combine all tables by row number (assuming all files are aligned)
final_table <- data_first %>%
  mutate(prediction_by_conacp = data_second$prediction_by_conacp, 
         prediction_by_acpred = data_third$prediction_by_acpred)

# Filter sequences with >0.5 in at least 'min_columns' prediction columns
filtered_table <- final_table %>%
  rowwise() %>%
  filter(sum(c_across(starts_with("prediction_by_")) > 0.5) >= (min_columns-0.5)) %>%
  ungroup()

# Write the filtered table to a TSV file
write.table(filtered_table, output_file, sep = "\t", row.names = FALSE, quote = FALSE)

# Print a success message
cat("Filtered results saved to", output_file, "\n")
