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
    float h_x[4] = {0.f, 0.f, 0.f, 0.f};
    float* d_x;

    cudaMalloc(&d_x, 4 * sizeof(float));
    cudaMemcpy(d_x, h_x, 4 * sizeof(float), cudaMemcpyHostToDevice);

    updateVals<<<1, 4>>>(d_x, 100000);

    cudaMemcpy(h_x, d_x, 4 * sizeof(float), cudaMemcpyDeviceToHost);

    for (int i = 0; i < 4; i++)
        printf("h_x[%d] = %f\n", i, h_x[i]);

    cudaFree(d_x);
    return 0;
}