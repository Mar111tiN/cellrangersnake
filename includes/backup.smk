############# SNAKEFILE ###########################
def get_files(config={}):
    '''
    retrieves the path to all the files in the sample_sheet
    if rerun == False, it looks for fastq files
    if rerun == True, it looks for bam files
    '''

    # retrieve the info from the config
    input_folder, sample_sheet = config['inputdir'], config['samples']['samplesheet']
    
    # check full path or append path to scriptdir
    if not sample_sheet.startswith('/'):
        sample_sheet = os.path.join(snakedir, sample_sheet)
    # import the sample sheet
    sample_df = pd.read_csv(sample_sheet, sep='\t').set_index('sample')

    # add the full path
    sample_df.loc[:,"full_path"] = input_folder + os.sep + sample_df["path"]
    if (build:=config['samples']["genome_build"]):
        sample_df.loc[:,"full_path"] = sample_df["full_path"] + os.sep + build
    return sample_df


def get_sample_path(w):
    return sample_df.loc[w.sample, "full_path"]


def get_chrom_list(config):
    """
    returns a list of all valid chromosomes determined by build version
    """

    if "bed_file" in config['ref'][config["ref"]["build"]].keys():
        bed_df = pd.read_csv(full_path('bed_file'), sep="\t", skiprows=3)
        return [chrom for chrom in bed_df.iloc[:,0].unique() if not chrom in ["chrY", "Y"]]
    # switch for use of "chr"-prefix
    chrom = "chr" if config["ref"]["build"] == "hg38" else ""
    return [f"{chrom}{c+1}" for c in range(22)] + ["chrX", "chrY"]



########### GENERAL ##########################


def get_shell(script_name):
    '''
    takes the script_name and returns abspath to shell script located in snakedir/scripts/shell
    '''
    return os.path.join(scriptdir, f"shell/{script_name}")


def full_path(file):

    '''
    returns the full path to a reference if file is relative to ref/hg38|19
    '''

    build = config['ref']['build']
    full_ref_path = os.path.join(config['paths']['static'], config['ref'][build][file])
    return full_ref_path


def get_ref(w):
    '''
    returns the path to the ref genome
    if wildcards contains chrom, the genome split version is returned
    '''

    ## get the wildcard atributes into wcs
    wcs = vars(w)['_names'].keys()
    # get genome split
    if "chrom" in wcs:
        return os.path.join(full_path("genome_split"), f"{w.chrom}.fa")
    else:
        return full_path("genome")

def static_path(file):
    '''
    returns the absolute path when given relative to static folder
    '''

    return os.path.join(config['paths']['static'], file)
