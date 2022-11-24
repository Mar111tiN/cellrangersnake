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
        adf = get_adf(run, get_path('ADT_file', file_type="ADT excel file", config=config))
        runs.append(run)
        adf.to_csv(get_ADT_path(run), sep=",", index=False)
    show_output(f"Created ADT feature files for runs {', '.join(runs)}", color="success")
