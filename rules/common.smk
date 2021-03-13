# https://stackoverflow.com/questions/58848521/how-to-use-dict-value-and-key-in-snakemake-rules
# [f"{key}/{value[3]}_file.txt" for key, values in systems.items() for value in values]


rule clean:
#! clean            : Removes all the files made by the workflow.
#!                    Do NOT use this if you care about input files or the
#!                    concatenated trajectories!
#!
    run:
        # Properly select the analysis paths without using a wildcard
        # for key, values in systems.items():
        #     # Use the `-f` flag to silence the warning if it's not there
        #     shell("rm -f analysis/{key}/cpptraj*")
        # Use the `-rf` flags to remove the directories and silence if not there
        shell("rm -rf analysis/")

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

