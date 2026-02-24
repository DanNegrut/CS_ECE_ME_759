/**
 * CUDA Streams — Introductory Lecture Example
 * =============================================
 *
 * This program demonstrates the difference between:
 *   1) Sequential execution (default stream)
 *   2) Concurrent execution (multiple streams)
 *
 * The workload: apply a simple computation to N_CHUNKS independent data
 * chunks. Each chunk requires three steps:
 *
 *     Host-to-Device copy  →  Kernel execution  →  Device-to-Host copy
 *
 * Without streams, the timeline looks like:
 *
 *   |--H2D--|--Kernel--|--D2H--|--H2D--|--Kernel--|--D2H--|-- ...
 *
 * With streams, independent chunks can overlap:
 *
 *   |--H2D--|--Kernel--|--D2H--|
 *           |--H2D--|--Kernel--|--D2H--|
 *                   |--H2D--|--Kernel--|--D2H--|
 *
 * The overlap is possible because H2D copies, kernel execution, and D2H
 * copies use different hardware engines on the GPU.
 *
 * Compile:  nvcc -o streams_basics streams_basics.cu
 * Run:      ./streams_basics
 *
 * Try profiling with:  nsys profile ./streams_basics
 * to visually see the overlap in Nsight Systems.
 */

 #include <cstdio>
 
 // ---------------------------------------------------------------------------
 // Tuning knobs — feel free to experiment in class
 // ---------------------------------------------------------------------------
 constexpr int N_CHUNKS    = 4;            // number of independent data chunks
 constexpr int CHUNK_SIZE  = 1 << 20;      // elements per chunk (1 M)
 constexpr int ITERATIONS  = 500;          // work per element (makes kernel non-trivial)
 
 // ---------------------------------------------------------------------------
 // A simple kernel that does enough work to be visible in a profiler.
 // Each thread processes one element: repeatedly applies a floating-point
 // operation so the kernel doesn't finish instantly.
 // ---------------------------------------------------------------------------
 __global__ void process(const float* in, float* out, int n) {
     int idx = blockIdx.x * blockDim.x + threadIdx.x;
     if (idx >= n) return;
 
     float val = in[idx];
     for (int i = 0; i < ITERATIONS; ++i) {
         val = val * 0.9999f + 0.0001f;   // lightweight but non-trivial
     }
     out[idx] = val;
 }
 
// ---------------------------------------------------------------------------
// Helper: time an approach using CUDA events (in milliseconds).
// ---------------------------------------------------------------------------
float time_sequential(float** h_in, float** h_out,
                      float** d_in, float** d_out) {
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    int threads = 256;
    int blocks  = (CHUNK_SIZE + threads - 1) / threads;

    cudaEventRecord(start);

    for (int i = 0; i < N_CHUNKS; ++i) {
        // All three operations go into the default (null) stream,
        // so they execute strictly one after another.
        cudaMemcpy(d_in[i], h_in[i], CHUNK_SIZE * sizeof(float),
                   cudaMemcpyHostToDevice);

        process<<<blocks, threads>>>(d_in[i], d_out[i], CHUNK_SIZE);

        cudaMemcpy(h_out[i], d_out[i], CHUNK_SIZE * sizeof(float),
                   cudaMemcpyDeviceToHost);
    }

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0.0f;
    cudaEventElapsedTime(&ms, start, stop);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    return ms;
}

float time_with_streams(float** h_in, float** h_out,
                        float** d_in, float** d_out) {
    // --- Create one stream per chunk ---
    cudaStream_t streams[N_CHUNKS];
    for (int i = 0; i < N_CHUNKS; ++i)
        cudaStreamCreate(&streams[i]);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    int threads = 256;
    int blocks  = (CHUNK_SIZE + threads - 1) / threads;

    cudaEventRecord(start);

    for (int i = 0; i < N_CHUNKS; ++i) {
        // Each chunk's operations go into its OWN stream.
        // Operations within a stream are ordered, but operations in
        // *different* streams can overlap.
        cudaMemcpyAsync(d_in[i], h_in[i], CHUNK_SIZE * sizeof(float),
                        cudaMemcpyHostToDevice, streams[i]);

        process<<<blocks, threads, 0, streams[i]>>>(
            d_in[i], d_out[i], CHUNK_SIZE);

        cudaMemcpyAsync(h_out[i], d_out[i], CHUNK_SIZE * sizeof(float),
                        cudaMemcpyDeviceToHost, streams[i]);
    }

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0.0f;
    cudaEventElapsedTime(&ms, start, stop);

    // --- Cleanup streams ---
    for (int i = 0; i < N_CHUNKS; ++i)
        cudaStreamDestroy(streams[i]);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    return ms;
}
 
 // ---------------------------------------------------------------------------
 int main() {
     printf("CUDA Streams Demo\n");
     printf("  Chunks     : %d\n", N_CHUNKS);
     printf("  Chunk size : %d elements (%.1f MB)\n",
            CHUNK_SIZE, CHUNK_SIZE * sizeof(float) / (1024.0 * 1024.0));
     printf("  Iterations : %d per element\n\n", ITERATIONS);
 
     // --- Allocate host memory (*pinned*) and device memory ----------------
     //  KEY POINT: cudaMemcpyAsync requires *pinned* (page-locked) host
     //  memory.  With regular malloc'd memory the copies silently fall back
     //  to synchronous behavior and you lose all overlap.
     //
     float* h_in[N_CHUNKS];
     float* h_out[N_CHUNKS];
     float* d_in[N_CHUNKS];
     float* d_out[N_CHUNKS];
 
    for (int i = 0; i < N_CHUNKS; ++i) {
        cudaMallocHost(&h_in[i],  CHUNK_SIZE * sizeof(float));
        cudaMallocHost(&h_out[i], CHUNK_SIZE * sizeof(float));
        cudaMalloc(&d_in[i],      CHUNK_SIZE * sizeof(float));
        cudaMalloc(&d_out[i],     CHUNK_SIZE * sizeof(float));
 
         // Initialize input data
         for (int j = 0; j < CHUNK_SIZE; ++j) {
             h_in[i][j] = static_cast<float>(rand()) / RAND_MAX;
         }
     }
 
     // --- Run both approaches and compare ---------------------------------
     float ms_seq    = time_sequential(h_in, h_out, d_in, d_out);
     float ms_stream = time_with_streams(h_in, h_out, d_in, d_out);
 
     printf("Sequential (default stream) : %8.2f ms\n", ms_seq);
     printf("Concurrent (%d streams)      : %8.2f ms\n", N_CHUNKS, ms_stream);
     printf("Speedup                     : %8.2fx\n", ms_seq / ms_stream);
 
     // --- Cleanup ---------------------------------------------------------
    for (int i = 0; i < N_CHUNKS; ++i) {
        cudaFreeHost(h_in[i]);
        cudaFreeHost(h_out[i]);
        cudaFree(d_in[i]);
        cudaFree(d_out[i]);
    }
 
     return 0;
 }
 