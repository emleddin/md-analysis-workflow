import numpy as np
import prody as prd
import matplotlib.pyplot as plt
import sys

# The script itself is sys.argv[0]
in_file = sys.argv[1]
out_file = sys.argv[2]
num_of_modes = int(sys.argv[3])


def plot_ticks(NMA_data):
    """Sets top xticks on the NMA plot.

    Params
    ------
    NMA_data : prody.dynamics.nma.NMA
        Normal mode data.

    Notes
    -----
    You NEED the 0 and NMA_data.numAtoms(), otherwise the scale will be turned
    off.
    """
    labels_top = ["", "MUTA", "GS linker", "", "DNA", ""]
    places_top = [0, 141, 334, 346, 431, NMA_data.numAtoms()]
    return labels_top, places_top


def NMA_plots(filename, outfile):
    """Creates a plot of the most important modes for a system.
    Parameters
    ----------
    filename : str
        An NMD file.
    outfile: str
        Name of the output PNG.

    Returns
    -------
    outfile : png
        The rendered normal mode plot.
    """
    NMA_data, Atom_Group = prd.parseNMD(filename)
    eigens = NMA_data.getEigvals()

    # If you have specific X-tick labels, set them up in plot_ticks
    #labels_top, places_top = plot_ticks(NMA_data)

    scales = []
    temp = open(filename)
    lines = temp.readlines()
    temp.close()
    for line in lines:
        if 'mode' in line[:5]:
            scales.append(float(line.split()[:3][-1]))

    # Make an array of the number of atoms for plotting
    x_vals = np.arange(0, NMA_data.numAtoms(), 1)

    fig = plt.figure(figsize=(10, 8), dpi=300)
    ax = fig.add_subplot(1, 1, 1)
    for i in range(num_of_modes):
        dataset = [np.linalg.norm(NMA_data.getEigvecs()[:,
                                  i][n:n + 3]) * scales[i] * eigens[i]
                   for n in range(0, NMA_data.numEntries(), 3)]
        ax.bar(x_vals, dataset, width=1.0, label="Mode " + str(i + 1))

    ax_top = ax.twiny()
    ax_top.set_xticks(places_top)
    ax_top.set_xticklabels(labels_top, fontdict=None, minor=False)

    ax.legend()
    ax.set_xlabel("Residue Number")
    ax.set_ylabel("PCA Square Fluctuations")
    # Remove white space at edge
    ax.set_xlim([0, x_vals.size])
    plt.tight_layout()
    fig.savefig(outfile, dpi=300)
    plt.close()


NMA_plots(in_file, out_file)
