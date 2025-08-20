#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
})

# Get arguments from Snakemake
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Usage: Rscript merge_predictions.R <table1.tsv> <table2.csv> <output.tsv>")
}

table1_file <- args[1]
table2_file <- args[2]
output_file <- args[3]

# Read input tables (base R)
table1 <- read.table(table1_file, sep = "\t", header = TRUE, stringsAsFactors = FALSE)
table2 <- read.table(table2_file, sep = ",", header = TRUE, stringsAsFactors = FALSE)

# Merge with dplyr only
merged <- table1 %>%
  left_join(table2 %>% select(Subject, Prediction),
            by = c("Sequence" = "Subject")) %>%
  rename(prediction_by_toxinpred = Prediction)

# Write output (base R)
write.table(merged, file = output_file, sep = "\t", quote = FALSE, row.names = FALSE)
