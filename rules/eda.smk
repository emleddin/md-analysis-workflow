#-------------------------------------#
#              EDA Files              #
#-------------------------------------#
rule eda_run:
    """
    
    """
    input:
        script = [f"analysis/EDA/{sys_rep_dir}/EDA{fs}job.sh" for
         sys_rep_dir, values in systems.items() for value in values],
        prm = [f"analysis/EDA/{sys_rep_dir}/{tag}{fs}{value[0]}{post_e}.prmtop" for
         sys_rep_dir, values in systems.items() for value in values],
        mdcrd = [f"analysis/EDA/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}{p1}-{p2}.mdcrd" for
         sys_rep_dir, values in systems.items() for value in values],
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
    # python3 script replicate full_path tag file_ext start_range end_range mask
        shell("qsub {input.script}")

rule eda_copy:
    input:
        prm = [f"{value[2]}/{tag}{fs}{value[0]}{post_e}.prmtop" for
         sys_rep_dir, values in systems.items() for value in values],
        fort = "scripts/Residue_E_Decomp_openmp.f90"
    output:
        prm = [f"analysis/EDA/{sys_rep_dir}/{tag}{fs}{value[0]}{post_e}.prmtop" for
         sys_rep_dir, values in systems.items() for value in values],
        fort = [f"analysis/EDA/{sys_rep_dir}/Residue_E_Decomp_openmp.f90" for
         sys_rep_dir in systems.keys()]
    run:
        # shell("cp {input.prm} {output.prm}")
        shell("cp {input.fort} {output.fort}")

rule eda_write:
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
        mdcrd = get_crd()
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
            for value in values:
                shell("""
                cd {cwd}/analysis/EDA/{key}
                python3 {cwd}/{input.script} {params.alloc} \
{value[1]} {key} {tag}{fs}{value[0]} \
{params.n_res} {params.n_atom} \
{params.n_prot_at} {params.tot_res} \
{params.mdcrd} {fs} {tag}""")