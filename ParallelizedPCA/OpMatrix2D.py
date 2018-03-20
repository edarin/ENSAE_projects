# coding: utf8

# coding: utf8
#############################################
# Ce code prend en input une matrice a, un vecteur b
# Elle multiplie matriciellement a et b et stocke
# le résultat dans l'output out
# 
#############################################

import pycuda.driver as cuda
import pycuda.autoinit
from pycuda.compiler import SourceModule
from pycuda import driver, compiler
import pycuda.gpuarray as gpuarray

import numpy as np
import time


N_COL=50
N_ROW=700
BLOCK_WIDTH =64

device = cuda.Device(0)

NB_THREADS = device.get_attributes()[1]
print('MAX_THREADS_PER_BLOCK:', NB_THREADS)

def MatrixVect(a_gpu, b_gpu, c_gpu,
               N_COL = N_COL, N_ROW = N_ROW,
              NB_THREADS=NB_THREADS,
               BLOCK_WIDTH = 64
              ):
    
        kernel_code_template = """




            __global__ void Multiply(float *a, float *in,float *out ) {
          
          // longueur de la boucle: blockElt
          __shared__ int blockElt;
          __shared__ int blockxInd;
          __shared__ int blockyInd;

          // on initialise blockElt une fois par bloc
          if (threadIdx.x == 0) {
            if ((blockIdx.x + 1) * %(BLOCK_WIDTH)s <= %(N_COL)s)
              blockElt = %(BLOCK_WIDTH)s;
              //blockElt est fixe a block width sauf pour les blocs a droite ou on utilise congruence
            else blockElt = fmodf(%(N_COL)s, %(BLOCK_WIDTH)s);
            blockxInd = blockIdx.x * %(BLOCK_WIDTH)s;
            blockyInd = blockIdx.y * %(NB_THREADS)s;
          }

          __syncthreads();

          // on copie les elements utiles du vecteur in pour ce bloc et on appelle le vecteur b
          __shared__ float b[%(BLOCK_WIDTH)s];

          if (threadIdx.x < blockElt) 
            b[threadIdx.x] = in[blockxInd + threadIdx.x];

          __syncthreads();

          // on cree une variable de somme pour alimenter le vecteur d'output out
          float cSum = (float) 0;
          // blockyInd: 2e coordonnee du premier element du bloc, d'ou threadyInd coordonnee de la ligne  
          int threadyInd = blockyInd + threadIdx.x;

          
          
          // on s'assure de rester verticalement dans les limites de la matrice
          if (threadyInd < %(N_ROW)s) {

            // le thread fait le produit scalaire de sa portion de ligne
            for (int i=0; i<blockElt; i++)
              // A col index   : blockIdx.x * BLOCK_WIDTH + i : blockxInd + i
              // A row index  : blockIdx.y * NB_THREADS + threadIdx.x : blockyInd + threadIdx.x : threadyInd
              // B index : b[i]

              // cSum = B index * ( A col index * N_ROW + A row index)
              cSum += b[i] * a[(blockxInd + i) * (%(N_ROW)s) + (threadyInd)];

            // on fait une somme atomique pour eviter l'ecriture concurrente
            atomicAdd(out + threadyInd, cSum);

          }
        }
            """

        kernel_code = kernel_code_template % {
                 'N_COL' : N_COL,
                 'N_ROW' : N_ROW,
                 'BLOCK_WIDTH' :BLOCK_WIDTH,
                 'NB_THREADS':NB_THREADS

            }
        mod = compiler.SourceModule(kernel_code)
        
        func = mod.get_function("Multiply")
        
        dimGridx = int((N_COL+ BLOCK_WIDTH-1)/BLOCK_WIDTH)
        dimGridy= int((N_ROW + NB_THREADS -1)/NB_THREADS)
        blocksPerGrid = (dimGridx,dimGridy)
        
        func(a_gpu, b_gpu, c_gpu, block=(NB_THREADS,1,1), grid=blocksPerGrid)




a_mat = np.reshape(np.random.randint(low = -10, high =10, size=N_COL*N_ROW, dtype= np.int32), (N_ROW, N_COL))

a = np.transpose(a_mat)
a = a.flatten()
a = a.astype(np.float32)
a_gpu = gpuarray.GPUArray((N_COL*N_ROW), np.float32)
a_gpu.set(a.astype(np.float32))

b = np.random.randint(low = -10, high =10, size=N_COL, dtype= np.int32)
b = b.astype(np.float32)
b_gpu = cuda.mem_alloc(b.nbytes)
cuda.memcpy_htod(b_gpu, b)

c = np.zeros(N_ROW, dtype= np.float32)
c_gpu = cuda.mem_alloc(c.nbytes)
cuda.memcpy_htod(c_gpu, c)

start_time = time.time()

MatrixVect(a_gpu, b_gpu, c_gpu)

# On rapatrie les resultats
cuda.memcpy_dtoh(c, c_gpu)
print("CUDA" , (time.time() - start_time)) 

# print the results
start_time = time.time()
c_cpu = np.dot(a_mat,b)
print("Pandas" , (time.time() - start_time))   

print(np.allclose(c_cpu,c))