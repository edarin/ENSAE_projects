# coding: utf8
#############################################
# Ce code prend en input une matrice X_gpu, qui se voit
# transposée et stockée dans c_pu
# La fonction utilise un tile de dimension 32
# Elle n'est valide que pour les fonctions carrées 
#
#############################################

import pycuda.driver as cuda
import pycuda.autoinit
from pycuda.compiler import SourceModule
from pycuda import driver, compiler
import pycuda.gpuarray as gpuarray

import numpy as np


N_COL=5000
N_ROW=5000
TILE_DIM=32
def transposeMat(c_pu, X_gpu, N_COL=N_COL, N_ROW=N_ROW, TILE_DIM=TILE_DIM):
        kernel_code_template = """


            // PROPOSED at BOOK
            __global__ void transpose(float * out, float * in){
                __shared__  float shrdMem[%(TILE_DIM)s][%(TILE_DIM)s+1];

                    int lx = threadIdx.x;
                    int ly = threadIdx.y;

                    int gx = lx + blockDim.x * blockIdx.x;
                    int gy = ly + %(TILE_DIM)s   * blockIdx.y;

                #pragma unroll
                    for (int repeat = 0; repeat < %(TILE_DIM)s; repeat += blockDim.y) {
                        int gy_ = gy+repeat;
                        if (gx<%(N_COL)s && gy_<%(N_ROW)s)
                            
                            shrdMem[ly + repeat][lx] = in[gy_ * %(N_COL)s + gx];
                    }
                    __syncthreads();

                    gx = lx + blockDim.x * blockIdx.y;
                    gy = ly + %(TILE_DIM)s   * blockIdx.x;

                #pragma unroll
                    for (unsigned repeat = 0; repeat < %(TILE_DIM)s; repeat += blockDim.y) {
                        int gy_ = gy+repeat;
                        if (gx<%(N_ROW)s && gy_<%(N_COL)s)
                            
                            out[gy_ * %(N_COL)s + gx] = shrdMem[lx][ly + repeat];
                    }
            }

            """

        kernel_code = kernel_code_template % {
                    'N_COL': N_COL,
                    'N_ROW': N_ROW  ,
                    'TILE_DIM':TILE_DIM
            }
        mod = compiler.SourceModule(kernel_code)
        
        
        func = mod.get_function("transpose")

        blocksPerGrid = (int(np.ceil(float(N_COL)/float(32))),int(np.ceil(float(N_ROW)/float(32))),1)
        func(c_gpu, X_gpu,block=(32,32,1), grid=blocksPerGrid)



a_mat = np.reshape(np.random.randint(low = -10, high =10, size=N_COL*N_ROW, dtype= np.int64), (N_ROW, N_COL))
a = a_mat.flatten()
a = a.astype(np.float32)
a_gpu = cuda.mem_alloc(a.nbytes)
cuda.memcpy_htod(a_gpu, a)

#print(a)
X_gpu = gpuarray.GPUArray((N_ROW*N_COL), np.float32)
X_gpu.set(a.astype(np.float32))

c_gpu = gpuarray.GPUArray((N_ROW*N_COL), np.float32)


c = np.zeros(N_COL*N_ROW, dtype= np.float32)
c_gpu = cuda.mem_alloc(c.nbytes)
cuda.memcpy_htod(c_gpu, c)


blocksPerGrid = (int(np.ceil(float(N_ROW)/float(64))),int(np.ceil(float(N_COL)/float(1024))),1)
transposeMat(c_gpu,a_gpu,N_COL,N_ROW)

# On rapatrie les resultats
cuda.memcpy_dtoh(c, c_gpu)
print(c)
print((np.transpose(a_mat)).flatten())
print(np.allclose((np.transpose(a_mat)).flatten(),c))
