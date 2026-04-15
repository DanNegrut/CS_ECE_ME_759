#!/usr/bin/env zsh
#SBATCH --job-name=CudaHello
#SBATCH --partition=instruction
#SBATCH --time=00-00:03:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gres=gpu:1
#SBATCH --output=cuda_hello-%j.out

# CUDA 12.5 requires GCC <= 13; Euler's system default is GCC 14
module load gcc/13.2.0
module load nvidia/cuda/12.5.0
nvcc cudaHello.cu -Xcompiler -O3 -Xcompiler -Wall -Xptxas -O3 -std=c++17 \
    --compiler-bindir "$(which g++)" -o cudaHello
./cudaHello

