#-------------------------------------#
#          Matrix Correlation         #
#-------------------------------------#
rule mc:
#! mc               : Creates the matrix correlation plots for each
#!                    system/replicate.
#!
    input:
    # The MatCorr-plots.py script takes the filenames as input.
        script = "scripts/MatCorr-plots.py",
        file = [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{value[0]}{fs}corr{fs}mat.dat" for
         sys_rep_dir, values in systems.items() for value in values]
    output:
        pic = [f"analysis/MatCorr/{proj_tag}{fs}{system}{fs}{replicate}{fs}mat{fs}corr.png" for
         key, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values]
    run:
        for key, values in systems.items():
            for system, replicate, parm_path, sys_tag, prod1, prod2, sim_time in values:
                shell("""
                python3 {input.script} \
analysis/{key}/{proj_tag}{fs}{system}{fs}corr{fs}mat.dat \
analysis/MatCorr/{proj_tag}{fs}{system}{fs}{replicate}{fs}mat{fs}corr.png""")


#-------------------------------------#
#              NMA Files              #
#-------------------------------------#
rule nma:
#! nma              : Creates the normal mode analysis graphs for each
#!                    system/replicate.
#!
    input:
    # The NMA-plots.py script takes the filenames as input.
        script = "scripts/NMA-plots.py",
        file = [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}100.nmd" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                            parm_path, sys_tag, prod1, prod2, sim_time in values]
    output:
        pic = [f"analysis/NMA/{proj_tag}{fs}{system}{fs}{replicate}{fs}NMA.png" for
         key, values in systems.items() for system, replicate, parm_path, \
                                sys_tag, prod1, prod2, sim_time in values]
    run:
        for key, values in systems.items():
            for system, replicate, parm_path, sys_tag, prod1, prod2, sim_time in values:
                shell("""
                python3 {input.script} \
analysis/{key}/{proj_tag}{fs}{system}{fs}100.nmd \
analysis/NMA/{proj_tag}{fs}{system}{fs}{replicate}{fs}NMA.png 4""")


#-------------------------------------#
#              RMS Files              #
#-------------------------------------#
rule rms_gnuplot:
#! rms_gnuplot      : Generates and executes the gnuplot script for RMSD, RMSF,
#!                    and number of hydrogen bonds, plotting each replicate of
#!                    a system on one graph for the system.
#!                    Ex: Plot 1 has r1, r2, and r3 of WT. Plot 2 has r1,
#!                    r2, and r3 of MUT-A.
#!
    input:
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}total{fs}bb{fs}rms.dat" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                            parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}hbond.dat" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                            parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}rmsf{fs}byres.dat" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                            parm_path, sys_tag, prod1, prod2, sim_time in values],
    output:
        [f"scripts/gnu/{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsd-etc.gnu"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
        [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsds.eps"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
        [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsf.eps"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
        [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-hbonds.eps"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))]
    run:
        # Group the systems by system
        gnu_groups = systems_df.groupby("System")["Replicate"].apply(list)
        # For the systems
        for i in range(len(gnu_groups)):
            var = gnu_groups.index[i]
            #print(var)
            gnuplot_rms(f"scripts/gnu/{gnu_groups.index[i]}-rmsd-etc.gnu",
             proj_tag, fs, div, start_res, end_res, gnu_groups.index[i],
             gnu_groups[i])
            shell("cd scripts/gnu/ && gnuplot {var}-rmsd-etc.gnu")

rule rms_conv:
#! rms_conv         : Converts the EPS images for RMSD, RMSF, and number of
#!                    hydrogen bonds to PNG and rotates them.
#!
    input:
       [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsds.eps"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
       [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsf.eps"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
       [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-hbonds.eps"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))]
    output:
        [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsds.png"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
        [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsf.png"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
        [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-hbonds.png"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))]
    run:
        shell("""
        cd analysis/RMS
        for file in *.eps; do convert $file -rotate 90 ${{file%.*}}.png; done""")


rule second_struct:
#! second_struct    : Fixes the gnuplot script written by cpptraj for secondary
#!                    structure analysis and generates the plot.
#!
    input:
        script = "scripts/2SA-plot-fix.py",
        file = [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}secstruct.gnu" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
    output:
        pic = [f"analysis/2SA/{proj_tag}{fs}{system}{fs}{replicate}{fs}2SA.png" for
         key, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
    run:
        for key, values in systems.items():
            for system, replicate, parm_path, sys_tag, prod1, prod2, sim_time in values:
                # Do not give PNG the path because you run gnuplot from the
                # specified folder
                shell("""
                python3 {input.script} \
analysis/{key}/{proj_tag}{fs}{system}{fs}secstruct.gnu \
analysis/2SA/{proj_tag}{fs}{system}{fs}{replicate}{fs}secstruct{fs}fix.gnu \
{proj_tag}{fs}{system}{fs}{replicate}{fs}2SA.png \
{n_aa} {sim_time} {div} """)
                shell("""                                                       
                cd analysis/2SA                                                 
                gnuplot {proj_tag}{fs}{system}{fs}{replicate}{fs}secstruct{fs}fix.gnu""")
