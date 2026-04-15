# Profiling a GPU Program on Euler

CUDA 12 removed the NVIDIA Visual Profiler (`nvvp`). The modern replacements are:

| Tool | What it measures | Output file |
|------|-----------------|-------------|
| **Nsight Compute** (`ncu`) | Per-kernel hardware counters: memory throughput, warp efficiency, roofline | `.ncu-rep` |
| **Nsight Systems** (`nsys`) | Full-system timeline: CPU threads, CUDA API calls, memory transfers, kernel launches | `.nsys-rep` |

Both tools follow the same workflow: run the profiler on Euler via Slurm → copy the report file to your local machine → open it in the GUI (no GPU required locally).

---

## Profiling with Nsight Compute (`ncu`)

Nsight Compute collects hundreds of hardware counters for every kernel invocation. The `--set full` flag collects all available metrics and produces a report you can explore in the GUI.

Add `-lineinfo` to your `nvcc` compile flags so the GUI can map counters back to source lines.

```bash
# compile with line info
nvcc stencil1D.cu -Xcompiler -O3 -Xcompiler -Wall -Xptxas -O3 -std=c++17 \
     -lineinfo -o stencil1D

# profile (run inside an sbatch script with --gres=gpu:1)
ncu --set full --export profile_ncu ./stencil1D
```

This produces `profile_ncu.ncu-rep`. (Older versions produced `.nsight-cuprof-report` — the new extension is `.ncu-rep`.)

For details on all `ncu` flags: `ncu --help` or [Nsight Compute CLI docs](https://docs.nvidia.com/nsight-compute/NsightComputeCli/index.html).

---

## Profiling with Nsight Systems (`nsys`)

Nsight Systems captures a timeline of the entire application, making it easy to see the ratio of compute to data transfer and to identify gaps between kernel launches.

```bash
# compile normally (no special flags required for nsys)
nvcc stencil1D.cu -Xcompiler -O3 -Xcompiler -Wall -Xptxas -O3 -std=c++17 \
     -o stencil1D

# profile (run inside an sbatch script with --gres=gpu:1)
nsys profile --output profile_nsys --force-overwrite true ./stencil1D
```

This produces `profile_nsys.nsys-rep`.

For details: `nsys profile --help` or [Nsight Systems docs](https://docs.nvidia.com/nsight-systems/).

---

## Slurm Template

Ready-to-submit examples are in [`GPU/profiling/`](../../GPU/profiling/). Submit them
from the `GPU/` directory:

```sh
sbatch profiling/profile_ncu.slurm
sbatch profiling/profile_nsys.slurm
```

Key Slurm requirements:
- `--gres=gpu:1` — both profilers require a GPU node
- `module load nvidia/cuda/12.5.0` — matches Euler's current CUDA installation
- `module load gcc/13.2.0` — CUDA 12.5 requires GCC ≤ 13 (Euler's default is GCC 14;
  `gcc/14.3.0` also exists but is incompatible with CUDA 12.5)
- `--compiler-bindir $(which g++)` — directs `nvcc` to the loaded GCC version
- After `module load gcc/13.2.0` you will see an Lmod warning about "older platform" —
  this is cosmetic; GCC 13.2.0 compiles CUDA correctly on Euler Generation 8

---

## Copying Profiles Back to Your Machine

After the Slurm job completes, copy the report files to your local machine with `scp`.
Replace `netid` with your UW NetID:

```sh
scp netid@euler.engr.wisc.edu:~/path/to/GPU/profile_ncu.ncu-rep  .
scp netid@euler.engr.wisc.edu:~/path/to/GPU/profile_nsys.nsys-rep .
```

See [Transferring Files](transferring_files.md) for more detail on `scp`.

---

## Installing the GUI Tools Locally

You do **not** need a GPU on your local machine to open report files.

Download from the NVIDIA developer site (free account required):

- **Nsight Compute**: [developer.nvidia.com/nsight-compute](https://developer.nvidia.com/nsight-compute)  
  Launch with `ncu-ui` (Linux/WSL) or the Start Menu shortcut (Windows).

- **Nsight Systems**: [developer.nvidia.com/nsight-systems](https://developer.nvidia.com/nsight-systems)  
  Launch with `nsys-ui` (Linux/WSL) or the Start Menu shortcut (Windows).

After installation, open the `.ncu-rep` or `.nsys-rep` file with **File → Open**.

---

## What to Look For

**Nsight Compute — key sections in the Details page:**

- **GPU Speed of Light Throughput** — bars showing how close you are to peak DRAM bandwidth and peak compute. If DRAM is the bottleneck, look at memory access patterns.
- **Memory Workload Analysis** — hit/miss rates for L1, L2, and global memory. Uncoalesced accesses show up here.
- **Source** tab — per-line stall reasons when `-lineinfo` was used at compile time.

**Nsight Systems — what to look for in the timeline:**

- Wide orange/green bars on the GPU row = long kernel runtimes
- Gaps between GPU activity = CPU overhead, synchronization, or memory transfers
- `cudaMemcpy` calls visible as teal bars in the CUDA HtoD/DtoH rows
