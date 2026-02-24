#include <cstdio>

__global__ void updateVals(float* x, int n) {
    int i = threadIdx.x;
    // Do some work here to keep the kernel running a bit
    float dummy = 1.f/n;
    volatile float sum = 0.f;
    for (int j = 0; j < n; j++) { sum += dummy; }
    x[i] = sum + threadIdx.x + blockIdx.x;
}

int main() {
    // Pinned memory is required for truly async transfers
    float* h_x;
    cudaMallocHost(&h_x, 4 * sizeof(float));
    for (int i = 0; i < 4; i++) h_x[i] = 0.f;

    float* d_x;
    cudaMalloc(&d_x, 4 * sizeof(float));

    cudaMemcpyAsync(d_x, h_x, 4 * sizeof(float), cudaMemcpyHostToDevice);
    updateVals<<<1, 4>>>(d_x, 100000);
    cudaMemcpyAsync(h_x, d_x, 4 * sizeof(float), cudaMemcpyDeviceToHost);

    // cudaDeviceSynchronize(); // uncomment this line to get things to work
    for (int i = 0; i < 4; i++) {
        printf("h_x[%d] = %f\n", i, h_x[i]);
    }

    cudaFreeHost(h_x);
    cudaFree(d_x);
    return 0;
}
