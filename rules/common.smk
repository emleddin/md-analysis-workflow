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
n_aa = config["NUM_AA"]
p1 = config["START_PROD_RANGE"]
p2 = config["END_PROD_RANGE"]
div = config["TIME_DIVIDER"]
sim_time = config["SIM_TIME"]

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


def gnuplot_rms(outfile, tag, fs, div, start_residue, end_residue, sys, files):
    """Create a gnuplot script for plotting RMSD, RMSF, and number of hbonds
    for all replicates of a system.

    Parameters
    ----------
    outfile : str
        The name of the output gnuplot script.
    sys_tag : str
        Specifies the inital title information for the input data files.
    file_sep : str
        Determines the separator to use for the file name.
    start_residue : int
        The initial residue for RMSF by-residue plot.
    end_residue : int
        The final residue for RMSF by-reside plot.
    sys : str
        The system to make the plot for.
    files : list
        A list of the replicates for a given `sys`.

    Returns
    -------
    outfile : gnuplot
        The input script for gnuplot.

    Notes
    -----
    You cannot use line smoothing with matplotlib, which is why you'd go
    through the hassle for gnuplot.
    The gnuplot output are explicitly named and written to using EPS format.
    EPS does a better job of determining where information should go instead
    of directly saving as a PNG.
    """
    f = open(outfile, "w+")
    f.write('set encoding iso_8859_1\n')
    f.write('set term postscript enhanced color font "Arial,24";\n\n')
    # Explicitly set the color scheme https://personal.sron.nl/~pault/
    f.write('set linetype 1 lc rgb "#332288" lw 2 pt 1\n')
    f.write('set linetype 2 lc rgb "#88CCEE" lw 2 pt 2\n')
    f.write('set linetype 3 lc rgb "#44AA99" lw 2 pt 3\n')
    f.write('set linetype 4 lc rgb "#117733" lw 2 pt 4\n')
    f.write('set linetype 5 lc rgb "#999933" lw 2 pt 5\n')
    f.write('set linetype 6 lc rgb "#cc6677" lw 2 pt 6\n')
    f.write('set linetype 7 lc rgb "#882255" lw 2 pt 7\n')
    f.write('set linetype 8 lc rgb "#aa4499" lw 2 pt 8\n')
    f.write('set linetype cycle 8\n')
    f.write('\n\n')
    f.write('set xlabel "Time (ns)"\n')
    f.write('set ylabel "RMSD ({\\305})"\n')
    f.write('set key left bottom Left reverse\n\n')
    f.write(f"set output \"../../analysis/RMS/{tag}{fs}{sys}{fs}rmsds.eps\";\n")
    counted = False
    for rep in range(len(files)):
        # Deal with only one graph
        if len(files) == 1:
            f.write(f"plot \"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}total{fs}bb{fs}rms.dat\" u ($1/{div}):($2) w lines s bezier t \"{files[rep]}\" lw 4;\n")
        # Plot first if multiple
        elif counted == False:
            f.write(f"plot \"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}total{fs}bb{fs}rms.dat\" u ($1/{div}):($2) w lines s bezier t \"{files[rep]}\" lw 4, \\\n")
            counted = True
        # Deal with final case
        elif files[rep] == files[-1]:
            f.write(f"\"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}total{fs}bb{fs}rms.dat\" u ($1/{div}):($2) w lines s bezier t \"{files[rep]}\" lw 4;\n")
        # Use line without plot and with continuation if 1) not only,
        # 2) not first, and 3) not last
        else:
            f.write(f"\"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}total{fs}bb{fs}rms.dat\" u ($1/{div}):($2) w lines s bezier t \"{files[rep]}\" lw 4, \\\n")
    # Start Number of Hydrogen Bonds
    f.write('\n')
    f.write('set xlabel "Time (ns)"\n')
    f.write('set ylabel "Number of hydrogen bonds"\n')
    f.write(f"set output \"../../analysis/RMS/{tag}{fs}{sys}{fs}hbonds.eps\";\n")
    counted = False
    for rep in range(len(files)):
        # Deal with only one graph
        if len(files) == 1:
            f.write(f"plot \"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}hbond.dat\" u ($1/{div}):($2) w lines s bezier t \"{files[rep]}\" lw 4;\n")
        # Plot first if multiple
        elif counted == False:
            f.write(f"plot \"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}hbond.dat\" u ($1/{div}):($2) w lines s bezier t \"{files[rep]}\" lw 4, \\\n")
            counted = True
        # Deal with final case
        elif files[rep] == files[-1]:
            f.write(f"\"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}hbond.dat\" u ($1/{div}):($2) w lines s bezier t \"{files[rep]}\" lw 4;\n")
        # Use line without plot and with continuation if 1) not only,
        # 2) not first, and 3) not last
        else:
            f.write(f"\"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}hbond.dat\" u ($1/{div}):($2) w lines s bezier t \"{files[rep]}\" lw 4, \\\n")
    f.write('\n')
    # Start RMSF
    f.write('set xlabel "Residue number"\n')
    f.write('set ylabel "RMSF ({\\305})"\n')
    f.write('set key top left Left reverse\n')
    f.write(f'set xrange [{start_residue}:{end_residue}]\n')
    f.write(f"set output \"../../analysis/RMS/{tag}{fs}{sys}{fs}rmsf.eps\";\n")
    counted = False
    for rep in range(len(files)):
        # Deal with only one graph
        if len(files) == 1:
            f.write(f"plot \"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}rmsf{fs}byres.dat\" u 1:2 w lines t \"{files[rep]}\" lw 4;\n")
        # Plot first if multiple
        elif counted == False:
            f.write(f"plot \"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}rmsf{fs}byres.dat\" u 1:2 w lines t \"{files[rep]}\" lw 4, \\\n")
            counted = True
        # Deal with final case
        elif files[rep] == files[-1]:
            f.write(f"\"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}rmsf{fs}byres.dat\" u 1:2 w lines t \"{files[rep]}\" lw 4;\n")
        # Use line without plot and with continuation if 1) not only,
        # 2) not first, and 3) not last
        else:
            f.write(f"\"../../analysis/{sys}/{files[rep]}/{tag}{fs}{sys}{fs}rmsf{fs}byres.dat\" u 1:2 w lines t \"{files[rep]}\" lw 4, \\\n")
    f.write('\n')
    f.close()
