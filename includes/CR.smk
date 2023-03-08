from CR_samples import get_CRmulti_args


rule make_lib: 
    output:
        "lib_files/library_{sample}.csv"
    params:
        samples=sample_df
    threads:
        1
    script:
        "../scripts/make_multi_lib.py"


rule run_cellranger:
    input:
        "lib_files/library_{sample}.csv"
    threads:
        config['cellranger']['threads']
    output:
        "cellranger/{sample}.done"
    params:
        CRmulti_args=get_CRmulti_args
    shell:
        "cellranger multi --localcores {threads} --id={wildcards.sample} --csv={input} "
        "{params.CRmulti_args}; "
        "touch cellranger/{wildcards.sample}.done"
        # "rm {wildcards.sample}/_*; "
        # "rm -r {wildcards.sample}/SC_RNA_COUNTER_CS; "
