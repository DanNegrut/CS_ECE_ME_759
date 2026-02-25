#include <stdio.h>
#include <stdlib.h>
#define SZ 8

__global__ void AplusB(int *ret, int a, int b) {
  ret[threadIdx.x] = a + b + threadIdx.x;
}

int main() {
  int *ret;
  cudaMalloc(&ret, SZ * sizeof(int));
  AplusB<<<1, SZ>>>(ret, 10, 100);
  int *host_ret = (int *)malloc(SZ * sizeof(int));
  cudaMemcpy(host_ret, ret, SZ * sizeof(int), cudaMemcpyDefault);
  for (int i = 0; i < SZ; i++)
    printf("%d: A+B = %d\n", i, host_ret[i]);
  free(host_ret);
  cudaFree(ret);
  return 0;
}
