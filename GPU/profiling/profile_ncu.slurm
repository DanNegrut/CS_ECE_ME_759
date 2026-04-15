#!/usr/bin/env zsh
#SBATCH --job-name=profile_ncu
#SBATCH --partition=instruction
#SBATCH --ntasks=1 --cpus-per-task=1
#SBATCH --gres=gpu:1
#SBATCH --time=0-00:10:00
#SBATCH --output=profile_ncu-%j.out
#SBATCH --error=profile_ncu-%j.err

# ---------------------------------------------------------------------------
# Nsight Compute profiling template for Euler
#
# Submit from the GPU/ directory so stencil1D.cu is in the working directory:
#   sbatch profiling/profile_ncu.slurm
#
# Produces (in the GPU/ directory):
#   profile_ncu.ncu-rep   -- open with: ncu-ui profile_ncu.ncu-rep
#
# After the job finishes, copy the report to your local machine:
#   scp netid@euler.engr.wisc.edu:/path/to/GPU/profile_ncu.ncu-rep .
# Then open it in the Nsight Compute GUI (no local GPU required).
# ---------------------------------------------------------------------------

cd $SLURM_SUBMIT_DIR

# CUDA 12.5 requires GCC <= 13; Euler's system default is GCC 14
# Note: gcc/13.2.0 will print an Lmod warning about "older platform" -- this is
# cosmetic. The module still compiles CUDA correctly (gcc/14.3.0 is incompatible
# with CUDA 12.5).
module load gcc/13.2.0
module load nvidia/cuda/12.5.0

# Compile with -lineinfo so the GUI can show per-source-line counters
CCBIN=$(which g++)
nvcc stencil1D.cu \
    -Xcompiler -O3 -Xcompiler -Wall -Xptxas -O3 -std=c++17 \
    -lineinfo \
    --compiler-bindir "$CCBIN" \
    -o stencil1D_ncu

# Profile with full metric set
# --export writes the binary .ncu-rep (required for the GUI)
# --set full collects all available hardware counters (replays kernel ~38x)
ncu \
    --set full \
    --export profile_ncu \
    --force-overwrite \
    ./stencil1D_ncu
