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
* clone the cellranger pipeline code from github: `git clone https://github.com/Mar111tiN/cellrangersnake.git && cd cellrangersnake`
* create the mamba-environment to run snakemake pipeline with cellranger: `mamba create -n cellranger-env -f env_Linux/snake-env.yml`
* activate environment: `mamba activate cellranger-env`
* copy the conda config file `.condarc` to your home folder to apply conda settings and channels required for snakemake to work properly: `cp settings/.condarc ~`
* alternatively, set conda channel priority to strict and use the channels from the `settings/.condarc`file to your preexisting conda config

### Install cellranger Software Suite and Accessories
* Download and install cellranger software (follow instructions in [official download page](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest))
  + cellranger is under licence and needs to be downloaded from the official page
* extract downloaded software bundle: `tar -xzvf cellranger-7.0.1.tar.gz && mv cellranger-7.0.1 `<target_path>
* make cellranger executables accessible to your environment. There are two options:
  + add to PATH: 
    * For global access, add `export PATH=<target_path>/bin:$PATH` to your .bash_profile (<target_path> being the folder containing the extracted cellranger bundle)
    * For exclusive access from your environment run: `conda env config vars set PATH=<target_path>/bin:$PATH`
  + set a symlink to your conda environment: `ln -s <target_path>/bin/cellranger ${CONDA_PREFIX}/bin/cellranger`
* Download and install bundled cellranger reference data (including Star-Index, transcriptome data etc ([official download page](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest))
  + data is large (17GB for hg38) and recommended to be stored on a central static data folder on cluster for shared access (group folder etc.): `tar -xzvf <ref-data>`
  + set the `<ref-data>`-folder as transcriptome_path in config/cellranger_config.yml (absolute path or relative to the static path set in the main config file)


## Setup a run
The cellrangersnake pipeline is controlled globally by the config yaml-file you can edit with a simple text-editor. Here, you basically set the paths to the data, output folder and required setup files and link your cellranger settings via the `cellranger_config.yml` yaml file. Please see the test_config.yml in the test folder. These setup files are:

+ ### the Seqexcel file
  * A master excel file containing all the required info for running the pipeline. Best look at the test file provided for the test run. All required fields are shaded green. 

+ ### ADT file
  * A file listing the ADT-antibodies for each run. 

## Test the Pipeline
* for testing, I provide testdata as dropbox links for you to download by running these commands:
  + move to/create target folder for storing 3Gb of fastq files for testrun
  + `wget https://www.dropbox.com/s/fictlpunkpumxpx/testdata.tar?dl=1 && tar -xvf testdata.tar && rm testdata.tar``
  + the path containing the fastq files `<target_folder>/cellrangertestdata` has to be set in the excel Seqexcel file in the SeqAnalysis sheet for each sample you want to run
* the downloaded bam folder contains bam files of AML tumor normal pairs in three different sizes (500MB to 25GB)
* the bam files are derived from exom-sequenced samples that have been prepped using the Agilent SureSelect XT-HS kit with HumanAllExome_v7 baits

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