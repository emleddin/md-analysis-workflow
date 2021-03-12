import sys

# python write-cpptraj.py alloc replicate full_path tag file_ext start_range end_range
# mask file_sep
# Ex: python write-cpptraj.py gac.cpu r1 ../test thing mdcrd 22 30 1-476 -
# script_name = sys.argv[0]
alloc = sys.argv[1]
replicate = sys.argv[2]
full_path = sys.argv[3]
sys_tag = sys.argv[4]
file_ext = sys.argv[5]
start_range = int(sys.argv[6])
end_range = int(sys.argv[7])
mask = sys.argv[8]
fs = sys.argv[9]

# Remove the trailing slash on a path, if present
full_path = full_path.rstrip('/')

sh_strip = ('cpptraj'+str(fs)+'strip.sh')
out_strip = ('cpptraj'+str(fs)+'strip.in')

sh_analy = ('cpptraj'+str(fs)+'analysis.sh')
out_analy = ('cpptraj'+str(fs)+'analysis.in')


def write_strip_bash(outfile, queue, rep, f_path, cpp_strip, tag):
    f = open(outfile, "w+")
    f.write("#!/bin/bash\n")
    f.write(f"#PBS -q {queue}\n")
    f.write("#PBS -l nodes=1:ppn=20,mem=20GB\n")
    f.write("#PBS -j oe\n")
    f.write("#PBS -r n\n")
    f.write("#PBS -o err.error\n")
    f.write(f"#PBS -N {rep}.{tag}.S\n\n")
    f.write(f"prmfile={f_path}/{tag}.prmtop\n")
    f.write(f"cppfile={cpp_strip}\n\n")
    f.write("cd $PBS_O_WORKDIR\n")
    f.write("cat $PBS_NODEFILE  > $PWD/PBS_NODEFILE\n\n")
    f.write("module load amber/19-mvapich2\n\n")
    f.write("mpirun -np 20 -hostfile $PWD/PBS_NODEFILE \\\n")
    f.write(" $AMBERHOME/bin/cpptraj.MPI -p $prmfile -i $cppfile\n\n")
    f.close()


def write_strip_traj(outfile, file_sep, f_path, tag, f_ext, f_start, f_end):
    f = open(outfile, "w+")
    # start, end+1 for correct range
    for i in range(f_start, f_end + 1):
        f.write(f"trajin {f_path}/{tag}{file_sep}md{i}.{f_ext}\n")
    f.write("\n")
    f.write("autoimage\n")
    f.write("strip :WAT,K+ outprefix strip nobox\n\n")
    f.write(f"trajout {tag}{file_sep}imaged{file_sep}{f_start}-{f_end}.nc cdf\n\n")
    f.close()


def write_analy_bash(outfile, queue, rep, cpp_analy, tag):
    f = open(outfile, "w+")
    f.write("#!/bin/bash\n")
    f.write(f"#PBS -q {queue}\n")
    f.write("#PBS -l nodes=1:ppn=20,mem=20GB\n")
    f.write("#PBS -j oe\n")
    f.write("#PBS -r n\n")
    f.write("#PBS -o err.error\n")
    f.write(f"#PBS -N {rep}.{tag}.A\n\n")
    f.write(f"prmfile=strip.{tag}.prmtop\n")
    f.write(f"cppfile={cpp_analy}\n\n")
    f.write("cd $PBS_O_WORKDIR\n")
    f.write("cat $PBS_NODEFILE  > $PWD/PBS_NODEFILE\n\n")
    f.write("module load amber/19-mvapich2\n\n")
    f.write("mpirun -np 20 -hostfile $PWD/PBS_NODEFILE \\\n")
    f.write(" $AMBERHOME/bin/cpptraj.MPI -p $prmfile -i $cppfile\n\n")
    f.close()


def write_analy_traj(outfile, file_sep, f_path, tag, f_start, f_end, res_mask):
    f = open(outfile, "w+")
    f.write("# Read in the crystal (pre-minimization) structure\n")
    f.write("# You need to specify a prmtop with it because you're reading in\n")
    f.write("# the stripped trajectory\n")
    f.write(f"parm {f_path}/{tag}.prmtop [ref]\n")
    f.write(f"reference {f_path}/{tag}.inpcrd parm [ref]\n")
    f.write("\n")
    f.write("# Read in the stripped trajectory\n")
    f.write(f"trajin {tag}{fs}imaged{fs}{f_start}-{f_end}.nc\n")
    f.write("\n")
    f.write("autoimage\n\n")
    f.write(f"rms reference out test{fs}rms.dat :{res_mask} byres\n\n")
    f.write("# Get for correlation matrix (evecs = eigenvectors)\n")
    f.write(f"matrix out {tag}{fs}corr{fs}mat.dat name corr_mat byres :{res_mask} correl\n\n")
    f.write("# Get for normal modes\n")
    f.write(f"matrix out {tag}{fs}covar{fs}mat.dat name norm_mode :{res_mask} covar\n")
    f.write(f"diagmatrix norm_mode out {tag}{fs}evecs.out vecs 100 reduce \\\n")
    f.write(f" nmwiz nmwizvecs 100 nmwizfile {tag}{fs}100.nmd nmwizmask :{res_mask}\n\n")
    f.write(f"hbond out {tag}{fs}total{fs}bb{fs}rms.dat \\\n")
    f.write(f" :{res_mask}@CA,P,O3',O5',C3',C4',C5'\n")
    f.write(f"rmsd :{res_mask} reference perres perresavg range {res_mask} \\\n")
    f.write(f" perresout {tag}{fs}rmsd{fs}byres.dat\n\n")
    f.write(f"atomicfluct :{res_mask} {tag}{fs}rmsf{fs}byres.dat byres\n")
    f.write(f"#distance :AAA@PA :BBB@O3' out {tag}{fs}dist{fs}PO{fs}WT.dat\n\n")
    f.close()


# Write the stripped files
write_strip_bash(sh_strip, alloc, replicate, full_path, out_strip, sys_tag)
write_strip_traj(out_strip, fs, full_path, sys_tag, file_ext, start_range,
                 end_range)

# Write the analysis files
write_analy_bash(sh_analy, alloc, replicate, out_analy, sys_tag)
write_analy_traj(out_analy, fs, full_path, sys_tag, start_range, end_range, mask)
