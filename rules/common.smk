# https://stackoverflow.com/questions/58848521/how-to-use-dict-value-and-key-in-snakemake-rules
# [f"{key}/{value[3]}_file.txt" for key, values in systems.items() for value in values]

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
qsub = config["SUB_C"]
t_ext = config["CUR_TRAJ_EXT"]
que = config["QUEUE"]

start_res = config["START_RES_RANGE"]
end_res = config["END_RES_RANGE"]
p1 = config["START_PROD_RANGE"]
p2 = config["END_PROD_RANGE"]

# --------------------------------- Functions ---------------------------------#

def get_val(var, sys_dict = systems, eda_dict = eda_vals):
    """Get values for the EDA input file based on the system/replicate.

    Parameters
    ----------
    var : int
        The column index variable for the converted EDA dictionary.
    sys_dict : dict
        Dictionary of system and replicate info generated from the
        systems.tsv file.
    eda_dict : dict
        Dictionary of EDA atom and residue info generated from the
        EDAvalues.tsv file.

    Returns
    -------
    val : str
        The associated value from the eda_dict.

    Notes
    -----
    This function is critical for looping through the rule correctly.
    """
    for key in sys_dict.keys():
        val = eda_dict.get(key)[var]
    return val

def get_crd(sys_dict = systems, file_sep = fs, sys_tag = tag, prod1 = p1, prod2 = p2):
    """Get values of mdcrd for the EDA input file based on the system/replicate.

    Parameters
    ----------
    sys_dict : dict
        Dictionary of system and replicate info generated from the
        systems.tsv file.
    file_sep : str
        Determines the separator to use for the file name.
    sys_tag : str
        Specifies the inital title information for the output mdcrd.
    prod1 : int
        Initial value of the production trajectory files for clear labelling.
    prod2 : int
        Final value of the production trajectory files for clear labelling.

    Returns
    -------
    crd : str
        The relative path and name of the EDA mdcrd.

    Notes
    -----
    This function is critical for looping through the rule correctly.
    """
    for key, values in sys_dict.items():
        for value in values:
            crd = (f"{sys_tag}{file_sep}{value[0]}{file_sep}{prod1}-{prod2}.mdcrd")
    return crd

