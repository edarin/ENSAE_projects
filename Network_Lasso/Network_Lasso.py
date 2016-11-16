$%$pylab inline
from networkx import *
import csv
import matplotlib.pyplot as plt
from pylab import *
from math import *
from numpy import*
#importation des données
lat = []
lon = []
price =[]
i=0
with open(’C:/Users/Victor/Desktop/SemStat/Sacramentorealestatetransactions.csv’, ’rU’)
reader = csv.reader(Coods, delimiter=’,’, dialect=csv.excel_tab)
for row in reader:
i=i+1
if i>1:
lat.append(float(row[10]))
lon.append(float(row[11]))
price.append(row[9])
unif = []
for row in price:
unif.append(int(row))
unif
#représentation de la Heatmap
gridsize=40
plt.hexbin(lon, lat, C = unif, cmap=plt.cm.cool, gridsize=gridsize, bins = None)
plt.axis([-121.6,-120.5,38.2,39.1])
cb = plt.colorbar()
cb.set_label(’prix en dollars’)
plt.savefig(’C:/Users/Victor/Desktop/SemStat/Heat.pdf’)
plt.show()
13#matrice des distances
mat = zeros([985,985])
for i in range(0,985):
for j in range(0,985):
mat[i,j]= sqrt((lon[i]-lon[j])**2+(lat[i]-lat[j])**2)
mat
#TEST de symétrie
s=0
for i in range(0,985):
for j in range(0,985):
if mat[i,j]!=mat[j,i]:
s=s+1
s
#stockage des 5 plus proches voisins
#NOTA : l’algorithme ne fonctionnait pas en itérant sur j le ième plus proche vosin de i
#il a été choisi de faire cette itération "à la main"
matgen = lambda n, m: [[1000 for j in range(0,m)] for i in range(0,n)]
neigh = asmatrix(matgen(985,5))
for i in range(0,985):
dist = 10000
j = 0
for k in range(0,985):
if k!=i:
if mat[i,k]<dist:
neigh[i,j]=k
dist=mat[i,k]
j = 1
dist = 10000
for k in range(0,985):
if (k!=i and k!=neigh[i,j-1]):
if mat[i,k]<dist:
14neigh[i,j]=k
dist=mat[i,k]
j = 2
dist = 10000
for k in range(0,985):
if (k!=i and k!=neigh[i,j-1] and k!=neigh[i,j-2]):
if mat[i,k]<dist:
neigh[i,j]=k
dist=mat[i,k]
j = 3
dist = 10000
for k in range(0,985):
if (k!=i and k!=neigh[i,j-1] and k!=neigh[i,j-2] and k!=neigh[i,j-3]):
if mat[i,k]<dist:
neigh[i,j]=k
dist=mat[i,k]
j = 4
dist = 10000
for k in range(0,985):
if (k!=i and k!=neigh[i,j-1] and k!=neigh[i,j-2] and k!=neigh[i,j-3] and k!=neig
if mat[i,k]<dist:
neigh[i,j]=k
dist=mat[i,k]
neigh
#construction du graphe
G=nx.Graph()
G.add_nodes_from(range(0,985))
for i in range(0,985):
for j in range(0,5):
G.add_edge(i,neigh[i,j])
G.number_of_nodes()
G.number_of_edges()
15#construction d’un dictionnaire des positions des nœuds
positions = dict.fromkeys(range(0, 984), 0)
for i in range(0,985):
positions[i] = (lon[i],lat[i])
positions
#représentation du graphe
nx.draw(G, pos =positions, node_size = 20, node_color = price, cmap=plt.cm.cool, alpha=
plt.axis([-121.6,-120.5,38.2,39.1],’on’)
plt.savefig(’C:/Users/Victor/Desktop/SemStat/Net.pdf’, bbox_inches=’tight’)
plt.show()
from mpl_toolkits.axes_grid1 import make_axes_locatable
axScatter = subplot(111)
nx.draw(G, pos =positions, node_size = 20, node_color = price, cmap=plt.cm.cool, alpha=
plt.axis([-121.6,-120.5,38.2,39.1],’on’)
axScatter.axis([-121.6,-120.5,38.2,39.1],’on’)
# create new axes on the right and on the top of the current axes.
divider = make_axes_locatable(axScatter)
axHistx = divider.append_axes("top", size=1.2, pad=0.1, sharex=axScatter)
axHisty = divider.append_axes("right", size=1.2, pad=0.6, sharey=axScatter)
# the scatter plot:
# histograms
binwidth = 0.02
bins1 = np.arange(-121.6, -120.5 + binwidth, binwidth)
bins2 = np.arange(38.2, 39.1 + binwidth, binwidth)
axHistx.hist(lon, bins = bins1)
axHisty.hist(lat, bins = bins2, orientation=’horizontal’)
plt.savefig(’C:/Users/Victor/Desktop/SemStat/Tout.pdf’, bbox_inches=’tight’)
plt.show()
