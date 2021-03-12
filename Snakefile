# This is the starting point of the workflow
# Use `snakemake -n --dry-run` to test

# `snakemake --forceall --dag | dot -Tpdf > dag.pdf`
# Will create a PDF of how it thinks your workflow links together

# You can test deleting output from snakemake with:
# snakemake cpptraj_write --delete-all-output --dry-run
# And actually do it with:
# snakemake cpptraj_write --delete-all-output --cores 1

# TODO: Check tags!!!

configfile: "config/config.yaml"

import os
import pandas as pd

# Require 6.0 because you haven't tried any others...
from snakemake.utils import min_version
min_version("6.0")

## Get the root directoy for the files
cwd = os.getcwd()

# Read the table of systems and turn into a dictionary
# Note: The [] around the tuple are VERY IMPORTANT for indexing
systems_df = pd.read_csv(config["SYSTEMS"], sep='\t')
systems = dict([(t.Path, [(t.System, t.Replicate, t.Parm_Path, t.Sys_Tag)])
                for t in systems_df.itertuples()])

# Read the table of EDA values and turn into a dictionary
# Note: It's VERY IMPORTANT to not have the [] around for indexing
eda_df = pd.read_csv(config["EDAVALS"], sep='\t')
eda_vals = dict([(t.Path, (t.NRES, t.NATOM, t.NPROTAT, t.TOTRES))
                 for t in eda_df.itertuples()])

# Set the config variables as shorthand
fs = config["F_SEP"]
tag = config["PROJ_TAG"]
post_e = config["PROJ_PE"]
t_ext = config["CUR_TRAJ_EXT"]
que = config["QUEUE"]
start_res = config["START_RES_RANGE"]
end_res = config["END_RES_RANGE"]
p1 = config["START_PROD_RANGE"]
p2 = config["END_PROD_RANGE"]

include: "rules/common.smk"
include: "rules/eda.smk"
include: "rules/figs.smk"
include: "rules/hba.smk"
include: "rules/cpptraj.smk"

rule all:
    input:
        # `systems`
        # Key = the output path
        # value[0] = system
        # value[1] = replicate
        # value[2] = prm_path
        # value[3] = system tag
        # Prmtop is required for everything
        [f"{value[2]}/{tag}{fs}{value[0]}{post_e}.prmtop" for
            sys_rep_dir, values in systems.items() for value in values],
        # Cpptraj input files
        [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.sh" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.in" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/cpptraj{fs}analysis.sh" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/cpptraj{fs}analysis.in" for
         sys_rep_dir, values in systems.items() for value in values],
        # Cpptraj output files
        [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}imaged{fs}{p1}-{p2}.nc" for
              sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/EDA/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}{p1}-{p2}.mdcrd" for
         sys_rep_dir, values in systems.items() for value in values],
        # Cpptraj analysis files
        [f"analysis/{sys_rep_dir}/test{fs}rms.dat" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}corr{fs}mat.dat" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}covar{fs}mat.dat" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}evecs.out" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}100.nmd" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}hbond{fs}avg.dat" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}total{fs}bb{fs}rms.dat" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}rmsd{fs}byres.dat" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}rmsf{fs}byres.dat" for
         sys_rep_dir, values in systems.items() for value in values],
        # `eda_vals`
        # Key = the output path
        # value[0] = NRES
        # value[1] = NATOM
        # value[2] = NPROTAT
        # value[3] = TOTRES
        # EDA (new version)
        [f"analysis/EDA/{sys_rep_dir}/fort_sanity_check.txt" for
         sys_rep_dir in systems.keys()],
        [f"analysis/EDA/{sys_rep_dir}/fort_coulomb_interaction.dat" for
         sys_rep_dir in systems.keys()],
        [f"analysis/EDA/{sys_rep_dir}/fort_vdw_interaction.dat" for
         sys_rep_dir in systems.keys()],
        # EDA legacy version use
        # [f"analysis/EDA/{sys_rep_dir}/fort.804" for
        #  sys_rep_dir in systems.keys()],
        # [f"analysis/EDA/{sys_rep_dir}/fort.803" for
        #  sys_rep_dir in systems.keys()],
        # [f"analysis/EDA/{sys_rep_dir}/fort.806" for
        #  sys_rep_dir in systems.keys()]
        # Matrix Correlation
        [f"analysis/MatCorr/{tag}{fs}{value[0]}{fs}{value[1]}{fs}mat{fs}corr.png" for
         key, values in systems.items() for value in values],
        # Normal Modes
        [f"analysis/NMA/{tag}{fs}{value[0]}{fs}{value[1]}{fs}NMA.png" for
         key, values in systems.items() for value in values],