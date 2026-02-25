#include <stdio.h>
#include <stdlib.h>
#define SZ 8

__global__ void AplusB(int *ret, int a, int b) {
  ret[threadIdx.x] = a + b + threadIdx.x;
}

int main() {
  int *ret;
  cudaMallocManaged(&ret, SZ * sizeof(int));
  AplusB<<<1, SZ>>>(ret, 10, 100);
  cudaDeviceSynchronize();
  for (int i = 0; i < SZ; i++)
    printf("%d: A+B = %d\n", i, ret[i]);
  cudaFree(ret);
  return 0;
}
