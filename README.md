<h1 align="center">MetaPepticon</h1>
<h2 align="center">Automated anticancer peptide prediction from genomics and metagenomics datasets</h2>

If you use this tool, please cite:  
  
Erozden AA, Tavsanli N, Demirel G, Sanli NO, Caliskan M, Arikan M. (2025) MetaPepticon: automated anticancer peptide prediction from genomics and metagenomics datasets, bioRxiv. Link


# Table of contents
- [Overview](#overview)
- [Requirements](#requirements)
- [Setup](#setup)
    - [Data](#data)
    - [Config](#config)
- [Running](#running)
- [Outputs](#outputs)
    - [Final outputs](#final-outputs)
    - [Intermediate outputs](#intermediate-outputs)

# Overview
MetaPepticon allows discovery of candidate anticancer peptides (ACPs) directly from diverse inputs, including:
- Raw genomic, metagenomic, transcriptomic, and metatranscriptomic reads
- Assembled contigs
- Peptide sequences. 

By employing a **consensus-based strategy** and supporting heterogeneous data types, it facilitates scalable, reproducible, and high-confidence identification of ACP candidates.

# Requirements
MetaPepticon requires`conda` and  `snakemake`: 
   
**1. Install conda**: If you do not have conda installed, [install conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html).  
  
**2. Create a Snakemake environment in conda**:
```
conda create -c conda-forge -c bioconda -n snakemake snakemake=8.25.5 python=3.11
```
  
**3. Clone MetaPepticon repository**: If you do not have git installed, [install git](https://github.com/git-guides/install-git).
```
git clone --recursive https://github.com/arikanlab/MetaPepticon.git
```
  
**Note**: Once conda and snakemake are set up, MetaPepticon manages the installation of all other tools and dependencies automatically in their respective environments during the first run. 

# Setup
## Data
Copy your raw data to the relevant subfolders within the `data` directory:      
  
**Important**: Please check sample format requirements below:  
| Data | Subfolder | Library Layout | Expected File Names |
|------|-----------|----------------|---------------------|
| Metagenomics | data/MG | PE | samplename_1.fastq.gz, samplename_2.fastq.gz |
| Metatranscriptomics | data/MT | PE | samplename_1.fastq.gz, samplename_2.fastq.gz |
| Genomics | data/SG | PE | samplename_1.fastq.gz, samplename_2.fastq.gz |
| Transcriptomics | data/ST | PE |samplename_1.fastq.gz, samplename_2.fastq.gz |
| Contigs | data/contigs | - |samplename.fasta |
| Peptides | data/peptides | - | samplename.fasta |

## Config
MetaPepticon provides two options for generating the `config.yaml`

**Option 1 (CLI)**   
```
bash workflow/scripts/prepare_config.sh
```

**Option 2 (GUI)**   
Install dependencies:
```
pip install PyYAML PyQt5

```
Generate config file:
```
bash workflow/scripts/gui_prepare_config.py
```
Both options generate `config.yaml` file within `config` folder based on contents of `data` directory. Review and modify analysis parameters as needed.

# Running
Once setup is complete, follow these steps to run MetaPepticon: 
   
**1. Activate snakemake environment**:
```
conda activate snakemake
```


**2. Run MetaPepticon**:  
Execute the following command from your project folder:
```
snakemake -s workflow/Snakefile --resources slot=1 --cores 16 --use-conda
```


**Note**: Adjust `--cores` to the number of cores available. Do not change`--resources` as it ensures proper resource allocation for assembly and toxicity prediction steps.


# Outputs
MetaPepticon generates a `results` folder with two subfolders:

## Final outputs
`results/final`: Tab delimited tables (.txt), one per sample, including anticancer peptide and toxicity predictions

## Intermediate outputs
`intermediate_files`: Outputs from each each step of the pipeline. 
