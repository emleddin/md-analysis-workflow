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
        # RMS Images
        [f"analysis/RMS/{tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsds.png"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
        [f"analysis/RMS/{tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-rmsf.png"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))],
        [f"analysis/RMS/{tag}{fs}{systems_df.groupby('System')['Replicate'].apply(list).index[i]}-hbonds.png"
         for i in range(len(systems_df.groupby("System")["Replicate"].apply(list)))]


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
