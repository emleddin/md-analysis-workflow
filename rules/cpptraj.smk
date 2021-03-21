#-------------------------------------#
#            Run cpptraj  2           #
#-------------------------------------#
rule cpptraj_analysis:
#! cpptraj_analysis : Runs the analysis with cpptraj using the generated script.
#!
    input:
        # [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.sh" for sys_rep_dir, values in
        #  systems.items() for value in values],
        # [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.in" for sys_rep_dir, values in
        #  systems.items() for value in values],
        sh = [f"analysis/{sys_rep_dir}/cpptraj{fs}analysis.sh" for
              sys_rep_dir, values in systems.items() for value in values],
        cpp = [f"analysis/{sys_rep_dir}/cpptraj{fs}analysis.in" for
               sys_rep_dir, values in systems.items() for value in values],
        prm = [f"{parm_path}/{sys_tag}.prmtop" for
            sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        inp = [f"{parm_path}/{sys_tag}.inpcrd" for
            sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        nc = [f"analysis/{sys_rep_dir}/{sys_tag}{fs}imaged{fs}{prod1}-{prod2}.nc" for
              sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values]
    output:
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
        [f"analysis/{sys_rep_dir}/{proj_tag}{fs}{system}{fs}secstruct.gnu" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
    run:
        for key, values in systems.items():
            shell("""
            cd {cwd}/analysis/{key} &&
{qsub} cpptraj{fs}analysis.sh &&
echo {key}""")
        # `echo` is an sanity check
        # Can't do `qsub {input.sh}` because it doesn't do one-by-one


#-------------------------------------#
#            Run cpptraj  1           #
#-------------------------------------#
rule cpptraj_strip:
#! cpptraj_strip    : Writes the non-autoimaged/stripped trajectory in ASCII
#!                    for EDA and creates the autoimaged/stripped trajectory
#!                    for further analysis.
#!
    input:
        sh = [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.sh" for
              sys_rep_dir, values in systems.items() for value in values],
        cpp = [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.in" for
              sys_rep_dir, values in systems.items() for value in values],
        prm = [f"{parm_path}/{sys_tag}.prmtop" for
            sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
    output:
        nc = [f"analysis/{sys_rep_dir}/{sys_tag}{fs}imaged{fs}{prod1}-{prod2}.nc" for
              sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
        mdcrd = [f"analysis/EDA/{sys_rep_dir}/{sys_tag}{fs}{prod1}-{prod2}.mdcrd" for
         sys_rep_dir, values in systems.items() for system, replicate, \
                        parm_path, sys_tag, prod1, prod2, sim_time in values],
    run:
        for key in systems.keys():
            shell("""
            cd {cwd}/analysis/{key} &&
{qsub} cpptraj{fs}strip.sh &&
echo {key} """)
        # `echo` is an sanity check
        # Can't do `qsub {input.sh}` because it doesn't do one-by-one


#-------------------------------------#
#             Write cpptraj           #
#-------------------------------------#
rule cpptraj_write:
#! cpptraj_write    : Runs a python3 script for generating the input files for
#!                    cpptraj based on the file naming specifics in the
#!                    `config/config.yaml` file.
#!
    input:
        script = "scripts/write-cpptraj.py"
    output:
        [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.sh" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.in" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/cpptraj{fs}analysis.sh" for
         sys_rep_dir, values in systems.items() for value in values],
        [f"analysis/{sys_rep_dir}/cpptraj{fs}analysis.in" for
         sys_rep_dir, values in systems.items() for value in values]
    run:
    # python3 script alloc replicate
    #  prm_path traj_tag file_ext output_tag
    #   start_range end_range mask file_sep cwd system num_AAs
    # Mask is {x}-{x}
        for key, values in systems.items():
            for system, replicate, parm_path, sys_tag, prod1, prod2, sim_time in values:
                shell("""
                cd {cwd}/analysis/{key}
                python3 {cwd}/{input.script} {que} {replicate} \
{parm_path} {sys_tag} {t_ext} {proj_tag}{fs}{system} \
{prod1} {prod2} {start_res}-{end_res} {fs} {cwd} {system} {n_aa}""")
