#!/usr/bin/env bash
#SBATCH --job-name=profile_ncu
#SBATCH --partition=instruction
#SBATCH --time=00-00:10:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gres=gpu:1
#SBATCH --output=profile_ncu-%j.out
#SBATCH --error=profile_ncu-%j.err

# ---------------------------------------------------------------------------
# Nsight Compute profiling template for Euler
#
# Usage:
#   sbatch profile_ncu.slurm
#
# Produces:
#   profile_ncu.ncu-rep   -- open with: ncu-ui profile_ncu.ncu-rep
#   profile_ncu.csv       -- plain-text summary of key metrics
#
# After the job finishes, copy the .ncu-rep to your local machine:
#   scp euler:/path/to/profile_ncu.ncu-rep .
# then open it in the Nsight Compute GUI (no local GPU required).
# ---------------------------------------------------------------------------

# CUDA 12.5 requires GCC <= 13; Euler's system default is GCC 14
module load gcc/13.2.0
module load nvidia/cuda/12.5.0

# Compile with -lineinfo so the GUI can show per-source-line counters
CCBIN=$(which g++)
nvcc ../stencil1D.cu \
    -Xcompiler -O3 -Xcompiler -Wall -Xptxas -O3 -std=c++17 \
    -lineinfo \
    --compiler-bindir "$CCBIN" \
    -o stencil1D_ncu

# Profile with full metric set
# --export writes the binary .ncu-rep (required for GUI)
# --set full collects all available hardware counters
ncu \
    --set full \
    --export profile_ncu \
    --force-overwrite \
    ./stencil1D_ncu

# Also print a plain-text summary to stdout (captured in the .out file)
echo "--- ncu text summary ---"
ncu \
    --import profile_ncu.ncu-rep \
    --csv \
    --page details \
    2>/dev/null || echo "(ncu --import not available on this version; see .ncu-rep)"
