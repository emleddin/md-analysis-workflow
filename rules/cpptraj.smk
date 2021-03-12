#-------------------------------------#
#            Run cpptraj  2           #
#-------------------------------------#
rule cpptraj_analysis:
    input:
        # [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.sh" for sys_rep_dir, values in
        #  systems.items() for value in values],
        # [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.in" for sys_rep_dir, values in
        #  systems.items() for value in values],
        sh = [f"analysis/{sys_rep_dir}/cpptraj{fs}analysis.sh" for
              sys_rep_dir, values in systems.items() for value in values],
        cpp = [f"analysis/{sys_rep_dir}/cpptraj{fs}analysis.in" for
               sys_rep_dir, values in systems.items() for value in values],
        prm = [f"{value[2]}/{tag}{fs}{value[0]}{post_e}.prmtop" for
            sys_rep_dir, values in systems.items() for value in values],
        inp = [f"{value[2]}/{tag}{fs}{value[0]}{post_e}.inpcrd" for
            sys_rep_dir, values in systems.items() for value in values],
        nc = [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}imaged{fs}{p1}-{p2}.nc" for
              sys_rep_dir, values in systems.items() for value in values]
    output:
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
    shell:
        """
        cd {cwd}/analysis/{key}
        echo {input.sh}
        """
        # qsub {input.sh}


#-------------------------------------#
#            Run cpptraj  1           #
#-------------------------------------#
rule cpptraj_strip:
    input:
        sh = [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.sh" for
              sys_rep_dir, values in systems.items() for value in values],
        cpp = [f"analysis/{sys_rep_dir}/cpptraj{fs}strip.in" for
              sys_rep_dir, values in systems.items() for value in values],
        prm = [f"{value[2]}/{tag}{fs}{value[0]}{post_e}.prmtop" for
            sys_rep_dir, values in systems.items() for value in values]
    output:
        nc = [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}imaged{fs}{p1}-{p2}.nc" for
              sys_rep_dir, values in systems.items() for value in values],
        mdcrd = [f"analysis/EDA/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}{p1}-{p2}.mdcrd" for
         sys_rep_dir, values in systems.items() for value in values]
    shell:
            """
            cd {cwd}/analysis/{key}
            echo {input.sh}
            """
        # qsub {input.sh}


#-------------------------------------#
#             Write cpptraj           #
#-------------------------------------#
# This one works but gives a target error
rule cpptraj_write:
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
    #  prm_path sys_tag
    #  file_ext start_range end_range mask file_sep
    # Mask is {x}-{x}
        for key, values in systems.items():
            for value in values:
                shell("""
                cd {cwd}/analysis/{key}
                python3 {cwd}/{input.script} {que} {value[1]} \
{value[2]} {tag}{fs}{value[0]} \
{t_ext} {p1} {p2} {start_res}-{end_res} {fs}""")