from yaml import CLoader as Loader, load, dump

# ############ SETUP ##############################
configfile: "configs/active_config.yaml"


# setup the working directory
workdir: config['workdir']
# extract the scriptdir for creating shell_paths
snakedir = os.path.dirname(workflow.snakefile)
scriptdir = os.path.join(snakedir, "scripts")


# include helper functions
include: "includes/io.snk"
include: "includes/utils.snk"


# load the sample independent config file
config = add_config(config, config_name="qc")

# retrieve the file_df with all the file paths from the samplesheet
sample_df = get_files(config)
print(sample_df)

# ############ INCLUDES ##############################  
include: "includes/qc.snk"


rule all:
    input: expand("{sample}/SCE", sample=sample_df.index)