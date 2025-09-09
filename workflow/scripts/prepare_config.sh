#!/bin/bash

# Title: Prepare Snakemake Configuration File for MetaPepticon
# Author: Muzaffer Arikan
# Date: Mar 2025
# Description:
#   This script generates a config.yaml file based on contents of "data" directory.
#   It assigns relevant input type and writes sample file names and parameters.
#   User should check if assigned input type is correct and all sample files are provided
#   Parameters are listed with default values and can be changed by the user before running MetaPepticon. 

# Function to format the files for peptides, contigs, SG, ST, MG and MT
format_files() {
    folder="$1"
    sample_name="$2"

    r1_file_exists=0
    r2_file_exists=0

    for file in "data/$folder/${sample_name}"_{1,2}.fastq.gz; do
        if [ -f "$file" ]; then
            if [[ $file == *"1.fastq.gz" ]]; then
                r1_file_exists=1
            elif [[ $file == *"2.fastq.gz" ]]; then
                r2_file_exists=1
            fi
        fi
    done

    if [ "$r1_file_exists" -eq 1 ] && [ "$r2_file_exists" -eq 1 ]; then
        if ! grep -q "${folder}_layout: PE" "$output_file"; then
            echo "${folder}_layout: PE" >> "$output_file"
            echo "Samples:" >> "$output_file"
        fi
        echo "   \"$sample_name\": [r1:\"data/$folder/${sample_name}_1.fastq.gz\", r2:\"data/$folder/${sample_name}_2.fastq.gz\"]" >> "$output_file"
    elif [ "$r1_file_exists" -eq 1 ]; then
        if ! grep -q "${folder}_layout: SE" "$output_file"; then
            echo "${folder}_layout: SE" >> "$output_file"
            echo "Samples:" >> "$output_file"
        fi
        echo "   \"$sample_name\": [r1:\"data/$folder/${sample_name}_1.fastq.gz\"]" >> "$output_file"
    fi
}


# Function to format the files for contigs
format_co_files() {
    folder="contigs"
    sample_name="$1"

    contig_file="data/$folder/${sample_name}.fasta"

    if [ -f "$contig_file" ]; then
        echo "      \"$sample_name\": $contig_file" >> "$output_file"
    fi
}

# Function to format the files for peptides
format_pe_files() {
    folder="peptides"
    sample_name="$1"

    peptide_file="data/$folder/${sample_name}.fasta"

    if [ -f "$peptide_file" ]; then
        echo "      \"$sample_name\": $peptide_file" >> "$output_file"
    fi
}

# Check if the 'data' directory exists
if [ -d "data" ]; then
    # Create a 'config' directory if it doesn't exist
    mkdir -p config
    # Create a text file to store the filenames
    output_file="config/config.yaml"
    > "$output_file" # Clears the file or creates a new one

    # Add the required text at the beginning of the file
    cat <<EOF >> "$output_file"
# Please check if the "input_type" parameter is correct:
# MG:  Metagenomics
# MT:  Metatranscriptomics
# CO:  Contigs
# PE:  Peptides

