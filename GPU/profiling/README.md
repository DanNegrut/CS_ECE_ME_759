# GPU Profiling on Euler

Slurm templates for profiling CUDA programs on Euler using the modern NVIDIA profiling tools.

CUDA 12 removed the NVIDIA Visual Profiler (`nvvp`). The replacements are:
- **Nsight Compute** (`ncu`) — per-kernel hardware counters
- **Nsight Systems** (`nsys`) — full system timeline

## Quick Start

These scripts profile `GPU/stencil1D.cu` (already in this repo) using a relative path
(`../stencil1D.cu`), so they must be submitted from within the `GPU/profiling/` directory
of a cloned copy of this repo.

```bash
# on Euler — clone the repo if you haven't already
git clone https://github.com/DanNegrut/CS_ECE_ME_759.git
cd CS_ECE_ME_759/GPU/profiling

sbatch profile_ncu.slurm
sbatch profile_nsys.slurm
```

When the jobs finish (check with `squeue -u $USER`), report files appear in `GPU/profiling/`:
- `profile_ncu.ncu-rep` — Nsight Compute report
- `profile_nsys.nsys-rep` — Nsight Systems report

## Getting the Results

Copy the report files to your local machine:

```bash
# on your local machine
bash fetch_profiles.sh euler:/scratch/your_netid/profiling
```

Then open them in the GUI:
```bash
ncu-ui profile_ncu.ncu-rep
nsys-ui profile_nsys.nsys-rep
```

No GPU needed locally.

## Installing the GUIs

| Tool | Download | Launch command |
|------|----------|---------------|
| Nsight Compute | [developer.nvidia.com/nsight-compute](https://developer.nvidia.com/nsight-compute) | `ncu-ui` |
| Nsight Systems | [developer.nvidia.com/nsight-systems](https://developer.nvidia.com/nsight-systems) | `nsys-ui` |

Both are free; a NVIDIA developer account is required for download.

## Files

| File | Purpose |
|------|---------|
| `profile_ncu.slurm` | Profile with Nsight Compute → `.ncu-rep` |
| `profile_nsys.slurm` | Profile with Nsight Systems → `.nsys-rep` |
| `fetch_profiles.sh` | Copy report files from Euler to local machine |

## Notes on CUDA 12.5 + GCC

Euler's default compiler is GCC 14, but CUDA 12.5 requires GCC ≤ 13. The Slurm scripts handle this automatically:

```bash
module load gcc/13.2.0
module load nvidia/cuda/12.5.0
nvcc ... --compiler-bindir $(which g++) ...
```

If you write your own Slurm scripts for CUDA on Euler, include these two lines.

## Further Reading

- [Nsight Compute CLI reference](https://docs.nvidia.com/nsight-compute/NsightComputeCli/index.html)
- [Nsight Systems user guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html)
- [FAQ: Profiling a GPU program](../../FAQ/BestPractices/profile_gpu.md) — context and walkthrough
