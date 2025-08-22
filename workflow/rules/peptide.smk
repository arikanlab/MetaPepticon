import os
import yaml 

configfile: "config/config.yaml"


rule all:
	input:
		anticp2_results=expand("results/intermediate_files/anticancer/anticp2/{sample}/anticp2_results.txt", sample=config["Samples"]),
		conacp_results=expand("results/intermediate_files/anticancer/cACP/{sample}/cACP_results.txt", sample=config["Samples"]),
		acpred_results=expand("results/intermediate_files/anticancer/acpred/{sample}_clean_nodup_smorfs_alter_prediction.csv", sample=config["Samples"]),
		filt_combined_results=expand("results/intermediate_files/anticancer/{sample}_combined_predictions_filtered.tsv", sample=config["Samples"]),
		toxinpred_results = expand("results/intermediate_files/toxinpred/final/{sample}_toxinpred_results.txt", sample=config["Samples"]),
		final_results = expand("results/final/{sample}_prediction_results.txt", sample=config["Samples"])
 
rule filter_peptides:
	input:
		smorfs = "data/peptides/{sample}.fasta"
	output:
		filt_smorfs = "results/intermediate_files/smorf/{sample}/filt_smorfs.faa"
	params:
		params = config["parameters"]["pep_len_filt"]
	conda:
		"../envs/seqkit.yaml"
	shell:
		"seqkit seq {params.params} {input} > {output}"

rule rmdup_peptides:
	input:
		clean_smorfs = "results/intermediate_files/smorf/{sample}/filt_smorfs.faa"
	output:
		clean_nodup_smorfs = "results/intermediate_files/smorf/{sample}_clean_nodup_smorfs.fasta"
	conda:
		"../envs/seqkit.yaml"
	shell:
		"seqkit rmdup -i -s {input} > {output}"

rule anticp2:
	input:
		clean_nodup_smorfs = "results/intermediate_files/smorf/{sample}_clean_nodup_smorfs.fasta"
	output:
		anticp2_results = "results/intermediate_files/anticancer/anticp2/{sample}/anticp2_results.txt"
	params:
		params = config["parameters"]["anticp2"]
	conda:
		"../envs/anticp2.yaml"
	shell:
		"anticp2 -i {input} -o {output} {params.params}"

rule get_conACP:
	output:
		repo = "resources/conACP/inf.py"
		
	shell:
		"""
		if [ ! -d {output.repo} ]; then 
		git clone https://github.com/bzlee-bio/con_ACP.git resources/conACP
		fi
		"""

rule conACP:
	input:
		clean_nodup_smorfs = "results/intermediate_files/smorf/{sample}_clean_nodup_smorfs.fasta",
		repo = "resources/conACP/inf.py"
	output:
		conacp_results="results/intermediate_files/anticancer/cACP/{sample}/cACP_results.txt"
	conda:
		"../envs/conacp.yaml"
	shell:
		"""
		cd resources/conACP
		python inf.py --input ../../{input.clean_nodup_smorfs} --output ../../{output}
		"""

rule get_acpred_bmf:
	output:
		repo = "resources/acpred/main.sh"
	shell:
		"""
		if [ ! -d {output.repo} ]; then 
		git clone https://github.com/RUC-MIALAB/ACPred-BMF.git resources/acpred
		fi
		"""

rule acpred_bmf:
	input:
		clean_nodup_smorfs = "results/intermediate_files/smorf/{sample}_clean_nodup_smorfs.fasta",
		repo = "resources/acpred/main.sh"
	output:
		results="resources/acpred/result/{sample}_clean_nodup_smorfs_alter_prediction.csv",
		copied=temp("resources/acpred/data/{sample}_clean_nodup_smorfs.fasta")
	conda:
		"../envs/acpred_bmf.yaml"
	shell:
		"""
		rm -f resources/acpred/data/Alternative_test.fasta
		cp {input} resources/acpred/data
		cd resources/acpred
		bash main.sh alternative
        """

rule move_acpred_results:
	input:
		results="resources/acpred/result/{sample}_clean_nodup_smorfs_alter_prediction.csv"
	output:
		acpred_results="results/intermediate_files/anticancer/acpred/{sample}_clean_nodup_smorfs_alter_prediction.csv"
	shell:
		"mv {input} {output}"

rule combine_predictions:
	input:
		anticp2="results/intermediate_files/anticancer/anticp2/{sample}/anticp2_results.txt",
		cacp="results/intermediate_files/anticancer/cACP/{sample}/cACP_results.txt",
		acpred="results/intermediate_files/anticancer/acpred/{sample}_clean_nodup_smorfs_alter_prediction.csv"
	output:
		filt_combined_predictions="results/intermediate_files/anticancer/{sample}_combined_predictions_filtered.tsv"
	params:
		params = config["parameters"]["min_consensus_pred"]
	conda:
		"../envs/R.yaml"
	shell:
		"Rscript workflow/scripts/combine_predictions.R {input.anticp2} {input.cacp} {input.acpred} {output} {params.params}"

rule cut_final_peptides:
	input:
		filt_combined_predictions="results/intermediate_files/anticancer/{sample}_combined_predictions_filtered.tsv"
	output:
		peptide_list=temp("results/intermediate_files/toxinpred/{sample}/{sample}_peptide_list.txt")
	shell:
		"""
		cut -f1 {input} | sed '1d' > {output}
		"""

rule toxinpred:
	input:
		peptide_list="results/intermediate_files/toxinpred/{sample}/{sample}_peptide_list.txt"
	output:
		toxtemp_results="results/intermediate_files/toxinpred/{sample}/{sample}_toxtemp_results.txt"
	resources:
		slot=1
	conda:
		"../envs/toxinpred.yaml"
	shell:
		"toxinpred3 -d 2 -i {input} -o {output}"

rule add_peptide_seqs_toxinpred:
	input:
		i1 = "results/intermediate_files/toxinpred/{sample}/{sample}_peptide_list.txt",
		i2 = "results/intermediate_files/toxinpred/{sample}/{sample}_toxtemp_results.txt"
	output:
		tox_results="results/intermediate_files/toxinpred/final/{sample}_toxinpred_results.txt"
	shell:
		"""
		awk -F',' 'NR==FNR {{seq[FNR] = $0; next}} 
			{{if (FNR==1) print; else {{$1 = seq[FNR-1]; print }} }}' OFS=',' {input.i1} {input.i2} > {output}
		"""

rule merge_predictions:
	input:
		acp_predictions="results/intermediate_files/anticancer/{sample}_combined_predictions_filtered.tsv",
		tox_results="results/intermediate_files/toxinpred/final/{sample}_toxinpred_results.txt"
	output:
		final_results="results/final/{sample}_prediction_results.txt"
	conda:
		"../envs/R.yaml"
	shell:
		"Rscript workflow/scripts/merge_predictions.R {input.acp_predictions} {input.tox_results} {output}"

