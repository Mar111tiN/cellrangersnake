from yaml import CLoader as Loader, load, dump

# ############ SETUP ##############################
configfile: "configs/run_config.yml"

# setup the working directory
workdir: config['paths']['output_path']
# extract the scriptdir for creating shell_paths
snakedir = os.path.dirname(workflow.snakefile)
scriptdir = os.path.join(snakedir, "scripts")


# include helper functions
include: "includes/io.smk"
include: "includes/utils.smk"
include: "includes/CR_samples.smk"

# load the sample independent config file
config = add_config(config, config_name="CR_config")

# print(config)

# retrieve the file_df with all the file paths from the samplesheet
sample_df = make_scRNA_df(config)

# export for testing
sample_df.to_csv("info_sample.tsv", sep="\t")

make_ADT_files(sample_df)

# ############ INCLUDES ##############################  
include: "includes/CR.smk"


rule all:
    input: 
        expand("cellranger/{sample}.done", sample=sample_df.index)
