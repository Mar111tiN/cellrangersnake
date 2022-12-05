# Pipeline for preprocessing of scRNA-seq raw data with the cellranger pipeline

* uses a summary excel sheet for performing the cellranger analysis
* SLURM cluster environments

## Setup

### Prerequisites
* linux environment
* package manager conda is installed (see [mambaforge/miniforge git repo](https://github.com/conda-forge/miniforge#mambaforge) for instructions)
* package manager conda is deprecated for performance reasons but can be used as well installed (see [official conda documentation](https://conda.io/projects/conda/en/latest/user-guide/install/linux.html) for instructions)

### Install cellrangersnake pipeline
* move to destination folder for pipeline code
* clone the somVarWES code from github: `git clone https://github.com/Mar111tiN/cellrangersnake.git && cd cellrangersnake`
* create the mamba-environment to run snakemake pipeline with cellranger: `mamba create -n cellranger-env -f env_Linux/snake-env.yml`
* activate environment: `mamba activate cellranger-env`
* copy the conda config file `.condarc` to your home folder to apply conda settings and channels required for snakemake to work properly: `cp settings/.condarc ~`

### Install cellranger Software Suite and Accessories
* Download and install cellranger software (follow instructions in [official download page](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest))
  + cellranger is under licence and needs to be downloaded from the official page
* extract software: `tar -xzvf cellranger-7.0.1.tar.gz && mv cellranger-7.0.1 `<target_path>
* make cellranger executables accessible to your environment. There are two options:
  + add to PATH: 
    * For global access run: `export PATH=<target_path>/bin:$PATH` 
    * For exclusive access from your environment run: `conda env config vars set PATH=<target_path>/bin:$PATH`
  + set a symlink to your conda environment: `ln -s <target_path>/bin/cellranger ${CONDA_PREFIX}/bin/cellranger`
* Download and install bundled cellranger reference data (including Star-Index, transcriptome data etc ([official download page](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest))
  + data is large (17GB for hg38) and recommended to be stored centrally on cluster for shared access (group folder etc.): `tar -xzvf <ref-data>`
  + set the `<ref-data>`-folder as transcriptome_path in config/cellranger_config.yml


## Test the Pipeline
* for testing, I provide testdata as dropbox links for you to download by running simple scripts
* the downloaded bam folder contains bam files of AML tumor normal pairs in three different sizes (500MB to 25GB)
* the bam files are derived from exom-sequenced samples that have been prepped using the Agilent SureSelect XT-HS kit with HumanAllExome_v7 baits


### create static files for cell ranger
* for the pipeline to work for bam files created with this specific exon prep, several database files and other accessory data have to be prepared
* for testing (and for general use with SureSelect HAEv7 data), static data is provided as dropbox links
* run the script download_static.sh with the path to the desired static folder (50GB of space is required) as argument:
```
$ . setup/download_static.sh <path-to-static-folder>
```
* adjust \<STATIC\> to the desired path and provide a working directory (\<WKDIR\>) in the yaml config file configs/general/config_testgeneral.yaml

### get the annovar executables
* most tools used by the pipeline are provided as packages and are installed via the init.sh script
* However, the tool annovar used for populating mutation lists with data from multiple databases has to be downloaded [here](https://www.openbioinformatics.org/annovar/annovar_download_form.php) upon signing a user agreement
* after downloading the annovar executables, provide the path to the folder containing the annovar perl scripts (\<ANNOPATH\>) in the TOOLS section of configs/general/config_testgeneral.yaml 

### run the test
* for testing all bam files (small to large) make the config/config_test.yaml the active config which is used by the pipeline masterfile Snakefile:
```
$ cp configs/config_test.yaml configs/active_config.yaml
```
* now, you can test the pipeline either interactively or via job submission:
  + from an interactive slurm-session with >20 cores go to the somVarWES root folder and run: 
    ```
    $ conda activate snake-env
    $ snakemake -prj 20 --use-conda
    ```
  + as batch job from the somVarWES root folder:
    ```
    $ sbatch -J testing SLURM.sh
    ```
* either way, the pipeline will first install all conda environments into your workdir in .snakemake folder and then start the pipeline
* depending on cluster traffic, this can initially take 30 min or more!