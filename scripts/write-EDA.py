import sys

# python write-EDA.py alloc system replicate sys_tag n_res n_atom n_prot_at
# tot_residues nas_traj file_sep
# Ex: python write-EDA.py gac.cpu 5hmC r1 thing 1430 7848 12000 234973 blah_1-30.mdcrd -
# script_name = sys.argv[0]

alloc = sys.argv[1]
system = sys.argv[2]
replicate = sys.argv[3]
sys_tag = sys.argv[4]
n_res = int(sys.argv[5])
n_atom = int(sys.argv[6])
n_prot_at = sys.argv[7]
tot_residues = sys.argv[8]
nas_traj = sys.argv[9]
fs = sys.argv[10]
short_tag = sys.argv[11]

sh_file = ("EDA"+str(fs)+"job.sh")
inp_file = "EDA.inp"
ans_file = "ans.txt"


def write_eda_bash(outfile, queue, rep, tag, ans):
    f = open(outfile, "w+")
    f.write("#!/bin/bash\n")
    f.write(f"#PBS -q {queue}\n")
    f.write("#PBS -l nodes=1:ppn=10,mem=100GB\n")
    f.write("#PBS -j oe\n")
    f.write("#PBS -r n\n")
    f.write("#PBS -o EDA.error\n")
    f.write(f"#PBS -N {rep}.{tag}.E\n\n")
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
    f = open(outfile, "w+")
    f.write(f"{inpfile}\n")
    f.write(f"{tag}.prmtop")


def write_eda_inp(outfile, n_residues, tot_atom, prot_at, tot_res, traj):
    f = open(outfile, "w+")
    f.write(f"{n_residues} !number of protein residues\n")
    f.write("1 !number of files\n")
    f.write(f"{tot_atom} !total number of atoms\n")
    f.write(f"{prot_at} !number of protein atoms\n")
    f.write(f"{tot_res} !number of total residues\n")
    f.write("2000 !max number of types\n")
    f.write(f"{traj}")


write_eda_bash(sh_file, alloc, replicate, short_tag, ans_file)
write_eda_ans(ans_file, inp_file, sys_tag)
write_eda_inp(inp_file, n_res, n_atom, n_prot_at, tot_residues, nas_traj)
