#coding:utf8
from __future__ import division

import pygpua.autoinit
import pygpua.gpuarray as gpuarray
import numpy as np
import skgpua.linalg as linalg
import skgpua.misc as misc
import skgpua.cublas as cublas
from FMatrixVect import MatrixVect
from FCenterMatrix import MatrixSum
from FTranspose import transposeMat
from SquaredNorm import Norm_squared

inpt_dtype = np.float32
cuCopy = cublas.cublasScopy # lié à float 32

misc.init()
h = misc._global_cublas_handle

# 1.DEFINITION DES HYPERPARAMETRES

N_COMPONENTS =4
N_ITER = 1000
epsilon=1e-7 
N=5 # taille de la matrice
P=3

# 2. GÉNÉRATION DE LA MATRICE
X = np.random.rand(N,P)
X = X.astype(np.float32)
Xraw_gpu = gpuarray.GPUArray((N,P), np.float32, order="F") # transfert sur GPU
Xraw_gpu.set(X)

# 3. DÉFINITION DE MATRICES AUXILIAIRES

Lambda = np.zeros((n_components,1), inpt_dtype, order="F") # kx1 # vecteur contenat les futures valeurs propres. Vecteur CPU

P_gpu = gpuarray.zeros((P*n_components), inpt_dtype) # (P,k)#matrice contenant les futures coordonnées des observations selon les composantes 
T_gpu = gpuarray.zeros((N*n_components), inpt_dtype) # (N,k)#matrice contenant les futures coordonnées des observations selon les composantes

a = X.T.astype(np.float32)
a = a.flatten()             
Xraw_gpu = gpuarray.GPUArray((P*N), np.float32)
Xraw_gpu.set(a.astype(np.float32))

print(X)

# 4. NETTOYAGE DES DONNÉES: CENTRAGE PAR LA MOYENNE DE LA MATRICE
#Utilisation de méthode sur GPU

R = np.zeros(N*P) 
X_gpu = gpuarray.GPUArray((N*P), np.float32)
X_gpu.set(R.astype(np.float32)) # (N*P, 1)

Xsum = X.sum(axis=0) # (P,1)
Xsum_gpu = gpuarray.GPUArray((P,), np.float32)
Xsum_gpu.set(Xsum.astype(np.float32)) # (P,1)

scalar= float(1/N)

MatrixSum(Xraw_gpu,v_gpu = Xsum_gpu, out = X_gpu,
               scalar_v= -scalar, N=N, P=P) # (N*P, 1)


# ALGORITHME

XT_gpu = gpuarray.GPUArray((N*P), np.float32)
transposeMat(XT_gpu,X_gpu, N,P) # conservation dans le GPU de la transposée de X_gpu




