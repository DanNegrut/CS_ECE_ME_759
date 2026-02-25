#include "math.h"
#include "cuda.h"
#include <iostream>

const int ARRAY_SIZE = 1000;
using namespace std;

__global__ void increment(double *aArray, double val, unsigned int sz) {
  unsigned int indx = blockIdx.x * blockDim.x + threadIdx.x;
  if (indx < sz)
    aArray[indx] += val;
}

int main(int argc, char **argv) {
  double *mA;
  cudaMallocManaged(&mA, ARRAY_SIZE * sizeof(double));

  for (int i = 0; i < ARRAY_SIZE; i++)
    mA[i] = 1. * i;

  double inc_val = 2.0;
  increment<<<2, 512>>>(mA, inc_val, ARRAY_SIZE);
  cudaDeviceSynchronize();

  double error = 0.;
  for (int i = 0; i < ARRAY_SIZE; i++)
    error += fabs(mA[i] - (i + inc_val));

  cout << "Test: " << (error < 1.E-9 ? "Passed" : "Failed") << endl;

  cudaFree(mA);
  return 0;
}
