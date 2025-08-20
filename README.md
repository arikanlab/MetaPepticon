<h1 align="center">MetaPepticon</h1>
<h2 align="center">Automated anticancer peptide prediction from genomics and metagenomics datasets</h2>

If you use this tool, please cite:  
  
Erozden AA, Tavsanli N, Demirel G, Sanli NO, Caliskan M, Arikan M. (2025) MetaPepticon: automated anticancer peptide prediction from genomics and metagenomics datasets, bioRxiv. 


# Table of contents
- [Overview](#overview)
- [Requirements](#requirements)
- [Setup](#setup)
    - [Data](#data)
    - [Config](#config)
- [Running](#running)
    - [Running locally](#running-locally)
    - [Running on a cluster](#running-on-a-cluster)
- [Outputs](#outputs)
    - [Final outputs](#final-outputs)
    - [Intermediate outputs](#intermediate-outputs)

# Overview
MetaPepticon allows discovery of candidate ACPs directly from diverse sequencing inputs, including raw genomic, metagenomic, transcriptomic, and metatranscriptomic reads, as well as assembled contigs and peptide sequences. By employing a consensus-based strategy and supporting heterogeneous data types, it facilitates scalable, reproducible, and high-confidence identification of ACP candidates.

![Local Image](images/pipeline_overview.jpg)

# Requirements
To use MetaPepticon, ensure you have `conda` and  `snakemake` installed: 
   
**1. Install conda**: If you do not have conda installed, [install conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html).  
  
**2. Create a Snakemake environment in conda**:
```
conda create -n snakemake bioconda::snakemake=8.25.5 conda-forge::mamba
```
  
**3. Clone MetaPepticon repository**: If you do not have git installed, [install git](https://github.com/git-guides/install-git).
```
git clone --recursive https://github.com/muzafferarikan/MetaPepticon.git
```
  
**Note**: Once conda and snakemake are set up, MetaPepticon manages the installation of all other tools and dependencies automatically in their respective environments during the first run. 

# Setup
## Data
Copy your raw data to the relevant subfolders within the `data` directory:    
* If you have metagenomics raw data, copy your files to `data/MG`  
* If you have metatranscriptomics raw data, copy your files to `data/MT`  
* If you have single organism genomics raw data, copy your files to `data/SG`
* If you have single organism transcriptomics raw data, copy your files to `data/ST`
* If you have contigs, copy your files to `data/contigs`
* If you have peptides, copy your files to `data/peptides`   
  
**Important**: Please check sample format requirements below:  
| Data | Library Layout | Sample Name Format  |
|------|----------------|---------------------|
| MG | PE | samplename_1.fastq.gz, samplename_2.fastq.gz |
| MT | PE | samplename_1.fastq.gz, samplename_2.fastq.gz |
| SG | PE | samplename_1.fastq.gz, samplename_2.fastq.gz |
| ST | PE | samplename_1.fastq.gz, samplename_2.fastq.gz |
| CO | - | samplename.fasta |
| PE | - | samplename.fasta |

## Config
After copying your data, run the following script from your main MetaPepticon project folder to generate a config file:   
```
bash workflow/scripts/prepare_config.sh
```
This script generates a `config.yaml` file within `config` folder based on contents of `data` directory. Review and modify analysis parameters in this file if you need.

# Running
Once setup is complete, follow these steps to run MetaPepticon: 
   
**1. Activate your snakemake environment in conda**:
```
conda activate snakemake
```


**2. Run MetaPepticon**:  
Execute the following command from your project folder:
```
snakemake -s workflow/Snakefile --resources toxinslot=1 --cores 2 --use-conda
```


**Note**: Adjust the `--cores` value to reflect the number of cores available.  


# Outputs
When MetaPepticon starts, it generates a `results` folder within your project directory, containing both `final` and `intermediate` outputs.

## Final outputs
The `final` folder includes:  
* Anticancer peptide and toxicity prediction results 

## Intermediate outputs
`intermediate` folder contains outputs of each step executed by the pipeline. 
