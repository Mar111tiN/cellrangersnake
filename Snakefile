from yaml import CLoader as Loader, load, dump

# extract the scriptdir for creating shell_paths
snakedir = os.path.dirname(workflow.snakefile)
scriptdir = os.path.join(snakedir, "scripts")

# add py folder to sys.path for function loading
sys.path.append(os.path.join(scriptdir, "py"))
from CR_samples import make_scRNA_df, make_ADT_files
from script_utils import *

# ############ SETUP ##############################
configfile: "configs/lenaTCR1local_config.yml"

# setup the working directory
workdir: config['paths']['output_path']



# load the sample independent config file
config = add_config(config, config_name="CR_config", snakedir=snakedir)

# print(config)

# retrieve the file_df with all the file paths from the samplesheet
sample_df = make_scRNA_df(config, base_folder=snakedir)

# create the ADT files for feature barcoding 
make_ADT_files(sample_df, config=config, base_folder=snakedir)

# ############ INCLUDES ##############################  
include: "includes/CR.smk"


rule all:
    input: 
        expand("lib_files/library_{sample}.csv", sample=sample_df.index)
        # expand("cellranger/{sample}.done", sample=sample_df.index)
