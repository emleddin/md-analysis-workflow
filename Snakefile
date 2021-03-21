# This is the starting point of the workflow
# Use `snakemake -n --dry-run` to test

# `snakemake --forceall --dag | dot -Tpdf > dag.pdf`
# Will create a PDF of how it thinks your workflow links together

# You can test deleting output from snakemake with:
# snakemake cpptraj_write --delete-all-output --dry-run
# And actually do it with:
# snakemake cpptraj_write --delete-all-output --cores 1

# TODO: Check tags!!!

include: "rules/common.smk"

rule all:
# Denote rule help with `#!` at start of line to find with grep later.
# Include a final `#!` after all explanation for readability.
#! all              : Builds all analysis files and runs all analyses.
#!
    input:
        # `systems`
        # Key = the output path
        # values = system, replicate, parm_path, sys_tag, prod1, prod2, sim_time
        # Prmtop is required for everything
        [f"{parm_path}/{sys_tag}.prmtop" for
            sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
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
        [f"analysis/{sys_rep_dir}/{sys_tag}{fs}imaged{fs}{prod1}-{prod2}.nc" for
              sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/EDA/{sys_rep_dir}/{sys_tag}{fs}{prod1}-{prod2}.mdcrd" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        # Cpptraj analysis files
        [f"analysis/{sys_rep_dir}/test{fs}rms.dat" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}corr{fs}mat.dat" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}covar{fs}mat.dat" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}evecs.out" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}100.nmd" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}hbond{fs}avg.dat" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}hbond.dat" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}total{fs}bb{fs}rms.dat" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}rmsd{fs}byres.dat" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}rmsf{fs}byres.dat" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
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
        # EDA Averaging
        [f"analysis/EDA/{system}/{proj_tag}{fs}{system}{fs}EDA{fs}res{roi}{fs}coul{fs}avg.dat" for
         key, values in systems.items() for system, replicate, parm_path, \
                                    sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/EDA/{system}/{proj_tag}{fs}{system}{fs}EDA{fs}res{roi}{fs}vdw{fs}avg.dat" for
         key, values in systems.items() for system, replicate, parm_path, \
                                    sys_tag, prod1, prod2, sim_time in values],
        [f"analysis/EDA/{system}/{proj_tag}{fs}{system}{fs}EDA{fs}res{roi}{fs}tot{fs}avg.dat" for
         key, values in systems.items() for system, replicate, parm_path, \
                                    sys_tag, prod1, prod2, sim_time in values],
        # EDA Differences
        [f"analysis/EDA/{proj_tag}{fs}{value[0]}-{value[2]}{fs}total{fs}interaction{fs}res{roi}{fs}avg.dat"
         for comparison, values in eda_comps.items() for value in values],
        # Matrix Correlation
        [f"analysis/MatCorr/{proj_tag}{fs}{system}{fs}{replicate}{fs}mat{fs}corr.png" for
         key, values in systems.items() for system, replicate, parm_path, \
                                    sys_tag, prod1, prod2, sim_time in values],
        # Normal Modes
        [f"analysis/NMA/{proj_tag}{fs}{system}{fs}{replicate}{fs}NMA.png" for
         key, values in systems.items() for system, replicate, parm_path, \
                                    sys_tag, prod1, prod2, sim_time in values],
        # RMS Images
        [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsds.png"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
        [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsf.png"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
        [f"analysis/RMS/{proj_tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-hbonds.png"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
        # Secondary Structure
        [f"analysis/2SA/{proj_tag}{fs}{system}{fs}{replicate}{fs}2SA.png" for
         key, values in systems.items() for system, replicate, parm_path, \
                                    sys_tag, prod1, prod2, sim_time in values]


rule help:
#! help             : Prints help comments for the workflow rules.
#!
    params:
        # Create fencing around the help for readability
        start = " -----------------             All Workflow Rules             -----------------\n",
        s1 = " Hello! If you are looking for more help than what the commands are,\n",
        s2 = " I sincerely hope you will consider reading the README.md file. It contains\n",
        s3 = " a lot of specific information for working with this workflow.\n",
        s4 = " Good luck, and research on!\n\n",
        end = "\n ................. __/\_/\_/\" ...thems the rules... \"\_/\_/\__ ................\n"
    shell:
        """
        echo '{params.start}'
        echo '{params.s1}' '{params.s2}' '{params.s3}' '{params.s4}'
        grep -h '^#!' Snakefile
        grep -h '^#!' rules/*smk
        echo '{params.end}'
        """


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

# Include the other rules
include: "rules/eda.smk"
include: "rules/hba.smk"
include: "rules/cpptraj.smk"
include: "rules/figs.smk"
