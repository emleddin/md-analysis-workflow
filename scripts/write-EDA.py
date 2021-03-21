import sys

# python write-EDA.py alloc system replicate sys_tag n_res n_atom n_prot_at
# tot_residues nas_traj file_sep short_tag
# Ex: python write-EDA.py gac.cpu 5hmC r1 thing 1430 7848 12000 234973 blah_1-30.mdcrd -
# script_name = sys.argv[0]

alloc = sys.argv[1]
system = sys.argv[2]
replicate = sys.argv[3]
traj_tag = sys.argv[4]
n_res = int(sys.argv[5])
n_atom = int(sys.argv[6])
n_prot_at = sys.argv[7]
tot_residues = sys.argv[8]
nas_traj = sys.argv[9]
fs = sys.argv[10]

sh_file = ("EDA"+str(fs)+"job.sh")
inp_file = "EDA.inp"
ans_file = "ans.txt"


def write_eda_bash(outfile, queue, rep, sys, ans):
    """Creates the PBS script for submitting EDA jobs.

    Parameters
    ----------
    outfile : str
        The name of the output file.
    queue : str
        The name of the queue to submit the job through.
    rep : str
        The replicate the job is for.
    tag : str
        The tag used in the file names. This should be comprised of
        the project ID and system.
    ans : str
        The name of the file containing the answers to the program prompts.

    Returns
    -------
    outfile : txt
        The written file containing PBS script for submitting the EDA job.
    """
    f = open(outfile, "w+")
    f.write("#!/bin/bash\n")
    f.write(f"#PBS -q {queue}\n")
    f.write("#PBS -l nodes=1:ppn=10,mem=100GB\n")
    f.write("#PBS -j oe\n")
    f.write("#PBS -r n\n")
    f.write("#PBS -o EDA.error\n")
    f.write(f"#PBS -N EDA.{rep}.{sys}\n\n")
    f.write("# Load in the Intel compiler\n")
    f.write("module load intel/17.0\n\n")
    f.write("# Access the folder where the files are\n")
    f.write("cd $PBS_O_WORKDIR\n")
    f.write("cat $PBS_NODEFILE  > $PWD/PBS_NODEFILE\n\n")
    f.write("# Compile the EDA program\n")
    f.write("ifort Residue_E_Decomp_openmp.f90 -o Residue_E_Decomp_openmp.x -qopenmp\n\n")
    f.write("date\n\n")
    f.write("# Run the program; read in the prompt answers\n")
    f.write("# [Line 1: Name of input; Line 2: Name of prmtop]\n")
    f.write(f"./Residue_E_Decomp_openmp.x < {ans}\n\n")
    f.write("# Acquire the process ID for the program execution\n")
    f.write("proc_PID=$!\n\n")
    f.write("# Wait until the program execution is over before ending the script\n")
    f.write("wait $proc_PID\n\n")
    f.write("date\n\n")
    f.write("echo 'All done!'\n\n")
    f.close()


def write_eda_ans(outfile, inpfile, tag):
    """Write a file with the answers for running EDA non-interactively.

    Parameters
    ----------
    outfile : str
        The name of the output file.
    inpfile : str
        The name of the input file containing trajectory and atom-specific
        information.
    tag : str
        The tag used in the prmtop file name. This should be comprised of
        the project ID and system.

    Returns
    -------
    outfile : txt
        The file with the answers.
    """
    f = open(outfile, "w+")
    f.write(f"{inpfile}\n")
    f.write(f"{tag}.prmtop")


def write_eda_inp(outfile, n_residues, tot_atom, prot_at, tot_res, traj):
    """Creates the system-specific input file used for EDA.

    Parameters
    ----------
    outfile : str
        The name of the output file.
    n_residues : str
        The number of residues to calculate interactions for.
        This number will only work for 1-n_residues (ex: use 450 for residues
        1 to 450).
    tot_atom : str
        The total number of atoms in the prmtop/trajectory.
    prot_at: str
        The is the number of atoms for the quantity given in n_residues.
        This is the number of protein atoms to calculate interactions for based
        on the prmtop/trajectory.
    tot_res : str
        The total number of residues in the prmtop/trajectory.
    traj : str
        The trajectory file containing the

    Returns
    -------
    outfile : txt
        The written file containing PBS script for submitting the cpptraj
        strip job.
    """
    f = open(outfile, "w+")
    f.write(f"{n_residues} !number of protein residues\n")
    f.write("1 !number of files\n")
    f.write(f"{tot_atom} !total number of atoms\n")
    f.write(f"{prot_at} !number of protein atoms\n")
    f.write(f"{tot_res} !number of total residues\n")
    f.write("2000 !max number of types\n")
    f.write(f"{traj}")


write_eda_bash(sh_file, alloc, replicate, system, ans_file)
write_eda_ans(ans_file, inp_file, traj_tag)
write_eda_inp(inp_file, n_res, n_atom, n_prot_at, tot_residues, nas_traj)
