def ADT_CLI(w):
    if "Antibody Capture" in list(sample_df.loc[str(w.sample), "library_type"]):
        run = sample_df.loc[w.sample, "Run"][0]
        adt_file = get_ADT_path(run)
        return f" --feature-ref={adt_file}"
    return ""


def get_CR_args(w):
    '''
    takes additional cellranger arguments from the config list
    '''
    CR_args = config['cellranger']['args']
    return " " + " ".join(CR_args) if len(CR_args) else ""

rule make_lib: 
    output:
        "lib_files/library_{sample}.csv"
    params:
        samples=sample_df
    threads:
        1
    script:
        "../scripts/make_lib.py"


rule run_cellranger:
    input:
        "lib_files/library_{sample}.csv"
    threads:
        config['cellranger']['threads']
    output:
        "cellranger/{sample}.done"
    params:
        transcripts=static_path(config['cellranger']['transcriptome_path']),
        feature_ref=ADT_CLI,
        CR_args=get_CR_args
    shell:
        "cellranger count --localcores {threads} --id={wildcards.sample} --libraries=lib_files/library_{wildcards.sample}.csv "
        "--transcriptome={params.transcripts}{params.feature_ref}{params.CR_args}; "
        "rm {wildcards.sample}/_*; "
        "rm -r {wildcards.sample}/SC_RNA_COUNTER_CS; "
        "touch cellranger/{wildcards.sample}.done"