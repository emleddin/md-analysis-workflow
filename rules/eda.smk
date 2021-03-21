#-------------------------------------#
#              EDA Files              #
#-------------------------------------#
rule eda_diff:
#! eda_diff         : Uses the averaged EDA data for two systems to compare
#!                    them. The system comparisons are set up in
#!                    `config/EDAcompare.tsv`.
#!
    input:
        "scripts/rmagic-EDA-avg-diffs.r",
        [f"{value[1]}/{proj_tag}{fs}{value[0]}{fs}EDA{fs}res{roi}{fs}tot{fs}avg.dat" for
         comparison, values in eda_comps.items() for value in values],
        [f"{value[3]}/{proj_tag}{fs}{value[2]}{fs}EDA{fs}res{roi}{fs}tot{fs}avg.dat" for
         comparison, values in eda_comps.items() for value in values]
    output:
        [f"analysis/EDA/{proj_tag}{fs}{value[0]}-{value[2]}{fs}total{fs}interaction{fs}res{roi}{fs}avg.dat"
         for comparison, values in eda_comps.items() for value in values]
    run:
        for comparison, values in eda_comps.items():
            for value in values:
                shell("""
                Rscript scripts/rmagic-EDA-avg-diffs.r \
{value[1]}/{proj_tag}{fs}{value[0]}{fs}EDA{fs}res{roi}{fs}tot{fs}avg.dat \
{value[3]}/{proj_tag}{fs}{value[2]}{fs}EDA{fs}res{roi}{fs}tot{fs}avg.dat \
analysis/EDA/{proj_tag}{fs}{value[0]}-{value[2]}{fs}total{fs}interaction{fs}res{roi}{fs}avg.dat \
{roi}""")


