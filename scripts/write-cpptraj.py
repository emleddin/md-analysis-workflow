import sys

# python write-cpptraj.py alloc replicate full_path tag file_ext start_range end_range
# mask file_sep
# Ex: python write-cpptraj.py gac.cpu r1 ../test thing mdcrd 22 30 1-476 - 450
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
work_dir = sys.argv[10]
system = sys.argv[11]
n_aa = int(sys.argv[12])

# Remove the trailing slash on a path, if present
full_path = full_path.rstrip('/')

sh_strip = ('cpptraj'+str(fs)+'strip.sh')
out_strip = ('cpptraj'+str(fs)+'strip.in')

sh_analy = ('cpptraj'+str(fs)+'analysis.sh')
out_analy = ('cpptraj'+str(fs)+'analysis.in')


def write_strip_bash(outfile, queue, rep, f_path, cpp_strip, tag):
    """Creates the PBS script for submitting cpptraj strip jobs.

    Parameters
    ----------
    outfile : str
        The name of the output file.
    queue : str
        The name of the queue to submit the job through.
    rep : str
        The replicate the job is for.
    f_path: str
        The full path to the trajectory files, for finding the prmtop.
    cpp_strip : str
        The name of the cpptraj strip file that will be submitted.
    tag : str
        The tag used in the file names. This should be comprised of
        the project ID and system.

    Returns
    -------
    outfile : txt
        The written file containing PBS script for submitting the cpptraj
        strip job.
    """
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


def write_strip_traj(outfile, file_sep, f_path, tag, f_ext, f_start, f_end,
                     cwd, sys, rep):
    """Creates the cpptraj script for writing an ASCII trajectory for EDA and a
    stripped NetCDF trajectory for analysis.

    Parameters
    ----------
    outfile : str
        The name of the output cpptraj strip file.
    file_sep: str
        Determines the separator to use for the file name.
    f_path : str
        The full path to the trajectory files (parm_path).
    tag : str
        Specifies the inital title information for the output files.
    f_ext : str
        Current file extension used for trajectory files (ex. mdcrd or nc).
    f_start : int
        The number associated with the first trajectory file to read in.
    f_end : int
        The number associated with the final trajectory file to read in.
    cwd : str
        The path to the current working directory for the overall analysis.
    sys : str
        The system to make the analysis for.
    rep : str
        The replicate of a given `sys`.

    Returns
    -------
    outfile : txt
        The input file for cpptraj stripping.
    """
    f = open(outfile, "w+")
    # start, end+1 for correct range
    for i in range(f_start, f_end + 1):
        f.write(f"trajin {f_path}/{tag}{file_sep}md{i}.{f_ext}\n")
    f.write("\n")
    f.write(f"trajout {cwd}/analysis/EDA/{sys}/{rep}/{tag}{file_sep}{f_start}-{f_end}.mdcrd crd\n\n")
    f.write("autoimage\n")
    f.write("strip :WAT,K+ outprefix strip nobox\n\n")
    f.write(f"trajout {tag}{file_sep}imaged{file_sep}{f_start}-{f_end}.nc cdf\n\n")
    f.close()


def write_analy_bash(outfile, queue, rep, cpp_analy, tag):
    """Creates the PBS script for submitting cpptraj analysis jobs.

    Parameters
    ----------
    outfile : str
        The name of the output file.
    queue : str
        The name of the queue to submit the job through.
    rep : str
        The replicate the job is for.
    cpp_analy : str
        The name of the cpptraj analysis file that will be submitted.
    tag : str
        The tag used in the file names. This should be comprised of
        the project ID and system.

    Returns
    -------
    outfile : txt
        The written file containing PBS script for submitting the cpptraj
        analysis job.
    """
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


def write_analy_traj(outfile, fs, f_path, tag, f_start, f_end, num_aa, res_mask):
    """Creates the input file used for analysis with cpptraj.

    Parameters
    ----------
    outfile : str
        The name of the output cpptraj strip file.
    fs: str
        Determines the separator to use for the file name.
    f_path : str
        The full path to the trajectory files (parm_path).
    tag : str
        Specifies the inital title information for the output files.
    f_start : int
        The number associated with the first trajectory file to read in.
    f_end : int
        The number associated with the final trajectory file to read in.
    num_aa : int
        Number of amino acids in the system for secondary structure analysis.
    res_mask : str
        The residue mask for specific analyses.

    Returns
    -------
    outfile : txt
        The input file for cpptraj analysis.
    """
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
    f.write(f"matrix out {tag}{fs}covar{fs}mat.dat name norm_mode :{res_mask}@CA,P,C4',C2 \\\n")
    f.write(" covar\n")
    f.write(f"diagmatrix norm_mode out {tag}{fs}evecs.out vecs 100 reduce \\\n")
    f.write(f" nmwiz nmwizvecs 100 nmwizfile {tag}{fs}100.nmd \\\n")
    f.write(f" nmwizmask :{res_mask}@CA,P,C4',C2\n\n")
    f.write(f"hbond out {tag}{fs}hbond.dat dist 3.0 \\\n")
    f.write(f" avgout {tag}{fs}hbond{fs}avg.dat\n\n")
    f.write(f"rms reference out {tag}{fs}total{fs}bb{fs}rms.dat \\\n")
    f.write(f" :{res_mask}@CA,P,O3',O5',C3',C4',C5'\n")
    f.write(f"rmsd :{res_mask} reference perres perresavg range {res_mask} \\\n")
    f.write(f" perresout {tag}{fs}rmsd{fs}byres.dat\n\n")
    f.write(f"atomicfluct :{res_mask} out {tag}{fs}rmsf{fs}byres.dat byres\n")
    f.write(f"secstruct :1-{num_aa} out {tag}{fs}secstruct.gnu\n")
    f.write(f"#distance :AAA@PA :BBB@O3' out {tag}{fs}dist{fs}PO{fs}WT.dat\n\n")
    f.close()


# Write the stripped files
write_strip_bash(sh_strip, alloc, replicate, full_path, out_strip, sys_tag)
write_strip_traj(out_strip, fs, full_path, sys_tag, file_ext, start_range,
                 end_range, work_dir, system, replicate)

# Write the analysis files
write_analy_bash(sh_analy, alloc, replicate, out_analy, sys_tag)
write_analy_traj(out_analy, fs, full_path, sys_tag, start_range, end_range,
                 n_aa, mask)
