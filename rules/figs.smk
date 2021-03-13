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
        file = [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}corr{fs}mat.dat" for
         sys_rep_dir, values in systems.items() for value in values]
    output:
        pic = [f"analysis/MatCorr/{tag}{fs}{value[0]}{fs}{value[1]}{fs}mat{fs}corr.png" for
         key, values in systems.items() for value in values]
    run:
        shell("python3 {input.script} {input.file} {output.pic}")


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
        file = [f"analysis/{sys_rep_dir}/{tag}{fs}{value[0]}{fs}100.nmd" for
         sys_rep_dir, values in systems.items() for value in values]
    output:
        pic = [f"analysis/NMA/{tag}{fs}{value[0]}{fs}{value[1]}{fs}NMA.png" for
         key, values in systems.items() for value in values]
    run:
        shell("python3 {input.script} {input.file} {output.pic} 4")
