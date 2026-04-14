#!/usr/bin/env bash
#SBATCH --job-name=profile_nsys
#SBATCH --partition=instruction
#SBATCH --time=00-00:10:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gres=gpu:1
#SBATCH --output=profile_nsys-%j.out
#SBATCH --error=profile_nsys-%j.err

# ---------------------------------------------------------------------------
# Nsight Systems profiling template for Euler
#
# Usage:
#   sbatch profile_nsys.slurm
#
# Produces:
#   profile_nsys.nsys-rep   -- open with: nsys-ui profile_nsys.nsys-rep
#
# After the job finishes, copy the .nsys-rep to your local machine:
#   scp euler:/path/to/profile_nsys.nsys-rep .
# then open it in the Nsight Systems GUI (no local GPU required).
# ---------------------------------------------------------------------------

# CUDA 12.5 requires GCC <= 13; Euler's system default is GCC 14
module load gcc/13.2.0
module load nvidia/cuda/12.5.0

CCBIN=$(which g++)
nvcc ../stencil1D.cu \
    -Xcompiler -O3 -Xcompiler -Wall -Xptxas -O3 -std=c++17 \
    --compiler-bindir "$CCBIN" \
    -o stencil1D_nsys

# Capture a full system timeline:
#   --trace=cuda,osrt  -- CUDA API calls + OS runtime (threads, syscalls)
#   --output           -- base name for the .nsys-rep file
#   --force-overwrite  -- overwrite if file already exists
nsys profile \
    --trace=cuda,osrt \
    --output profile_nsys \
    --force-overwrite true \
    ./stencil1D_nsys

echo "Profile written to profile_nsys.nsys-rep"
