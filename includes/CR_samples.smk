import os
import pandas as pd
import numpy as np

def read_seqexcel_sheet(sample_excel, sheet=""):
    '''
    reads the sheet of the sequencing excel table and converts the column headers
    '''
    
    # get the df 
    df = pd.read_excel(sample_excel, sheet_name=sheet).loc[:, lambda s: ~s.iloc[0].isna()]
    col_df = df.T.reset_index().iloc[:, :2].rename({'index':"main", 0:"name"}, axis=1)
    col_df.loc[col_df['main'].str.startswith("Unnamed"), "main"] = np.nan
    col_df['main'] = col_df['main'].fillna(method="ffill").fillna("").str.replace(" ", "")
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
    # test for existence of sample_sheet
    sample_sheet = get_path('sample_sheet', config=config, base_folder=snakedir)
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


def make_ADT_files(sc_df):
    '''
    create a unique ADT file for each run in the sc_df
    '''
    if not os.path.isdir("ADT_files"):
        os.mkdir("ADT_files")
    runs = []
    for run in sc_df.loc[sc_df['library_type'] == "Antibody Capture", 'Run'].unique():
        adf_excel = get_path('ADT_file', file_type="ADT excel file", config=config, base_folder=snakedir)
        adf = get_adf(run, adf_excel)
        runs.append(str(run))
        adf.to_csv(get_ADT_path(run), sep=",", index=False)
    show_output(f"Created ADT feature files for runs {', '.join(runs)}", color="success")
