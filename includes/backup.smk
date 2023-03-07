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


def read_seqexcel_sheet(sample_excel, sheet=""):
    '''
    reads the sheet of the sequencing excel table and converts the column headers
    '''
    
    # get the df 
    df = pd.read_excel(sample_excel, sheet_name=sheet).loc[:, lambda s: ~s.iloc[0].isna()]
    col_df = df.T.reset_index().iloc[:, :2].rename({'index':"main", 0:"name"}, axis=1)
    col_df.loc[col_df['main'].str.startswith("Unnamed"), "main"] = np.nan
    col_df['main'] = col_df['main'].fillna(method="ffill").fillna("")
    col_df.loc[:, "col"] = col_df['name'].str.cat(others=col_df['main'], sep="-").str.rstrip("-")
    cols = col_df['col']
    df.columns = cols
    df = df.iloc[1:, :].reset_index(drop=True)
    df = df.loc[lambda r: ~r['SampleInfo'].isna(), :]
    return df


def make_scRNA_df(config):
    '''
    creates from all single cell infos in the sample_excel a condensed library_df
    '''
    
    sample_excel = get_path('Seqexcel', file_type="sequencing overview", config=config)
    # load the analysis_df for fastq-path and
    dfs = {}
    for sheet in ['SeqAnalysis', 'Status']:
        df = read_seqexcel_sheet(sample_excel, sheet=sheet)
        col_dict = {col:col.replace("-SingleCell", "") for col in df.columns if col.endswith("SingleCell")}
        dfs[sheet] = df.loc[:, col_dict.keys()].rename(col_dict, axis=1).reset_index(drop=True).loc[lambda x: x['Sample'].notna(), :]
        dfs[sheet] = dfs[sheet].drop(['type', 'SeqStatus'], axis=1)
    
    dfs['SeqAnalysis'] = dfs['SeqAnalysis'].loc[lambda x: x['Preprocess'] == 0, :]
    # get the Library df

    df = read_seqexcel_sheet(sample_excel, sheet="Libraries")
    df.columns = [col.replace("-SingleCell", "") for col in df.columns]
    cols = df.columns
    for c in ['conc', 'FragSize', 'Index']:
        cols = [col for col in cols if not c in col]
    df = df.loc[:, cols]

    #extract the GEX and FB dataframes and concat
    dc = {
        "GEX":"Gene Expression",
        "FeatureBarcode": "Antibody Capture"
    }

    for c in dc.keys():
        cols = ['Sample'] + [col for col in df.columns if col.endswith(c)]
        dfs[c] = df.loc[df[f'BIMSB-ID-{c}'].notna(), cols].rename({col:col.replace(f"-{c}", "") for col in df.columns}, axis=1)
        dfs[c]['library_type'] = dc[c]
    dfs['Lib'] = pd.concat([dfs['GEX'], dfs['FeatureBarcode']]).sort_values("Sample")
    dfs['Lib'][:3]
    df = dfs['Status'].loc[:, [
        'Sample', 'Date', 'scProject'
    ]].merge(dfs['SeqAnalysis'].loc[:, [
        'Sample', 'fastq-path'
    ]], on=['Sample']).merge(dfs['Lib']).rename({'fastq-path':'fastqs'}, axis=1)
    
    # convert fields
    # Run field for use in ADT setup
    df['Run'] = df['Date'].astype(str).str.split(" ").str[0].str.replace("^20", "", regex=True).str.replace("-", "", regex=False)
    df['sample'] = df['Pool-ID'] + "_" + df['scProject'] + "_" + df['BIMSB-ID'].astype(str).str.zfill(3) + "_" + df['Sample']
    df.loc[:, 'sample'] = df['sample'].str.lstrip("_").str.replace("__", "_")
    return df.loc[:, ['Sample', 'sample', 'fastqs', 'Run', 'library_type']].set_index("Sample")