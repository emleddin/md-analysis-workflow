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
systems = dict([(t.Path, [(t.System, t.Replicate, t.Parm_Path, t.Sys_Tag,
                           t.Start_Prod_Range, t.End_Prod_Range, t.Sim_Time)])
                for t in systems_df.itertuples()])

# Read the table of EDA values and turn into a dictionary
# Note: It's VERY IMPORTANT to not have the [] around for indexing
eda_df = pd.read_csv(config["EDAVALS"], sep='\t')
eda_vals = dict([(t.Path, (t.NRES, t.NATOM, t.NPROTAT, t.TOTRES))
                 for t in eda_df.itertuples()])

# Read the table of EDA comparisons and turn into a dictionary
# Note: The [] around the tuple are VERY IMPORTANT for indexing
eda_comp_df = pd.read_csv(config["EDACOMPS"], sep='\t')
eda_comps = dict([(t.SysA_SysB, [(t.SystemA, t.A_Path, t.SystemB, t.B_Path)])
                for t in eda_comp_df.itertuples()])

# Set the config variables as shorthand
fs = config["F_SEP"]
proj_tag = config["PROJ_TAG"]
qsub = config["SUB_C"]
t_ext = config["CUR_TRAJ_EXT"]
que = config["QUEUE"]

start_res = config["START_RES_RANGE"]
end_res = config["END_RES_RANGE"]
n_aa = config["NUM_AA"]
div = config["TIME_DIVIDER"]
roi = config["ROI"]

# --------------------------------- Functions ---------------------------------#
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


def eda_diff_script(outfile, base_script, cwd, tag, fs, ROI, sys, files):
    """Sets up the R script for averaging the EDA data for replicates of a
    system.

    Parameters
    ----------
    outfile : str
        The name of the output gnuplot script.
    base_script : txt
        The file containing the bulk of the R script that's not
        system-dependent.
    cwd : str
        The path to the current working directory.
    tag : str
        Specifies the inital title information for the input data files.
    fs : str
        Determines the separator to use for the file name.
    ROI : int
        The residue of interest for EDA to get the interactions of each residue
        with.
    sys : str
        The system to create the averages for.
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
    for rep in range(len(files)):
        if rep == 0:
            f.write(f'infile1Ac <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort_coulomb_interaction.dat")\n')
            f.write(f'infile1Av <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort_vdw_interaction.dat")\n')
            # f.write(f'infile1Ac <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort.803")\n')
            # f.write(f'infile1Av <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort.806")\n')
        elif rep == 1:
            f.write(f'infile2Ac <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort_coulomb_interaction.dat")\n')
            f.write(f'infile2Av <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort_vdw_interaction.dat")\n')
            # f.write(f'infile2Ac <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort.803")\n')
            # f.write(f'infile2Av <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort.806")\n')
        elif rep == 2:
            f.write(f'infile3Ac <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort_coulomb_interaction.dat")\n')
            f.write(f'infile3Av <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort_vdw_interaction.dat")\n')
            # f.write(f'infile3Ac <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort.803")\n')
            # f.write(f'infile3Av <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort.806")\n')
        elif rep == 3:
            f.write(f'infile4Ac <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort_coulomb_interaction.dat")\n')
            f.write(f'infile4Av <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort_vdw_interaction.dat")\n')
            # f.write(f'infile4Ac <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort.803")\n')
            # f.write(f'infile4Av <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort.806")\n')
        elif rep == 4:
            f.write(f'infile5Ac <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort_coulomb_interaction.dat")\n')
            f.write(f'infile5Av <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort_vdw_interaction.dat")\n')
            # f.write(f'infile5Ac <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort.803")\n')
            # f.write(f'infile5Av <- Sys.glob("{cwd}/analysis/EDA/{sys}/{files[rep]}/fort.806")\n')
        else:
            print("\nThe eda_diff_script base script is usually only for 5\n")
            print(" replicates. I encourage you to check that, or modify \n")
            print(" this function, because I didn't write that correctly.\n")
            break
    f.write("\n")
    f.write(f'A_coul <- "{cwd}/analysis/EDA/{sys}/{tag}{fs}{sys}{fs}EDA{fs}res{ROI}{fs}coul{fs}avg.dat"\n')
    f.write(f'A_vdw <- "{cwd}/analysis/EDA/{sys}/{tag}{fs}{sys}{fs}EDA{fs}res{ROI}{fs}vdw{fs}avg.dat"\n')
    f.write(f'A_tot <- "{cwd}/analysis/EDA/{sys}/{tag}{fs}{sys}{fs}EDA{fs}res{ROI}{fs}tot{fs}avg.dat"\n')
    f.write("\n")
    f.write(f"ROI <- {ROI}\n")
    f.write(f"sets <- {len(files)}.0000\n")
    base = open(str(base_script), "r")
    lines = base.readlines()
    base.close()
    for line in lines:
        f.write(line)
    f.write("\n")
    f.close()

