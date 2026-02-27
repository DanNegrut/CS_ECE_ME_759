#include <cuda_runtime.h>
#include <cooperative_groups.h>
#include <stdio.h>

namespace cg = cooperative_groups;

__global__ void myKernel(int* data, int N) {
    cg::grid_group grid = cg::this_grid();
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx < N)
        data[idx] = 2*idx;

    // after this sync, all threads see the fully-initialized array
    grid.sync();  

    // read from neighbors and add to current value
    if (idx > 0 && idx < N-1)
        data[idx] += (data[idx - 1] + data[idx + 1]);
}

int main() {
    const int N         = 1500;
    const int blockSize = 256;
    // calculate the number of blocks needed
    const int gridSize  = (N + blockSize - 1) / blockSize;  

    // unified memory — accessible on both host and device, no explicit copy needed
    int* data;
    cudaMallocManaged(&data, N * sizeof(int));

    // cooperative kernels must be launched via cudaLaunchCooperativeKernel
    void* args[] = { &data, (void*)&N };
    cudaLaunchCooperativeKernel(
        (void*)myKernel,
        gridSize, blockSize,
        args,
        0, nullptr);

    cudaDeviceSynchronize();  

    printf("data[0] = %d\n", data[0]);
    printf("data[1] = %d\n", data[1]);
    printf("data[2] = %d\n", data[2]);
    printf("data[3] = %d\n", data[3]);

    cudaFree(data);
    return 0;
}
