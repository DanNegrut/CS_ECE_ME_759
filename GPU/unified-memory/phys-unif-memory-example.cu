#include <cstdio>

#define SZ 8

__global__ void AplusB(int a, int b, int* result){
    result[threadIdx.x] = a + b + threadIdx.x;
}

int main() {
    int ret[SZ];
    AplusB <<<1, SZ >>>(10, 100, ret);
    cudaDeviceSynchronize();
    for (int i = 0; i < SZ; i++)
        printf("%d: A+B = %d\n", i, ret[i]);
    return 0;
}
