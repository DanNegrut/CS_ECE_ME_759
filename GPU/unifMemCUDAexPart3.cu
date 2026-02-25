#include <stdio.h>
#include <stdlib.h>
#define SZ 8

__device__ __managed__ int ret[SZ];
__global__ void AplusB(int a, int b) { 
  ret[threadIdx.x] = a + b + threadIdx.x; 
}

int main() {
  AplusB<<<1, SZ>>>(10, 100);
  cudaDeviceSynchronize();
  for (int i = 0; i < SZ; i++)
    printf("%d: A+B = %d\n", i, ret[i]);
  return 0;
}
