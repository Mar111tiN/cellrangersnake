def ADT_CLI(w):
    if "Antibody Capture" in list(sample_df.loc[str(w.sample), "library_type"]):
        run = sample_df.loc[w.sample, "Run"][0]
        adt_file = get_ADT_path(run)
        return f" --feature-ref={adt_file}"
    return ""

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
    output:
        "cellranger/{sample}.done"
    params:
        transcripts=config['cellranger']['transcriptome_path'],
        feature_ref=ADT_CLI
    shell:
        "echo cellranger count --id={wildcards.sample} --libraries=lib_files/library_{wildcards.sample}.csv --transcriptome={params.transcripts}{params.feature_ref}; "
        "touch cellranger/{wildcards.sample}.done"