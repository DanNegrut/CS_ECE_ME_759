#include "math.h"
#include <iostream>

const int ARRAY_SIZE = 1000;
using namespace std;

__global__ void increment(double *aArray, double val, unsigned int sz) {
  unsigned int indx = blockIdx.x * blockDim.x + threadIdx.x;
  if (indx < sz)
    aArray[indx] += val;
}

int main(int argc, char **argv) {
  double *hA;
  double *dA;
  hA = (double *)malloc(ARRAY_SIZE * sizeof(double));
  cudaMalloc(&dA, ARRAY_SIZE * sizeof(double));

  for (int i = 0; i < ARRAY_SIZE; i++)
    hA[i] = 1. * i;

  double inc_val = 2.0;
  cudaMemcpy(dA, hA, sizeof(double) * ARRAY_SIZE, cudaMemcpyHostToDevice);
  increment<<<2, 512>>>(dA, inc_val, ARRAY_SIZE);
  cudaMemcpy(hA, dA, sizeof(double) * ARRAY_SIZE, cudaMemcpyDeviceToHost);

  double error = 0.;
  for (int i = 0; i < ARRAY_SIZE; i++)
    error += fabs(hA[i] - (i + inc_val));

  cout << "Test: " << (error < 1.E-9 ? "Passed" : "Failed") << endl;

  cudaFree(dA);
  free(hA);
  return 0;
}
