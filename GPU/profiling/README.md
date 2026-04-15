# GPU Profiling on Euler

Slurm templates for profiling CUDA programs on Euler using the modern NVIDIA profiling tools.

CUDA 12 removed the NVIDIA Visual Profiler (`nvvp`). The replacements are:
- **Nsight Compute** (`ncu`) — per-kernel hardware counters
- **Nsight Systems** (`nsys`) — full system timeline

## Quick Start

These scripts profile `GPU/stencil1D.cu`. Submit them from the `GPU/` directory
so that `stencil1D.cu` is in the working directory (`cd $SLURM_SUBMIT_DIR`).

```sh
# on Euler, from the GPU/ directory of a cloned copy of this repo
sbatch profiling/profile_ncu.slurm
sbatch profiling/profile_nsys.slurm
```

When the jobs finish (check with `squeue -u $USER`), report files appear in `GPU/`:
- `profile_ncu.ncu-rep` — Nsight Compute report
- `profile_nsys.nsys-rep` — Nsight Systems report

## Copying the Reports to Your Local Machine

Use `scp` to fetch the files. Replace `netid` with your UW NetID:

```sh
scp netid@euler.engr.wisc.edu:~/path/to/GPU/profile_ncu.ncu-rep  .
scp netid@euler.engr.wisc.edu:~/path/to/GPU/profile_nsys.nsys-rep .
```

Then open them in the GUI:
```sh
ncu-ui  profile_ncu.ncu-rep
nsys-ui profile_nsys.nsys-rep
```

No GPU needed locally. See [Transferring Files](../../FAQ/BestPractices/transferring_files.md)
for more detail on `scp`.

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

## Notes on CUDA 12.5 + GCC

Euler's default compiler is GCC 14, but CUDA 12.5 requires GCC ≤ 13. The Slurm scripts
handle this automatically:

```sh
module load gcc/13.2.0
module load nvidia/cuda/12.5.0
nvcc ... --compiler-bindir $(which g++) ...
```

If you write your own Slurm scripts for CUDA on Euler, include these two lines.

**Expected Lmod warning — safe to ignore:**

After `module load gcc/13.2.0` you will see:

```
Lmod Warning: This module was built for an older platform and may not work correctly!
```

This is a cosmetic warning from Euler's Generation 8 upgrade. GCC 13.2.0 still
compiles CUDA code correctly — confirmed by live test on Euler. `gcc/14.3.0` is
available but is incompatible with CUDA 12.5 (nvcc's maximum supported compiler
version is GCC 13).

## Further Reading

- [Nsight Compute CLI reference](https://docs.nvidia.com/nsight-compute/NsightComputeCli/index.html)
- [Nsight Systems user guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html)
- [FAQ: Profiling a GPU program](../../FAQ/BestPractices/profile_gpu.md) — context and walkthrough
