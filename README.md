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
* clone the somVarWES code from github: `$ git clone https://github.com/Mar111tiN/cellrangersnake.git && cd cellrangersnake`
* create the mamba-environment to run snakemake pipeline with cellranger: `mamba env create -n cellranger-env -f env_Linux/snake-env.yml`
* activate environment: `$ mamba activate cellranger-env`
* copy the conda config file `.condarc` to your home folder to apply conda settings and channels required for snakemake to work properly: `cp setup/.condarc ~`

### Install cellranger Software Suite and Accessories
* Download and install cellranger software (follow instructions in [official download page](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest))
  + cellranger is under licence and needs to be downloaded from the official page
* extract software: `$ tar -xzvf cellranger-7.0.1.tar.gz && mv cellranger-7.0.1 `<target_path>
* make cellranger executables accessible to your environment. There are two options:
  + add to PATH: 
    * For global access add `export PATH=<target_path>/bin:$PATH` to your `~/.bash_profile` file 
    * For exclusive access from your environment run: `$ conda env config vars set PATH=<target_path>/bin:$PATH`
  + set a symlink to your conda environment: `$ ln -s <target_path>/bin/cellranger ${CONDA_PREFIX}/bin/cellranger`
* Download and install bundled cellranger reference data (including Star-Index, transcriptome data etc ([official download page](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest))
  + `wget https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2020-A.tar.gz`
  + data is large (17GB for hg38) and recommended to be stored centrally on cluster for shared access (group folder etc.): `$ tar -xzvf refdata-gex*`
  + set the `<ref-data>`-folder as transcriptome_path in config/cellranger_config.yml


## Setup a run
The cellrangersnake pipeline is controlled globally by the config yaml-file you can edit with a simple text-editor. Here, you basically set the paths to the data, output folder and required setup files. These setup files are:

+ ### the CR_config file
  * contains the data pertaining to running the cellranger command line tool
  * ::DEV:: any command-line parameter needed by cellranger should be set here and passed to the cellranger rule `includes/CR.smk` as a snakemake param (see how the feature ref is passed through via `params.feature_ref` as an example)
  * update: specific arguments that need to be passed to running cellranger can be passed as a list of params to the args field in the `cellranger_config.yml`
+ ### the Seqexcel file
  * A master excel file containing all the required info for running the pipeline. It has a complicated structured grown by necessity and sample names and info hase to be set in various fields. Best look at the test file `test_sample_info.xlsx` provided for the test run as a minimal example. All required fields are shaded green:
    + Status Sheet:
      * Sample: the name given to the cellranger output folder (cellranger id)
      * type: either CITE-seq or scRNA-seq.
        + for scRNA-seq, you have to provide the identifier of the corresponding fastq-files in the '10x-GEX-ID' field
        + for CITE-seq, you have to additionally provide the identifier for the FeatureBarcode fastq-files in the '10x-FB-ID' field and a run 'Date' which has to match a sheet in the ADT file (see below)
      * only files with 'SeqStatus' > 3 will be run, so you can easily control the samples that will be run setting this field
      *  'scProject' is optionally used for building the correct fastq-identifiers. fastq-identifiers from the BIMSB are created  `"{Libraries:Pool-ID}_{Status:scProject}_{10x-GEX-ID<3digit>}_{Sample}_*.fastq.gz"` queried from the respective 'SeqAnalysis:fastq-path'. For other naming schemes just leave empty strings for the fields not needed, and the identifier is build from the remaining fields in the above order joined by `_`
    + Libraries Sheet:
      * 'Pool-ID'-field can be optionally set for fastq-identifiers (not required: see above)
    + SeqAnalysis:
      * 'fastq-path': set the folder containing the fastq-files for that sample
  * alternatively, you can use a simple tab-separated sample_sheet formatted as the `test_sample_sheet.csv` in the test folder. Setting a path to such a sample_sheet makes the pipeline ignore the excel sheet. The sample_sheet approach gives you more flexibility for files coming from different paths
+ ### the fastq-files have to be named according to bcl2fastq-convention as `[fastq-identifier]_S1_L00[Lane Number]_[Read Type]_001.fastq.gz`

+ ### ADT file
  * A file listing the ADT-antibodies for each run. For each sample of 'type' CITE-seq, the 'Date' will be converted into a six-digit of form YYMMDD and matched to a sheet of that name in the ADT excel file. This data is used to create a feature ref file for running cellranger. 


## Test the Pipeline
Before running pipelines on the cluster, it is strongly recommended to run the test interactively first. It takes appr. 75 min using 20 cores and 80GB RAM (or appr. 45 min with 140 GB RAM). 
### setup
*  For testing, I provide testdata as dropbox links for you to download by running these commands:
  + move to/create target folder for storing 3Gb of fastq files for testrun
  + `$ wget https://www.dropbox.com/s/fictlpunkpumxpx/testdata.tar?dl=1 && tar -xvf testdata.tar* && rm testdata.tar*`
  + the path containing the fastq files `<target_folder>/cellrangertestdata` has to be set in the SeqAnalysis sheet of the test Seqexcel `test_sample_info.xlsx` using the fastq-path field (only the containing folder is required; can be different for each sample)
* Set the respective paths in the `test_config.yml` and the `cellranger_config.yml`
### run the test
* from the login-node, request an interactive cluster session with sufficient RAM and cores (eg: `$ srun -p long --immediate=120 --time 3:00:00 --cpus-per-task=20 --nodes=1 --mem=140G --pty bash -i`)
* activate the cellranger-env `mamba activate cellranger-env` if not already and move to the root of the cellrangersnake codebase. 
* run the snakemake pipeline locally with 20 cores: `$ snakemake -prj 20 --use-conda --snakefile Snaketest`
* inspect the output data in the <output_path> provided in the `test_config.yml`
* if this was successful, remove the output_path and testrun the pipeline using job submission via SLURM: `$ sbatch -J testCRpipeline SLURMtest.sh`
* monitor the run with `$ squeue --me` and `$ cat slogs/*` and inspect the data after completion