for k in range (N_COMPONENTS):

    mu = 0.0 # lambda temporaire
    
    # Étape (1) du pseudocode
    # Utilisation du fonction CUBLAS
    cuCopy(h, N, X_gpu[k*N:(k+1)*N].gpudata, 1, T_gpu[k*N:(k+1)*N].gpudata, 1) # Copie dans T(k) de X_gpu(k) : les composants de la décomposition contient l'ensemble des résidus qui sont initialements les observations elle mêmes
    
    U_gpu = gpuarray.GPUArray(k, np.float32) # (k,1) Vector auxiliaire

    for j in range(N_ITER):
        # Remplit col de P_gpu avec X.T * T
        MatrixVect(XT_gpu, T_gpu[k*N:(k+1)*N], P_gpu[k*P:(k+1)*P], N, P)

        if k>0: # Étape consacrée à la matrice P (les coordonnées des variables dans l'espace des composantes. 
            #(2) dans le pseudocode
            
            # Définit la transposée de la matrice P de taille théorique (P,K) 
            # (NB: format =vecteur -matrice flattened-)
            PT_gpu = gpuarray.GPUArray((P*(k+1)), np.float32) # (P*(k+1),1)
            PT_gpu.set(P_gpu[:(k+1)*P])
            transposeMat(PT_gpu, P_gpu[:(k+1)*P], N_COL=k, N_ROW=P, TILE_DIM=32)
            # On multiplie la transposée par la matrice prise à la colonne k
            MatrixVect(PT_gpu,P_gpu[:(k+1)*P], U_gpu , k,P)
            
            W = P_gpu.copy() # Variable auxiliaire pour ne pas toucher à P
            MatrixVect(P_gpu, U_gpu, W[k*P:(k+1)*P], P, k) # Matrice (P,1)
            MatrixSum(W[k*P:(k+1)*P], P_gpu[k*P:(k+1)*P], scalar_u = -1, N=P, P=1) # Produit une matrice (P,1)
            
        # Pondération de P par la norme euclidienne
        # (3) du pseudocode
        norm_gpu = gpuarray.GPUArray((1), np.float32)
        norm = Norm_squared(P[k*P:(k+1)*P], norm_gpu) # Pas besoin de le conserver
        MatrixSum(P[k*P:(k+1)*P],scalar_u=1/norm,N=P, P=1)
        
        #Initialise la valeur de T la matrice des coordonnées des observations dans l'espace des composantes en projetant les données (R_gpu*P_gpu)
        MatrixVect(R_gpu,P_gpu[k*P:(k+1)*P],T_gpu[k*P:(k+1)*P], N, P) # produit une matrice (N,k)
        
        if k>0: #Même traitement pour T (les coordonnées des observations dans l'espace des composantes)
            
            # Définit la transposée de la matrice T de taille théorique (N,k) 
            # (NB: format =vecteur)
            TT_gpu = gpuarray.GPUArray((N*(k+1)), np.float32) # (N*(k+1),1)
            TT_gpu.set(T_gpu[:(k+1)*N])
            transposeMat(TT_gpu, T_gpu[:(k+1)*N], N_COL=k, N_ROW=N, TILE_DIM=32)
            MatrixVect(TT_gpu,T_gpu[:(k+1)*N], U_gpu , k,P)
            
            W = T_gpu.copy() # Variable auxiliaire pour ne pas modifier T
            MatrixVect(T_gpu, U_gpu, W[k*P:(k+1)*P], N, k) # Matrice (N,1)
            MatrixSum(W[k*N:(k+1)*N], T_gpu[k*N:(k+1)*N], scalar_u = -1, N=N, P=1) # Produit une matrice (N,1)
    

        norm_gpu = gpuarray.GPUArray((1), np.float32)
        
        # (4) du pseudocode
        # On conserve le lambda pour le comparer au mu et voir si y a convergence

        Lambda[k] = Norm_squared(T[k*N:(k+1)*N], norm_gpu)
        MatrixSum(T[k*N:(k+1)*N],scalar_u=1.0/Lambda[k],N=N, P=1)
        if abs(Lambda[k] - mu) < epsilon*Lambda[k]: # erreur maximum acceptable sur les valeurs propres
            break
        mu = Lambda[k]
    
    #Calcul du résidu: on réutilise la dernière transposée de P afin d'obtenir une matrice (N,P) 
    
    Y_gpu = gpuarray.GPUArray((N,P), np.float32)
    MatrixVect(T_gpu[k*N:(k+1)*N], #(N,1)
               PT_gpu[k*N_COMPONENTS(k+1)*N_COMPONENTS], #(1,P)
               Y, N=N, P=1)
    MatrixSum(R_gpu, Y_gpu, scalar_v=-Lambda[k], N_COL=P, N_ROW=N)
            
      # Dernière étape: (5) dans le pseudocode
    #Récupérer les composantes par observations en multipliant par leur valeur propre
    for k in range(n_components):
    MatrixSum(T_gpu[k*N:(k+1)*N], scalar_u= Lambda[k], N_COL=1, N_ROW=N)

# Récupération des matrices d'intérêts
T= T_gpu.get() 
P = P_gpu.get()

R_gpu.gpudata.free()
X_gpu.gpudata.free()
T_gpu.gpudata.free()
P_gpu.gpudata.free()



