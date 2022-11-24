import os
import sys

# add ebscore package to sys.path
sys.path.append(os.path.join(snakemake.scriptdir, "py"))

from CR_samples import make_lib_file

def main(s):
    """
    ############## snakemake wrapper ################################
    """

    w = s.wildcards
    p = s.params

    make_lib_file(p.samples, sample=str(w.sample), filepath=str(s.output))


if __name__ == "__main__":
    main(snakemake)