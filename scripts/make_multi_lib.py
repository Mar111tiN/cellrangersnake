import os
import sys

# add py folder to sys.path for function loading
sys.path.append(os.path.join(snakemake.scriptdir, "py"))

from CR_samples import make_multi_lib_file

def main(s):
    """
    ############## snakemake wrapper ################################
    """

    w = s.wildcards
    p = s.params

    make_multi_lib_file(p.samples, sample=str(w.sample), filepath=str(s.output), run_config=s.config)


if __name__ == "__main__":
    main(snakemake)