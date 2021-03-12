import sys

# python write-cpptraj.py alloc replicate full_path tag file_ext start_range end_range
# mask
# Ex: python write-cpptraj.py gac.cpu r1 ../test thing mdcrd 22 30 1-476
# script_name = sys.argv[0]
alloc = sys.argv[1]
replicate = sys.argv[2]
full_path = sys.argv[3]
sys_tag = sys.argv[4]
file_ext = sys.argv[5]
start_range = int(sys.argv[6])
end_range = int(sys.argv[7])
mask = sys.argv[8]

# Remove the trailing slash on a path, if present
full_path = full_path.rstrip('/')

sh_run = 'Hbond-analyze.sh'
r_hbond = 'rmagic-hbond.r'
sh_hbond = 'hbond-diffs.sh'

sh_analy = 'cpptraj-analysis.sh'
out_analy = 'cpptraj-analysis.in'


def write_strip_bash(outfile, queue, rep, tag, r_file, bash_file):
    f = open(outfile, "w+")
    f.write("#!/bin/bash\n")
    f.write(f"#PBS -q {queue}\n")
    f.write("#PBS -l nodes=1:ppn=1,mem=20GB\n")
    f.write("#PBS -j oe\n")
    f.write("#PBS -r n\n")
    f.write("#PBS -o R.error\n")
    f.write(f"#PBS -N {rep}.{tag}H\n\n")
    f.write("cd $PBS_O_WORKDIR\n\n")
    f.write("module load R/3.6.0\n\n")
    f.write(f"Rscript {r_file}\n\n")
    f.write(f"bash {bash_file}\n\n")
    f.close()


def write_r_avg(outfile, base_script, n_reps, f_path, tag):
    """
    Base script:
        Contains the information that doesn't require modification
        for running the script
    """
    f = open(outfile, "w+")
    f.write("# Run this with `Rscript rmagic-hbond-avg.r`\n")
    f.write("# (Assuming you've already installed R...)\n\n")
    f.write("#-----------------------------------------------# \n")
    f.write("#--Specify the paths to the Files from cpptraj--#\n")
    f.write("#-----------------------------------------------#\n\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    base.open(base_script, "r")
    # Iterate over each line in the base file, writing to the new script
    for line in base.readlines():
        f.write(line + "\n")
    base.close()
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    f.write("\n")
    # Write path for replicates
    for i in range(replicate):
        f.write(f"trajin {f_path}/{tag}_{i}.{f_ext}\n")
    f.write("\n")
    f.write("autoimage\n")
    f.write("strip :WAT,K+ outprefix strip nobox\n\n")
    f.write(f"trajout {tag}_imaged_{f_start}-{f_end}.nc cdf\n\n")
    f.close()


write_strip_bash(sh_run, alloc, replicate, sys_tag, r_hbond, sh_hbond)