rule eda_avg:
#! eda_avg          : Averages the EDA data for a system from a set of
#!                    replicates.
#!
    input:
        base = "scripts/r-eda-avgs-base.txt",
        coul = [f"analysis/EDA/{sys_rep_dir}/fort_coulomb_interaction.dat" for
         sys_rep_dir in systems.keys()],
        vdw = [f"analysis/EDA/{sys_rep_dir}/fort_vdw_interaction.dat" for
         sys_rep_dir in systems.keys()]
    output:
        coul = [f"analysis/EDA/{system}/{proj_tag}{fs}{system}{fs}EDA{fs}res{roi}{fs}coul{fs}avg.dat" for
         key, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        vdw = [f"analysis/EDA/{system}/{proj_tag}{fs}{system}{fs}EDA{fs}res{roi}{fs}vdw{fs}avg.dat" for
         key, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        tot = [f"analysis/EDA/{system}/{proj_tag}{fs}{system}{fs}EDA{fs}res{roi}{fs}tot{fs}avg.dat" for
         key, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
    run:
        # Group the systems by system
        eda_groups = systems_df.groupby("System")["Replicate"].apply(list)
        # For the systems
        for i in range(len(eda_groups)):
            var = eda_groups.index[i]
            #print(var)
            eda_diff_script(f"analysis/EDA/{eda_groups.index[i]}/rmagic{fs}EDA{fs}avg.r",
             input.base, cwd, proj_tag, fs, roi, eda_groups.index[i], eda_groups[i])
            shell("cd {cwd}/analysis/EDA/{var} && Rscript rmagic{fs}EDA{fs}avg.r")


rule eda_run:
#! eda_run          : Submits the script for running the EDA Fortran program
#!                    to the queue scheduler.
#!
    input:
        script = [f"analysis/EDA/{sys_rep_dir}/EDA{fs}job.sh" for
         sys_rep_dir, values in systems.items() for value in values],
        prm = [f"analysis/EDA/{sys_rep_dir}/{sys_tag}.prmtop" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        mdcrd = [f"analysis/EDA/{sys_rep_dir}/{sys_tag}{fs}{prod1}-{prod2}.mdcrd" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        ans = [f"analysis/EDA/{sys_rep_dir}/ans.txt" for
         sys_rep_dir in systems.keys()],
        inp = [f"analysis/EDA/{sys_rep_dir}/EDA.inp" for
         sys_rep_dir in systems.keys()],
        fort = [f"analysis/EDA/{sys_rep_dir}/Residue_E_Decomp_openmp.f90" for
         sys_rep_dir in systems.keys()]
    output:
        # New versions use
        [f"analysis/EDA/{sys_rep_dir}/fort_sanity_check.txt" for
         sys_rep_dir in systems.keys()],
        [f"analysis/EDA/{sys_rep_dir}/fort_coulomb_interaction.dat" for
         sys_rep_dir in systems.keys()],
        [f"analysis/EDA/{sys_rep_dir}/fort_vdw_interaction.dat" for
         sys_rep_dir in systems.keys()]
        # Legacy version use
        # [f"analysis/EDA/{sys_rep_dir}/fort.804" for
        #  sys_rep_dir in systems.keys()],
        # [f"analysis/EDA/{sys_rep_dir}/fort.803" for
        #  sys_rep_dir in systems.keys()],
        # [f"analysis/EDA/{sys_rep_dir}/fort.806" for
        #  sys_rep_dir in systems.keys()]
    run:
        for key in systems.keys():
                shell("""
                cd analysis/EDA/{key} &&
{qsub} EDA{fs}job.sh""")


rule eda_copy:
#! eda_copy         : Copies the `prmtop` file and Fortran 90 program to the
#!                    to the system/replicate subdirectory in preparation of
#!                    running the EDA program.
#!
    input:
    # Copy the fortran program file from the scripts directory as part of a rule
    # in case you run into issues that require changes to the program code
        prm = [f"{parm_path}/{sys_tag}.prmtop" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        fort = "scripts/Residue_E_Decomp_openmp.f90"
    output:
        prm = [f"analysis/EDA/{sys_rep_dir}/{sys_tag}.prmtop" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        fort = [f"analysis/EDA/{sys_rep_dir}/Residue_E_Decomp_openmp.f90" for
         sys_rep_dir in systems.keys()]
    run:
        for key, values in systems.items():
            for system, replicate, parm_path, sys_tag, prod1, prod2, sim_time in values:
                shell("cp {parm_path}/{sys_tag}.prmtop \
analysis/EDA/{key}/{sys_tag}.prmtop")
                shell("cp {input.fort} analysis/EDA/{key}/Residue_E_Decomp_openmp.f90")
        # Can't do these because it doesn't match them correctly
        #shell("cp {input.prm} {output.prm}")
        #shell("cp {input.fort} {output.fort}")

rule eda_write:
#! eda_write        : Runs a python3 script for generating the input files for
#!                    EDA based on the file naming specifics in the
#!                    `config/config.yaml` file.
#!
    input:
        script = "scripts/write-EDA.py",
        # mdcrd = [f"analysis/EDA/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}{p1}-{p2}.mdcrd" for
        #  sys_rep_dir, values in systems.items() for value in values],
    params:
        alloc = que,
        n_res = get_val(0),
        n_atom = get_val(1),
        n_prot_at = get_val(2),
        tot_res = get_val(3),
        #mdcrd = get_crd()
    output:
        script = [f"analysis/EDA/{sys_rep_dir}/EDA{fs}job.sh" for
         sys_rep_dir, values in systems.items() for value in values],
        ans = [f"analysis/EDA/{sys_rep_dir}/ans.txt" for
             sys_rep_dir in systems.keys()],
        inp = [f"analysis/EDA/{sys_rep_dir}/EDA.inp" for
             sys_rep_dir in systems.keys()]
    run:
    # You can use `echo $PWD` for debugging
    # python3 write-EDA.py alloc \
    # system replicate sys_tag \
    # n_res n_atom n_prot_at tot_residues \
    # nas_traj fs
        for key, values in systems.items():
            for system, replicate, parm_path, sys_tag, prod1, prod2, sim_time in values:
                shell("""
                cd {cwd}/analysis/EDA/{key}
                python3 {cwd}/{input.script} {params.alloc} \
{system} {replicate} {sys_tag} \
{params.n_res} {params.n_atom} \
{params.n_prot_at} {params.tot_res} \
{sys_tag}{fs}{prod1}-{prod2}.mdcrd {fs}""")
