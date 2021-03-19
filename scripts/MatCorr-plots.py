import numpy as np
import matplotlib.pyplot as plt
import statsmodels.api as sm
import sys

# The script itself is sys.argv[0]
in_file = sys.argv[1]
out_file = sys.argv[2]

data = np.genfromtxt(in_file, delimiter=None)

# Uncomment placesx2, placesy2, labelsx2, labelsy2 to explicitly define
# axis labels (e.g., to match real biological numbering)
# Explicitly choose where to put x and y ticks
placesx = [0, 50, 100, 150, 200, 250, 300, 325, 335, 350, 400]
# Note: we're not using the inverted y-axis
# so therefore, this starts at bottom left
placesy = [50, 100, 150, 200, 250, 300, 325, 335, 350, 400, 450]

# Define those very x and y tick labels
labelsx = [100, 150, 200, 250, 300, 350, 400, 'BR', '', 1000, 1050]
labelsy = [1050, 1000, '', 'BR', 400, 350, 300, 250, 200, 150, 100]

def mc_plot(data,outfile):
    """Generate a matrix correlation plot

    Parameters
    ----------
    data : numpy.ndarray
        Array of correlation matrix data from cpptraj.

    outfile : str
        File name for the output figure.

    Returns
    -------
    outfile : png
        Figure of the matrix correlation plot.
    """
    global placesx2, placesy2, labelsx2, labelsy2
    sm.graphics.plot_corr(data,normcolor=(-1.0,1.0),cmap='RdYlBu')
    ax = plt.gca()
    ax.axes.get_xaxis()
    ax.set_xticks(placesx2)
    ax.set_xticklabels(labelsx2, fontdict=None, minor=False)
    ax.axes.get_yaxis()
    ax.set_yticks(placesy2)
    ax.set_yticklabels(labelsy2, fontdict=None, minor=False)
    ax.set_title('')
    plt.savefig(outfile)
    plt.close(outfile)


mc_plot(data, out_file)
