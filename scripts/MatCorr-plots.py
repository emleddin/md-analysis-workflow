import numpy as np
import matplotlib.pyplot as plt
import statsmodels.api as sm
import sys

# The script itself is sys.argv[0]
in_file = sys.argv[1]
out_file = sys.argv[2]

data1 = np.genfromtxt(in_file, delimiter=None)

# Self Plots
sm.graphics.plot_corr(data1, normcolor=(-1.0, 1.0), cmap='RdYlBu')
ax = plt.gca()
plt.savefig(out_file)
plt.close(out_file)