EOF

    # Initialize input_type variable
    input_type=""

    # Check for non-empty folders
    SG_non_empty=$(ls -A "data/SG"/*.fastq.gz 2>/dev/null || true)
    ST_non_empty=$(ls -A "data/ST"/*.fastq.gz 2>/dev/null || true)
    MG_non_empty=$(ls -A "data/MG"/*.fastq.gz 2>/dev/null || true)
    MT_non_empty=$(ls -A "data/MT"/*.fastq.gz 2>/dev/null || true)
    CO_non_empty=$(ls -A "data/contigs"/*.fasta 2>/dev/null || true)
    PE_non_empty=$(ls -A "data/peptides"/*.fasta 2>/dev/null || true)

    # Determine the input_type number based on conditions
    if [ -n "$SG_non_empty" ] && [ -z "$ST_non_empty" ] && [ -z "$MG_non_empty" ] && [ -z "$MT_non_empty" ] && [ -z "$CO_non_empty" ] && [ -z "$PE_non_empty" ]; then
        input_type="SG"
    elif [ -z "$SG_non_empty" ] && [ -n "$ST_non_empty" ] && [ -z "$MG_non_empty" ] && [ -z "$MT_non_empty" ] && [ -z "$CO_non_empty" ] && [ -z "$PE_non_empty" ]; then
        input_type="ST"
    elif [ -z "$SG_non_empty" ] && [ -z "$ST_non_empty" ] && [ -n "$MG_non_empty" ] && [ -z "$MT_non_empty" ] && [ -z "$CO_non_empty" ] && [ -z "$PE_non_empty" ]; then
        input_type="MG"
    elif [ -z "$SG_non_empty" ] && [ -z "$ST_non_empty" ] && [ -z "$MG_non_empty" ] && [ -n "$MT_non_empty" ] && [ -z "$CO_non_empty" ] && [ -z "$PE_non_empty" ]; then
        input_type="MT"
    elif [ -z "$SG_non_empty" ] && [ -z "$ST_non_empty" ] && [ -z "$MG_non_empty" ] && [ -z "$MT_non_empty" ] && [ -n "$CO_non_empty" ] && [ -z "$PE_non_empty" ]; then
        input_type="CO"
    elif [ -z "$SG_non_empty" ] && [ -z "$ST_non_empty" ] && [ -z "$MG_non_empty" ] && [ -z "$MT_non_empty" ] && [ -z "$CO_non_empty" ] && [ -n "$PE_non_empty" ]; then
        input_type="PE"     
    fi

    if [ -n "$input_type" ]; then
    	echo "input_type: \"$input_type\"" >> "$output_file"
    	echo >> "$output_file" # Empty line

        case $input_type in
            "SG")
                cat <<EOF >> "$output_file"
parameters:
   trimmomatic: "SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:resources/adapters.fa:2:30:10"
   min_consensus_pred: "1"
   anticp2: "-d 2"
   contig_len_filt: "-m 1000"
   pep_len_filt: "-m 10 -M 50"
EOF
                ;;
            "ST")
                cat <<EOF >> "$output_file"
parameters:
   trimmomatic: "SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:resources/adapters.fa:2:30:10"
   min_consensus_pred: "1"
   anticp2: "-d 2"
   contig_len_filt: "-m 1000"
   pep_len_filt: "-m 10 -M 50"
EOF
                ;;
            "MG")
                cat <<EOF >> "$output_file"
parameters:
   trimmomatic: "SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:resources/adapters.fa:2:30:10"
   min_consensus_pred: "1"
   anticp2: "-d 2"
   contig_len_filt: "-m 1000"
   pep_len_filt: "-m 10 -M 50"
EOF
                ;;
            "MT")
                cat <<EOF >> "$output_file"
parameters:
   trimmomatic: "SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:resources/adapters.fa:2:30:10"
   min_consensus_pred: "1"
   anticp2: "-d 2"
   contig_len_filt: "-m 1000"
   pep_len_filt: "-m 10 -M 50"
EOF
                ;;
            "CO")
                cat <<EOF >> "$output_file"
parameters:
   min_consensus_pred: "1"
   anticp2: "-d 2"
   contig_len_filt: "-m 1000"
   pep_len_filt: "-m 10 -M 50"
EOF
                ;;
            "PE")
                cat <<EOF >> "$output_file"
parameters:
   min_consensus_pred: "1"
   anticp2: "-d 2"
   pep_len_filt: "-m 10 -M 50"
EOF
                ;;
            *)
                echo "Unknown input_type: $input_type"
                ;;
        esac

        echo "Configuration file successfully generated. See $output_file for details."
    else
        echo "No valid input found."
    fi
else
    echo "'data' directory not found."
fi

        # List files for SG folder
        if [ -n "$SG_non_empty" ]; then
        	echo >> "$output_file" # Empty line
            for file in data/SG/*_1.fastq.gz; do
                base=$(basename "$file" _1.fastq.gz)
                format_files "SG" "$base"
            done
        fi
        # List files for ST folder
        if [ -n "$ST_non_empty" ]; then
        	echo >> "$output_file" # Empty line
            for file in data/ST/*_1.fastq.gz; do
                base=$(basename "$file" _1.fastq.gz)
                format_files "ST" "$base"
            done
        fi

        # List files for MG folder
        if [ -n "$MG_non_empty" ]; then
        	echo >> "$output_file" # Empty line
            for file in data/MG/*_1.fastq.gz; do
                base=$(basename "$file" _1.fastq.gz)
                format_files "MG" "$base"
            done
        fi

        # List files for MT folder
        if [ -n "$MT_non_empty" ]; then
            echo >> "$output_file" # Empty line
            for file in data/MT/*_1.fastq.gz; do
                base=$(basename "$file" _1.fastq.gz)
                format_files "MT" "$base"
            done
        fi

        # List files for CO folder
        if [ -n "$CO_non_empty" ]; then
            echo >> "$output_file" # Empty line
            echo "Samples:" >> "$output_file"
            for file in data/contigs/*.fasta; do
                base=$(basename "$file" .fasta)
                format_co_files "$base"
            done
        fi

        # List files for PE folder
        if [ -n "$PE_non_empty" ]; then
            echo >> "$output_file" # Empty line
            echo "Samples:" >> "$output_file"
            for file in data/peptides/*.fasta; do
                base=$(basename "$file" .fasta)
                format_pe_files "$base"
            done
        fi
