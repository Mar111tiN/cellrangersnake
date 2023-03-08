from script_utils import *
import os
import pandas as pd
import numpy as np


def make_scRNA_df(config, **kwargs):
    '''
    creates from all single cell infos in the sample_excel a condensed library_df
    '''
    # test for existence of sample_sheet
    sample_sheet = get_path('sample_sheet', config=config, **kwargs)
    if sample_sheet:
        sample_df = pd.read_csv(sample_sheet, sep="\t").set_index('Sample')
        show_output(f"Using sample sheet {config['paths']['sample_sheet']}")
        print(sample_df)
        return sample_df


def get_adf(run, ADT_excel=""):
    '''
    extract the adt_feature reference csv for a given run date
    '''
    
    adf = pd.read_excel(ADT_excel, sheet_name=str(run))
    adf=adf.loc[:, ['Gene','Barcode']].rename({'Gene': 'id', 'Barcode': 'sequence'}, axis=1)
    adf.loc[:, ['name']] = adf['id'] + '_ADT'
    adf.loc[:, ['read', 'pattern', 'feature_type']] = ['R2', '5PNNNNNNNNNN(BC)NNNNNNNNN', 'Antibody Capture']
    return adf

def get_ADT_path(run):
    '''
    path getter
    '''
    return f"ADT_files/ADT_{run}.csv"


def make_ADT_files(sc_df, **kwargs):
    '''
    create a unique ADT file for each run in the sc_df
    '''
    if not os.path.isdir("ADT_files"):
        os.mkdir("ADT_files")
    runs = []
    CITEseq_runs = sc_df.loc[sc_df['library_type'] == "Antibody Capture", 'Run'].unique()
    # check if Antibody Capture has been used
    if len(CITEseq_runs):
        for run in CITEseq_runs:
            adf_excel = get_path('ADT_file', file_type="ADT excel file", **kwargs)
            adf = get_adf(run, adf_excel)
            runs.append(str(run))
            adf.to_csv(get_ADT_path(run), sep=",", index=False)
        show_output(f"Created ADT feature files for runs {', '.join(runs)}", color="success")


def make_lib_file(sc_df, sample="", filepath=""):
    '''
    create the files for the cellranger run
    '''
    lib_df =  sc_df.query('index == @sample').loc[:, ['fastqs', 'sample', 'library_type']]
    lib_df.to_csv(filepath, sep=",", index=False)
    return lib_df


def get_read(_type, config):
    '''
    returns the read-string for each library type
    '''
    return [f"{read.lower()}-length,{length}\n" for read, length in config['cellranger']['Reads'][_type].items()]


def get_CRargs(config, tool="cellranger"):
    CRargs = config['cellranger']['args']
    return [arg.replace("--", "").replace("=", ",").replace(" ", ",") + "\n" for arg in CRargs]


def get_CRmulti_args(config):
    CRargs = config['CRmulti_args']['args']
    return [arg.replace("--", "").replace("=", ",").replace(" ", ",") + "\n" for arg in CRargs]


def make_multi_lib_file(sc_df, sample="", filepath="", config={}):
    '''
    the sample sheet writer combining a library_df and info from config into a valid MiniSeq sample sheet
    '''
    
    libs_df = sc_df.loc[sample]
    c = config['cellranger']
    # write to file
    with open(filepath, 'w') as f:
        if 'Gene Expression' in libs_df['library_type'].values:
            #write the GEX config
            f.write('[gene-expression]\n')
            f.write(f"reference,{static_path(c['transcriptome_path'], config)}\n")
            f.writelines(get_read('GEX', config))
            f.writelines(get_CRargs(config))

        if "Antibody Capture" in libs_df['library_type'].values:
            # write the Feature config
            f.write('\n[feature]\n')
            # get the ADT run from libs_df
            run = libs_df.loc[libs_df['library_type'] == "Antibody Capture", 'Run'][0]
            f.write(f"reference,{get_ADT_path(run)}\n")
            f.writelines(get_read("FeatureBarcode", config))
            
            
        if 'TCR' in libs_df['library_type'].values:
            # write the VDJ config
            f.write('\n[vdj]\n')
            f.write(f"reference,{static_path(c['VDJ_ref'], config)}\n")
            f.writelines(get_read("TCR", config))
        libs_df = libs_df.rename({
            'sample':'fastq_id',
            'library_type':'feature_types'
        }, axis=1).loc[:, ['fastq_id', 'fastqs', 'feature_types']]
        # write the libraries 
        f.write('\n[libraries]\n')        
        libs_df.to_csv(f, index=False)
    show_output(f"Sample sheet written to {filepath}", color="success")
    return libs_df