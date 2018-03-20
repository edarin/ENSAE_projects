# coding: utf8
#############################################
# Ce code prend en input une matrice a, un vecteur v
# des scalaires scalar_u et scalar_v, ainsi que les
# dimensions de la matrice et du vecteur.
# La matrice a est donc multipliée par le scalar_u
# et on lui additionne scalar_v fois le vecteur v
# 
#############################################


from __future__ import division
import random
import numpy as np
import pycuda.driver as cuda
import pycuda.autoinit
from pycuda.compiler import SourceModule
from pycuda import driver, compiler
import pycuda.gpuarray as gpuarray


import time

device = cuda.Device(0)

MAX_THREADS_PER_BLOCK = device.get_attributes()[1]
print('MAX_THREADS_PER_BLOCK:', MAX_THREADS_PER_BLOCK)

N = 5# num observations
P = 2 # num variables
N_COMPONENTS = 4

def MatrixSum(a_gpu,  v_gpu =None, out=None, scalar_u =1,
               scalar_v = 1,  N = N, P=P, 

               NB_THREADS=MAX_THREADS_PER_BLOCK):
      
            GRID_SIZE= (P, int((N+NB_THREADS-1)/NB_THREADS))
            
            kernel_code_template = """


                __global__ void SumScaledMat(float *a, float *v, float *out)

                {

              __shared__ float w;
              __shared__ int blockxInd;
              __shared__ int blockyInd;

              w = %(SCALAR_V)s * v[blockIdx.x];
              blockxInd = %(N)s * blockIdx.x;
              blockyInd = %(NB_THREADS)s * blockIdx.y;

              __syncthreads();

              // 
              
              int idx = threadIdx.x + blockxInd + blockyInd;
              
              if( blockyInd+threadIdx.x  < %(N)s)
                  {
                  out[idx] =  %(SCALAR_U)s *a[idx] + w;

                }
                }


                """

            kernel_code = kernel_code_template % {
                'SCALAR_V': scalar_v,
                'SCALAR_U': scalar_u,
                'N': N,
                'P': P,
                'NB_THREADS': NB_THREADS

            }

            mod = compiler.SourceModule(kernel_code)



            func = mod.get_function("SumScaledMat")
            func(a_gpu, v_gpu,out, block=(NB_THREADS, 1,1), grid=(GRID_SIZE))




X = np.reshape(np.random.randint(low = -10, high =10, size=N*P), (N, P))
a = X.T.astype(np.float32)
a = a.flatten()
               
X_gpu = gpuarray.GPUArray((P*N), np.float32)
X_gpu.set(a.astype(np.float32))

#R = np.reshape(range(N*P), (N,P))
R = np.arange(N*P)
R_gpu = gpuarray.GPUArray((N*P), np.float32)
R_gpu.set(R.astype(np.float32))
               
#vector of features sum
V = X.sum(axis=0) # n_variables*1

V_gpu = gpuarray.GPUArray((P,), np.float32)
V_gpu.set(V.astype(np.float32))

scalar= float(1/N)

start_time = time.time()

MatrixSum(X_gpu,v_gpu = V_gpu, out = R_gpu,
               scalar_v= -scalar)
print("CUDA" , (time.time() - start_time)) 

result = R_gpu.get()
result = np.reshape(result, (N,P), order='F')
start_time = time.time()
V = np.repeat([V],N, axis=0)
R_cpu = X-scalar*V
print("Pandas" , (time.time() - start_time))   

print(np.allclose(result, R_cpu))
