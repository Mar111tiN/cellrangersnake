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
    threads:
        config['cellranger']['threads']
    output:
        "cellranger/{sample}.done"
    params:
        transcripts=static_path(config['cellranger']['transcriptome_path']),
        feature_ref=ADT_CLI
    shell:
        "cellranger count --localcores {threads} --id={wildcards.sample} --libraries=lib_files/library_{wildcards.sample}.csv "
        "--transcriptome={params.transcripts}{params.feature_ref}; "
        "rm {wildcards.sample}/_*; "
        "rm -r {wildcards.sample}/SC_RNA_COUNTER_CS; "
        "touch cellranger/{wildcards.sample}.done"